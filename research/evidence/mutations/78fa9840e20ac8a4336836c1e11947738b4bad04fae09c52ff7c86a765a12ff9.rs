// Rust edition 2021, Rust 1.81+ IoSliceMut::advance_slices; std only.
// Exclusive borrowed scatter destinations; resume the SAME plan on the SAME
// logical source after WouldBlock. Never restart a fresh plan over a prefix.
// Each successful read commits its reported prefix; Err commits no bytes for
// that call, per Read's contract. Earlier progress survives errors/EOF.
// No rollback, readiness wait, atomic record or nonblocking guarantee. An
// indefinitely Interrupted reader can prevent completion. Reader must honor Read.
// API: https://doc.rust-lang.org/std/io/trait.Read.html
use std::collections::VecDeque;
use std::fmt;
use std::io::{self, Cursor, ErrorKind, IoSliceMut, Read};

#[derive(Debug)]
struct FillError {
    filled: usize,
    source: io::Error,
}

struct Fill<'buffers, 'data> {
    remaining: &'buffers mut [IoSliceMut<'data>],
    filled: usize,
    total: usize,
}

impl<'buffers, 'data> Fill<'buffers, 'data> {
    fn new(buffers: &'buffers mut [IoSliceMut<'data>]) -> io::Result<Self> {
        let total = buffers.iter().try_fold(0usize, |sum, b| sum.checked_add(b.len()))
            .ok_or_else(|| io::Error::new(ErrorKind::InvalidInput, "capacity overflow"))?;
        Ok(Self { remaining: buffers, filled: 0, total })
    }

    fn drive<R: Read + ?Sized>(&mut self, reader: &mut R) -> Result<(), FillError> {
        while self.filled < self.total {
            // In particular, skip runs of >16 empty buffers before offering.
            IoSliceMut::advance_slices(&mut self.remaining, 0);
            let count = self.remaining.len().min(16);
            let offered: usize = self.remaining[..count].iter().map(|b| b.len()).sum();
            let n = match reader.read_vectored(&mut self.remaining[..count]) {
                Err(error) if error.kind() == ErrorKind::Interrupted => continue,
                Err(source) => return Err(FillError { filled: self.filled, source }),
                Ok(0) => return Err(FillError { filled: self.filled,
                    source: io::Error::new(ErrorKind::UnexpectedEof, "scatter destination incomplete") }),
                Ok(n) => n,
            };
            if n > offered {
                // Reject the report before advancing. Illegal reader side
                // effects cannot be undone; this is not a rollback mechanism.
                return Err(FillError { filled: self.filled,
                    source: io::Error::new(ErrorKind::InvalidData, "reader overreported") });
            }
            self.filled += n;
            // omitted advancement
        }
        Ok(()) // zero total: no transport call, even for a failing reader
    }
}

#[derive(Clone, Copy)]
enum Event { Take(usize), Interrupted, Blocked, Fault(u32), Eof, Overreport }
#[derive(Debug)]
struct Marker(u32);
impl fmt::Display for Marker {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { write!(f, "fixture {}", self.0) }
}
impl std::error::Error for Marker {}

struct Scripted {
    bytes: Vec<u8>,
    at: usize,
    events: VecDeque<Event>,
    offered_counts: Vec<usize>,
}
impl Scripted {
    fn new(bytes: Vec<u8>, events: &[Event]) -> Self {
        Self { bytes, at: 0, events: events.iter().copied().collect(), offered_counts: vec![] }
    }
}
impl Read for Scripted {
    fn read(&mut self, _: &mut [u8]) -> io::Result<usize> { panic!("fixture requires vectored call") }
    fn read_vectored(&mut self, out: &mut [IoSliceMut<'_>]) -> io::Result<usize> {
        self.offered_counts.push(out.len());
        let capacity: usize = out.iter().map(|b| b.len()).sum();
        let limit = match self.events.pop_front().unwrap_or(Event::Take(usize::MAX)) {
            Event::Take(n) => n,
            Event::Interrupted => return Err(ErrorKind::Interrupted.into()),
            Event::Blocked => return Err(ErrorKind::WouldBlock.into()),
            Event::Fault(value) => return Err(io::Error::new(ErrorKind::Other, Marker(value))),
            Event::Eof => return Ok(0),
            Event::Overreport => return Ok(capacity + 1),
        };
        let n = limit.min(capacity).min(self.bytes.len() - self.at);
        let mut left = n;
        for buffer in out {
            let size = left.min(buffer.len());
            buffer[..size].copy_from_slice(&self.bytes[self.at..self.at + size]);
            self.at += size;
            left -= size;
        }
        Ok(n)
    }
}

// Deliberately does NOT override read_vectored: exercise Read's scalar fallback.
struct Scalar { cursor: Cursor<Vec<u8>>, max: usize, calls: usize }
impl Read for Scalar {
    fn read(&mut self, out: &mut [u8]) -> io::Result<usize> {
        self.calls += 1;
        let n = self.max.min(out.len());
        self.cursor.read(&mut out[..n])
    }
}

fn data(n: usize) -> Vec<u8> { (0..n).map(|i| ((i * 73 + 19) % 256) as u8).collect() }
fn guarded(sizes: &[usize]) -> Vec<Vec<u8>> {
    sizes.iter().map(|&n| { let mut b = vec![0xcc; n + 2]; b[0] = 0xa1; b[n + 1] = 0xb2; b }).collect()
}
fn slices(storage: &mut [Vec<u8>]) -> Vec<IoSliceMut<'_>> {
    storage.iter_mut().map(|b| { let end = b.len() - 1; IoSliceMut::new(&mut b[1..end]) }).collect()
}
// Independent flat-prefix oracle: no vectored cursor/advance code.
fn check(storage: &[Vec<u8>], source: &[u8], filled: usize) {
    let mut offset = 0;
    for b in storage {
        assert_eq!(b[0], 0xa1, "leading canary");
        assert_eq!(b[b.len() - 1], 0xb2, "trailing canary");
        for &actual in &b[1..b.len() - 1] {
            let expected = if offset < filled { source[offset] } else { 0xcc };
            assert_eq!(actual, expected, "flat-prefix destination at {offset}");
            offset += 1;
        }
    }
}

fn main() {
    let mut cases = 0;
    let mut layouts = vec![vec![], vec![0], vec![0; 40], vec![1], vec![0, 1, 0, 2, 5, 0],
        vec![0; 33], vec![1024, 0, 17], vec![1; 40]];
    layouts[5].extend([3, 0, 7]);
    let mut seed = 0x93a1_u32;
    for _ in 0..200 {
        let count = (seed % 45) as usize;
        let mut sizes = vec![];
        for _ in 0..count {
            seed = seed.wrapping_mul(1664525).wrapping_add(1013904223);
            sizes.push((seed % 17) as usize);
        }
        layouts.push(sizes);
        seed = seed.wrapping_add(1);
    }
    for sizes in layouts {
        let total: usize = sizes.iter().sum();
        let expected = data(total + 3); // plan must not consume beyond its capacity
        let start = sizes.iter().position(|&n| n != 0).unwrap_or(sizes.len());
        let first_offer: usize = sizes[start..].iter().take(16).sum();
        for step in [1, 2, 7, 64, 4096] {
            let mut storage = guarded(&sizes);
            let mut vectors = slices(&mut storage);
            let mut plan = Fill::new(&mut vectors).unwrap();
            let mut reader = Scripted::new(expected.clone(), &[Event::Interrupted, Event::Take(step),
                Event::Interrupted, Event::Blocked, Event::Blocked]);
            let first_take = step.min(first_offer);
            if total > first_take {
                let error = plan.drive(&mut reader).unwrap_err();
                assert_eq!(error.source.kind(), ErrorKind::WouldBlock, "blocked status");
                assert_eq!(error.filled, first_take, "reported committed prefix");
                assert_eq!(plan.filled, first_take);
                assert_eq!(reader.at, first_take);
                let calls = reader.offered_counts.len();
                let error = plan.drive(&mut reader).unwrap_err();
                assert_eq!(error.source.kind(), ErrorKind::WouldBlock);
                assert_eq!(error.filled, first_take, "repeated block retains prefix");
                assert_eq!(reader.at, first_take);
                assert_eq!(reader.offered_counts.len(), calls + 1, "caller owns readiness retries");
            }
            // Continue with the existing borrowed plan, never rebuild at zero.
            plan.drive(&mut reader).unwrap();
            assert_eq!(plan.filled, total);
            let calls = reader.offered_counts.len();
            plan.drive(&mut reader).unwrap();
            assert_eq!(reader.offered_counts.len(), calls, "complete plan performs no read");
            drop(plan);
            drop(vectors);
            check(&storage, &expected, total);
            assert_eq!(reader.at, total, "no read ahead");
            assert!(reader.offered_counts.iter().all(|&n| n <= 16));
            cases += 1;

            let mut storage = guarded(&sizes);
            let mut vectors = slices(&mut storage);
            let mut plan = Fill::new(&mut vectors).unwrap();
            let mut reader = Scalar { cursor: Cursor::new(expected.clone()), max: step, calls: 0 };
            plan.drive(&mut reader).unwrap();
            assert_eq!(plan.filled, total);
            assert_eq!(reader.cursor.position(), total as u64);
            if total == 0 { assert_eq!(reader.calls, 0, "empty scalar target"); }
            drop(plan);
            drop(vectors);
            check(&storage, &expected, total);
            cases += 1;
        }
    }

    // Every possible early EOF across buffers, with untouched suffix/canaries.
    for prefix in 0..9 {
        let expected = data(prefix);
        let mut storage = guarded(&[0, 2, 0, 3, 4, 0]);
        let mut vectors = slices(&mut storage);
        let mut plan = Fill::new(&mut vectors).unwrap();
        let mut reader = Scripted::new(expected.clone(), &[]);
        let error = plan.drive(&mut reader).unwrap_err();
        assert_eq!(error.source.kind(), ErrorKind::UnexpectedEof);
        assert_eq!(error.filled, prefix);
        assert_eq!(plan.filled, prefix);
        drop(plan); drop(vectors);
        check(&storage, &expected, prefix);
        cases += 1;
    }
    // Original custom error payload survives, along with its committed count.
    let expected = data(9);
    let mut storage = guarded(&[2, 0, 3, 4]);
    let mut vectors = slices(&mut storage);
    let mut plan = Fill::new(&mut vectors).unwrap();
    let mut reader = Scripted::new(expected.clone(), &[Event::Take(3), Event::Fault(71)]);
    let error = plan.drive(&mut reader).unwrap_err();
    assert_eq!(error.filled, 3);
    assert_eq!(error.source.get_ref().unwrap().downcast_ref::<Marker>().unwrap().0, 71);
    plan.drive(&mut reader).unwrap();
    drop(plan); drop(vectors);
    check(&storage, &expected, 9);

    // Ok(0) is observable EOF, not a busy-loop; caller may explicitly retry it.
    let mut out = [0xcc; 2];
    let mut vectors = [IoSliceMut::new(&mut out)];
    let mut plan = Fill::new(&mut vectors).unwrap();
    let mut reader = Scripted::new(vec![6, 7], &[Event::Eof]);
    assert_eq!(plan.drive(&mut reader).unwrap_err().filled, 0);
    assert_eq!(reader.offered_counts.len(), 1);
    plan.drive(&mut reader).unwrap();
    drop(plan);
    assert_eq!(out, [6, 7]);

    let mut out = [0xcc; 2];
    let mut vectors = [IoSliceMut::new(&mut out)];
    let mut plan = Fill::new(&mut vectors).unwrap();
    let mut reader = Scripted::new(vec![8, 9], &[Event::Take(1), Event::Overreport]);
    let error = plan.drive(&mut reader).unwrap_err();
    assert_eq!(error.source.kind(), ErrorKind::InvalidData);
    assert_eq!(error.filled, 1);
    assert_eq!(plan.filled, 1);
    drop(plan);
    assert_eq!(out, [8, 0xcc]);
    println!("vectored fill: {} differential/error cases passed", cases + 3);
}
