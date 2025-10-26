# Исправление Main Actor Isolation ошибки

## Проблема

```
Main actor-isolated conformance of 'User' to 'Decodable' cannot satisfy
conformance requirement for a 'Sendable' type parameter 'Self.Response'
```

## Причина

Проект имеет настройку `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, которая делает **все типы** изолированными на главном акторе по умолчанию. Это конфликтует с требованиями ASC библиотеки.

## ✅ Решение: Отключить главный актор по умолчанию

### Вариант 1: Через Xcode UI (рекомендуется)

1. **Откройте проект:**
   ```bash
   open TestExample.xcodeproj
   ```

2. **В Project Navigator:**
   - Выберите проект **TestExample** (синяя иконка)
   - Выберите target **TestExample**

3. **Build Settings:**
   - Найдите поле поиска вверху
   - Введите: `default actor`
   - Найдите **"Swift Default Actor Isolation"**

4. **Измените значение:**
   - Было: `MainActor`
   - Стало: **`unspecified`** (или оставить пустым)

5. **Rebuild:**
   ```
   Cmd+Shift+K (Clean)
   Cmd+B (Build)
   ```

### Вариант 2: Удалить настройку полностью

В Build Settings:
- Правый клик на **"Swift Default Actor Isolation"**
- Выберите **"Delete"**
- Rebuild проект

## 🎯 После исправления

Проект должен собраться без ошибок:

```swift
struct User: Codable, Identifiable, @unchecked Sendable {
    let id: Int
    let name: String
    let email: String
}

struct GetUsersRequest: NetworkRequest {
    typealias Response = [User]
    var path: String { "/users" }
    var method: HTTPMethod { .get }
}
```

## 📝 Что означает эта настройка?

### `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- **Что делает:** Все типы (классы, структуры) автоматически изолируются на главном акторе
- **Для чего:** Упрощает написание UI кода в SwiftUI
- **Минус:** Конфликтует с библиотеками, требующими non-isolated типы

### `SWIFT_DEFAULT_ACTOR_ISOLATION = unspecified` (по умолчанию)
- **Что делает:** Нет изоляции по умолчанию
- **Для чего:** Стандартное поведение Swift
- **Плюс:** Работает со всеми библиотеками

## 🔍 Проверка

После изменения настройки, проверьте что она применилась:

```bash
xcodebuild -project TestExample.xcodeproj -scheme TestExample \
  -showBuildSettings | grep SWIFT_DEFAULT_ACTOR_ISOLATION
```

Должно показать либо пусто, либо:
```
SWIFT_DEFAULT_ACTOR_ISOLATION = unspecified
```

## ✅ Rebuild и запуск

```bash
# В Xcode
Cmd+Shift+K  # Clean
Cmd+B        # Build
Cmd+R        # Run
```

Ошибка должна исчезнуть! 🎉

## 💡 Альтернатива (если не хотите менять настройки)

Если нужно оставить `MainActor` по умолчанию, можно вручную пометить типы:

```swift
@preconcurrency
struct User: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let email: String
}
```

Но это более громоздко и требует изменений в каждом типе.
