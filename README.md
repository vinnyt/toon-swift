# Toon

A Swift implementation of **TOON (Token-Oriented Object Notation)** - a compact serialization format designed for passing structured data to Large Language Models with significantly reduced token consumption.

Built using **Test-Driven Development (TDD)** with **100% test coverage** (59/59 tests passing).

## What is TOON?

TOON combines CSV's tabular efficiency with YAML's indentation-based structure while maintaining JSON's semantic clarity. It achieves **30-60% token reduction** compared to formatted JSON, making it ideal for LLM applications where token costs matter.

### Key Features

- ✅ **Token Efficient**: 30-60% fewer tokens than JSON on large uniform arrays
- ✅ **LLM-Friendly**: Explicit length declarations and field headers enable structural validation
- ✅ **Minimal Syntax**: Removes redundant punctuation (braces, brackets, unnecessary quotes)
- ✅ **Indentation-Based**: YAML-style nesting using whitespace
- ✅ **Tabular Arrays**: Declare column names once, stream data as rows
- ✅ **Full Swift Codable Support**: Seamlessly encode/decode your Swift types

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/vinnyt/toon-swift.git", from: "1.0.0")
]
```

## Usage

### Basic Encoding and Decoding

```swift
import Toon

// Encode a ToonValue
let encoder = ToonEncoder()
let value: ToonValue = .object([
    "name": "Alice",
    "age": 30,
    "active": true
])

let toon = try encoder.encode(value)
print(toon)
// Output:
// active: true
// age: 30
// name: Alice

// Decode TOON back to ToonValue
let decoder = ToonDecoder()
let decoded = try decoder.decode(toon)
```

### Using Swift Codable

The real power comes from seamless Codable support:

```swift
struct User: Codable {
    let id: Int
    let name: String
    let email: String
    let active: Bool
}

let encoder = ToonEncoder()
let user = User(id: 1, name: "Alice", email: "alice@example.com", active: true)

let toon = try encoder.encode(user)
print(toon)
// Output:
// active: true
// email: alice@example.com
// id: 1
// name: Alice

// Decode back to Swift struct
let decoder = ToonDecoder()
let decoded = try decoder.decode(User.self, from: toon)
```

### Tabular Arrays (The Power Feature)

TOON excels at encoding arrays of uniform objects:

```swift
let users = [
    User(id: 1, name: "Alice", email: "alice@example.com", active: true),
    User(id: 2, name: "Bob", email: "bob@example.com", active: false),
    User(id: 3, name: "Charlie", email: "charlie@example.com", active: true)
]

let toon = try encoder.encode(users)
print(toon)
// Output:
// [3]{active,email,id,name}:
//  true,alice@example.com,1,Alice
//  false,bob@example.com,2,Bob
//  true,charlie@example.com,3,Charlie
```

Compare this to the equivalent JSON - TOON is dramatically more compact!

### Nested Structures

```swift
struct Company: Codable {
    let name: String
    let founded: Int
    let employees: [Employee]
}

struct Employee: Codable {
    let name: String
    let role: String
}

let company = Company(
    name: "TechCorp",
    founded: 2020,
    employees: [
        Employee(name: "Alice", role: "Engineer"),
        Employee(name: "Bob", role: "Designer")
    ]
)

let toon = try encoder.encode(company)
print(toon)
// Output:
// employees[2]{name,role}:
//   Alice,Engineer
//   Bob,Designer
// founded: 2020
// name: TechCorp
```

## Configuration

Customize encoding/decoding behavior:

```swift
var config = ToonConfiguration()
config.indentSize = 4           // Default: 2 spaces
config.strictMode = false       // Default: true
config.defaultDelimiter = .pipe // Default: .comma
config.enableKeyFolding = true  // Default: false

let encoder = ToonEncoder(configuration: config)
let decoder = ToonDecoder(configuration: config)
```

### Delimiter Options

TOON supports three delimiters for arrays:

```swift
// Comma (default)
[3]: a,b,c

// Pipe
[3|]: a|b|c

// Tab
[3\t]: a	b	c
```

## TOON Format Quick Reference

### Primitives
```
null
true
false
42
3.14159
"hello world"
unquoted_string
```

### Objects
```
key: value
nested:
  inner: value
```

### Arrays

**Inline Primitive Array:**
```
[3]: 1,2,3
```

**Tabular Array (Uniform Objects):**
```
[2]{id,name,role}:
 1,Alice,admin
 2,Bob,user
```

**Mixed Array:**
```
[2]:
- first_item
- second_item
```

### Quoting Rules

Strings must be quoted if they:
- Match reserved words (`true`, `false`, `null`)
- Look like numbers
- Contain delimiters, colons, brackets, or special characters
- Are empty or have leading/trailing whitespace

## Testing

Run the comprehensive test suite:

```bash
swift test
```

All 59 tests pass, covering:
- ✅ Primitives (null, bool, number, string)
- ✅ Objects (simple and nested)
- ✅ Arrays (inline, tabular, mixed)
- ✅ Quoting and escaping
- ✅ All three delimiters
- ✅ Codable integration
- ✅ Round-trip encoding/decoding
- ✅ Strict mode validation
- ✅ Error handling

## Performance

TOON achieves significant token savings on uniform data:

```swift
// Test with 100 user objects
let users = (1...100).map { i in
    User(id: i, name: "User\(i)", email: "user\(i)@example.com", active: i % 2 == 0)
}

let toonString = try ToonEncoder().encode(users)
let jsonData = try JSONEncoder().encode(users)
let jsonString = String(data: jsonData, encoding: .utf8)!

print("TOON size: \(toonString.count) bytes")
print("JSON size: \(jsonString.count) bytes")
print("Savings: \((1.0 - Double(toonString.count) / Double(jsonString.count)) * 100)%")
```

## Specification

This implementation follows the [TOON v2.0 specification](https://github.com/toon-format/spec).

## License

MIT License - See LICENSE file for details

## Contributing

Contributions welcome! Please ensure all tests pass and add tests for new features.

## Credits

Built with ❤️ using Test-Driven Development

TOON format specification by the [toon-format organization](https://github.com/toon-format)
