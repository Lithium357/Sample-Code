//! Rust 2021, std only. Chunked UTF-8 decoding with an at-most-three-byte tail.
//! Successful feeds publish complete scalar values. A malformed feed publishes
//! no text for that call; earlier calls cannot be rolled back. Errors are sticky
//! until reset, except size-limit errors, which leave the entire state unchanged.
//! finish rejects incomplete tails; successful finish is idempotent and closes
//! the decoder. Offsets count original input bytes, not characters.
#[derive(Clone, Debug, PartialEq, Eq)]
enum Error {
    Invalid { at: usize, bad_len: Option<usize> },
    ChunkTooLarge,
    MessageTooLarge,
    Closed,
}
#[derive(Default)]
struct Decoder {
    tail: Vec<u8>,
    accepted: usize,
    failure: Option<Error>,
    closed: bool,
}
impl Decoder {
    fn feed(&mut self, chunk: &[u8]) -> Result<String, Error> {
        if self.closed {
            return Err(Error::Closed);
        }
        if let Some(error) = &self.failure {
            return Err(error.clone());
        }
        if chunk.len() > 4096 {
            return Err(Error::ChunkTooLarge);
        }
        if chunk.len() > 65536 - self.accepted {
            return Err(Error::MessageTooLarge);
        }
        let base = self.accepted - self.tail.len();
        let mut combined = self.tail.clone();
        combined.extend_from_slice(chunk);
        let (valid, pending) = match std::str::from_utf8(&combined) {
            Ok(_) => (combined.len(), 0),
            Err(error) => {
                if let Some(length) = error.error_len() {
                    let failure = Error::Invalid {
                        at: base + error.valid_up_to(),
                        bad_len: Some(length),
                    };
                    self.failure = Some(failure.clone());
                    return Err(failure);
                }
                (error.valid_up_to(), combined.len() - error.valid_up_to())
            }
        };
        assert!(pending <= 3);
        let output = std::str::from_utf8(&combined[..valid]).unwrap().to_owned();
        self.tail = combined[valid..].to_vec();
        self.accepted += chunk.len();
        Ok(output)
    }
    fn finish(&mut self) -> Result<(), Error> {
        if let Some(error) = &self.failure {
            return Err(error.clone());
        }
        if !self.tail.is_empty() {
            let error = Error::Invalid {
                at: self.accepted - self.tail.len(),
                bad_len: None,
            };
            self.failure = Some(error.clone());
            return Err(error);
        }
        self.closed = true;
        Ok(())
    }
    fn reset(&mut self) {
        *self = Self::default();
    }
}
fn main() {
    let mut partitions = 0;
    for text in ["", "ASCII", "a\0b", "é雪😀", "start\n💧end"] {
        let bytes = text.as_bytes();
        // Every partition into three chunks, including empty chunks.
        for first in 0..=bytes.len() {
            for second in first..=bytes.len() {
                let mut decoder = Decoder::default();
                let mut output = String::new();
                for chunk in [&bytes[..first], &bytes[first..second], &bytes[second..]] {
                    output.push_str(&decoder.feed(chunk).unwrap());
                }
                assert_eq!(decoder.finish(), Ok(()));
                assert_eq!(decoder.finish(), Ok(()));
                assert_eq!(decoder.feed(b""), Err(Error::Closed));
                assert_eq!(output, text);
                assert_eq!(decoder.accepted, bytes.len());
                partitions += 1;
            }
        }
    }
    // The whole-input standard-library decoder is the reference for this
    // buffering layer, not an independent implementation of Unicode itself.
    let text: String = (0..=0x10ffff)
        .step_by(7919)
        .filter_map(char::from_u32)
        .collect();
    let reference = std::str::from_utf8(text.as_bytes()).unwrap();
    for width in 1..=9 {
        let mut decoder = Decoder::default();
        let mut output = String::new();
        for chunk in text.as_bytes().chunks(width) {
            output.push_str(&decoder.feed(chunk).unwrap());
        }
        decoder.finish().unwrap();
        assert_eq!(output, reference);
    }
    let malformed: &[(&[u8], usize, usize)] = &[
        (&[0x80], 0, 1),
        (&[0xc0, 0x80], 0, 1),
        (&[0xed, 0xa0, 0x80], 0, 1),
        (&[0xf4, 0x90, 0x80, 0x80], 0, 1),
        (&[b'a', b'b', 0xe2, 0x82, b'x'], 2, 2),
    ];
    for &(bytes, at, length) in malformed {
        let expected = Error::Invalid {
            at,
            bad_len: Some(length),
        };
        for split in 0..=bytes.len() {
            let mut decoder = Decoder::default();
            let result = decoder
                .feed(&bytes[..split])
                .and_then(|_| decoder.feed(&bytes[split..]));
            assert_eq!(result, Err(expected.clone()));
            assert_eq!(decoder.feed(b"valid"), Err(expected.clone()));
            assert_eq!(decoder.finish(), Err(expected.clone()));
        }
    }
    let mut decoder = Decoder::default();
    assert_eq!(decoder.feed(b"ok\xe2\x82").unwrap(), "ok");
    let truncated = Error::Invalid {
        at: 2,
        bad_len: None,
    };
    assert_eq!(decoder.finish(), Err(truncated.clone()));
    assert_eq!(decoder.feed(&[0xac]), Err(truncated));
    decoder.reset();
    assert_eq!(decoder.feed(&[0xf0]).unwrap(), "");
    assert_eq!(decoder.feed(&vec![0; 4097]), Err(Error::ChunkTooLarge));
    assert_eq!(decoder.accepted, 1);
    assert_eq!(decoder.tail, vec![0xf0]);
    assert_eq!(decoder.feed(&[0x9f, 0x98, 0x80]).unwrap(), "😀");
    decoder.finish().unwrap();
    decoder.reset();
    for _ in 0..16 {
        assert_eq!(decoder.feed(&vec![b'x'; 4096]).unwrap().len(), 4096);
    }
    assert_eq!(decoder.accepted, 65536);
    assert_eq!(decoder.feed(b"x"), Err(Error::MessageTooLarge));
    assert_eq!(decoder.accepted, 65536);
    assert_eq!(decoder.feed(b""), Ok(String::new()));
    decoder.finish().unwrap();
    println!("UTF-8 streaming: {partitions} three-chunk partitions, scalar reference, exact sticky errors, truncation, reset and size limits passed");
}
