# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ASC (Alamofire Swift Client) is a Swift Package Manager library built on top of Alamofire. The project targets iOS 18+ and macOS 15+ and uses Swift 6.2.

## Development Commands

### Building
```bash
swift build
```

### Testing
```bash
# Run all tests
swift test

# Run a specific test
swift test --filter ASCTests.example
```

### Linting
The project uses SwiftLint with a strict configuration. Linting runs automatically during build via the SwiftLintBuildToolPlugin.

```bash
# Manually run SwiftLint (if installed)
swiftlint

# Auto-fix issues
swiftlint --fix
```

## Architecture

### Package Structure
- **ASC/Sources/ASC/**: Main library source code
- **ASC/Tests/ASCTests/**: Test suite using Swift Testing framework
- **ASC/Package.swift**: SPM configuration with Alamofire dependency

### Dependencies
- **Alamofire** (5.10.2+): Core networking library this package wraps
- **SwiftLint** (0.61.0+): Build-time linting via plugin

### Testing Framework
Uses Swift Testing framework (not XCTest). Tests use the `@Test` attribute and `#expect` for assertions.

## Code Standards

### SwiftLint Configuration
The project has a **very strict** SwiftLint configuration (.swiftlint.yml):

- **Force unwrapping/casting/try**: Errors (must avoid `!`, `as!`, `try!`)
- **Line length**: 120 warning, 150 error
- **Function body length**: 50 warning, 100 error
- **Cyclomatic complexity**: 10 warning, 15 error (strict)
- **Function parameters**: 5 warning, 7 error (strict)
- **print() prohibited**: Use Logger instead (warning)
- **!. chaining prohibited**: Use optional chaining (error)
- **Documentation required**: Missing docs on public API (error)
- **Explicit ACL**: All declarations need explicit access control

### Key Rules
- Tests and Package.swift are excluded from linting
- All public APIs must have documentation comments
- Prefer optional chaining over force unwrapping
- Use Logger instead of print()
- Keep functions under 50 lines
- Maximum 5 parameters per function
- Use MARK comments to organize code

## Code Structure

- Use Swift's latest features and protocol-oriented programming.
- Prefer value types (structs) over classes.
- Follow Apple's Human Interface Guidelines.

## Naming
- camelCase for vars/funcs, PascalCase for types
- Verbs for methods (fetchData)
- Boolean: use is/has/should prefixes
- Clear, descriptive names following Apple style
- Use camel case for network model variables


## Swift Best Practices

- Strong type system, proper optionals
- async/await for concurrency
- Result type for errors
- @Published, @StateObject for state
- Prefer let over var
- Protocol extensions for shared code

## 6. Performance

- Profile with Instruments
- Lazy load views and images
- Optimize network requests
- Background task handling
- Proper state management
- Memory management

## GitHub Integration

The repository has GitHub Actions configured for Claude Code:
- Claude responds to `@claude` mentions in issues, PRs, and comments
- Workflow file: .github/workflows/claude.yml
