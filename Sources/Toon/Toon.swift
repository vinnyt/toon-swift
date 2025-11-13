import Foundation

/// Token-Oriented Object Notation (TOON) encoder and decoder
public struct Toon {
    public static let version = "2.0"
}

/// Errors that can occur during TOON encoding or decoding
public enum ToonError: Error, LocalizedError {
    case invalidFormat(String)
    case invalidIndentation(String)
    case invalidHeader(String)
    case invalidArrayCount(expected: Int, actual: Int)
    case invalidEscape(String)
    case invalidKey(String)
    case unexpectedEndOfInput
    case typeMismatch(String)

    public var errorDescription: String? {
        switch self {
        case .invalidFormat(let msg): return "Invalid format: \(msg)"
        case .invalidIndentation(let msg): return "Invalid indentation: \(msg)"
        case .invalidHeader(let msg): return "Invalid header: \(msg)"
        case .invalidArrayCount(let expected, let actual):
            return "Array count mismatch: expected \(expected), got \(actual)"
        case .invalidEscape(let msg): return "Invalid escape sequence: \(msg)"
        case .invalidKey(let msg): return "Invalid key: \(msg)"
        case .unexpectedEndOfInput: return "Unexpected end of input"
        case .typeMismatch(let msg): return "Type mismatch: \(msg)"
        }
    }
}

/// Delimiter type for TOON arrays
public enum ToonDelimiter: String, Sendable {
    case comma = ","
    case tab = "\t"
    case pipe = "|"

    var headerMarker: String {
        switch self {
        case .comma: return ""
        case .tab: return "\t"
        case .pipe: return "|"
        }
    }
}

/// Configuration for TOON encoding/decoding
public struct ToonConfiguration: Sendable {
    public var indentSize: Int
    public var strictMode: Bool
    public var defaultDelimiter: ToonDelimiter
    public var enableKeyFolding: Bool

    public init(
        indentSize: Int = 2,
        strictMode: Bool = true,
        defaultDelimiter: ToonDelimiter = .comma,
        enableKeyFolding: Bool = false
    ) {
        self.indentSize = indentSize
        self.strictMode = strictMode
        self.defaultDelimiter = defaultDelimiter
        self.enableKeyFolding = enableKeyFolding
    }

    public static let `default` = ToonConfiguration()
}

/// Represents a TOON value in the JSON data model
public enum ToonValue: Equatable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([ToonValue])
    case object([String: ToonValue])

    public var isNull: Bool {
        if case .null = self { return true }
        return false
    }

    public var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    public var numberValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }

    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    public var arrayValue: [ToonValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    public var objectValue: [String: ToonValue]? {
        if case .object(let value) = self { return value }
        return nil
    }
}

// MARK: - Codable Support

extension ToonValue: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([ToonValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: ToonValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.typeMismatch(
                ToonValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Cannot decode ToonValue"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
}

// MARK: - Convenience Initializers

extension ToonValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension ToonValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension ToonValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}

extension ToonValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value)
    }
}

extension ToonValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension ToonValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: ToonValue...) {
        self = .array(elements)
    }
}

extension ToonValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, ToonValue)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }
}
