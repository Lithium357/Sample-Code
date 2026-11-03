// Rust 2021, standard library only. rustc --edition=2021 vectored_cursor.rs
// Borrowed scatter/gather output with explicit progress across failed calls.
// Each Ok(n) commits exactly n bytes. Err commits none for that call, as Write
// requires. Retrying after WouldBlock must use the SAME logical destination.
// No atomic-record, flush, durability or rollback guarantee is implied. An
// endlessly Interrupted writer can prevent completion; readiness waits belong
// to the caller. Do not restart a fresh cursor after a partial transmission.
use std::io::{self, ErrorKind, IoSlice, Write};

struct Pending<'a> {
    parts: &'a [&'a [u8]],
    index: usize,
    offset: usize,
    committed: usize,
    total: usize,
}

impl<'a> Pending<'a> {
    fn new(parts: &'a [&'a [u8]]) -> io::Result<Self> {
        let total = parts
            .iter()
            .try_fold(0usize, |n, part| n.checked_add(part.len()))
            .ok_or_else(|| io::Error::new(ErrorKind::InvalidInput, "total length overflow"))?;
        let mut pending = Self {
            parts,
            index: 0,
            offset: 0,
            committed: 0,
            total,
        };
        pending.skip_empty();
        Ok(pending)
    }

    fn skip_empty(&mut self) {
        while self.index < self.parts.len() && self.offset == self.parts[self.index].len() {
            self.index += 1;
            self.offset = 0;
        }
    }

    fn remaining(&self) -> usize {
        self.total - self.committed
    }

    fn drain<W: Write + ?Sized>(&mut self, writer: &mut W) -> io::Result<()> {
        while self.index < self.parts.len() {
            // A bounded vector avoids allocations and enormous platform iovec
            // counts. A Write implementation may still consume only its first
            // nonempty slice, including Write's default scalar fallback.
            let mut vectors = [IoSlice::new(&[]); 16];
            let mut count = 0;
            let mut offered = 0;
            for (relative, part) in self.parts[self.index..].iter().enumerate() {
                let tail = if relative == 0 {
                    &part[self.offset..]
                } else {
                    part
                };
                if tail.is_empty() {
                    continue;
                }
                vectors[count] = IoSlice::new(tail);
                offered += tail.len(); // <= checked total, so cannot overflow
                count += 1;
                if count == vectors.len() {
                    break;
                }
            }
            let n = match writer.write_vectored(&vectors[..count]) {
                Err(error) if error.kind() == ErrorKind::Interrupted => continue,
                result => result?,
            };
            if n == 0 {
                return Err(io::Error::new(
                    ErrorKind::WriteZero,
                    "pending bytes made no progress",
                ));
            }
            if n > offered {
                // A broken writer violated Write's contract. Its external side
                // effects cannot be repaired, but our cursor must not overrun.
                return Err(io::Error::new(
                    ErrorKind::InvalidData,
                    "writer overreported progress",
                ));
            }
            self.committed += n;
            let mut advance = n;
            while advance > 0 {
                let take = advance.min(self.parts[self.index].len() - self.offset);
                self.offset += take;
                advance -= take;
                self.skip_empty();
            }
            self.skip_empty();
        }
        Ok(())
    }
}

// Fixture transport: flattening is deliberately confined to the test oracle.
// The cursor above never concatenates payload or consults these expectations.
#[derive(Clone, Copy)]
enum Action {
    Take(usize),
    Interrupt,
    Block,
    Fail,
    Zero,
    Lie,
}
struct Scripted {
    actions: std::collections::VecDeque<Action>,
    quota: usize,
    output: Vec<u8>,
    offers: Vec<Vec<u8>>,
}
impl Scripted {
    fn new(actions: &[Action], quota: usize) -> Self {
        Self {
            actions: actions.iter().copied().collect(),
            quota,
            output: vec![],
            offers: vec![],
        }
    }
}
impl Write for Scripted {
    fn write(&mut self, _: &[u8]) -> io::Result<usize> {
        panic!("expected vectored path")
    }
    fn flush(&mut self) -> io::Result<()> {
        panic!("drain does not flush")
    }
    fn write_vectored(&mut self, slices: &[IoSlice<'_>]) -> io::Result<usize> {
        assert!(!slices.is_empty() && slices.len() <= 16);
        assert!(slices.iter().all(|s| !s.is_empty()));
        let offered: Vec<u8> = slices.iter().flat_map(|s| s.iter().copied()).collect();
        self.offers.push(offered.clone());
        let quota = match self.actions.pop_front().unwrap_or(Action::Take(self.quota)) {
            Action::Interrupt => return Err(io::Error::from(ErrorKind::Interrupted)),
            Action::Block => return Err(io::Error::from(ErrorKind::WouldBlock)),
            Action::Fail => return Err(io::Error::new(ErrorKind::BrokenPipe, "fixture pipe")),
            Action::Zero => return Ok(0),
            Action::Lie => return Ok(offered.len() + 1),
            Action::Take(n) => n,
        };
        let n = quota.min(offered.len());
        self.output.extend_from_slice(&offered[..n]);
        Ok(n)
    }
}

// Uses the default Write::write_vectored implementation rather than Scripted.
struct Scalar(Vec<u8>);
impl Write for Scalar {
    fn write(&mut self, data: &[u8]) -> io::Result<usize> {
        let n = data.len().min(1);
        self.0.extend_from_slice(&data[..n]);
        Ok(n)
    }
    fn flush(&mut self) -> io::Result<()> {
        panic!("unexpected flush")
    }
}

fn main() {
    let parts: &[&[u8]] = &[b"", b"ab", b"", b"C\0D", b"\xff", b""];
    let expected = b"abC\0D\xff";
    let mut cursor = Pending::new(parts).unwrap();
    let mut sink = Scripted::new(&[Action::Interrupt, Action::Take(3), Action::Block], 2);
    assert_eq!(
        cursor.drain(&mut sink).unwrap_err().kind(),
        ErrorKind::WouldBlock
    );
    assert_eq!(sink.output, b"abC");
    assert_eq!(
        (
            cursor.index,
            cursor.offset,
            cursor.committed,
            cursor.remaining()
        ),
        (3, 1, 3, 3)
    );
    assert_eq!(
        sink.offers,
        [expected.to_vec(), expected.to_vec(), b"\0D\xff".to_vec()]
    );
    cursor.drain(&mut sink).unwrap();
    assert_eq!(sink.output, expected);
    let calls = sink.offers.len();
    cursor.drain(&mut sink).unwrap();
    assert_eq!(sink.offers.len(), calls); // completed cursor is idempotent

    for (action, kind) in [
        (Action::Zero, ErrorKind::WriteZero),
        (Action::Fail, ErrorKind::BrokenPipe),
        (Action::Lie, ErrorKind::InvalidData),
    ] {
        let mut cursor = Pending::new(parts).unwrap();
        let mut sink = Scripted::new(&[Action::Take(1), action], 2);
        let error = cursor.drain(&mut sink).unwrap_err();
        assert_eq!(error.kind(), kind);
        if kind == ErrorKind::BrokenPipe {
            assert_eq!(error.to_string(), "fixture pipe");
        }
        assert_eq!((cursor.index, cursor.offset, cursor.committed), (1, 1, 1));
        assert_eq!(sink.output, b"a");
        cursor.drain(&mut sink).unwrap();
        assert_eq!(sink.output, expected);
    }
    for prefix in 0..expected.len() {
        for (action, kind) in [
            (Action::Block, ErrorKind::WouldBlock),
            (Action::Fail, ErrorKind::BrokenPipe),
            (Action::Zero, ErrorKind::WriteZero),
        ] {
            let mut script = vec![];
            if prefix > 0 {
                script.push(Action::Take(prefix));
            }
            script.extend([action, action]);
            let mut sink = Scripted::new(&script, 1);
            let mut cursor = Pending::new(parts).unwrap();
            for _ in 0..2 {
                assert_eq!(cursor.drain(&mut sink).unwrap_err().kind(), kind);
                assert_eq!(cursor.committed, prefix);
                assert_eq!(sink.output, &expected[..prefix]);
            }
            cursor.drain(&mut sink).unwrap();
            assert_eq!(sink.output, expected);
        }
    }
    let mut storage = [0u8; 4];
    let mut capacity_limited = &mut storage[..];
    let mut limited = Pending::new(parts).unwrap();
    assert_eq!(
        limited.drain(&mut capacity_limited).unwrap_err().kind(),
        ErrorKind::WriteZero
    );
    assert_eq!(limited.committed, 4);
    assert_eq!(storage, *b"abC\0");
    let mut scalar = Scalar(vec![]);
    Pending::new(parts).unwrap().drain(&mut scalar).unwrap();
    assert_eq!(scalar.0, expected);
    for empty in [&[][..], &[&[][..], &[][..]][..]] {
        let mut cursor = Pending::new(empty).unwrap();
        let mut sink = Scripted::new(&[Action::Fail], 0);
        cursor.drain(&mut sink).unwrap();
        assert_eq!(cursor.remaining(), 0);
        assert!(sink.offers.is_empty());
    }
    let seventeen = [&b"x"[..]; 17];
    let mut sink = Scripted::new(&[], usize::MAX);
    Pending::new(&seventeen).unwrap().drain(&mut sink).unwrap();
    assert_eq!(
        sink.offers.iter().map(Vec::len).collect::<Vec<_>>(),
        [16, 1]
    );
    assert_eq!(sink.output, vec![b'x'; 17]);

    // 1820 segmentation/quota cases, including every placement of empty
    // segments in this range. Expected bytes come from the original flat input,
    // not from Pending's index/offset or Scripted's accumulated output.
    let flat: &[u8] = b"\0A\xffB-1234567";
    let mut cases = 0;
    for end in 0..=flat.len() {
        for first in 0..=end {
            for second in first..=end {
                let split = [
                    &[][..],
                    &flat[..first],
                    &flat[first..second],
                    &[][..],
                    &flat[second..end],
                    &[][..],
                ];
                for quota in [1, 2, 4, 100] {
                    let mut sink = Scripted::new(&[Action::Interrupt], quota);
                    let mut cursor = Pending::new(&split).unwrap();
                    cursor.drain(&mut sink).unwrap();
                    assert_eq!(sink.output, &flat[..end]);
                    assert_eq!(cursor.committed, end);
                    assert_eq!(cursor.remaining(), 0);
                    cases += 1;
                }
            }
        }
    }
    assert_eq!(cases, 1820);
    println!("vectored cursor: fixed failures, fallback, window and {cases} partitions passed");
}
