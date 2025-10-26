# Добавление файлов в Xcode проект

## Проблема
Файлы созданы в файловой системе, но НЕ добавлены в Xcode проект для компиляции.

## Решение: Добавьте файлы через Xcode

### Шаг 1: Откройте проект
```bash
open TestExample.xcodeproj
```

### Шаг 2: Добавьте КАЖДЫЙ файл по отдельности

В Xcode Project Navigator:

#### 1. Добавьте Models:
- Правый клик на папку **TestExample** (синяя иконка)
- **Add Files to "TestExample"...**
- Выберите `TestExample/Models/User.swift`
- ✅ **Отметьте** "Add to targets: TestExample"
- ❌ **Снимите** "Copy items if needed" (файл уже на месте)
- Нажмите **Add**

Повторите для `Post.swift`

#### 2. Добавьте Network:
- Правый клик на **TestExample**
- **Add Files to "TestExample"...**
- Выберите `TestExample/Network/APIClient.swift`
- ✅ **Отметьте** "Add to targets: TestExample"
- ❌ **Снимите** "Copy items if needed"
- **Add**

Повторите для `APIDefinitions.swift`

#### 3. Добавьте ViewModels:
- Добавьте `TestExample/ViewModels/NetworkTestViewModel.swift`

#### 4. Добавьте Views:
- Добавьте `TestExample/Views/NetworkTestView.swift`

#### 5. Проверьте что ContentView.swift добавлен:
Если `ContentView.swift` не виден в Project Navigator:
- Добавьте `TestExample/ContentView.swift`
- Добавьте `TestExample/TestExampleApp.swift`

### Шаг 3: Проверка

После добавления всех файлов, в **Project Navigator** должны быть видны:

```
TestExample (folder)
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
  └── Assets.xcassets
```

### Шаг 4: Build
- **Cmd+B** - должен собраться без ошибок

## Альтернативный способ (если не работает):

### Создайте группы и перетащите файлы:

1. Создайте группу "Models":
   - Правый клик на **TestExample**
   - **New Group**
   - Назовите "Models"

2. Откройте Finder:
   ```bash
   open TestExample/TestExample
   ```

3. Перетащите файлы из Finder в соответствующие группы в Xcode:
   - Перетащите `User.swift` и `Post.swift` в группу Models
   - В диалоге:
     - ❌ **Снимите** "Copy items if needed"
     - ✅ **Отметьте** "Create groups"
     - ✅ **Отметьте** "Add to targets: TestExample"

4. Повторите для Network/, ViewModels/, Views/

## Проверка добавления

Чтобы проверить что файл добавлен:
1. Выберите файл в Project Navigator
2. Откройте **File Inspector** (справа)
3. В секции **Target Membership** должна быть галочка возле **TestExample**

## После успешного добавления

Build должен пройти успешно:
```bash
xcodebuild -project TestExample.xcodeproj -scheme TestExample build
```
