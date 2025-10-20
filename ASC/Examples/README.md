# ASC Examples

Practical examples demonstrating how to use the ASC networking library.

## 📚 Table of Contents

- [Quick Start](#quick-start) - Get started in 5 minutes
- [Request Organization](#request-organization) - Organize your API calls
- [Real-World Example](#real-world-example) - Complete CRUD with JSONPlaceholder API
- [Advanced Features](#advanced-features) - Interceptors, monitoring, retry policies
- [File Uploads](#file-uploads) - Handle file uploads efficiently

---

## 🚀 Quick Start

**File:** [`QuickStart.swift`](QuickStart.swift)

The fastest way to get started with ASC. This example shows:

- Creating a NetworkClient
- Making GET requests
- Making POST requests with JSON body
- Basic error handling

```swift
import ASC

// 1. Create client
let client = NetworkClient(baseURL: "https://jsonplaceholder.typicode.com")

// 2. Define request
struct GetPostsRequest: NetworkRequest {
    typealias Response = [Post]
    var path: String { "/posts" }
    var method: HTTPMethod { .get }
}

// 3. Execute
let posts = try await client.execute(GetPostsRequest())
```

**Perfect for:** First-time users, quick prototypes

---

## 📋 Request Organization

**File:** [`EnumRequestExample.swift`](EnumRequestExample.swift)

Learn different patterns for organizing your API calls:

### Pattern 1: Namespace Enum ⭐️ (Recommended)

```swift
enum UserAPI {
    struct Get: NetworkRequest { ... }      // -> User
    struct List: NetworkRequest { ... }     // -> [User]
    struct Delete: NetworkRequest { ... }   // -> EmptyResponse
}

// Usage
let user = try await client.execute(UserAPI.Get(userId: "123"))
let users = try await client.execute(UserAPI.List(page: 1, limit: 10))
```

**Advantages:**
- Different response types per request
- Clean organization
- Easy to extend

### Pattern 2: Simple Enum

```swift
enum PostRequest: NetworkRequest {
    typealias Response = Post

    case get(id: String)
    case list(page: Int)
}

// Usage
let post = try await client.execute(PostRequest.get(id: "123"))
```

**Advantages:**
- Concise syntax
- Good for simple CRUD operations

**Perfect for:** Understanding best practices for structuring your API layer

---

## 🌐 Real-World Example

**File:** [`JSONPlaceholderExample.swift`](JSONPlaceholderExample.swift)

Complete example using the JSONPlaceholder API (https://jsonplaceholder.typicode.com).

Demonstrates:
- Full CRUD operations (GET, POST, PUT, DELETE)
- Path parameters
- Query parameters
- Nested resources
- Error handling

```swift
// Get all posts
let posts = try await client.execute(PostAPI.GetAll())

// Get single post
let post = try await client.execute(PostAPI.Get(postId: 1))

// Create post
let newPost = try await client.execute(
    PostAPI.Create(userId: 1, title: "Hello", body: "World")
)

// Update post
let updated = try await client.execute(
    PostAPI.Update(postId: 1, userId: 1, title: "Updated", body: "Content")
)

// Delete post
try await client.execute(PostAPI.Delete(postId: 1))
```

**Perfect for:** Seeing how everything fits together in a real API

---

## ⚙️ Advanced Features

**File:** [`AdvancedExample.swift`](AdvancedExample.swift)

Deep dive into ASC's powerful features:

### Request Interceptors

Add authentication, logging, or custom headers to all requests:

```swift
final class AuthInterceptor: RequestInterceptor {
    func adapt(_ request: URLRequest, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var request = request
        request.headers.add(.authorization(bearerToken: token))
        completion(.success(request))
    }
}
```

### Event Monitors

Track request lifecycle for analytics or debugging:

```swift
final class NetworkLogger: EventMonitor {
    func requestDidResume(_ request: Request) {
        print("🚀 Request started: \(request.description)")
    }
}
```

### Advanced Configuration

```swift
let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    interceptors: [AuthInterceptor(), LoggingInterceptor()],
    eventMonitors: [NetworkLogger()],
    serverTrustManager: customTrustManager,
    defaultTimeout: 30.0
)

let client = NetworkClient(configuration: config)
```

### Retry Policies

```swift
struct ImportantRequest: NetworkRequest {
    // ...
    var retryPolicy: Alamofire.RetryPolicy? { .aggressive }  // 5 retries
}
```

**Perfect for:** Production apps requiring authentication, logging, and robust error handling

---

## 📤 File Uploads

**File:** [`FileUploadExample.swift`](FileUploadExample.swift)

Learn how to upload files efficiently:

### Small Files (< 10MB)

Use `fileUploads` for in-memory encoding:

```swift
struct UploadPhotoRequest: NetworkRequest {
    typealias Response = Photo
    let imageData: Data

    var path: String { "/photos" }
    var method: HTTPMethod { .post }
    var fileUploads: [String: FileUpload]? {
        ["photo": .jpeg(data: imageData, fileName: "photo.jpg")]
    }
}
```

### Large Files (> 10MB)

Use `largeFileUploads` for file-based encoding:

```swift
struct UploadVideoRequest: NetworkRequest {
    typealias Response = Video
    let videoURL: URL

    var path: String { "/videos" }
    var method: HTTPMethod { .post }
    var largeFileUploads: [LargeFileUpload]? {
        [LargeFileUpload(
            fileURL: videoURL,
            fieldName: "video",
            fileName: "video.mp4",
            mimeType: "video/mp4"
        )]
    }
}
```

### Files with Metadata

```swift
struct UploadDocumentsRequest: NetworkRequest {
    // ...
    var largeFileUploads: [LargeFileUpload]? { files }
    var parameters: Parameters? {
        ["category": "documents", "count": files.count]
    }
}
```

**Perfect for:** Apps that need to upload images, videos, or documents

---

## 🎯 Quick Reference

| Example | Complexity | Topics Covered | Lines |
|---------|-----------|----------------|-------|
| **QuickStart** | ⭐️ Beginner | GET, POST, Basic setup | ~100 |
| **EnumRequest** | ⭐️⭐️ Intermediate | Code organization, Patterns | ~250 |
| **JSONPlaceholder** | ⭐️⭐️ Intermediate | Full CRUD, Path params | ~200 |
| **Advanced** | ⭐️⭐️⭐️ Advanced | Interceptors, Monitoring, Config | ~300 |
| **FileUpload** | ⭐️⭐️ Intermediate | File uploads, MIME types | ~200 |

---

## 💡 Learning Path

**New to ASC?** Follow this order:

1. **Start:** `QuickStart.swift` - Understand the basics (5 min)
2. **Learn:** `EnumRequestExample.swift` - Organize your code (10 min)
3. **Practice:** `JSONPlaceholderExample.swift` - Try real API (15 min)
4. **Master:** `AdvancedExample.swift` - Production features (20 min)
5. **Extend:** `FileUploadExample.swift` - Handle file uploads (10 min)

**Total learning time:** ~1 hour

---

## 🔗 Additional Resources

- **Main README:** [../README.md](../README.md) - Complete library documentation
- **CLAUDE.md:** [../CLAUDE.md](../CLAUDE.md) - Architecture and design decisions
- **Tests:** [../Tests/ASCTests/](../Tests/ASCTests/) - See how ASC is tested

---

## ❓ Common Questions

### Which pattern should I use for organizing requests?

**Answer:** Use **Namespace Enum** (Pattern 1) for most projects. It's the most flexible and scales well.

### How do I handle authentication?

**Answer:** See `AdvancedExample.swift` for `AuthInterceptor` implementation.

### When should I use file-based vs in-memory uploads?

**Answer:** ASC automatically chooses based on file size:
- < 10MB → In-memory (automatic)
- > 10MB → File-based (automatic)

You can also explicitly use `largeFileUploads` for files on disk.

### How do I add headers to all requests?

**Answer:** Use `NetworkClientConfiguration` with `defaultHeaders`:

```swift
let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    defaultHeaders: [
        "X-App-Version": "1.0.0",
        "Accept-Language": "en-US"
    ]
)
```

### Can I use multiple interceptors?

**Answer:** Yes! Pass an array of interceptors in configuration:

```swift
let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    interceptors: [
        AuthInterceptor(),
        LoggingInterceptor(),
        AnalyticsInterceptor()
    ]
)
```

---

**Ready to start?** Open [`QuickStart.swift`](QuickStart.swift) and begin your ASC journey! 🚀
