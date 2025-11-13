import Foundation

/// Encodes ToonValue into TOON format string
public class ToonEncoder {
    public var configuration: ToonConfiguration

    public init(configuration: ToonConfiguration = .default) {
        self.configuration = configuration
    }

    /// Encode a ToonValue to TOON format string
    public func encode(_ value: ToonValue) throws -> String {
        var output = ""
        try encodeValue(value, depth: 0, output: &output)
        return output
    }

    /// Encode any Encodable type to TOON format
    public func encode<T: Encodable>(_ value: T) throws -> String {
        let jsonData = try JSONEncoder().encode(value)
        let jsonValue = try JSONDecoder().decode(ToonValue.self, from: jsonData)
        return try encode(jsonValue)
    }

    private func encodeValue(_ value: ToonValue, depth: Int, output: inout String) throws {
        switch value {
        case .null:
            output += "null"
        case .bool(let bool):
            output += bool ? "true" : "false"
        case .number(let number):
            output += formatNumber(number)
        case .string(let string):
            output += encodeString(string, delimiter: configuration.defaultDelimiter)
        case .array(let array):
            try encodeRootArray(array, output: &output)
        case .object(let object):
            try encodeObject(object, depth: depth, output: &output)
        }
    }

    private func encodeObject(_ object: [String: ToonValue], depth: Int, output: inout String) throws {
        let indent = makeIndent(depth)

        for (key, value) in object.sorted(by: { $0.key < $1.key }) {
            output += indent
            output += encodeKey(key)

            switch value {
            case .null, .bool, .number, .string:
                output += ": "
                try encodeValue(value, depth: depth, output: &output)
                output += "\n"

            case .array(let array):
                try encodeArray(key: key, array: array, depth: depth, output: &output)

            case .object(let nested):
                output += ":\n"
                try encodeObject(nested, depth: depth + 1, output: &output)
            }
        }
    }

    private func encodeArray(key: String, array: [ToonValue], depth: Int, output: inout String) throws {
        let indent = makeIndent(depth)

        if array.isEmpty {
            output += "[0]:\n"
            return
        }

        // Determine array form
        let form = determineArrayForm(array)

        switch form {
        case .primitive:
            // Inline primitive array
            let delimiterMarker = configuration.defaultDelimiter == .comma ? "" : configuration.defaultDelimiter.rawValue
            output += "[\(array.count)\(delimiterMarker)]:"
            for (index, value) in array.enumerated() {
                if index > 0 {
                    output += configuration.defaultDelimiter.rawValue
                }
                output += " "
                var temp = ""
                try encodeValue(value, depth: depth, output: &temp)
                output += temp
            }
            output += "\n"

        case .tabular(let fields):
            // Tabular array of objects
            let delimiterMarker = configuration.defaultDelimiter == .comma ? "" : configuration.defaultDelimiter.rawValue
            output += "[\(array.count)\(delimiterMarker)]{"
            output += fields.joined(separator: configuration.defaultDelimiter.rawValue)
            output += "}:\n"

            for element in array {
                guard case .object(let obj) = element else {
                    throw ToonError.invalidFormat("Tabular array must contain objects")
                }

                output += indent + String(repeating: " ", count: configuration.indentSize)
                for (index, field) in fields.enumerated() {
                    if index > 0 {
                        output += configuration.defaultDelimiter.rawValue
                    }
                    if let value = obj[field] {
                        var temp = ""
                        try encodeValue(value, depth: depth + 1, output: &temp)
                        output += temp
                    } else {
                        output += "null"
                    }
                }
                output += "\n"
            }

        case .mixed:
            // Mixed array
            let delimiterMarker = configuration.defaultDelimiter == .comma ? "" : configuration.defaultDelimiter.rawValue
            output += "[\(array.count)\(delimiterMarker)]:\n"
            for element in array {
                output += indent + String(repeating: " ", count: configuration.indentSize)
                output += "- "
                switch element {
                case .object(let obj):
                    var first = true
                    for (k, v) in obj.sorted(by: { $0.key < $1.key }) {
                        if !first {
                            output += indent + String(repeating: " ", count: configuration.indentSize) + "  "
                        }
                        output += encodeKey(k) + ": "
                        var temp = ""
                        try encodeValue(v, depth: depth + 2, output: &temp)
                        output += temp
                        output += "\n"
                        first = false
                    }
                default:
                    var temp = ""
                    try encodeValue(element, depth: depth + 1, output: &temp)
                    output += temp
                    output += "\n"
                }
            }
        }
    }

    private func encodeRootArray(_ array: [ToonValue], output: inout String) throws {
        if array.isEmpty {
            output += "[0]:\n"
            return
        }

        let form = determineArrayForm(array)

        switch form {
        case .primitive:
            let delimiterMarker = configuration.defaultDelimiter == .comma ? "" : configuration.defaultDelimiter.rawValue
            output += "[\(array.count)\(delimiterMarker)]:"
            for (index, value) in array.enumerated() {
                if index > 0 {
                    output += configuration.defaultDelimiter.rawValue
                }
                output += " "
                var temp = ""
                try encodeValue(value, depth: 0, output: &temp)
                output += temp
            }
            output += "\n"

        case .tabular(let fields):
            let delimiterMarker = configuration.defaultDelimiter == .comma ? "" : configuration.defaultDelimiter.rawValue
            output += "[\(array.count)\(delimiterMarker)]{"
            output += fields.joined(separator: configuration.defaultDelimiter.rawValue)
            output += "}:\n"

            for element in array {
                guard case .object(let obj) = element else {
                    throw ToonError.invalidFormat("Tabular array must contain objects")
                }

                output += " "
                for (index, field) in fields.enumerated() {
                    if index > 0 {
                        output += configuration.defaultDelimiter.rawValue
                    }
                    if let value = obj[field] {
                        var temp = ""
                        try encodeValue(value, depth: 1, output: &temp)
                        output += temp
                    } else {
                        output += "null"
                    }
                }
                output += "\n"
            }

        case .mixed:
            let delimiterMarker = configuration.defaultDelimiter == .comma ? "" : configuration.defaultDelimiter.rawValue
            output += "[\(array.count)\(delimiterMarker)]:\n"
            for element in array {
                output += "- "
                switch element {
                case .object(let obj):
                    var first = true
                    for (k, v) in obj.sorted(by: { $0.key < $1.key }) {
                        if !first {
                            output += "  "
                        }
                        output += encodeKey(k) + ": "
                        var temp = ""
                        try encodeValue(v, depth: 1, output: &temp)
                        output += temp
                        output += "\n"
                        first = false
                    }
                default:
                    var temp = ""
                    try encodeValue(element, depth: 0, output: &temp)
                    output += temp
                    output += "\n"
                }
            }
        }
    }

    private enum ArrayForm {
        case primitive
        case tabular([String])
        case mixed
    }

    private func determineArrayForm(_ array: [ToonValue]) -> ArrayForm {
        guard !array.isEmpty else { return .primitive }

        // Check if all primitives
        let allPrimitives = array.allSatisfy { element in
            switch element {
            case .null, .bool, .number, .string:
                return true
            default:
                return false
            }
        }

        if allPrimitives {
            return .primitive
        }

        // Check if all objects with same keys (tabular)
        let allObjects = array.allSatisfy { element in
            if case .object = element { return true }
            return false
        }

        if allObjects {
            guard case .object(let firstObj) = array[0] else { return .mixed }
            let firstKeys = Set(firstObj.keys)

            let allSameKeys = array.dropFirst().allSatisfy { element in
                guard case .object(let obj) = element else { return false }
                return Set(obj.keys) == firstKeys
            }

            if allSameKeys {
                let sortedKeys = firstObj.keys.sorted()
                return .tabular(sortedKeys)
            }
        }

        return .mixed
    }

    private func makeIndent(_ depth: Int) -> String {
        return String(repeating: " ", count: depth * configuration.indentSize)
    }

    private func encodeKey(_ key: String) -> String {
        // Check if key needs quoting
        let unquotedKeyPattern = "^[A-Za-z_][A-Za-z0-9_.]*$"
        let regex = try! NSRegularExpression(pattern: unquotedKeyPattern)
        let range = NSRange(key.startIndex..<key.endIndex, in: key)

        if regex.firstMatch(in: key, range: range) != nil &&
           key != "true" && key != "false" && key != "null" {
            return key
        }

        return "\"\(escapeString(key))\""
    }

    func encodeString(_ string: String, delimiter: ToonDelimiter) -> String {
        if needsQuoting(string, delimiter: delimiter) {
            return "\"\(escapeString(string))\""
        }
        return string
    }

    private func needsQuoting(_ string: String, delimiter: ToonDelimiter) -> Bool {
        if string.isEmpty {
            return true
        }

        // Check for reserved words
        if string == "true" || string == "false" || string == "null" {
            return true
        }

        // Check if it looks like a number
        if Double(string) != nil {
            return true
        }

        // Check for special characters
        let specialChars: [Character] = ["\n", "\r", "\t", "\"", "\\", ":", "[", "]", "{", "}", "-"]
        if string.contains(where: { specialChars.contains($0) }) {
            return true
        }

        // Check for delimiter
        if string.contains(delimiter.rawValue) {
            return true
        }

        // Check for any whitespace (including spaces in the middle)
        if string.contains(where: { $0.isWhitespace }) {
            return true
        }

        return false
    }

    private func escapeString(_ string: String) -> String {
        var result = ""
        for char in string {
            switch char {
            case "\\":
                result += "\\\\"
            case "\"":
                result += "\\\""
            case "\n":
                result += "\\n"
            case "\r":
                result += "\\r"
            case "\t":
                result += "\\t"
            default:
                result.append(char)
            }
        }
        return result
    }

    private func formatNumber(_ number: Double) -> String {
        // Canonical number format: no exponents, no leading zeros, no trailing fractional zeros
        if number.isNaN || number.isInfinite {
            return "null"
        }

        if number == 0 {
            return "0"
        }

        if number == floor(number) && abs(number) < Double(Int64.max) {
            return String(Int64(number))
        }

        let formatted = String(format: "%.15g", number)
        return formatted
    }
}
