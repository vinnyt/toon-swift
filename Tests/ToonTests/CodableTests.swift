import Testing
@testable import Toon
import Foundation

// MARK: - Test Models

struct User: Codable, Equatable {
    let id: Int
    let name: String
    let email: String
    let active: Bool
}

struct Product: Codable, Equatable {
    let id: Int
    let name: String
    let price: Double
    let tags: [String]
}

struct Company: Codable, Equatable {
    let name: String
    let founded: Int
    let employees: [Employee]
}

struct Employee: Codable, Equatable {
    let name: String
    let role: String
}

// MARK: - Codable Encoding Tests

@Test("Encode Swift struct to TOON")
func encodeSwiftStruct() throws {
    let encoder = ToonEncoder()
    let user = User(id: 1, name: "Alice", email: "alice@example.com", active: true)

    let toon = try encoder.encode(user)

    #expect(toon.contains("id: 1"))
    #expect(toon.contains("name: Alice"))
    #expect(toon.contains("email: alice@example.com"))
    #expect(toon.contains("active: true"))
}

@Test("Encode array of Swift structs to TOON")
func encodeSwiftStructArray() throws {
    let encoder = ToonEncoder()
    let users = [
        User(id: 1, name: "Alice", email: "alice@example.com", active: true),
        User(id: 2, name: "Bob", email: "bob@example.com", active: false)
    ]

    let toon = try encoder.encode(users)

    // Should create a tabular array
    #expect(toon.contains("[2]{"))
    #expect(toon.contains("Alice"))
    #expect(toon.contains("Bob"))
}

@Test("Encode nested Swift struct to TOON")
func encodeNestedSwiftStruct() throws {
    let encoder = ToonEncoder()
    let company = Company(
        name: "TechCorp",
        founded: 2020,
        employees: [
            Employee(name: "Alice", role: "Engineer"),
            Employee(name: "Bob", role: "Designer")
        ]
    )

    let toon = try encoder.encode(company)

    #expect(toon.contains("name: TechCorp"))
    #expect(toon.contains("founded: 2020"))
    #expect(toon.contains("employees[2]{"))
    #expect(toon.contains("Alice"))
    #expect(toon.contains("Bob"))
}

// MARK: - Codable Decoding Tests

@Test("Decode TOON to Swift struct")
func decodeSwiftStruct() throws {
    let decoder = ToonDecoder()
    let toon = """
    id: 1
    name: Alice
    email: "alice@example.com"
    active: true
    """

    let user = try decoder.decode(User.self, from: toon)

    #expect(user.id == 1)
    #expect(user.name == "Alice")
    #expect(user.email == "alice@example.com")
    #expect(user.active == true)
}

@Test("Decode TOON tabular array to Swift struct array")
func decodeSwiftStructArray() throws {
    let decoder = ToonDecoder()
    let toon = """
    [2]{id,name,email,active}:
     1,Alice,"alice@example.com",true
     2,Bob,"bob@example.com",false
    """

    let users = try decoder.decode([User].self, from: toon)

    #expect(users.count == 2)
    #expect(users[0].name == "Alice")
    #expect(users[1].name == "Bob")
}

@Test("Decode nested TOON to Swift struct")
func decodeNestedSwiftStruct() throws {
    let decoder = ToonDecoder()
    let toon = """
    name: TechCorp
    founded: 2020
    employees[2]{name,role}:
      Alice,Engineer
      Bob,Designer
    """

    let company = try decoder.decode(Company.self, from: toon)

    #expect(company.name == "TechCorp")
    #expect(company.founded == 2020)
    #expect(company.employees.count == 2)
    #expect(company.employees[0].name == "Alice")
    #expect(company.employees[0].role == "Engineer")
    #expect(company.employees[1].name == "Bob")
    #expect(company.employees[1].role == "Designer")
}

// MARK: - Round-trip Codable Tests

@Test("Round-trip Swift struct through TOON")
func roundTripSwiftStruct() throws {
    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let original = User(id: 42, name: "Charlie", email: "charlie@example.com", active: true)

    let toon = try encoder.encode(original)
    let decoded = try decoder.decode(User.self, from: toon)

    #expect(decoded == original)
}

@Test("Round-trip Swift struct array through TOON")
func roundTripSwiftStructArray() throws {
    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let original = [
        User(id: 1, name: "Alice", email: "alice@example.com", active: true),
        User(id: 2, name: "Bob", email: "bob@example.com", active: false),
        User(id: 3, name: "Charlie", email: "charlie@example.com", active: true)
    ]

    let toon = try encoder.encode(original)
    let decoded = try decoder.decode([User].self, from: toon)

    #expect(decoded == original)
}

@Test("Round-trip nested Swift struct through TOON")
func roundTripNestedSwiftStruct() throws {
    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let original = Company(
        name: "TechCorp",
        founded: 2020,
        employees: [
            Employee(name: "Alice", role: "Engineer"),
            Employee(name: "Bob", role: "Designer"),
            Employee(name: "Charlie", role: "Manager")
        ]
    )

    let toon = try encoder.encode(original)
    let decoded = try decoder.decode(Company.self, from: toon)

    #expect(decoded == original)
}

@Test("Round-trip struct with array property")
func roundTripStructWithArray() throws {
    let encoder = ToonEncoder()
    let decoder = ToonDecoder()

    let original = Product(
        id: 1,
        name: "Widget",
        price: 29.99,
        tags: ["new", "featured", "sale"]
    )

    let toon = try encoder.encode(original)
    let decoded = try decoder.decode(Product.self, from: toon)

    #expect(decoded == original)
}

// MARK: - Optional and Nil Tests

struct OptionalUser: Codable, Equatable {
    let id: Int
    let name: String
    let email: String?
    let phone: String?
}

@Test("Encode struct with optional fields")
func encodeStructWithOptionals() throws {
    let encoder = ToonEncoder()
    let user = OptionalUser(
        id: 1,
        name: "Alice",
        email: "alice@example.com",
        phone: nil
    )

    let toon = try encoder.encode(user)

    #expect(toon.contains("email: alice@example.com"))
    // Note: Swift's Codable omits nil optionals by default, which is standard behavior
    #expect(!toon.contains("phone"))
}

@Test("Decode struct with optional fields")
func decodeStructWithOptionals() throws {
    let decoder = ToonDecoder()
    let toon = """
    id: 1
    name: Alice
    email: alice@example.com
    phone: null
    """

    let user = try decoder.decode(OptionalUser.self, from: toon)

    #expect(user.id == 1)
    #expect(user.name == "Alice")
    #expect(user.email == "alice@example.com")
    #expect(user.phone == nil)
}

// MARK: - Performance Characteristic Tests

@Test("TOON is more compact than JSON for tabular data")
func toonVsJsonCompactness() throws {
    let users = (1...100).map { i in
        User(
            id: i,
            name: "User\(i)",
            email: "user\(i)@example.com",
            active: i % 2 == 0
        )
    }

    // Encode to TOON
    let toonEncoder = ToonEncoder()
    let toonString = try toonEncoder.encode(users)

    // Encode to JSON
    let jsonEncoder = JSONEncoder()
    let jsonData = try jsonEncoder.encode(users)
    let jsonString = String(data: jsonData, encoding: .utf8)!

    // TOON should be more compact
    #expect(toonString.count < jsonString.count)
}
