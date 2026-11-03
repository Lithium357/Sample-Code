//! Rust 2021: borrowed records, a fallible iterator and typed parse errors.
//! rustc --edition=2021 borrowed_records.rs -o records && ./records
//! Grammar: nonempty ASCII name [A-Za-z_-]+ ':' unsigned decimal u32. Blank
//! lines are ignored. Errors retain physical line numbers; iteration may resume.
use std::collections::HashMap;

#[derive(Debug, PartialEq)]
enum ParseError {
    MissingColon(usize),
    Name(usize),
    Amount(usize),
}
#[derive(Debug, PartialEq)]
struct Record<'a> {
    name: &'a str,
    amount: u32,
}
struct Records<'a> {
    lines: std::iter::Enumerate<std::str::Lines<'a>>,
}
impl<'a> Records<'a> {
    fn new(text: &'a str) -> Self {
        Self {
            lines: text.lines().enumerate(),
        }
    }
}
impl<'a> Iterator for Records<'a> {
    type Item = Result<Record<'a>, ParseError>;
    fn next(&mut self) -> Option<Self::Item> {
        for (index, line) in self.lines.by_ref() {
            let line = line.trim();
            let number = index + 1;
            if line.is_empty() {
                continue;
            }
            let Some((name, amount)) = line.split_once(':') else {
                return Some(Err(ParseError::MissingColon(number)));
            };
            let name = name.trim();
            let amount = amount.trim();
            if name.is_empty()
                || !name
                    .bytes()
                    .all(|c| c.is_ascii_alphabetic() || c == b'_' || c == b'-')
            {
                return Some(Err(ParseError::Name(number)));
            }
            if amount.is_empty() || !amount.bytes().all(|c| c.is_ascii_digit()) {
                return Some(Err(ParseError::Amount(number)));
            }
            return Some(
                amount
                    .parse::<u32>()
                    .map(|amount| Record { name, amount })
                    .map_err(|_| ParseError::Amount(number)),
            );
        }
        None
    }
}
fn main() {
    let input = String::from("pen:2\n\n pen : 3\nzero:0\n");
    let values = Records::new(&input).collect::<Result<Vec<_>, _>>().unwrap();
    assert_eq!(
        values,
        vec![
            Record {
                name: "pen",
                amount: 2
            },
            Record {
                name: "pen",
                amount: 3
            },
            Record {
                name: "zero",
                amount: 0
            }
        ]
    );
    for value in &values {
        let address = value.name.as_ptr() as usize;
        let start = input.as_ptr() as usize;
        assert!((start..start + input.len()).contains(&address));
    }
    let totals = values.iter().fold(HashMap::new(), |mut map, value| {
        *map.entry(value.name).or_insert(0u64) += u64::from(value.amount);
        map
    });
    assert_eq!(totals.get("pen"), Some(&5));
    assert!(Records::new("").next().is_none());
    for (bad, expected) in [
        ("no colon", ParseError::MissingColon(1)),
        (":1", ParseError::Name(1)),
        ("é:1", ParseError::Name(1)),
        ("x:-1", ParseError::Amount(1)),
        ("x:+1", ParseError::Amount(1)),
        ("x:4294967296", ParseError::Amount(1)),
    ] {
        assert_eq!(Records::new(bad).next().unwrap(), Err(expected));
    }
    let mut stream = Records::new("bad\nx:1");
    assert_eq!(stream.next().unwrap(), Err(ParseError::MissingColon(1)));
    assert_eq!(stream.next().unwrap().unwrap().amount, 1);
    drop(values);
    assert!(input.starts_with("pen")); // The owned buffer remains usable.
    println!("Borrowed records: lifetimes, fallible iteration, line errors and boundaries passed");
}
