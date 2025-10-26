# TestExample - ASC Library Integration

Тестовое iOS приложение для проверки работоспособности ASC (Alamofire Swift Client) библиотеки с живыми запросами к JSONPlaceholder API.

## Структура проекта

```
TestExample/
├── Network/              # Networking слой
│   ├── APIClient.swift   # Основной API клиент
│   └── APIDefinitions.swift  # Определения API endpoints
├── Models/               # Модели данных
│   ├── User.swift
│   └── Post.swift
├── ViewModels/           # ViewModels
│   └── NetworkTestViewModel.swift
├── Views/                # UI Views
│   └── NetworkTestView.swift
├── ContentView.swift     # Главный view
└── TestExampleApp.swift  # App entry point
```

## Установка

### Шаг 1: Добавьте ASC пакет в проект

1. Откройте проект в Xcode:
   ```bash
   open TestExample.xcodeproj
   ```

2. В Xcode:
   - **File** → **Add Package Dependencies...**
   - Нажмите кнопку **"Add Local..."** внизу окна
   - Выберите папку `ASC/ASC` (путь: `/Users/nikitaomelchenko/Documents/Projects/ASC/ASC`)
   - Нажмите **"Add Package"**
   - Убедитесь что ASC добавлен к target **TestExample**

### Шаг 2: Добавьте файлы в проект

Все файлы уже созданы в файловой системе. Теперь добавьте их в Xcode проект:

1. В Project Navigator, кликните правой кнопкой на **TestExample** папку
2. Выберите **"Add Files to TestExample..."**
3. Выберите следующие папки:
   - `Network/`
   - `Models/`
   - `ViewModels/`
   - `Views/`
4. Убедитесь что опция **"Copy items if needed"** НЕ выбрана (файлы уже на месте)
5. Нажмите **"Add"**

### Шаг 3: Запустите приложение

1. Выберите симулятор (iPhone 15 Pro или любой iOS 18+)
2. Нажмите **Cmd+R** или кнопку **Run**

## Возможности приложения

### 📱 Tab 1: Users
- **Fetch Users** - Загрузка всех пользователей (GET /users)
- Клик на пользователя - Загрузка его постов

### 📝 Tab 2: Posts
- **All Posts** - Загрузка всех постов (GET /posts)
- **User Posts** - Загрузка постов выбранного пользователя (GET /users/{id}/posts)
- **Swipe to Delete** - Удаление поста (DELETE /posts/{id})

### ✏️ Tab 3: Create
- Форма для создания нового поста (POST /posts)
- Поля: Title, User ID, Body
- Автоматическая очистка формы после успешного создания

## API Endpoints

Приложение тестирует следующие endpoints:

```swift
// Users
GET  https://jsonplaceholder.typicode.com/users
GET  https://jsonplaceholder.typicode.com/users/{id}

// Posts
GET    https://jsonplaceholder.typicode.com/posts
GET    https://jsonplaceholder.typicode.com/users/{userId}/posts
GET    https://jsonplaceholder.typicode.com/posts/{id}
POST   https://jsonplaceholder.typicode.com/posts
PUT    https://jsonplaceholder.typicode.com/posts/{id}
DELETE https://jsonplaceholder.typicode.com/posts/{id}
```

## Архитектура

### APIClient
Singleton класс, предоставляющий удобный доступ ко всем API:

```swift
let client = APIClient.shared

// Fetch users
let users = try await client.fetchUsers()

// Create post
let post = try await client.createPost(
    title: "Test",
    body: "Content",
    userId: 1
)
```

### APIDefinitions
Организация через **Namespace Enum** pattern:

```swift
enum JSONPlaceholderAPI {
    struct GetUsers: NetworkRequest { /* ... */ }
    struct GetUser: NetworkRequest { /* ... */ }
    struct CreatePost: NetworkRequest { /* ... */ }
}
```

### NetworkTestViewModel
MVVM pattern с `@Published` properties:

```swift
@MainActor
class NetworkTestViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
}
```

## Особенности реализации

### ✅ Path Parameters
```swift
struct GetUser: NetworkRequest {
    let userId: Int
    var path: String { "/users/{id}" }
    var pathParameters: [String: String]? {
        ["id": String(userId)]
    }
}
```

### ✅ Request Body
```swift
struct CreatePost: NetworkRequest {
    let title: String
    let bodyText: String

    var body: (any Encodable)? {
        CreatePostBody(title: title, body: bodyText, userId: userId)
    }
}
```

### ✅ Error Handling
```swift
do {
    let users = try await client.fetchUsers()
} catch let error as NetworkError {
    debugPrint("Network error: \(error.errorDescription)")
} catch let error as ResponseError {
    debugPrint("Response error: \(error.errorDescription)")
}
```

### ✅ Connectivity Checking
```swift
let config = NetworkClientConfiguration(
    logLevel: .info,
    connectivityCheckEnabled: true  // Автоматическая проверка подключения
)
```

### ✅ Logging
```swift
// Включить verbose логирование
let client = APIClient(logLevel: .verbose)

// Выключить логирование
let client = APIClient(logLevel: .none)
```

## UI Features

- **Segmented Control** для переключения между вкладками
- **Status Banner** для отображения ошибок и успехов
- **Loading Overlay** с blur эффектом
- **Swipe Actions** для удаления постов
- **Auto-dismiss** баннеров после взаимодействия

## Требования

- iOS 18.0+
- Xcode 16.0+
- Swift 6.2+
- ASC 1.0+ (local package)

## Зависимости

- **ASC** (local) → Alamofire 5.10.2+

## Troubleshooting

### Ошибка "No such module 'ASC'"
1. Убедитесь что ASC пакет добавлен в проект
2. Clean Build Folder (Cmd+Shift+K)
3. Rebuild проект (Cmd+B)

### Файлы не видны в Xcode
1. Добавьте файлы через **Add Files to TestExample...**
2. НЕ копируйте файлы (они уже на месте)

### Ошибки компиляции
1. Проверьте что все файлы добавлены в target **TestExample**
2. Build Settings → Deployment Target = iOS 18.0

## Примечания

- Приложение использует **JSONPlaceholder** - бесплатный fake REST API для тестирования
- POST/PUT/DELETE запросы работают, но не изменяют данные на сервере (mock API)
- Все запросы логируются через ASCLogger с emoji маркерами
- Используется `debugPrint` вместо `print` (code standards)

## Пример лога

```
📥 GET https://jsonplaceholder.typicode.com/users
✅ 200 OK (534ms)
📄 JSON Response: 10 users
```
