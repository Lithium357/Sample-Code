//! Rust 2021: strict application/x-www-form-urlencoded component decoding.
//! '+' means space, percent escapes are decoded once, UTF-8 is required, and
//! duplicate keys retain order. Size limits are explicit; no network is used.
#[derive(Debug, PartialEq)]
enum Error {
    TooLong,
    TooMany,
    Escape(usize),
    Utf8,
}
fn hex(c: u8) -> Option<u8> {
    match c {
        b'0'..=b'9' => Some(c - b'0'),
        b'a'..=b'f' => Some(c - b'a' + 10),
        b'A'..=b'F' => Some(c - b'A' + 10),
        _ => None,
    }
}
fn component(input: &str) -> Result<String, Error> {
    let bytes = input.as_bytes();
    let mut output = Vec::new();
    let mut i = 0;
    while i < bytes.len() {
        match bytes[i] {
            b'+' => output.push(b' '),
            b'%' => {
                if i + 2 >= bytes.len() {
                    return Err(Error::Escape(i));
                }
                let a = hex(bytes[i + 1]).ok_or(Error::Escape(i))?;
                let b = hex(bytes[i + 2]).ok_or(Error::Escape(i))?;
                output.push(a * 16 + b);
                i += 2;
            }
            byte => output.push(byte),
        }
        i += 1;
    }
    String::from_utf8(output).map_err(|_| Error::Utf8)
}
fn query(input: &str) -> Result<Vec<(String, String)>, Error> {
    if input.len() > 1024 {
        return Err(Error::TooLong);
    }
    if input.is_empty() {
        return Ok(vec![]);
    }
    let mut result = vec![];
    for pair in input.split('&') {
        if result.len() == 16 {
            return Err(Error::TooMany);
        }
        let (key, value) = pair.split_once('=').unwrap_or((pair, ""));
        result.push((component(key)?, component(value)?));
    }
    Ok(result)
}
fn encode(input: &str) -> String {
    let mut text = String::new();
    for byte in input.bytes() {
        if byte.is_ascii_alphanumeric() {
            text.push(char::from(byte))
        } else {
            text.push_str(&format!("%{byte:02X}"));
        }
    }
    text
}
fn main() {
    assert_eq!(
        query("tag=a&tag=b&empty&=value").unwrap(),
        vec![
            ("tag".into(), "a".into()),
            ("tag".into(), "b".into()),
            ("empty".into(), "".into()),
            ("".into(), "value".into())
        ]
    );
    assert_eq!(component("a+b%2Bc%2520").unwrap(), "a b+c%20");
    assert_eq!(component("%E2%98%83").unwrap(), "☃");
    assert_eq!(component("x%Q0"), Err(Error::Escape(1)));
    assert_eq!(component("%A"), Err(Error::Escape(0)));
    assert_eq!(component("%FF"), Err(Error::Utf8));
    assert!(query("").unwrap().is_empty());
    assert!(query(&"x".repeat(1024)).is_ok());
    assert_eq!(query(&"x".repeat(1025)), Err(Error::TooLong));
    assert!(query(&vec!["x"; 16].join("&")).is_ok());
    assert_eq!(query(&vec!["x"; 17].join("&")), Err(Error::TooMany));
    for input in ["", "plain", "a+b&c=d", "雪\n☃", "\0", "%20"] {
        assert_eq!(component(&encode(input)).unwrap(), input);
    }
    println!("Query decoder: duplicates, UTF-8, one-pass escaping, boundaries and independent round trips passed");
}
