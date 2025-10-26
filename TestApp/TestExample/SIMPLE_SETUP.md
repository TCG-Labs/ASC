# TestExample - Простая реализация с ASC

## ✅ Что уже сделано

Создана минималистичная реализация networking в **одном файле** (ContentView.swift):

- ✅ **User Model** - простая модель с 3 полями (id, name, email)
- ✅ **GetUsersRequest** - один GET запрос к JSONPlaceholder API
- ✅ **UI** - кнопка загрузки и список пользователей
- ✅ **Error handling** - отображение ошибок
- ✅ **Loading state** - индикатор загрузки

## 🚀 Как запустить

### 1. Откройте проект в Xcode:
```bash
open /Users/nikitaomelchenko/Documents/Projects/ASC/TestApp/TestExample/TestExample.xcodeproj
```

### 2. Настройте Signing:
- Выберите проект **TestExample** в Project Navigator
- Вкладка **Signing & Capabilities**
- В поле **Team** выберите вашу команду разработчика
- Или выберите **"Automatically manage signing"**

### 3. Выберите симулятор:
- iPhone 15 Pro (или любой iOS 18+)

### 4. Запустите:
```
Cmd+R
```

## 📱 Как использовать

1. Запустите приложение
2. Нажмите кнопку **"Загрузить пользователей"**
3. Приложение сделает GET запрос к `https://jsonplaceholder.typicode.com/users`
4. Отобразится список из 10 пользователей

## 📝 Код

Весь код в одном файле: **ContentView.swift**

### User Model (3 поля)
```swift
nonisolated(unsafe) struct User: Codable, Identifiable, @unchecked Sendable {
    let id: Int
    let name: String
    let email: String
}
```

### Network Request
```swift
nonisolated(unsafe) struct GetUsersRequest: NetworkRequest {
    typealias Response = [User]

    var baseURL: String? { "https://jsonplaceholder.typicode.com" }
    var path: String { "/users" }
    var method: HTTPMethod { .get }
}
```

### NetworkClient
```swift
private let networkClient = NetworkClient(
    configuration: NetworkClientConfiguration(
        logLevel: .verbose,
        connectivityCheckEnabled: false
    )
)
```

### Выполнение запроса
```swift
users = try await networkClient.execute(GetUsersRequest())
```

## 🎯 Что тестирует

- ✅ **GET запрос** к live API
- ✅ **JSON декодирование** в Swift модели
- ✅ **Async/await** обработка
- ✅ **Error handling** с локализованными сообщениями
- ✅ **Loading states** с ProgressView
- ✅ **SwiftUI интеграция**

## 🔧 Технические детали

### Использованные фичи ASC:
- `NetworkClient` с конфигурацией
- `NetworkRequest` протокол
- `HTTPMethod` из Alamofire
- Verbose logging для отладки
- Connectivity check отключен для простоты

### Решение проблемы MainActor:
Использован `nonisolated(unsafe)` для User и GetUsersRequest из-за настройки проекта:
```
SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
```

## 📊 Результат

После запуска в консоли (Cmd+Shift+Y) вы увидите:
```
"✅ Загружено 10 пользователей"
```

И подробные логи от ASC с emoji маркерами:
- 📥 GET запрос
- ✅ Успешный ответ
- 📄 JSON данные
- ⚡ Время выполнения

## 🎉 Готово!

Простая рабочая реализация готова к использованию и тестированию!
