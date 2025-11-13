# Contributing to Toon Swift

Thank you for your interest in contributing to Toon Swift! This project follows a test-driven development (TDD) approach and maintains 100% test coverage.

## Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/vinnyt/toon-swift.git
   cd toon-swift
   ```

2. **Build the project**
   ```bash
   swift build
   ```

3. **Run tests**
   ```bash
   swift test
   ```

## Development Workflow

### Test-Driven Development (TDD)

This project was built using TDD and we maintain this approach for all new features:

1. **Write tests first** - Before implementing any feature, write failing tests that define the expected behavior
2. **Implement the feature** - Write the minimum code needed to make the tests pass
3. **Refactor** - Clean up the implementation while keeping tests green
4. **Verify coverage** - Ensure new code has test coverage

### Making Changes

1. **Fork the repository** and create a new branch
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Write tests** for your changes in `Tests/ToonTests/`

3. **Implement your changes** in `Sources/Toon/`

4. **Ensure all tests pass**
   ```bash
   swift test
   ```

5. **Commit your changes** with clear, descriptive messages
   ```bash
   git commit -m "Add support for [feature]"
   ```

6. **Push to your fork** and submit a pull request
   ```bash
   git push origin feature/your-feature-name
   ```

## Code Style

- Follow Swift conventions and best practices
- Use clear, descriptive variable and function names
- Add comments for complex logic
- Keep functions focused and single-purpose

## Testing Guidelines

- All tests should be in the `Tests/ToonTests/` directory
- Use descriptive test names that explain what is being tested
- Test both success and failure cases
- Include round-trip tests for encoding/decoding features
- Aim for 100% test coverage

### Test Categories

- **Primitive Tests**: Null, booleans, numbers, strings
- **Object Tests**: Simple and nested objects
- **Array Tests**: Inline, tabular, and mixed arrays
- **Codable Tests**: Swift struct encoding/decoding
- **Round-trip Tests**: Encode → Decode verification
- **Error Handling**: Invalid input and edge cases

## Pull Request Process

1. Ensure all tests pass
2. Update README.md if you've added new features
3. Add tests for any new functionality
4. Follow the existing code style
5. Write a clear PR description explaining your changes

## Reporting Issues

- Use the GitHub issue tracker
- Include a clear description of the problem
- Provide code samples that reproduce the issue
- Specify your Swift version and platform

## Questions?

Feel free to open an issue for questions or discussion about potential contributions.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
