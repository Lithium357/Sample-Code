//! Checked integer expression evaluator: lexer + Pratt parser, no dependencies.
//! rustc --edition=2021 pratt_calculator.rs -o calculator && ./calculator
//! Grammar: integers, parentheses, unary +/-, + - * / %, and right-associative ^.
//! Exponentiation binds more tightly than unary minus: -2^2 is -(2^2).
//! Every arithmetic operation is checked. Nesting and exponent sizes are bounded.

#[derive(Debug, Clone, PartialEq)]
enum Token {
    Number(i64),
    Op(char),
    Left,
    Right,
    End,
}

#[derive(Debug, Clone, PartialEq)]
struct Error {
    offset: usize,
    message: &'static str,
}
type Result<T> = std::result::Result<T, Error>;

fn lex(input: &str) -> Result<Vec<(Token, usize)>> {
    let bytes = input.as_bytes();
    let mut tokens = Vec::new();
    let mut i = 0;
    while i < bytes.len() {
        let start = i;
        match bytes[i] {
            b'0'..=b'9' => {
                let mut value = 0i64;
                while i < bytes.len() && bytes[i].is_ascii_digit() {
                    value = value
                        .checked_mul(10)
                        .and_then(|n| n.checked_add((bytes[i] - b'0') as i64))
                        .ok_or(Error {
                            offset: start,
                            message: "integer literal overflow",
                        })?;
                    i += 1;
                }
                tokens.push((Token::Number(value), start));
                continue;
            }
            b'+' | b'-' | b'*' | b'/' | b'%' | b'^' => {
                tokens.push((Token::Op(bytes[i] as char), start))
            }
            b'(' => tokens.push((Token::Left, start)),
            b')' => tokens.push((Token::Right, start)),
            c if c.is_ascii_whitespace() => {}
            _ => {
                return Err(Error {
                    offset: i,
                    message: "unexpected character",
                })
            }
        }
        i += 1;
    }
    tokens.push((Token::End, input.len()));
    Ok(tokens)
}

struct Parser {
    tokens: Vec<(Token, usize)>,
    cursor: usize,
}
impl Parser {
    fn error(&self, message: &'static str) -> Error {
        Error {
            offset: self.tokens[self.cursor].1,
            message,
        }
    }
    fn expression(&mut self, minimum: u8, depth: usize) -> Result<i64> {
        if depth > 128 {
            return Err(self.error("expression nesting limit"));
        }
        let (token, position) = self.tokens[self.cursor].clone();
        // Keep the End sentinel in place, including on missing-operand errors.
        if token == Token::End {
            return Err(self.error("expected an operand"));
        }
        self.cursor += 1;
        let mut left = match token {
            Token::Number(value) => value,
            Token::Op('+') => self.expression(5, depth + 1)?,
            Token::Op('-') => self.expression(5, depth + 1)?.checked_neg().ok_or(Error {
                offset: position,
                message: "negation overflow",
            })?,
            Token::Left => {
                let value = self.expression(0, depth + 1)?;
                if self.tokens[self.cursor].0 != Token::Right {
                    return Err(self.error("expected closing parenthesis"));
                }
                self.cursor += 1;
                value
            }
            _ => {
                return Err(Error {
                    offset: position,
                    message: "expected an operand",
                })
            }
        };
        loop {
            let (operator, offset) = match self.tokens[self.cursor] {
                (Token::Op(c), p) => (c, p),
                _ => break,
            };
            let (left_power, right_power) = match operator {
                '+' | '-' => (1, 2),
                '*' | '/' | '%' => (3, 4),
                '^' => (7, 6), // Lower right binding power permits a^b^c = a^(b^c).
                _ => unreachable!(),
            };
            if left_power < minimum {
                break;
            }
            self.cursor += 1;
            let right = self.expression(right_power, depth + 1)?;
            let value = match operator {
                '+' => left.checked_add(right),
                '-' => left.checked_sub(right),
                '*' => left.checked_mul(right),
                '/' => {
                    if right == 0 {
                        return Err(Error {
                            offset,
                            message: "division by zero",
                        });
                    }
                    left.checked_div(right)
                }
                '%' => {
                    if right == 0 {
                        return Err(Error {
                            offset,
                            message: "remainder by zero",
                        });
                    }
                    left.checked_rem(right)
                }
                '^' => {
                    if !(0..=63).contains(&right) {
                        return Err(Error {
                            offset,
                            message: "exponent must be in 0..63",
                        });
                    }
                    left.checked_pow(right as u32)
                }
                _ => unreachable!(),
            };
            left = value.ok_or(Error {
                offset,
                message: "arithmetic overflow",
            })?;
        }
        Ok(left)
    }
}

fn evaluate(input: &str) -> Result<i64> {
    if input.len() > 16384 {
        return Err(Error {
            offset: 0,
            message: "input length limit",
        });
    }
    let mut parser = Parser {
        tokens: lex(input)?,
        cursor: 0,
    };
    let result = parser.expression(0, 0)?;
    if parser.tokens[parser.cursor].0 != Token::End {
        return Err(parser.error("unexpected trailing token"));
    }
    Ok(result)
}

fn main() {
    let examples = [
        ("2+3*4", 14),
        ("(2+3)*4", 20),
        ("2^3^2", 512),
        ("-2^2", -4),
        ("(-2)^2", 4),
        ("10-3-2", 5),
        ("20/3", 6),
        ("-20/3", -6),
        ("-20%3", -2),
        ("1--2", 3),
        (" + ( 7 ) ", 7),
        ("0^0", 1),
        ("9223372036854775807", i64::MAX),
    ];
    for (expression, expected) in examples {
        assert_eq!(evaluate(expression), Ok(expected), "{expression}");
    }
    for invalid in [
        "",
        "()",
        "1+",
        "(2",
        "2)",
        "1 2",
        "2**3",
        "a+1",
        "1/0",
        "1%0",
        "2^-1",
        "2^64",
        "9223372036854775808",
        "9223372036854775807+1",
        "3037000500*3037000500",
        "(-9223372036854775807-1)/-1",
    ] {
        assert!(
            evaluate(invalid).is_err(),
            "accepted invalid expression {invalid}"
        );
    }
    assert_eq!(evaluate("1 + @").unwrap_err().offset, 4);
    assert!(evaluate(&"(".repeat(200)).is_err());
    // A family of identities exercises parentheses, precedence and subtraction.
    for a in -20i64..=20 {
        for b in -20i64..=20 {
            assert_eq!(evaluate(&format!("({a}+{b})^2-({a}-{b})^2")), Ok(4 * a * b));
        }
    }
    println!("Pratt calculator: precedence, errors, limits and 1681 identities passed");
}
