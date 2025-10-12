# ASC Examples

This directory contains practical examples demonstrating how to use the ASC networking library.

## 📚 Available Examples

### 1. **QuickStart.swift** - Get Started in 5 Minutes

Perfect for beginners! Shows the absolute minimum you need to make network requests.

**What it covers:**
- ✅ Basic client setup
- ✅ GET requests
- ✅ POST requests with JSON body
- ✅ Simple error handling

**Complexity:** ⭐ Beginner

---

### 2. **JSONPlaceholderExample.swift** - Complete Reference

A comprehensive example using the JSONPlaceholder API demonstrating all ASC features.

**What it covers:**
- ✅ All HTTP methods (GET, POST, PUT, DELETE)
- ✅ Path parameters (`/posts/{id}`)
- ✅ Query parameters (`/posts?userId=1`)
- ✅ Complex Codable models
- ✅ Empty responses (204 No Content)
- ✅ Concurrent requests with TaskGroup
- ✅ Comprehensive error handling
- ✅ Real-world workflows

**Complexity:** ⭐⭐⭐ Advanced

---

### 3. **AdvancedExample.swift** - Production Patterns

Advanced features for production applications.

**What it covers:**
- ✅ Custom Request Interceptors (authentication, logging)
- ✅ Event Monitors (performance tracking)
- ✅ Advanced configuration
- ✅ Custom retry policies
- ✅ Token refresh flow
- ✅ Concurrent request monitoring

**Complexity:** ⭐⭐⭐⭐ Expert

---

### 4. **FileUploadExample.swift** - File Upload Guide

Complete guide to uploading files with ASC.

**What it covers:**
- ✅ Single file upload
- ✅ Multiple files upload
- ✅ Upload with form parameters
- ✅ Custom headers for uploads
- ✅ Timeout configuration
- ✅ Real working examples (httpbin.org)
- ✅ Error handling for uploads

**Complexity:** ⭐⭐ Intermediate

---

## 🚀 How to Run Examples

### Option 1: iOS/macOS App

```swift
import SwiftUI
import ASC

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Run examples on app launch
                    await runExamples()
                }
        }
    }
}
```

### Option 2: Command-Line Tool

Create a new Swift executable package:

```bash
# Create package
mkdir ASCExamples && cd ASCExamples
swift package init --type executable

# Add ASC dependency to Package.swift
```

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/ASC.git", from: "1.0.0")
]
```

```swift
// Sources/main.swift
@main
struct Main {
    static func main() async {
        await runExamples()
    }
}
```

### Option 3: Swift Playground (macOS)

1. Create a new Playground in Xcode
2. Copy example code
3. Run in the playground

---

## 📖 API Used: JSONPlaceholder

All examples use the **JSONPlaceholder** API - a free fake REST API for testing and prototyping.

**Base URL:** `https://jsonplaceholder.typicode.com`

### Available Resources:

| Resource | Endpoint | Description |
|----------|----------|-------------|
| Posts | `/posts` | Blog posts (100 items) |
| Comments | `/comments` | Post comments (500 items) |
| Albums | `/albums` | Photo albums (100 items) |
| Photos | `/photos` | Photos (5000 items) |
| Todos | `/todos` | Todo items (200 items) |
| Users | `/users` | Users (10 items) |

### Example Endpoints:

```
GET    /posts              - Get all posts
GET    /posts/1            - Get post by ID
POST   /posts              - Create new post
PUT    /posts/1            - Update post
PATCH  /posts/1            - Partially update post
DELETE /posts/1            - Delete post
GET    /posts?userId=1     - Filter by user
GET    /posts/1/comments   - Get post's comments
```

**Documentation:** https://jsonplaceholder.typicode.com

---

## 🎯 Learning Path

**New to ASC?** Follow this learning path:

1. **Start with `QuickStart.swift`**
   - Understand basic concepts
   - Make your first requests
   - ~5 minutes

2. **Explore specific features in `JSONPlaceholderExample.swift`**
   - Example 1-2: Basic GET requests
   - Example 3-5: Creating/updating/deleting resources
   - Example 6-8: URL parameters and path parameters
   - Example 9: Complex workflows
   - Example 10: Concurrent requests
   - Example 11: Error handling

3. **Read the documentation**
   - Check `CLAUDE.md` in the root directory
   - Understand advanced features (interceptors, monitors, etc.)

4. **Build your own API client**
   - Use these examples as a template
   - Adapt to your specific API
   - Add your own business logic

---

## 💡 Tips for Using ASC

### Tip 1: Define Models First
```swift
// Always start with your data models
struct Post: Codable, Sendable {
    let id: Int
    let title: String
}
```

### Tip 2: One Request = One Struct
```swift
// Each endpoint gets its own request struct
struct GetPostRequest: NetworkRequest {
    typealias Response = Post
    let postId: Int
    var path: String { "/posts/\(postId)" }
    var method: HTTPMethod { .get }
}
```

### Tip 3: Use Path Parameters for Clean URLs
```swift
// ✅ Good - uses path parameters
var path: String { "/posts/{id}" }
var pathParameters: [String: String]? { ["id": "123"] }

// ❌ Avoid - string interpolation
var path: String { "/posts/\(postId)" }
```

### Tip 4: Choose the Right Encoding
```swift
// For POST/PUT with JSON body
var parameterEncoding: any ParameterEncoding {
    JSONEncoding.default
}

// For GET with query parameters
var parameterEncoding: any ParameterEncoding {
    URLEncoding.default
}
```

### Tip 5: Handle Errors Gracefully
```swift
do {
    let post = try await client.execute(request)
} catch let error as ResponseError {
    // Handle API errors (4xx, 5xx)
} catch let error as NetworkError {
    // Handle network errors (no connection, timeout)
}
```

---

## 🔗 Related Resources

- **Main Documentation:** `../CLAUDE.md`
- **API Reference:** Use Xcode's documentation browser
- **JSONPlaceholder Guide:** https://jsonplaceholder.typicode.com/guide/
- **GitHub Issues:** Report bugs or request features

---

## 🤝 Contributing Examples

Have a great example? Share it!

1. Create a new `.swift` file in this directory
2. Follow the existing format:
   - Clear comments
   - Step-by-step explanation
   - Real-world use case
3. Add it to this README
4. Submit a PR

**Example ideas:**
- Authentication flow
- File uploads
- GraphQL client
- WebSocket integration
- Retry strategies
- Custom interceptors

---

## ❓ FAQ

**Q: Do I need API keys for these examples?**
A: No! JSONPlaceholder is completely free and doesn't require authentication.

**Q: Can I use a different API?**
A: Absolutely! Just change the base URL and adapt the models to match your API.

**Q: Are these examples production-ready?**
A: The code patterns are production-ready, but you should add proper error handling, logging, and testing for production use.

**Q: How do I add authentication?**
A: Use request interceptors or custom headers. Check the advanced examples and documentation.

**Q: Can I run these on Linux?**
A: ASC targets iOS 18+ and macOS 15+. Linux support depends on Swift and Foundation availability.

---

**Happy coding! 🚀**

If you have questions, check the main documentation or open an issue on GitHub.
