# Исправление ошибок TestExample

## Проблема
Main actor-isolated conformance ошибки возникают из-за:
1. Файлы не добавлены в Xcode проект
2. Настройка `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` в проекте

## Решение

### ✅ Шаг 1: Исправления уже применены

Я исправил все файлы:
- ✅ `User.swift` - изменен на `@unchecked Sendable`
- ✅ `Post.swift` - изменен на `@unchecked Sendable`
- ✅ `APIClient.swift` - исправлен `ASCLogLevel`
- ✅ `NetworkTestViewModel.swift` - добавлен `import ASC`
- ✅ `NetworkTestView.swift` - исправлен `body` конфликт

### ⚠️ Шаг 2: Добавьте файлы в Xcode проект

**ВАЖНО:** Файлы созданы, но Xcode их не видит!

#### Вариант A: Drag & Drop (быстрее)

1. **Откройте Finder:**
   ```bash
   open /Users/nikitaomelchenko/Documents/Projects/ASC/TestApp/TestExample/TestExample
   ```

2. **Откройте Xcode:**
   ```bash
   open TestExample.xcodeproj
   ```

3. **Перетащите папки из Finder в Xcode:**
   - Из Finder перетащите в Xcode Project Navigator:
     - `Models/` (с User.swift, Post.swift)
     - `Network/` (с APIClient.swift, APIDefinitions.swift)
     - `ViewModels/` (с NetworkTestViewModel.swift)
     - `Views/` (с NetworkTestView.swift)

4. **В диалоге добавления:**
   - ❌ **СНИМИТЕ** "Copy items if needed"
   - ✅ **Выберите** "Create groups"
   - ✅ **Отметьте** "Add to targets: TestExample"
   - Нажмите **Add**

#### Вариант B: Add Files (через меню)

1. Откройте проект:
   ```bash
   open TestExample.xcodeproj
   ```

2. В Project Navigator:
   - Правый клик на **TestExample** (папка)
   - **Add Files to "TestExample"...**

3. Выберите **ВСЕ 4 папки**:
   - Models
   - Network
   - ViewModels
   - Views

4. Настройки:
   - ❌ "Copy items if needed" - **СНЯТЬ**
   - ✅ "Create groups" - **ВЫБРАТЬ**
   - ✅ "TestExample" target - **ОТМЕТИТЬ**

5. **Add**

### ✅ Шаг 3: Build

После добавления файлов:

```bash
# В Xcode
Cmd+B
```

## Проверка

После добавления файлов, в Project Navigator должно быть:

```
TestExample/
  ├── Models/
  │   ├── User.swift
  │   └── Post.swift
  ├── Network/
  │   ├── APIClient.swift
  │   └── APIDefinitions.swift
  ├── ViewModels/
  │   └── NetworkTestViewModel.swift
  ├── Views/
  │   └── NetworkTestView.swift
  ├── ContentView.swift
  ├── TestExampleApp.swift
  └── Assets.xcassets/
```

## Что исправлено в файлах:

### User.swift & Post.swift
```swift
// Было:
struct User: Codable, Identifiable, Sendable { }

// Стало:
struct User: Codable, Identifiable, @unchecked Sendable { }
```

Это обходит проблему с `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.

### APIClient.swift
```swift
// Было:
init(logLevel: ASCLogger.LogLevel = .info)

// Стало:
init(logLevel: ASCLogLevel = .info)
```

### NetworkTestViewModel.swift
```swift
// Добавлен импорт:
import ASC
```

### NetworkTestView.swift
```swift
// Было:
@State private var body = ""

// Стало:
@State private var postBody = ""
```

## Если все еще есть ошибки

После добавления файлов, если есть ошибки:

1. **Clean Build Folder:**
   ```
   Cmd+Shift+K
   ```

2. **Rebuild:**
   ```
   Cmd+B
   ```

3. **Restart Xcode**

## Запуск скрипта проверки

```bash
cd /Users/nikitaomelchenko/Documents/Projects/ASC/TestApp/TestExample
./fix_project.sh
```

Скрипт покажет какие файлы существуют и даст инструкции.
