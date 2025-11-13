import Testing
import Foundation
@testable import Toon

// MARK: - Primitive Tests

@Test("Decode null primitive")
func decodeNull() throws {
    let decoder = ToonDecoder()
    let result = try decoder.decode("null")
    #expect(result == .null)
}

@Test("Decode true boolean")
func decodeTrue() throws {
    let decoder = ToonDecoder()
    let result = try decoder.decode("true")
    #expect(result == .bool(true))
}

@Test("Decode false boolean")
func decodeFalse() throws {
    let decoder = ToonDecoder()
    let result = try decoder.decode("false")
    #expect(result == .bool(false))
}

@Test("Decode integer number")
func decodeInteger() throws {
    let decoder = ToonDecoder()
    let result = try decoder.decode("42")
    #expect(result == .number(42))
}

@Test("Decode negative number")
func decodeNegativeNumber() throws {
    let decoder = ToonDecoder()
    let result = try decoder.decode("-123")
    #expect(result == .number(-123))
}

@Test("Decode decimal number")
func decodeDecimal() throws {
    let decoder = ToonDecoder()
    let result = try decoder.decode("3.14159")
    #expect(result == .number(3.14159))
}

@Test("Decode unquoted string")
func decodeUnquotedString() throws {
    let decoder = ToonDecoder()
    let result = try decoder.decode("hello")
    #expect(result == .string("hello"))
}

@Test("Decode quoted string")
func decodeQuotedString() throws {
    let decoder = ToonDecoder()
    let result = try decoder.decode("\"hello world\"")
    #expect(result == .string("hello world"))
}

@Test("Encode null primitive")
func encodeNull() throws {
    let encoder = ToonEncoder()
    let result = try encoder.encode(.null)
    #expect(result == "null")
}

@Test("Encode boolean primitives")
func encodeBooleans() throws {
    let encoder = ToonEncoder()
    #expect(try encoder.encode(.bool(true)) == "true")
    #expect(try encoder.encode(.bool(false)) == "false")
}

@Test("Encode integer number")
func encodeInteger() throws {
    let encoder = ToonEncoder()
    let result = try encoder.encode(.number(42))
    #expect(result == "42")
}

@Test("Encode zero")
func encodeZero() throws {
    let encoder = ToonEncoder()
    let result = try encoder.encode(.number(0))
    #expect(result == "0")
}

@Test("Encode negative number")
func encodeNegative() throws {
    let encoder = ToonEncoder()
    let result = try encoder.encode(.number(-123))
    #expect(result == "-123")
}

@Test("Encode string without quoting")
func encodeSimpleString() throws {
    let encoder = ToonEncoder()
    let result = try encoder.encode(.string("hello"))
    #expect(result == "hello")
}

@Test("Encode string with spaces requires quoting")
func encodeStringWithSpaces() throws {
    let encoder = ToonEncoder()
    let result = try encoder.encode(.string("hello world"))
    #expect(result == "\"hello world\"")
}

@Test("Encode reserved words with quoting")
func encodeReservedWords() throws {
    let encoder = ToonEncoder()
    #expect(try encoder.encode(.string("true")) == "\"true\"")
    #expect(try encoder.encode(.string("false")) == "\"false\"")
    #expect(try encoder.encode(.string("null")) == "\"null\"")
}

// MARK: - Object Tests

@Test("Decode empty object")
func decodeEmptyObject() throws {
    let decoder = ToonDecoder()
    let result = try decoder.decode("")
    #expect(result == .object([:]))
}

@Test("Decode simple object")
func decodeSimpleObject() throws {
    let decoder = ToonDecoder()
    let toon = """
    name: Alice
    age: 30
    """
    let result = try decoder.decode(toon)

    guard case .object(let obj) = result else {
        Issue.record("Expected object")
        return
    }

    #expect(obj["name"] == .string("Alice"))
    #expect(obj["age"] == .number(30))
}

@Test("Decode nested object")
func decodeNestedObject() throws {
    let decoder = ToonDecoder()
    let toon = """
    user:
      name: Alice
      age: 30
    """
    let result = try decoder.decode(toon)

    guard case .object(let obj) = result,
          case .object(let user) = obj["user"] else {
        Issue.record("Expected nested object")
        return
    }

    #expect(user["name"] == .string("Alice"))
    #expect(user["age"] == .number(30))
}

@Test("Encode simple object")
func encodeSimpleObject() throws {
    let encoder = ToonEncoder()
    let value: ToonValue = .object([
        "name": "Alice",
        "age": 30
    ])

    let result = try encoder.encode(value)
    #expect(result.contains("name: Alice"))
    #expect(result.contains("age: 30"))
}

@Test("Encode nested object")
func encodeNestedObject() throws {
    let encoder = ToonEncoder()
    let value: ToonValue = .object([
        "user": .object([
            "name": "Alice",
            "age": 30
        ])
    ])

    let result = try encoder.encode(value)
    #expect(result.contains("user:"))
    #expect(result.contains("  name: Alice"))
    #expect(result.contains("  age: 30"))
}

// MARK: - Array Tests

@Test("Decode empty array")
func decodeEmptyArray() throws {
    let decoder = ToonDecoder()
    let toon = "[0]:"
    let result = try decoder.decode(toon)
    #expect(result == .array([]))
}

@Test("Decode inline primitive array")
func decodeInlinePrimitiveArray() throws {
    let decoder = ToonDecoder()
    let toon = "[3]: 1,2,3"
    let result = try decoder.decode(toon)
    #expect(result == .array([.number(1), .number(2), .number(3)]))
}

@Test("Decode tabular array")
func decodeTabularArray() throws {
    let decoder = ToonDecoder()
    let toon = """
    [2]{id,name,role}:
     1,Alice,admin
     2,Bob,user
    """
    let result = try decoder.decode(toon)

    guard case .array(let arr) = result else {
        Issue.record("Expected array")
        return
    }

    #expect(arr.count == 2)

    guard case .object(let first) = arr[0] else {
        Issue.record("Expected object in array")
        return
    }

    #expect(first["id"] == .number(1))
    #expect(first["name"] == .string("Alice"))
    #expect(first["role"] == .string("admin"))

    guard case .object(let second) = arr[1] else {
        Issue.record("Expected object in array")
        return
    }

    #expect(second["id"] == .number(2))
    #expect(second["name"] == .string("Bob"))
    #expect(second["role"] == .string("user"))
}

@Test("Encode tabular array")
func encodeTabularArray() throws {
    let encoder = ToonEncoder()
    let value: ToonValue = .array([
        .object(["id": 1, "name": "Alice", "role": "admin"]),
        .object(["id": 2, "name": "Bob", "role": "user"])
    ])

    let result = try encoder.encode(value)
    #expect(result.contains("[2]{"))
    #expect(result.contains("Alice"))
    #expect(result.contains("Bob"))
}

@Test("Encode inline primitive array")
func encodeInlinePrimitiveArray() throws {
    let encoder = ToonEncoder()
    let value: ToonValue = .array([1, 2, 3])

    let result = try encoder.encode(value)
    #expect(result.contains("[3]:"))
    #expect(result.contains("1"))
    #expect(result.contains("2"))
    #expect(result.contains("3"))
}

@Test("Decode nested array in object")
func decodeNestedArrayInObject() throws {
    let decoder = ToonDecoder()
    let toon = """
    users[2]{id,name}:
      1,Alice
      2,Bob
    """
    let result = try decoder.decode(toon)

    guard case .object(let obj) = result,
          case .array(let users) = obj["users"] else {
        Issue.record("Expected object with array")
        return
    }

    #expect(users.count == 2)
}

@Test("Encode nested array in object")
func encodeNestedArrayInObject() throws {
    let encoder = ToonEncoder()
    let value: ToonValue = .object([
        "users": .array([
            .object(["id": 1, "name": "Alice"]),
            .object(["id": 2, "name": "Bob"])
        ])
    ])

    let result = try encoder.encode(value)
    #expect(result.contains("users[2]{"))
}

// MARK: - Escaping Tests

@Test("Decode escaped characters")
func decodeEscapedCharacters() throws {
    let decoder = ToonDecoder()
    let toon = "\"hello\\nworld\\t!\\r\\\"\\\\\""
    let result = try decoder.decode(toon)
    #expect(result == .string("hello\nworld\t!\r\"\\"))
}

@Test("Encode escaped characters")
func encodeEscapedCharacters() throws {
    let encoder = ToonEncoder()
    let result = try encoder.encode(.string("hello\nworld"))
    #expect(result == "\"hello\\nworld\"")
}

@Test("Invalid escape sequence throws error")
func invalidEscapeSequence() throws {
    let decoder = ToonDecoder()
    let toon = "\"hello\\x\""

    #expect(throws: ToonError.self) {
        try decoder.decode(toon)
    }
}

// MARK: - Quoting Tests

@Test("String with delimiter requires quoting")
func stringWithDelimiterRequiresQuoting() throws {
    let encoder = ToonEncoder()
    let result = try encoder.encode(.string("a,b"))
    #expect(result == "\"a,b\"")
}

@Test("String with colon requires quoting")
func stringWithColonRequiresQuoting() throws {
    let encoder = ToonEncoder()
    let result = try encoder.encode(.string("key:value"))
    #expect(result == "\"key:value\"")
}

@Test("Empty string requires quoting")
func emptyStringRequiresQuoting() throws {
    let encoder = ToonEncoder()
    let result = try encoder.encode(.string(""))
    #expect(result == "\"\"")
}

@Test("String with leading whitespace requires quoting")
func leadingWhitespaceRequiresQuoting() throws {
    let encoder = ToonEncoder()
    let result = try encoder.encode(.string(" hello"))
    #expect(result == "\" hello\"")
}

@Test("String with trailing whitespace requires quoting")
func trailingWhitespaceRequiresQuoting() throws {
    let encoder = ToonEncoder()
    let result = try encoder.encode(.string("hello "))
    #expect(result == "\"hello \"")
}

// MARK: - Round-trip Tests

@Test("Round-trip simple object")
func roundTripSimpleObject() throws {
    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let original: ToonValue = .object([
        "name": "Alice",
        "age": 30,
        "active": true
    ])

    let encoded = try encoder.encode(original)
    let decoded = try decoder.decode(encoded)

    guard case .object(let obj) = decoded else {
        Issue.record("Expected object")
        return
    }

    #expect(obj["name"] == .string("Alice"))
    #expect(obj["age"] == .number(30))
    #expect(obj["active"] == .bool(true))
}

@Test("Round-trip tabular array")
func roundTripTabularArray() throws {
    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let original: ToonValue = .array([
        .object(["id": 1, "name": "Alice"]),
        .object(["id": 2, "name": "Bob"])
    ])

    let encoded = try encoder.encode(original)
    let decoded = try decoder.decode(encoded)

    #expect(decoded == original)
}

@Test("Round-trip primitive array")
func roundTripPrimitiveArray() throws {
    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let original: ToonValue = .array([1, 2, 3, 4, 5])

    let encoded = try encoder.encode(original)
    let decoded = try decoder.decode(encoded)

    #expect(decoded == original)
}

// MARK: - Strict Mode Tests

@Test("Strict mode enforces array count")
func strictModeArrayCount() throws {
    let decoder = ToonDecoder(configuration: ToonConfiguration(strictMode: true))

    let toon = """
    [3]: 1,2
    """

    #expect(throws: ToonError.self) {
        try decoder.decode(toon)
    }
}

@Test("Non-strict mode allows mismatched count")
func nonStrictModeArrayCount() throws {
    let decoder = ToonDecoder(configuration: ToonConfiguration(strictMode: false))

    let toon = """
    [3]: 1,2
    """

    let result = try decoder.decode(toon)
    guard case .array(let arr) = result else {
        Issue.record("Expected array")
        return
    }

    #expect(arr.count == 2)
}

// MARK: - Delimiter Tests

@Test("Decode array with pipe delimiter")
func decodeArrayWithPipeDelimiter() throws {
    let decoder = ToonDecoder()
    let toon = "[3|]: a|b|c"
    let result = try decoder.decode(toon)
    #expect(result == .array([.string("a"), .string("b"), .string("c")]))
}

@Test("Decode tabular array with pipe delimiter")
func decodeTabularArrayWithPipeDelimiter() throws {
    let decoder = ToonDecoder()
    let toon = """
    [2|]{name|value}:
     Alice|100
     Bob|200
    """
    let result = try decoder.decode(toon)

    guard case .array(let arr) = result else {
        Issue.record("Expected array")
        return
    }

    #expect(arr.count == 2)

    guard case .object(let first) = arr[0] else {
        Issue.record("Expected object")
        return
    }

    #expect(first["name"] == .string("Alice"))
    #expect(first["value"] == .number(100))
}

@Test("Encode array with tab delimiter")
func encodeArrayWithTabDelimiter() throws {
    var config = ToonConfiguration()
    config.defaultDelimiter = .tab
    let encoder = ToonEncoder(configuration: config)

    let value: ToonValue = .array([1, 2, 3])
    let result = try encoder.encode(value)

    #expect(result.contains("[3\t]:"))
    #expect(result.contains("\t"))
}

@Test("Encode tabular array with tab delimiter")
func encodeTabularArrayWithTabDelimiter() throws {
    var config = ToonConfiguration()
    config.defaultDelimiter = .tab
    let encoder = ToonEncoder(configuration: config)

    let value: ToonValue = .array([
        .object(["name": "Alice", "value": 100]),
        .object(["name": "Bob", "value": 200])
    ])

    let result = try encoder.encode(value)

    #expect(result.contains("[2\t]{"))
    #expect(result.contains("name\tvalue"))
}

@Test("Round-trip with tab delimiter")
func roundTripTabDelimiter() throws {
    var config = ToonConfiguration()
    config.defaultDelimiter = .tab
    let encoder = ToonEncoder(configuration: config)
    let decoder = ToonDecoder(configuration: config)

    let original: ToonValue = .array([
        .object(["a": "x", "b": "y"]),
        .object(["a": "m", "b": "n"])
    ])

    let encoded = try encoder.encode(original)
    let decoded = try decoder.decode(encoded)

    #expect(decoded == original)
}

// MARK: - Key Tests

@Test("Decode quoted key")
func decodeQuotedKey() throws {
    let decoder = ToonDecoder()
    let toon = "\"my-key\": value"
    let result = try decoder.decode(toon)

    guard case .object(let obj) = result else {
        Issue.record("Expected object")
        return
    }

    #expect(obj["my-key"] == .string("value"))
}

@Test("Encode key with special characters")
func encodeSpecialKey() throws {
    let encoder = ToonEncoder()
    let value: ToonValue = .object([
        "my-key": "value"
    ])

    let result = try encoder.encode(value)
    #expect(result.contains("\"my-key\""))
}

@Test("Unquoted key pattern")
func unquotedKeyPattern() throws {
    let encoder = ToonEncoder()
    let value: ToonValue = .object([
        "valid_key123": "value",
        "_underscore": "value",
        "CamelCase": "value"
    ])

    let result = try encoder.encode(value)
    #expect(!result.contains("\"valid_key123\""))
    #expect(!result.contains("\"_underscore\""))
    #expect(!result.contains("\"CamelCase\""))
}

// MARK: - Unicode and Emoji Tests

@Test("Encode unicode string")
func encodeUnicode() throws {
    let encoder = ToonEncoder()
    let result = try encoder.encode(.string("Hello 世界"))
    #expect(result == "\"Hello 世界\"")
}

@Test("Decode unicode string")
func decodeUnicode() throws {
    let decoder = ToonDecoder()
    let result = try decoder.decode("\"Hello 世界\"")
    #expect(result == .string("Hello 世界"))
}

@Test("Round-trip unicode")
func roundTripUnicode() throws {
    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let original: ToonValue = .string("Hello 世界 🌍")
    let encoded = try encoder.encode(original)
    let decoded = try decoder.decode(encoded)

    #expect(decoded == original)
}

@Test("Encode emoji string")
func encodeEmoji() throws {
    let encoder = ToonEncoder()
    let result = try encoder.encode(.string("🚀💻🎉"))
    // Emojis don't require quoting per TOON spec
    #expect(result == "🚀💻🎉")
}

@Test("Decode emoji string")
func decodeEmoji() throws {
    let decoder = ToonDecoder()
    let result = try decoder.decode("\"🚀💻🎉\"")
    #expect(result == .string("🚀💻🎉"))
}

@Test("Object with unicode keys and values")
func unicodeObjectKeysAndValues() throws {
    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let original: ToonValue = .object([
        "名前": "太郎",
        "emoji": "😊"
    ])

    let encoded = try encoder.encode(original)
    let decoded = try decoder.decode(encoded)

    #expect(decoded == original)
}

// MARK: - Non-finite Number Tests

@Test("Encode infinity as null")
func encodeInfinity() throws {
    let encoder = ToonEncoder()
    let result = try encoder.encode(.number(.infinity))
    #expect(result == "null")
}

@Test("Encode negative infinity as null")
func encodeNegativeInfinity() throws {
    let encoder = ToonEncoder()
    let result = try encoder.encode(.number(-.infinity))
    #expect(result == "null")
}

@Test("Encode NaN as null")
func encodeNaN() throws {
    let encoder = ToonEncoder()
    let result = try encoder.encode(.number(.nan))
    #expect(result == "null")
}

@Test("Object with non-finite numbers")
func objectWithNonFiniteNumbers() throws {
    let encoder = ToonEncoder()
    let value: ToonValue = .object([
        "infinity": .number(.infinity),
        "negInfinity": .number(-.infinity),
        "notANumber": .number(.nan),
        "normal": .number(42)
    ])

    let result = try encoder.encode(value)
    #expect(result.contains("infinity: null"))
    #expect(result.contains("negInfinity: null"))
    #expect(result.contains("notANumber: null"))
    #expect(result.contains("normal: 42"))
}

// MARK: - Empty Key Tests

@Test("Encode object with empty key")
func encodeEmptyKey() throws {
    let encoder = ToonEncoder()
    let value: ToonValue = .object([
        "": .string("value"),
        "normalKey": .string("normal")
    ])

    let result = try encoder.encode(value)
    #expect(result.contains("\"\": value"))
    #expect(result.contains("normalKey: normal"))
}

@Test("Decode object with empty key")
func decodeEmptyKey() throws {
    let decoder = ToonDecoder()
    let toon = """
    "": value
    normalKey: normal
    """

    let result = try decoder.decode(toon)
    guard case .object(let obj) = result else {
        throw ToonError.invalidFormat("Expected object")
    }

    #expect(obj[""] == .string("value"))
    #expect(obj["normalKey"] == .string("normal"))
}

@Test("Round-trip object with empty key")
func roundTripEmptyKey() throws {
    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let original: ToonValue = .object([
        "": .number(123),
        "key": .bool(true)
    ])

    let encoded = try encoder.encode(original)
    let decoded = try decoder.decode(encoded)

    #expect(decoded == original)
}

// MARK: - Numeric Key Tests

@Test("Encode object with numeric string key")
func encodeNumericKey() throws {
    let encoder = ToonEncoder()
    let value: ToonValue = .object([
        "123": .string("value"),
        "456.789": .string("another")
    ])

    let result = try encoder.encode(value)
    // Numeric keys should be quoted to avoid confusion with numbers
    #expect(result.contains("\"123\": value") || result.contains("123: value"))
    #expect(result.contains("\"456.789\": another") || result.contains("456.789: another"))
}

@Test("Decode object with quoted numeric key")
func decodeNumericKey() throws {
    let decoder = ToonDecoder()
    let toon = """
    "123": value
    "456": another
    """

    let result = try decoder.decode(toon)
    guard case .object(let obj) = result else {
        throw ToonError.invalidFormat("Expected object")
    }

    #expect(obj["123"] == .string("value"))
    #expect(obj["456"] == .string("another"))
}

@Test("Round-trip object with numeric string keys")
func roundTripNumericKeys() throws {
    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let original: ToonValue = .object([
        "0": .bool(false),
        "1": .bool(true),
        "999": .number(999)
    ])

    let encoded = try encoder.encode(original)
    let decoded = try decoder.decode(encoded)

    #expect(decoded == original)
}

// MARK: - Foundation Type Integration Tests

@Test("Encode Date as timestamp")
func encodeDate() throws {
    struct Event: Codable {
        let name: String
        let timestamp: Date
    }

    let encoder = ToonEncoder()
    let date = Date(timeIntervalSince1970: 1_700_000_000) // Fixed date for reproducibility
    let event = Event(name: "Launch", timestamp: date)

    let result = try encoder.encode(event)
    #expect(result.contains("name: Launch"))
    #expect(result.contains("timestamp:")) // Date will be encoded as number (timestamp)
}

@Test("Round-trip struct with Date")
func roundTripDate() throws {
    struct Event: Codable, Equatable {
        let name: String
        let timestamp: Date
    }

    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let original = Event(name: "Launch", timestamp: date)

    let encoded = try encoder.encode(original)
    let decoded = try decoder.decode(Event.self, from: encoded)

    #expect(decoded.name == original.name)
    // Dates may have slight precision differences, check they're close
    #expect(abs(decoded.timestamp.timeIntervalSince1970 - original.timestamp.timeIntervalSince1970) < 0.001)
}

@Test("Encode URL as string")
func encodeURL() throws {
    struct Link: Codable {
        let title: String
        let url: URL
    }

    let encoder = ToonEncoder()
    let link = Link(title: "Example", url: URL(string: "https://example.com")!)

    let result = try encoder.encode(link)
    #expect(result.contains("title: Example"))
    #expect(result.contains("url: https://example.com") || result.contains("url: \"https://example.com\""))
}

@Test("Round-trip struct with URL")
func roundTripURL() throws {
    struct Link: Codable, Equatable {
        let title: String
        let url: URL
    }

    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let original = Link(title: "Example", url: URL(string: "https://example.com")!)

    let encoded = try encoder.encode(original)
    let decoded = try decoder.decode(Link.self, from: encoded)

    #expect(decoded == original)
}

@Test("Encode Data as base64 string")
func encodeData() throws {
    struct Payload: Codable {
        let name: String
        let data: Data
    }

    let encoder = ToonEncoder()
    let data = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]) // "Hello" in hex
    let payload = Payload(name: "test", data: data)

    let result = try encoder.encode(payload)
    #expect(result.contains("name: test"))
    #expect(result.contains("data:")) // Data will be base64 encoded
}

@Test("Round-trip struct with Data")
func roundTripData() throws {
    struct Payload: Codable, Equatable {
        let name: String
        let data: Data
    }

    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let data = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F])
    let original = Payload(name: "test", data: data)

    let encoded = try encoder.encode(original)
    let decoded = try decoder.decode(Payload.self, from: encoded)

    #expect(decoded == original)
}

@Test("Complex struct with multiple Foundation types")
func complexStructWithFoundationTypes() throws {
    struct Record: Codable, Equatable {
        let id: Int
        let createdAt: Date
        let website: URL
        let signature: Data
    }

    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let record = Record(
        id: 42,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000),
        website: URL(string: "https://swift.org")!,
        signature: Data([0xDE, 0xAD, 0xBE, 0xEF])
    )

    let encoded = try encoder.encode(record)
    let decoded = try decoder.decode(Record.self, from: encoded)

    #expect(decoded.id == record.id)
    #expect(abs(decoded.createdAt.timeIntervalSince1970 - record.createdAt.timeIntervalSince1970) < 0.001)
    #expect(decoded.website == record.website)
    #expect(decoded.signature == record.signature)
}

// MARK: - Whitespace Formatting Edge Cases

@Test("String with multiple spaces requires quoting")
func multipleSpaces() throws {
    let encoder = ToonEncoder()
    let value: ToonValue = .string("hello  world")

    let result = try encoder.encode(value)
    #expect(result == "\"hello  world\"")
}

@Test("String with tab character requires quoting")
func stringWithTab() throws {
    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let value: ToonValue = .string("hello\tworld")

    let encoded = try encoder.encode(value)
    #expect(encoded.contains("\\t")) // Tab should be escaped

    let decoded = try decoder.decode(encoded)
    #expect(decoded == value)
}

@Test("String with newline requires quoting and escaping")
func stringWithNewline() throws {
    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let value: ToonValue = .string("line1\nline2")

    let encoded = try encoder.encode(value)
    #expect(encoded.contains("\\n")) // Newline should be escaped

    let decoded = try decoder.decode(encoded)
    #expect(decoded == value)
}

@Test("String with carriage return requires quoting")
func stringWithCarriageReturn() throws {
    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let value: ToonValue = .string("hello\rworld")

    let encoded = try encoder.encode(value)
    #expect(encoded.contains("\\r")) // CR should be escaped

    let decoded = try decoder.decode(encoded)
    #expect(decoded == value)
}

@Test("String with mixed whitespace")
func mixedWhitespace() throws {
    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let value: ToonValue = .string(" \t\n ")

    let encoded = try encoder.encode(value)
    let decoded = try decoder.decode(encoded)

    #expect(decoded == value)
}

@Test("Object with whitespace-heavy values")
func objectWithWhitespaceValues() throws {
    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let original: ToonValue = .object([
        "text": .string("  hello  "),
        "multiline": .string("line1\nline2\nline3"),
        "tabs": .string("\t\ttabbed")
    ])

    let encoded = try encoder.encode(original)
    let decoded = try decoder.decode(encoded)

    #expect(decoded == original)
}

@Test("Decode tolerates extra blank lines")
func extraBlankLines() throws {
    let decoder = ToonDecoder()
    let toon = """
    name: Alice


    age: 30


    active: true
    """

    let result = try decoder.decode(toon)
    guard case .object(let obj) = result else {
        throw ToonError.invalidFormat("Expected object")
    }

    #expect(obj["name"] == .string("Alice"))
    #expect(obj["age"] == .number(30))
    #expect(obj["active"] == .bool(true))
}
