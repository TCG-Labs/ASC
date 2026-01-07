# 🗺️ План развития ASC (Alamofire Swift Client)

> **ASC** — современная, типобезопасная, протокол-ориентированная обертка над Alamofire для Swift 6.2+

## 📊 Текущее состояние проекта

### Статистика реализации

- **Общий прогресс**: ~85% готово
- **Core функциональность**: 100%
- **Конфигурация**: 100%
- **Обработка ошибок**: 100%
- **Retry механизм**: 100%
- **Логирование**: 100%
- **Мониторинг**: 100%
- **Аутентификация**: 80% (нужна доработка OAuth refresh)
- **Операции с файлами**: 0% (критично для v1.0)

### Ключевые достижения

✅ Полностью рабочий протокол-ориентированный API  
✅ Type-safe запросы и ответы с compile-time проверкой  
✅ Полная поддержка async/await  
✅ Структурированная система обработки ошибок  
✅ Встроенный logger с уровнями логирования  
✅ Network reachability мониторинг  
✅ Гибкая система конфигурации  
✅ Retry policies с exponential backoff  

### Что критично для v1.0.0

🔴 **Обязательно реализовать:**
- File Uploads (multipart form-data) — **КРИТИЧНО**
- OAuth Authenticator с автоматическим refresh токенов

🟡 **Желательно доработать:**
- Улучшить документацию примеров
- Добавить integration тесты

---

## 🎯 Core Features (Ключевые фичи)

### 1. Protocol-Oriented API

**Статус**: ✅ **Реализовано**

**Описание**: Основной протокол `Endpoint` определяет контракт для всех сетевых запросов. Использует associated types для типобезопасности на этапе компиляции.

**Пример использования**:

```swift
struct GetUserRequest: Endpoint {
    typealias Response = User
    typealias Request = Empty
    
    let userId: String
    
    var path: String { "/users/\(userId)" }
    var method: HTTPMethod { .get }
}

// Использование
let user = try await client.execute(GetUserRequest(userId: "123"))
```

**Что реализовано**:
- ✅ Протокол `Endpoint` с associated types
- ✅ Default implementations через extensions
- ✅ Type-safe запросы и ответы
- ✅ Поддержка `Empty` для запросов без параметров

**Что нужно доработать**:
- Нет критичных доработок

---

### 2. Базовые HTTP операции

**Статус**: ✅ **Реализовано**

**Описание**: Поддержка всех стандартных HTTP методов через Alamofire.

**Пример использования**:

```swift
// GET запрос
struct GetPostsRequest: Endpoint {
    typealias Response = [Post]
    var path: String { "/posts" }
    var method: HTTPMethod { .get }
}

// POST запрос
struct CreatePostRequest: Endpoint {
    typealias Response = Post
    struct PostData: Encodable, Sendable {
        let title: String
        let content: String
    }
    typealias Request = PostData
    
    let title: String
    let content: String
    
    var path: String { "/posts" }
    var method: HTTPMethod { .post }
    var parameters: PostData? {
        PostData(title: title, content: content)
    }
}

// DELETE запрос
struct DeletePostRequest: Endpoint {
    typealias Response = Empty
    let postId: String
    var path: String { "/posts/\(postId)" }
    var method: HTTPMethod { .delete }
}
```

**Что реализовано**:
- ✅ GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
- ✅ Автоматическое кодирование параметров
- ✅ Поддержка пустых ответов (`Empty`)

**Что нужно доработать**:
- Нет критичных доработок

---

### 3. Сериализация/Десериализация

**Статус**: ✅ **Реализовано**

**Описание**: Автоматическая обработка JSON с поддержкой кастомных стратегий кодирования/декодирования.

**Пример использования**:

```swift
// Кастомный decoder с ISO8601 датами
let customDecoder = JSONDecoder()
customDecoder.dateDecodingStrategy = .iso8601
customDecoder.keyDecodingStrategy = .convertFromSnakeCase

let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    decoder: customDecoder
)

// Автоматическая конвертация snake_case → camelCase
struct UserResponse: Decodable {
    let firstName: String  // Будет декодировано из "first_name"
    let createdAt: Date    // Будет декодировано из ISO8601 строки
}
```

**Что реализовано**:
- ✅ Автоматический JSON decode/encode
- ✅ Кастомные JSONDecoder/JSONEncoder
- ✅ ISO8601 даты по умолчанию
- ✅ Snake_case ↔ camelCase конвертация
- ✅ Кастомные parameter encoders

**Что нужно доработать**:
- Нет критичных доработок

---

### 4. Обработка ошибок

**Статус**: ✅ **Реализовано**

**Описание**: Структурированная иерархия ошибок с автоматическим маппингом из Alamofire ошибок.

**Пример использования**:

```swift
do {
    let user = try await client.execute(GetUserRequest(userId: "123"))
} catch let error as ASCError {
    switch error {
    case .noConnection:
        print("Нет интернета")
    case .timeout(let duration):
        print("Таймаут после \(duration) секунд")
    case .clientError(let code, let message):
        print("Ошибка клиента \(code): \(message ?? "")")
    case .serverError(let code, let message):
        print("Ошибка сервера \(code): \(message)")
    case .decodingFailed(let underlying, let data):
        print("Ошибка декодирования: \(underlying)")
        // data содержит сырой ответ для отладки
    default:
        print("Другая ошибка: \(error.localizedDescription)")
    }
}
```

**Что реализовано**:
- ✅ Иерархия ошибок (`ASCError`)
- ✅ Маппинг Alamofire → ASC ошибок
- ✅ Три категории: Network/Response/Auth
- ✅ Извлечение сообщений из JSON ответов
- ✅ `LocalizedError` conformance
- ✅ Recovery suggestions

**Что нужно доработать**:
- Нет критичных доработок

---

### 5. Асинхронность

**Статус**: ✅ **Реализовано**

**Описание**: Полная поддержка современного async/await API с автоматической отменой задач.

**Пример использования**:

```swift
// Базовое использование
let user = try await client.execute(GetUserRequest(userId: "123"))

// С отменой через Task
let task = Task {
    do {
        let user = try await client.execute(GetUserRequest(userId: "123"))
        return user
    } catch is CancellationError {
        print("Запрос отменен")
        return nil
    }
}

// Отмена через 5 секунд
Task {
    try? await Task.sleep(nanoseconds: 5_000_000_000)
    task.cancel()
}
```

**Что реализовано**:
- ✅ async/await API
- ✅ Task cancellation support
- ✅ Автоматическая отмена Alamofire запросов
- ✅ Sendable conformance для thread safety

**Что нужно доработать**:
- Нет критичных доработок

---

### 6. Конфигурация клиента

**Статус**: ✅ **Реализовано**

**Описание**: Гибкая система конфигурации с поддержкой всех продвинутых возможностей Alamofire.

**Пример использования**:

```swift
// Простая конфигурация
let client = NetworkClient(baseURL: "https://api.example.com")

// Расширенная конфигурация
let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    defaultTimeout: 30.0,
    defaultHeaders: [
        "X-App-Version": "1.0.0",
        "Accept-Language": "en-US"
    ],
    interceptors: [AuthInterceptor(storage: tokenStorage)],
    eventMonitors: [ASCLogger(logLevel: .debug)],
    serverTrustManager: ServerTrustManager(
        evaluators: ["api.example.com": PinnedCertificatesTrustEvaluator()]
    ),
    defaultRetryPolicy: .default,
    networkConstraints: .default,
    validation: .default
)

let client = NetworkClient(configuration: config)

// Preset конфигурации
let devClient = NetworkClient(configuration: .development(baseURL: "https://dev.api.com"))
let prodClient = NetworkClient(configuration: .production(baseURL: "https://api.com"))
let testClient = NetworkClient(configuration: .testing(baseURL: "https://test.api.com"))
```

**Что реализовано**:
- ✅ `NetworkClientConfiguration` структура
- ✅ Base URL, headers, timeouts
- ✅ Кастомные dispatch queues
- ✅ Cache policy
- ✅ Preset конфигурации (development, production, testing)
- ✅ Network constraints
- ✅ Validation options

**Что нужно доработать**:
- Нет критичных доработок

---

### 7. Аутентификация

**Статус**: ⚠️ **Частично реализовано**

**Описание**: Система аутентификации с поддержкой Bearer, Basic токенов и OAuth.

**Пример использования**:

```swift
// Bearer Token
final class BearerTokenStorage: TokenStorage {
    private var token: String?
    
    var authToken: AuthToken? {
        guard let token = token else { return nil }
        return .bearer(token: token)
    }
    
    func updateToken(_ newToken: String) {
        self.token = newToken
    }
    
    func flush() {
        token = nil
    }
}

let storage = BearerTokenStorage(token: "your-token")
let authInterceptor = AuthInterceptor(storage: storage)

let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    authInterceptor: authInterceptor
)

// В запросе
struct GetProfileRequest: Endpoint {
    typealias Response = UserProfile
    var path: String { "/me" }
    var method: HTTPMethod { .get }
    var enableAuthorization: Bool { true }  // Добавит Authorization header
}
```

**Что реализовано**:
- ✅ `AuthInterceptor` (базовая версия)
- ✅ `TokenStorage` протокол
- ✅ Bearer, Basic, Custom токены
- ✅ `AuthToken` enum
- ⚠️ `OAuthAuthenticator` (частично, нужен refresh)

**Что нужно доработать**:
- ❌ Автоматический refresh токенов на 401
- ❌ Завершить реализацию `OAuthAuthenticator.refresh()`
- ❌ Интеграция refresh с `TokenStorage`

---

### 8. Retry механизм

**Статус**: ✅ **Реализовано**

**Описание**: Гибкая система повторных попыток с preset политиками и кастомными настройками.

**Пример использования**:

```swift
// Preset политики
struct CriticalRequest: Endpoint {
    var retryPolicy: Alamofire.RetryPolicy? { .aggressive }  // 5 попыток
}

struct StandardRequest: Endpoint {
    var retryPolicy: Alamofire.RetryPolicy? { .default }  // 3 попытки
}

struct NonCriticalRequest: Endpoint {
    var retryPolicy: Alamofire.RetryPolicy? { .conservative }  // 2 попытки
}

// Кастомная политика
let customPolicy = RetryPolicy(
    retryLimit: 3,
    exponentialBackoffBase: 2,
    exponentialBackoffScale: 1.0,
    retryableHTTPMethods: [.get, .head, .put, .delete, .options],
    retryableHTTPStatusCodes: [408, 429, 500, 502, 503, 504],
    retryableURLErrorCodes: [
        .timedOut,
        .networkConnectionLost,
        .notConnectedToInternet
    ]
)
```

**Что реализовано**:
- ✅ Preset policies (none, conservative, default, aggressive)
- ✅ Per-request retry policy
- ✅ Exponential backoff
- ✅ Настройка retryable статусов и ошибок

**Что нужно доработать**:
- Нет критичных доработок

---

### 9. Логирование

**Статус**: ✅ **Реализовано**

**Описание**: Встроенный logger с уровнями логирования и красивым форматированием.

**Пример использования**:

```swift
let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    logLevel: .verbose  // none, error, info, debug, verbose
)

// Кастомный logger
final class CustomLogger: EventMonitor {
    func request(_ request: Request, didResumeTask task: URLSessionTask) {
        print("🚀 Request started: \(request.description)")
    }
    
    func request<Value>(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Value, AFError>
    ) {
        print("✅ Response: \(response.response?.statusCode ?? 0)")
    }
}

let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    eventMonitors: [CustomLogger()]
)
```

**Что реализовано**:
- ✅ `ASCLogger` (EventMonitor)
- ✅ Уровни логирования (none, error, info, debug, verbose)
- ✅ Форматирование с эмодзи
- ✅ Redaction чувствительных данных
- ✅ Pretty-print JSON
- ✅ Метрики (duration, size)

**Что нужно доработать**:
- Нет критичных доработок

---

### 10. Мониторинг сети

**Статус**: ✅ **Реализовано**

**Описание**: Мониторинг доступности сети с использованием Network.framework.

**Пример использования**:

```swift
// Автоматическая проверка перед запросами
let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    connectivityCheckEnabled: true  // Проверяет сеть перед каждым запросом
)

// Ручной мониторинг
let reachability = NetworkReachability()
reachability.startMonitoring()

// Проверка статуса
if case .reachable(let type) = reachability.currentStatus {
    print("Сеть доступна через: \(type)")  // wifi, cellular, wired, other
}

// Async stream
Task {
    for await status in reachability.statusStream {
        switch status {
        case .reachable(let type):
            print("Сеть доступна: \(type)")
        case .unreachable:
            print("Сеть недоступна")
        }
    }
}

// Combine publisher
reachability.statusPublisher
    .sink { status in
        print("Статус сети: \(status)")
    }
    .store(in: &cancellables)
```

**Что реализовано**:
- ✅ `NetworkReachability` класс
- ✅ Проверка перед запросами
- ✅ AsyncStream для статуса
- ✅ Combine publishers
- ✅ Определение типа соединения (WiFi, Cellular, Wired)

**Что нужно доработать**:
- Нет критичных доработок

---

### 11. Interceptors & Monitors

**Статус**: ✅ **Реализовано**

**Описание**: Полная поддержка Alamofire interceptors и event monitors.

**Пример использования**:

```swift
// Request Interceptor для модификации запросов
final class CustomInterceptor: RequestInterceptor {
    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        var request = urlRequest
        request.setValue("Custom-Value", forHTTPHeaderField: "X-Custom-Header")
        completion(.success(request))
    }
    
    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        // Кастомная логика retry
        completion(.retry)
    }
}

// Event Monitor для логирования
final class AnalyticsMonitor: EventMonitor {
    func request(_ request: Request, didResumeTask task: URLSessionTask) {
        // Отправить аналитику о начале запроса
    }
    
    func request<Value>(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Value, AFError>
    ) {
        // Отправить аналитику о завершении запроса
    }
}

let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    interceptors: [CustomInterceptor()],
    eventMonitors: [AnalyticsMonitor()]
)
```

**Что реализовано**:
- ✅ Поддержка `RequestInterceptor`
- ✅ Поддержка `EventMonitor`
- ✅ Множественные interceptors/monitors
- ✅ `Interceptor` комбинатор

**Что нужно доработать**:
- Нет критичных доработок

---

### 12. SSL/TLS

**Статус**: ✅ **Реализовано**

**Описание**: Поддержка SSL pinning и кастомной валидации сертификатов.

**Пример использования**:

```swift
// Certificate pinning
let serverTrustManager = ServerTrustManager(
    evaluators: [
        "api.example.com": PinnedCertificatesTrustEvaluator()
    ]
)

let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    serverTrustManager: serverTrustManager
)

// Public key pinning
let publicKeyPinner = PublicKeysTrustEvaluator()

// Disabled evaluation (только для разработки!)
let disabledEvaluator = DisabledTrustEvaluator()
```

**Что реализовано**:
- ✅ `ServerTrustManager` support
- ✅ Certificate pinning готовность
- ✅ Интеграция с Alamofire trust evaluators

**Что нужно доработать**:
- Нет критичных доработок

---

### 13. Валидация ответов

**Статус**: ✅ **Реализовано**

**Описание**: Кастомная валидация ответов после декодирования.

**Пример использования**:

```swift
struct GetUserRequest: Endpoint {
    typealias Response = UserResponse
    
    let userId: String
    var path: String { "/users/\(userId)" }
    var method: HTTPMethod { .get }
    
    // Кастомная валидация
    func validate(response: UserResponse) throws {
        guard response.success else {
            throw ASCError.validationFailed(response.errorMessage ?? "Unknown error")
        }
        guard response.user.isActive else {
            throw ASCError.unauthorized("User is inactive")
        }
    }
}
```

**Что реализовано**:
- ✅ `validate(response:)` метод
- ✅ Автоматическая валидация статус кодов
- ✅ Кастомная бизнес-логика валидации

**Что нужно доработать**:
- Нет критичных доработок

---

## 🚀 Advanced Features (Дополнительные фичи)

### 16. File Uploads

**Статус**: ❌ **Не реализовано** (КРИТИЧНО для v1.0)

**Описание**: Поддержка загрузки файлов через multipart form-data с тремя уровнями сложности.

**Планируемый API**:

```swift
// Простая загрузка (маленькие файлы < 10MB)
struct UploadAvatarRequest: Endpoint {
    typealias Response = User
    let imageData: Data
    
    var path: String { "/users/me/avatar" }
    var method: HTTPMethod { .post }
    var files: [String: Data]? {
        ["avatar": imageData]
    }
}

// Загрузка с MIME типами
struct UploadPhotoRequest: Endpoint {
    typealias Response = Photo
    let imageData: Data
    
    var path: String { "/photos" }
    var method: HTTPMethod { .post }
    var uploadDatas: [String: UploadData]? {
        [
            "photo": UploadData(
                data: imageData,
                fileName: "photo.jpg",
                mimeType: "image/jpeg"
            )
        ]
    }
}

// Загрузка больших файлов (> 10MB) - memory-efficient
struct UploadVideoRequest: Endpoint {
    typealias Response = Video
    let videoURL: URL
    
    var path: String { "/videos" }
    var method: HTTPMethod { .post }
    var largeUploadDatas: [LargeUploadData]? {
        [
            LargeUploadData(
                fileURL: videoURL,
                fieldName: "video",
                fileName: "video.mp4",
                mimeType: "video/mp4"
            )
        ]
    }
}

// Множественные файлы
struct UploadDocumentsRequest: Endpoint {
    typealias Response = UploadResult
    let files: [URL]
    let category: String
    
    var path: String { "/documents" }
    var method: HTTPMethod { .post }
    var largeUploadDatas: [LargeUploadData]? {
        files.map { url in
            LargeUploadData(
                fileURL: url,
                fieldName: "documents[]",
                fileName: url.lastPathComponent
            )
        }
    }
    var parameters: Parameters? {
        ["category": category, "count": files.count]
    }
}
```

**Что нужно реализовать**:
- ❌ Добавить `files: [String: Data]?` в `Endpoint`
- ❌ Добавить `uploadDatas: [String: UploadData]?` с MIME типами
- ❌ Добавить `largeUploadDatas: [LargeUploadData]?` для больших файлов
- ❌ Создать типы `UploadData` и `LargeUploadData`
- ❌ Реализовать multipart encoding в `RequestBuilder`
- ❌ Progress tracking для uploads
- ❌ Тесты для всех типов uploads

**Приоритет**: 🔴 **P0 - Критично для v1.0**

---

### 17. Downloads

**Статус**: ❌ **Не реализовано**

**Описание**: Поддержка скачивания файлов с progress tracking и возможностью возобновления.

**Планируемый API**:

```swift
// Простое скачивание
let fileURL = try await client.download(
    from: "https://example.com/file.pdf",
    to: destinationURL
)

// С progress tracking
let stream = client.downloadWithProgress(
    from: "https://example.com/file.pdf",
    to: destinationURL
)

for try await progress in stream {
    switch progress {
    case .progress(let fraction):
        print("Прогресс: \(Int(fraction * 100))%")
    case .completed(let url):
        print("Файл сохранен: \(url)")
    }
}

// Resume download
let resumeData = // ... сохраненные данные
let fileURL = try await client.resumeDownload(
    from: resumeData,
    to: destinationURL
)
```

**Что нужно реализовать**:
- ❌ Download API в `NetworkClient`
- ❌ Progress tracking для downloads
- ❌ Resume downloads
- ❌ Background downloads
- ❌ Тесты

**Приоритет**: 🟠 **P1 - Важно для v1.1**

---

### 18. Response Caching Layer

**Статус**: ⚠️ **Частично реализовано**

**Описание**: Высокоуровневый слой кэширования ответов поверх URLRequest cache policy.

**Текущее состояние**:
- ✅ URLRequest cache policy поддержка
- ✅ `CachedResponseHandler` support
- ❌ Высокоуровневый caching layer

**Планируемый API**:

```swift
// Cache policy в запросе
struct GetCachedDataRequest: Endpoint {
    typealias Response = Data
    var path: String { "/data" }
    var method: HTTPMethod { .get }
    var cachePolicy: URLRequest.CachePolicy? {
        .returnCacheDataElseLoad  // Использовать кэш если доступен
    }
}

// Высокоуровневый cache (будущее)
struct CachedRequest: Endpoint {
    typealias Response = User
    var cacheOptions: CacheOptions? {
        CacheOptions(
            ttl: 3600,  // Time to live в секундах
            key: "user_\(userId)",  // Кастомный ключ
            invalidateOn: [.post, .put, .delete]  // Инвалидация при изменении
        )
    }
}
```

**Что нужно реализовать**:
- ❌ Высокоуровневый caching layer
- ❌ TTL поддержка
- ❌ Кастомные cache keys
- ❌ Инвалидация кэша

**Приоритет**: 🟡 **P2 - Желательно для v1.1**

---

### 19. Request Deduplication

**Статус**: ❌ **Не реализовано**

**Описание**: Предотвращение дублирующих запросов и coalescing одинаковых запросов.

**Планируемый API**:

```swift
// Автоматическая дедупликация
struct GetUserRequest: Endpoint {
    typealias Response = User
    let userId: String
    var path: String { "/users/\(userId)" }
    var method: HTTPMethod { .get }
    var deduplicationKey: String? { "user_\(userId)" }  // Опционально
}

// Если несколько запросов с одинаковым ключом выполняются одновременно,
// только один реальный запрос будет отправлен, остальные получат тот же результат
```

**Что нужно реализовать**:
- ❌ Request deduplication механизм
- ❌ Request coalescing
- ❌ Конфигурация в `NetworkClientConfiguration`
- ❌ Тесты

**Приоритет**: 🟡 **P2 - Желательно для v1.1**

---

### 20. Rate Limiting

**Статус**: ❌ **Не реализовано**

**Описание**: Встроенный rate limiter для предотвращения превышения лимитов API.

**Планируемый API**:

```swift
// Rate limiter в конфигурации
let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    rateLimiter: RateLimiter(
        maxRequests: 100,
        perInterval: 60,  // 100 запросов в минуту
        strategy: .fifo  // First in, first out
    )
)

// Per-request rate limiting
struct LimitedRequest: Endpoint {
    var rateLimit: RateLimit? {
        RateLimit(maxRequests: 10, perInterval: 1)  // 10 запросов в секунду
    }
}
```

**Что нужно реализовать**:
- ❌ Rate limiter implementation
- ❌ Throttling механизм
- ❌ Конфигурация
- ❌ Тесты

**Приоритет**: 🟡 **P2 - Желательно для v1.1**

---

### 21. Batch Requests

**Статус**: ❌ **Не реализовано**

**Описание**: Выполнение множественных запросов в batch с контролем параллелизма.

**Планируемый API**:

```swift
// Batch execution
let results = try await client.executeBatch([
    GetUserRequest(userId: "1"),
    GetUserRequest(userId: "2"),
    GetUserRequest(userId: "3")
], maxConcurrency: 3)

// С обработкой ошибок
let results = try await client.executeBatch(
    requests: [request1, request2, request3],
    maxConcurrency: 2,
    failFast: false  // Продолжить даже при ошибках
)

// Результаты
for result in results {
    switch result {
    case .success(let value):
        print("Успех: \(value)")
    case .failure(let error):
        print("Ошибка: \(error)")
    }
}
```

**Что нужно реализовать**:
- ❌ Batch request execution
- ❌ Request queue management
- ❌ Priority queue
- ❌ Контроль параллелизма
- ❌ Тесты

**Приоритет**: 🟢 **P3 - Nice to have для v1.2**

---

### 22. WebSocket Support

**Статус**: ❌ **Не реализовано**

**Описание**: Поддержка WebSocket соединений для real-time коммуникации.

**Приоритет**: 🟢 **P3 - Nice to have для v1.3+**

---

### 23. GraphQL Support

**Статус**: ❌ **Не реализовано**

**Описание**: Helpers для работы с GraphQL запросами и ответами.

**Приоритет**: 🟢 **P3 - Nice to have для v1.3+**

---

### 24. Mock Engine

**Статус**: ⚠️ **Частично реализовано**

**Описание**: Встроенный mock engine для тестирования без реальных сетевых запросов.

**Текущее состояние**:
- ✅ `MockURLProtocol` в тестах
- ❌ Встроенный mock engine для библиотеки
- ❌ Response stubbing API

**Планируемый API**:

```swift
// Mock engine
let mockEngine = MockEngine()
mockEngine.stub(GetUserRequest.self) { request in
    User(id: request.userId, name: "Mock User")
}

let client = NetworkClient(
    configuration: .testing(),
    mockEngine: mockEngine
)
```

**Приоритет**: 🟡 **P2 - Желательно для v1.2**

---

## 📅 Календарь релизов

### v1.0.0 - MVP Release (Текущий фокус)

**Цель**: Стабильный, production-ready релиз с базовым функционалом

**Критичные фичи для релиза**:
- ✅ Все текущие Core Features
- ❌ **File Uploads** (обязательно)
- ⚠️ **OAuth Authenticator** (доработать refresh)

**Планируемые сроки**: Гибкий график (по готовности фич)

**Задачи**:
1. Реализовать File Uploads (multipart form-data)
2. Завершить OAuth refresh логику
3. Comprehensive тестирование
4. Документация и примеры
5. Performance оптимизации

**После релиза**:
- Стабильный API для production использования
- Базовая функциональность покрыта
- Готовность к расширению

---

### v1.1.0 - Downloads & Performance

**Цель**: Добавить downloads и улучшить производительность

**Новые фичи**:
- ❌ Downloads с progress tracking
- ❌ Resume downloads
- ❌ Background downloads
- ❌ Response caching layer
- ❌ Request deduplication
- ❌ Rate limiting

**Улучшения**:
- Performance оптимизации
- Memory optimizations
- Better error messages

**Планируемые сроки**: После v1.0.0, гибкий график

---

### v1.2.0 - Advanced Features

**Цель**: Продвинутые возможности для сложных сценариев

**Новые фичи**:
- ❌ Batch requests
- ❌ Request queue management
- ❌ Mock engine для тестирования
- ❌ Enhanced analytics
- ❌ Response transformers

**Улучшения**:
- Расширенная документация
- Больше примеров
- Best practices guide

**Планируемые сроки**: После v1.1.0, гибкий график

---

### v1.3.0+ - Future Enhancements

**Цель**: Экспериментальные и специализированные фичи

**Возможные фичи**:
- ❌ WebSocket support
- ❌ GraphQL helpers
- ❌ Advanced analytics
- ❌ Custom serializers
- ❌ Request/Response middleware pipeline

**Планируемые сроки**: По мере необходимости и запросов сообщества

---

## 🎯 Приоритизация фич

### P0 - Критично для v1.0.0 (MVP)

**Обязательно реализовать перед первым релизом:**

1. ✅ Protocol-oriented API
2. ✅ Базовые HTTP операции
3. ✅ Сериализация/Десериализация
4. ✅ Обработка ошибок
5. ✅ async/await поддержка
6. ✅ Базовая конфигурация
7. ✅ Простая аутентификация
8. ✅ Retry policies
9. ✅ Логирование
10. ❌ **File Uploads** — **КРИТИЧНО, НЕ РЕАЛИЗОВАНО**

**Статус P0**: 9/10 готово (90%)

---

### P1 - Важно для v1.0.0 (High Priority)

**Желательно реализовать для первого релиза:**

1. ✅ Response validation
4. ✅ Network reachability
5. ⚠️ OAuth authenticator (refresh) — **НУЖНА ДОРАБОТКА**
6. ✅ Custom interceptors/monitors
7. ✅ SSL pinning support

**Статус P1**: 4/5 готово (80%)

---

### P2 - Желательно для v1.1.0 (Medium Priority)

**Планируется для следующего релиза:**

1. ❌ Downloads с progress
2. ❌ Background downloads
3. ❌ Response caching layer
4. ❌ Request deduplication
5. ❌ Rate limiting
6. ❌ Batch requests
7. ✅ Enhanced logging (уже есть)

**Статус P2**: 1/7 готово (14%)

---

### P3 - Nice to have (Low Priority)

**Будущие улучшения:**

1. ❌ WebSocket support
2. ❌ GraphQL support
3. ❌ Встроенная аналитика
4. ❌ Mock engine для библиотеки
5. ❌ Response transformers
6. ❌ Custom serializers

**Статус P3**: 0/6 готово (0%)

---

## 📊 Roadmap Timeline

```
v1.0.0 (MVP)          v1.1.0              v1.2.0              v1.3.0+
     │                    │                    │                    │
     │                    │                    │                    │
     ├─ File Uploads      ├─ Downloads         ├─ Batch Requests    ├─ WebSocket
     ├─ OAuth Refresh     ├─ Caching           ├─ Mock Engine       ├─ GraphQL
     └─ Polish & Docs     ├─ Deduplication     └─ Analytics         └─ Advanced
                          └─ Rate Limiting
```

### Детальный план v1.0.0

**Неделя 1: File Uploads**
- [ ] Добавить `files: [String: Data]?` в `Endpoint`
- [ ] Добавить `uploadDatas: [String: UploadData]?` с MIME типами
- [ ] Добавить `largeUploadDatas: [LargeUploadData]?` для больших файлов
- [ ] Реализовать multipart encoding в `RequestBuilder`
- [ ] Создать типы `UploadData` и `LargeUploadData`
- [ ] Тесты для всех типов uploads
- [ ] Документация с примерами

**Неделя 2: OAuth Authenticator**
- [ ] Завершить реализацию `OAuthAuthenticator.refresh()`
- [ ] Интеграция с `TokenStorage`
- [ ] Автоматический refresh на 401
- [ ] Тесты для refresh flow
- [ ] Документация

**Неделя 3: Полировка**
- [ ] Проверка всех edge cases
- [ ] Улучшение error messages
- [ ] Примеры использования
- [ ] README обновление
- [ ] Performance тесты

---

## 🔄 Стратегия развития

### Философия версионирования

**v1.0.0 - Стабильная база**
- Минимальный, но полный функционал
- Простой API без излишней гибкости
- Фокус на надежности и простоте использования

**v1.1.0 - Расширение возможностей**
- Добавление downloads
- Performance улучшения
- Оптимизация памяти

**v1.2.0 - Продвинутые фичи**
- Batch requests
- Mock engine
- Расширенная аналитика

**v1.3.0+ - Специализация**
- WebSocket, GraphQL
- Экспериментальные фичи
- По запросам сообщества

### Принципы добавления фич

1. **Простота прежде гибкости** — первая версия должна быть простой
2. **Постепенное усложнение** — каждый релиз добавляет "сахар"
3. **Обратная совместимость** — не ломать существующий API
4. **Документация** — каждая фича должна быть задокументирована
5. **Тесты** — покрытие тестами обязательно

---

## 📝 Заметки по реализации

### File Uploads - Детальный план

**Типы для реализации**:

```swift
// Простой тип для маленьких файлов
public struct UploadData: Sendable {
    public let data: Data
    public let fileName: String
    public let mimeType: String
    
    public init(data: Data, fileName: String, mimeType: String) {
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
    }
}

// Тип для больших файлов (memory-efficient)
public struct LargeUploadData: Sendable {
    public let fileURL: URL
    public let fieldName: String
    public let fileName: String
    public let mimeType: String
    
    public init(
        fileURL: URL,
        fieldName: String,
        fileName: String,
        mimeType: String
    ) {
        self.fileURL = fileURL
        self.fieldName = fieldName
        self.fileName = fileName
        self.mimeType = mimeType
    }
}
```

**Изменения в Endpoint**:

```swift
public protocol Endpoint: Sendable {
    // ... существующие свойства
    
    /// Simple file uploads (field name → Data)
    /// Use for small files (< 10MB)
    var files: [String: Data]? { get }
    
    /// File uploads with MIME types (field name → UploadData)
    /// Use for files with specific MIME types
    var uploadDatas: [String: UploadData]? { get }
    
    /// Large file uploads (array of LargeUploadData)
    /// Use for large files (> 10MB) - memory-efficient
    var largeUploadDatas: [LargeUploadData]? { get }
}
```

**Изменения в RequestBuilder**:

- Добавить логику определения multipart encoding
- Использовать `MultipartFormData` из Alamofire
- Обработка всех трех типов uploads

### OAuth Authenticator - Детальный план

**Завершение реализации**:

```swift
final class OAuthAuthenticator: Authenticator {
    private let tokenStorage: any TokenStorage
    private let client: NetworkClient
    
    func refresh(
        _ credential: OAuthCredential,
        for session: Session,
        completion: @escaping (Result<OAuthCredential, Error>) -> Void
    ) {
        Task {
            do {
                // Использовать refreshRequest из TokenStorage
                guard let refreshRequest = tokenStorage.refreshRequest else {
                    completion(.failure(ASCError.invalidToken))
                    return
                }
                
                // Выполнить refresh через NetworkClient
                let response = try await client.execute(refreshRequest)
                
                // Обновить токены в storage
                // ...
                
                // Создать новую credential
                let newCredential = OAuthCredential(
                    accessToken: response.accessToken,
                    refreshToken: response.refreshToken,
                    userID: response.userID,
                    expiration: response.expiration
                )
                
                completion(.success(newCredential))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
```

---

## 🎓 Сравнение с Moya

### Что есть в Moya, но нет в ASC

- ❌ Provider pattern (MoyaProvider)
- ❌ Plugins система (более гибкая чем interceptors)
- ❌ Stub responses для тестов
- ❌ Endpoint closure pattern

### Что есть в ASC, но нет в Moya

- ✅ Более современный async/await API
- ✅ Встроенный logger
- ✅ Network reachability
- ✅ Более гибкая конфигурация
- ✅ Более детальная обработка ошибок

### Общее

- ✅ Protocol-oriented design
- ✅ Type-safe requests
- ✅ Interceptors/Plugins
- ✅ Error handling
- ✅ Alamofire под капотом

---

## 📚 Ресурсы

### Документация
- [README.md](../README.md) - Основная документация
- [Package.swift](../Package.swift) - SPM манифест

### Примеры
- [Examples/](../Examples/) - Примеры использования

### Тесты
- [Tests/ASCTests/](../Tests/ASCTests/) - Test suite

---

## 🤝 Вклад в развитие

Если вы хотите помочь с реализацией фич:

1. Проверьте раздел "Календарь релизов" для текущих задач
2. Выберите фичу из P0 или P1 приоритетов
3. Создайте issue или PR с описанием изменений
4. Следуйте принципам разработки из `.cursorrules`

---

**Последнее обновление**: 2025-01-XX  
**Версия документа**: 1.0

