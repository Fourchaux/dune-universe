## 3.0.4

- **Default print wdith is now changed from 100 to 80** (#1675).
- Much better callback formatting (#1664)!
- Single-argument function doesn't print with parentheses anymore (#1692).
- Printer more lenient when user writes `[%bs.obj {"foo": bar}]`. Probably a confusion with just `{"foo": bar}` (#1659).
- Better formatting for variants constructors with attributes (#1668, #1677).
- Fix exponentiation operator printing associativity (#1678).
