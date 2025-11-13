import Foundation

/// Decodes TOON format string into ToonValue
public class ToonDecoder {
    public var configuration: ToonConfiguration

    public init(configuration: ToonConfiguration = .default) {
        self.configuration = configuration
    }

    /// Decode a TOON format string to ToonValue
    public func decode(_ toon: String) throws -> ToonValue {
        let lines = toon.split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0) }

        if lines.first?.contains("{") == true {
        }

        if lines.isEmpty || lines.allSatisfy({ $0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            return .object([:])
        }

        // Find first non-empty line to determine root type
        guard let firstLine = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) else {
            return .object([:])
        }


        // Check if it's a root array
        // Format: [N]:... or [N]{...}:... or [N|]:... or [N\t]:...
        // Must start with [ and contain ]: somewhere (after the count/delimiter)
        if firstLine.hasPrefix("[") && (firstLine.contains("]:") || firstLine.contains("]{")) {
            return try decodeRootArray(lines)
        }

        // Check if it's a single primitive (no colon means not a key-value pair)
        if !firstLine.contains(":") {
            let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
            // Make sure it's not a list item marker
            if !trimmed.hasPrefix("- ") {
                return try decodePrimitive(trimmed, delimiter: configuration.defaultDelimiter)
            }
        }

        // Otherwise it's an object
        return try decodeRootObject(lines)
    }

    /// Decode a TOON format string to any Decodable type
    public func decode<T: Decodable>(_ type: T.Type, from toon: String) throws -> T {
        let toonValue = try decode(toon)
        let jsonData = try JSONEncoder().encode(toonValue)
        return try JSONDecoder().decode(type, from: jsonData)
    }

    private func decodeRootObject(_ lines: [String]) throws -> ToonValue {
        var index = 0
        let result = try decodeObject(lines, index: &index, expectedDepth: 0)
        return .object(result)
    }

    private func decodeObject(_ lines: [String], index: inout Int, expectedDepth: Int) throws -> [String: ToonValue] {
        var result: [String: ToonValue] = [:]

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                index += 1
                continue
            }

            let depth = getIndentDepth(line)

            if depth < expectedDepth {
                // End of this object
                break
            }

            if depth > expectedDepth {
                throw ToonError.invalidIndentation("Unexpected indentation at line \(index + 1)")
            }

            // Parse key-value pair
            if let colonIndex = trimmed.firstIndex(of: ":") {
                let keyPart = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let valuePart = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)

                let key = try decodeKey(keyPart)

                // Check if it's an array
                if keyPart.contains("[") {
                    index += 1
                    let value = try decodeArray(keyPart, valuePart, lines, index: &index, depth: expectedDepth)
                    result[key] = value
                } else if valuePart.isEmpty {
                    // Nested object
                    index += 1
                    let nested = try decodeObject(lines, index: &index, expectedDepth: expectedDepth + 1)
                    result[key] = .object(nested)
                } else {
                    // Simple value
                    let value = try decodePrimitive(valuePart, delimiter: configuration.defaultDelimiter)
                    result[key] = value
                    index += 1
                }
            } else {
                throw ToonError.invalidFormat("Missing colon at line \(index + 1): \(trimmed)")
            }
        }

        return result
    }

    private func decodeRootArray(_ lines: [String]) throws -> ToonValue {
        var index = 0
        guard index < lines.count else {
            throw ToonError.unexpectedEndOfInput
        }

        let headerLine = lines[index].trimmingCharacters(in: .whitespaces)
        let (count, delimiter, fields) = try parseArrayHeader(headerLine)


        // Check if values are inline on the header line (only for primitive arrays, not tabular)
        if fields.isEmpty && headerLine.contains("]:") {
            let afterColon = headerLine.split(separator: ":", maxSplits: 1)
            if afterColon.count > 1 {
                let values = String(afterColon[1]).trimmingCharacters(in: .whitespaces)
                if !values.isEmpty {
                    return try decodePrimitiveArray(values, count: count, delimiter: delimiter)
                }
            }
        }

        index += 1

        if fields.isEmpty {

            // Primitive or mixed array
            var elements: [ToonValue] = []

            while elements.count < count && index < lines.count {
                let line = lines[index].trimmingCharacters(in: .whitespaces)

                if line.isEmpty {
                    index += 1
                    continue
                }

                if line.hasPrefix("- ") {
                    // Mixed array element
                    let element = try decodeMixedElement(String(line.dropFirst(2)), lines, index: &index, depth: 0, delimiter: delimiter)
                    elements.append(element)
                } else {
                    index += 1
                }
            }

            if configuration.strictMode && elements.count != count {
                throw ToonError.invalidArrayCount(expected: count, actual: elements.count)
            }

            return .array(elements)
        } else {
            // Tabular array
            var elements: [ToonValue] = []

            while elements.count < count && index < lines.count {
                let line = lines[index]

                // For root arrays, accept any line with leading whitespace
                let hasIndentation = line.first == " " || line.first == "\t"
                let trimmed = line.trimmingCharacters(in: .whitespaces)


                if trimmed.isEmpty {
                    index += 1
                    continue
                }

                // If no indentation and not empty, we've reached the end of the array
                if !hasIndentation {
                    break
                }

                let values = splitByDelimiter(trimmed, delimiter: delimiter)
                var obj: [String: ToonValue] = [:]

                for (fieldIndex, field) in fields.enumerated() {
                    if fieldIndex < values.count {
                        obj[field] = try decodePrimitive(values[fieldIndex], delimiter: delimiter)
                    } else {
                        obj[field] = .null
                    }
                }

                elements.append(.object(obj))
                index += 1
            }


            if configuration.strictMode && elements.count != count {
                throw ToonError.invalidArrayCount(expected: count, actual: elements.count)
            }

            return .array(elements)
        }
    }

    private func decodeArray(_ keyPart: String, _ valuePart: String, _ lines: [String], index: inout Int, depth: Int) throws -> ToonValue {
        let (count, delimiter, fields) = try parseArrayHeader(keyPart + ":" + valuePart)

        if !valuePart.isEmpty && fields.isEmpty && !valuePart.contains("{") {
            // Inline primitive array
            let trimmed = valuePart.trimmingCharacters(in: .whitespaces)
            return try decodePrimitiveArray(trimmed, count: count, delimiter: delimiter)
        }

        if fields.isEmpty {
            // Mixed array
            var elements: [ToonValue] = []

            while elements.count < count && index < lines.count {
                let line = lines[index]
                let lineDepth = getIndentDepth(line)

                if lineDepth <= depth {
                    break
                }

                let trimmed = line.trimmingCharacters(in: .whitespaces)

                if trimmed.isEmpty {
                    index += 1
                    continue
                }

                if trimmed.hasPrefix("- ") {
                    let element = try decodeMixedElement(String(trimmed.dropFirst(2)), lines, index: &index, depth: depth + 1, delimiter: delimiter)
                    elements.append(element)
                } else {
                    index += 1
                }
            }

            if configuration.strictMode && elements.count != count {
                throw ToonError.invalidArrayCount(expected: count, actual: elements.count)
            }

            return .array(elements)
        } else {
            // Tabular array
            var elements: [ToonValue] = []

            while elements.count < count && index < lines.count {
                let line = lines[index]
                let lineDepth = getIndentDepth(line)

                if lineDepth <= depth {
                    break
                }

                let trimmed = line.trimmingCharacters(in: .whitespaces)

                if trimmed.isEmpty {
                    index += 1
                    continue
                }

                let values = splitByDelimiter(trimmed, delimiter: delimiter)
                var obj: [String: ToonValue] = [:]

                for (fieldIndex, field) in fields.enumerated() {
                    if fieldIndex < values.count {
                        obj[field] = try decodePrimitive(values[fieldIndex], delimiter: delimiter)
                    } else {
                        obj[field] = .null
                    }
                }

                elements.append(.object(obj))
                index += 1
            }

            if configuration.strictMode && elements.count != count {
                throw ToonError.invalidArrayCount(expected: count, actual: elements.count)
            }

            return .array(elements)
        }
    }

    private func decodePrimitiveArray(_ values: String, count: Int, delimiter: ToonDelimiter) throws -> ToonValue {
        let parts = splitByDelimiter(values, delimiter: delimiter)
        let elements = try parts.map { try decodePrimitive($0, delimiter: delimiter) }

        if configuration.strictMode && elements.count != count {
            throw ToonError.invalidArrayCount(expected: count, actual: elements.count)
        }

        return .array(elements)
    }

    private func decodeMixedElement(_ content: String, _ lines: [String], index: inout Int, depth: Int, delimiter: ToonDelimiter) throws -> ToonValue {
        index += 1

        if content.contains(":") {
            // It's an object
            var obj: [String: ToonValue] = [:]

            // Parse first line
            if let colonIndex = content.firstIndex(of: ":") {
                let keyPart = String(content[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let valuePart = String(content[content.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)

                let key = try decodeKey(keyPart)

                if valuePart.isEmpty {
                    // Nested value
                    let nested = try decodeObject(lines, index: &index, expectedDepth: depth + 1)
                    obj[key] = .object(nested)
                } else {
                    obj[key] = try decodePrimitive(valuePart, delimiter: delimiter)
                }
            }

            // Continue parsing remaining fields at same depth
            while index < lines.count {
                let line = lines[index]
                let lineDepth = getIndentDepth(line)

                if lineDepth < depth + 1 {
                    break
                }

                if lineDepth > depth + 1 {
                    index += 1
                    continue
                }

                let trimmed = line.trimmingCharacters(in: .whitespaces)

                if trimmed.isEmpty || trimmed.hasPrefix("- ") {
                    break
                }

                if let colonIndex = trimmed.firstIndex(of: ":") {
                    let keyPart = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                    let valuePart = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)

                    let key = try decodeKey(keyPart)
                    obj[key] = try decodePrimitive(valuePart, delimiter: delimiter)
                    index += 1
                } else {
                    break
                }
            }

            return .object(obj)
        } else {
            // Primitive value
            return try decodePrimitive(content, delimiter: delimiter)
        }
    }

    private func parseArrayHeader(_ header: String) throws -> (count: Int, delimiter: ToonDelimiter, fields: [String]) {
        // Format: [N<delim?>]{fields?}:
        guard let bracketStart = header.firstIndex(of: "["),
              let bracketEnd = header.firstIndex(of: "]") else {
            throw ToonError.invalidHeader("Missing brackets in array header")
        }

        let countPart = String(header[header.index(after: bracketStart)..<bracketEnd])

        // Parse delimiter marker
        var delimiter = configuration.defaultDelimiter
        var countString = countPart

        if countPart.hasSuffix("\t") {
            delimiter = .tab
            countString = String(countPart.dropLast())
        } else if countPart.hasSuffix("|") {
            delimiter = .pipe
            countString = String(countPart.dropLast())
        }

        guard let count = Int(countString) else {
            throw ToonError.invalidHeader("Invalid array count: \(countString)")
        }

        // Parse fields
        var fields: [String] = []
        if let braceStart = header.firstIndex(of: "{"),
           let braceEnd = header.firstIndex(of: "}"),
           braceStart > bracketEnd {
            let fieldsPart = String(header[header.index(after: braceStart)..<braceEnd])
            fields = splitByDelimiter(fieldsPart, delimiter: delimiter)
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }

        return (count, delimiter, fields)
    }

    private func splitByDelimiter(_ string: String, delimiter: ToonDelimiter) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var escaped = false

        for char in string {
            if escaped {
                current.append(char)
                escaped = false
                continue
            }

            if char == "\\" {
                escaped = true
                current.append(char)
                continue
            }

            if char == "\"" {
                inQuotes.toggle()
                current.append(char)
                continue
            }

            if !inQuotes && String(char) == delimiter.rawValue {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
                continue
            }

            current.append(char)
        }

        if !current.isEmpty {
            result.append(current.trimmingCharacters(in: .whitespaces))
        }

        return result
    }

    private func decodePrimitive(_ string: String, delimiter: ToonDelimiter) throws -> ToonValue {
        let trimmed = string.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            return .string("")
        }

        // Check for quoted string
        if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") {
            let content = String(trimmed.dropFirst().dropLast())
            return .string(try unescapeString(content))
        }

        // Check for primitives
        switch trimmed {
        case "null":
            return .null
        case "true":
            return .bool(true)
        case "false":
            return .bool(false)
        default:
            break
        }

        // Try to parse as number
        if let number = Double(trimmed) {
            return .number(number)
        }

        // Otherwise it's an unquoted string
        return .string(trimmed)
    }

    private func decodeKey(_ key: String) throws -> String {
        let trimmed = key.trimmingCharacters(in: .whitespaces)

        // Remove array bracket notation if present
        if let bracketIndex = trimmed.firstIndex(of: "[") {
            let keyPart = String(trimmed[..<bracketIndex])
            return try decodeKey(keyPart)
        }

        if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") {
            let content = String(trimmed.dropFirst().dropLast())
            return try unescapeString(content)
        }

        return trimmed
    }

    private func unescapeString(_ string: String) throws -> String {
        var result = ""
        var escaped = false

        for char in string {
            if escaped {
                switch char {
                case "\\":
                    result.append("\\")
                case "\"":
                    result.append("\"")
                case "n":
                    result.append("\n")
                case "r":
                    result.append("\r")
                case "t":
                    result.append("\t")
                default:
                    throw ToonError.invalidEscape("Invalid escape sequence: \\\(char)")
                }
                escaped = false
            } else if char == "\\" {
                escaped = true
            } else {
                result.append(char)
            }
        }

        if escaped {
            throw ToonError.invalidEscape("Trailing backslash")
        }

        return result
    }

    private func getIndentDepth(_ line: String) -> Int {
        var spaces = 0
        for char in line {
            if char == " " {
                spaces += 1
            } else {
                break
            }
        }
        return spaces / configuration.indentSize
    }
}
