# Main Actor Isolation - Подробное объяснение ошибки

## 🔴 Ошибка

```
Main actor-isolated conformance of 'User' to 'Decodable' cannot satisfy
conformance requirement for a 'Sendable' type parameter 'Self.Response'
```

## 📚 Теория: Основные концепции

### 1. MainActor (Главный актор)

**MainActor** - это специальный актор в Swift для работы с UI:

```swift
@MainActor
class MyViewModel {
    var data: String = ""  // Всегда доступен только на главном потоке
}
```

**Что это значит:**
- Все обращения к свойствам/методам происходят **только на главном потоке**
- UI в iOS/macOS должен обновляться только на главном потоке
- MainActor гарантирует это автоматически

### 2. Sendable (Передаваемый между потоками)

**Sendable** - протокол, который говорит: "этот тип безопасно передавать между потоками":

```swift
struct User: Sendable {  // ✅ Безопасно для многопоточности
    let id: Int          // Все поля immutable (неизменяемые)
    let name: String
}
```

**Что это значит:**
- Тип можно безопасно отправлять между разными акторами/потоками
- Для структур: все поля должны быть immutable (`let`) и тоже Sendable
- Гарантирует отсутствие race conditions

### 3. Конфликт: MainActor vs Sendable

**Проблема:** Эти две концепции конфликтуют!

```swift
// ❌ КОНФЛИКТ!
@MainActor
struct User: Sendable {
    let id: Int
}

// User изолирован на главном потоке (@MainActor)
// НО Sendable требует возможности передачи между потоками
// Это противоречие!
```

## 🔍 Что происходит в вашем проекте

### Шаг 1: Настройка проекта

В вашем Xcode проекте установлено:

```
SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
```

**Это означает:** ВСЕ типы автоматически получают `@MainActor`:

```swift
// Вы пишете:
struct User: Codable {
    let id: Int
}

// Компилятор видит:
@MainActor  // ← Добавлено автоматически!
struct User: Codable {
    let id: Int
}
```

### Шаг 2: ASC NetworkRequest требования

Протокол `NetworkRequest` из ASC библиотеки определен так:

```swift
public protocol NetworkRequest {
    associatedtype Response: Decodable & Sendable  // ← Требует Sendable!

    var path: String { get }
    var method: HTTPMethod { get }
    // ...
}
```

**Ключевой момент:** `Response` должен быть `Sendable`!

### Шаг 3: Ваш код

```swift
struct User: Codable, @unchecked Sendable {  // Вы говорите: User это Sendable
    let id: Int
}

struct GetUsersRequest: NetworkRequest {
    typealias Response = [User]  // Response = массив User
}
```

### Шаг 4: Конфликт!

Компилятор анализирует:

1. **User должен быть Sendable** (из-за требования NetworkRequest)
2. **НО User изолирован на MainActor** (из-за настройки проекта)
3. **MainActor-isolated типы НЕ МОГУТ быть Sendable**

```
@MainActor      ←─────┐
struct User { }       │  КОНФЛИКТ!
                      │
User: Sendable  ←─────┘
```

**Результат:** Компилятор выдает ошибку!

## 🎯 Почему это важно для ASC

### NetworkClient работает асинхронно

```swift
let client = NetworkClient(...)

// Запрос может выполняться на фоновом потоке
let users = try await client.execute(GetUsersRequest())
//                                    ^
//                                    Response должен быть Sendable
//                                    чтобы передать результат обратно
```

**Процесс:**

1. **Главный поток:** Вызываете `client.execute()`
2. **Фоновый поток:** Делается HTTP запрос, парсится JSON
3. **Главный поток:** Результат возвращается

**Проблема:** Если `User` изолирован на MainActor, его **нельзя создать на фоновом потоке** для парсинга JSON!

### Что нужно ASC

ASC нужно:

```swift
// ✅ ПРАВИЛЬНО
struct User: Codable, Sendable {  // БЕЗ @MainActor
    let id: Int
}

// Теперь User можно:
// 1. Создать на фоновом потоке (парсинг JSON)
// 2. Передать на главный поток (вернуть результат)
```

## 📊 Визуальное объяснение

### Проблема с MainActor

```
┌─────────────────┐
│  Main Thread    │
│  (@MainActor)   │
├─────────────────┤
│                 │
│  [User]         │  ← User создается ЗДЕСЬ
│    ↓            │
│  Parse JSON     │  ❌ НЕ РАБОТАЕТ!
│    ↓            │     MainActor типы нельзя
│  Return         │     создавать на главном потоке
│                 │     для фонового парсинга
└─────────────────┘
```

### Решение с Sendable (без MainActor)

```
┌─────────────────┐         ┌─────────────────┐
│  Main Thread    │         │ Background      │
├─────────────────┤         ├─────────────────┤
│                 │         │                 │
│  Request ──────────────→  │  HTTP Request   │
│                 │         │       ↓         │
│                 │         │  Parse JSON     │
│                 │         │       ↓         │
│                 │         │  Create [User]  │ ✅ РАБОТАЕТ!
│                 │         │       ↓         │    Sendable типы
│  ←──────────────────────  │  Return         │    можно передавать
│  [User]         │         │                 │
│                 │         │                 │
└─────────────────┘         └─────────────────┘
```

## 🔧 Детальный разбор ошибки

```
Main actor-isolated conformance of 'User' to 'Decodable'
cannot satisfy conformance requirement for a 'Sendable'
type parameter 'Self.Response'
```

**Разбор по частям:**

1. **"Main actor-isolated conformance of 'User' to 'Decodable'"**
   - User изолирован на MainActor
   - User реализует Decodable (для парсинга JSON)
   - Decodable работает только на MainActor (из-за изоляции User)

2. **"cannot satisfy conformance requirement"**
   - Не может удовлетворить требование протокола

3. **"for a 'Sendable' type parameter 'Self.Response'"**
   - NetworkRequest требует чтобы Response был Sendable
   - Но MainActor-isolated типы НЕ Sendable

## 💡 Почему @unchecked Sendable не помогает

Вы пытались использовать:

```swift
struct User: Codable, @unchecked Sendable {  // @unchecked = "доверься мне"
    let id: Int
}
```

**@unchecked Sendable** говорит компилятору: "Доверься мне, я знаю что делаю".

**НО:** Это не убирает `@MainActor` изоляцию!

```swift
// Компилятор видит:
@MainActor  // ← Все еще здесь из-за SWIFT_DEFAULT_ACTOR_ISOLATION!
struct User: Codable, @unchecked Sendable {
    let id: Int
}
```

Конфликт остается:
- **@MainActor:** "Использовать только на главном потоке"
- **Sendable:** "Можно передавать между потоками"

## ✅ Решения

### Решение 1: Отключить MainActor по умолчанию (рекомендуется)

**В Xcode Build Settings:**
```
SWIFT_DEFAULT_ACTOR_ISOLATION = unspecified  (или удалить)
```

**Результат:**
```swift
// Компилятор видит:
struct User: Codable, @unchecked Sendable {  // БЕЗ @MainActor
    let id: Int
}
// ✅ Теперь User это просто Sendable без изоляции
```

### Решение 2: Явно указать nonisolated (не работает для struct)

```swift
// ❌ НЕ РАБОТАЕТ для struct
nonisolated struct User { }

// ✅ Работает только для методов/свойств в классах
@MainActor
class MyClass {
    nonisolated func parse() { }  // Этот метод БЕЗ MainActor
}
```

### Решение 3: Использовать отдельный файл (тоже не работает)

Настройка `SWIFT_DEFAULT_ACTOR_ISOLATION` применяется ко **всему target**, не к отдельным файлам.

## 🎓 Когда нужен MainActor?

**MainActor нужен для:**

```swift
@MainActor  // ✅ Правильное использование
class ViewModel: ObservableObject {
    @Published var users: [User] = []  // UI обновления на главном потоке

    func loadUsers() async {
        // await вызовы автоматически на MainActor
    }
}
```

**MainActor НЕ нужен для:**

```swift
// ✅ Просто модели данных
struct User: Codable, Sendable {
    let id: Int
    let name: String
}

// ✅ Network запросы
struct GetUsersRequest: NetworkRequest {
    typealias Response = [User]
}
```

## 📝 Итог

**Проблема:** Настройка `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` делает все типы привязанными к главному потоку, что конфликтует с требованиями многопоточности в сетевых библиотеках.

**Решение:** Отключить эту настройку и использовать `@MainActor` явно только там, где это действительно нужно (ViewModels, UI классы).

**Правило:** Модели данных должны быть `Sendable` (БЕЗ MainActor), чтобы их можно было безопасно передавать между потоками.
