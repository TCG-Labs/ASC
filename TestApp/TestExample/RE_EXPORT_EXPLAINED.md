# Почему не работает реэкспорт HTTPMethod из ASC

## 🔴 Проблема

```swift
import ASC  // HTTPMethod должен быть доступен

struct GetUsersRequest: NetworkRequest {
    var method: HTTPMethod { .get }  // ❌ Error: 'get' is not available
}
```

**Ошибка:**
```
static property 'get' is not available due to missing import of defining module 'Alamofire'
```

## 🔍 Что происходит?

### ASC реэкспортирует HTTPMethod через typealias:

```swift
// В ASC/Sources/ASC/Core/AlamofireReExports.swift
public typealias HTTPMethod = Alamofire.HTTPMethod
```

### Но это НЕ полный реэкспорт!

**typealias реэкспортирует:**
- ✅ Сам тип (HTTPMethod)
- ✅ Инициализаторы
- ✅ Instance методы/свойства

**typealias НЕ реэкспортирует:**
- ❌ Static свойства (`.get`, `.post`, `.put`)
- ❌ Static методы
- ❌ Вложенные типы

## 📚 Теория: typealias vs @_exported

### 1. public typealias (что использует ASC)

```swift
// В ASC
public typealias HTTPMethod = Alamofire.HTTPMethod

// В вашем коде
import ASC

let method: HTTPMethod = ???  // ✅ Тип доступен
let method: HTTPMethod = .get  // ❌ .get недоступен!
```

**Почему `.get` недоступен?**

`.get` это **static property** типа `Alamofire.HTTPMethod`:

```swift
// В Alamofire
extension HTTPMethod {
    public static let get = HTTPMethod(rawValue: "GET")
    public static let post = HTTPMethod(rawValue: "POST")
    // ...
}
```

Swift видит:
1. `HTTPMethod` → Да, есть через typealias из ASC
2. `.get` → Это static property из модуля **Alamofire**
3. Alamofire не импортирован → **Ошибка!**

### 2. @_exported import (альтернатива)

```swift
// Если бы ASC использовал:
@_exported import Alamofire

// Тогда в вашем коде:
import ASC  // Автоматически импортирует Alamofire

let method: HTTPMethod = .get  // ✅ Работает!
```

**Но @_exported имеет проблемы:**
- Не всегда стабилен
- Может вызывать конфликты имен
- Экспортирует ВСЕ из модуля (не только нужное)

## 🎯 Почему ASC выбрал typealias?

**Из CLAUDE.md ASC проекта:**

```markdown
## Architecture Decision: Type Re-exports

Instead of duplicating Alamofire types, ASC **re-exports them directly**:
- ✅ Uses battle-tested implementations from Alamofire
- ✅ Zero conversion overhead
- ✅ Automatic updates when Alamofire improves
- ✅ Focuses on unique value: protocol-based API, error handling
```

**Причины:**
1. **Меньше кода** - не нужно дублировать типы
2. **Прозрачность** - явно видно что типы из Alamofire
3. **Контроль** - экспортируются только нужные типы
4. **Стабильность** - избегает проблем с @_exported

## ✅ Решение: Явный импорт Alamofire

### В вашем коде:

```swift
import Foundation
import ASC
import Alamofire  // ← Добавить!

struct GetUsersRequest: NetworkRequest {
    var method: HTTPMethod { .get }  // ✅ Теперь работает!
}
```

### Почему это нормально?

1. **ASC документация ожидает этого:**
   ```swift
   // Примеры из README.md
   import ASC
   import Alamofire  // ← Всегда импортируется
   ```

2. **Вы уже зависите от Alamofire:**
   - ASC добавляет Alamofire как dependency
   - Alamofire уже в вашем проекте

3. **Минимальные издержки:**
   - Один дополнительный import
   - Ясность откуда берутся типы

## 📊 Визуальное объяснение

### Что видит компилятор с typealias:

```
┌──────────────┐
│ Ваш код      │
├──────────────┤
│ import ASC   │
│              │
│ HTTPMethod   │ ✅ Доступен через typealias
│    ↓         │
│ .get         │ ❌ Это static property из Alamofire
└──────────────┘    модуль не импортирован!
```

### С явным импортом Alamofire:

```
┌──────────────┐     ┌──────────────┐
│ Ваш код      │     │ Alamofire    │
├──────────────┤     ├──────────────┤
│ import ASC   │     │ HTTPMethod   │
│ import       │────→│   .get ✅    │
│ Alamofire    │     │   .post ✅   │
│              │     │   .put ✅    │
│ HTTPMethod   │ ✅  └──────────────┘
│   .get       │ ✅
└──────────────┘
```

## 🔧 Практическое применение

### До (не работает):

```swift
import Foundation
import ASC

struct GetUsersRequest: NetworkRequest {
    var method: HTTPMethod { .get }  // ❌
}
```

### После (работает):

```swift
import Foundation
import ASC
import Alamofire  // Добавили

struct GetUsersRequest: NetworkRequest {
    var method: HTTPMethod { .get }  // ✅
}
```

## 💡 Альтернативные решения

### 1. Использовать полное имя (без import Alamofire)

```swift
import ASC

struct GetUsersRequest: NetworkRequest {
    var method: HTTPMethod {
        HTTPMethod(rawValue: "GET")  // ✅ Работает без Alamofire import
    }
}
```

**Минус:** Неудобно и многословно.

### 2. Создать extension в ASC (не рекомендуется)

```swift
// В ASC можно было бы добавить:
extension HTTPMethod {
    public static let get = Alamofire.HTTPMethod.get
    public static let post = Alamofire.HTTPMethod.post
}
```

**Минус:**
- Дублирование кода
- Нужно обновлять при изменениях Alamofire
- Противоречит philosophy ASC

### 3. Импортировать Alamofire (рекомендуется)

```swift
import ASC
import Alamofire  // ✅ Простое и явное решение
```

## 📝 Итог

**Вопрос:** Почему не видит `.get` из HTTPMethod?

**Ответ:**
1. ASC реэкспортирует `HTTPMethod` через `typealias`
2. `typealias` **не реэкспортирует static members** (`.get`, `.post`)
3. Нужен явный `import Alamofire` для доступа к static properties

**Решение:** Добавить `import Alamofire` в файлы где используете `HTTPMethod.get`

**Это нормально и ожидаемо** - так задумано в архитектуре ASC для прозрачности и контроля зависимостей.
