# 🚀 Быстрый старт TestExample

## Шаг 1: Откройте проект в Xcode

```bash
cd /Users/nikitaomelchenko/Documents/Projects/ASC/TestApp/TestExample
open TestExample.xcodeproj
```

## Шаг 2: Добавьте ASC Package

1. В Xcode: **File** → **Add Package Dependencies...**
2. Нажмите **"Add Local..."** (кнопка внизу)
3. Выберите папку: `/Users/nikitaomelchenko/Documents/Projects/ASC/ASC`
4. Нажмите **"Add Package"**
5. В диалоге выбора target, убедитесь что **TestExample** отмечен
6. Нажмите **"Add Package"**

## Шаг 3: Добавьте файлы в проект

Файлы уже созданы в файловой системе, но нужно добавить их в Xcode:

### Вариант A: Drag & Drop (рекомендуется)

1. Откройте Finder в папке проекта:
   ```bash
   open /Users/nikitaomelchenko/Documents/Projects/ASC/TestApp/TestExample/TestExample
   ```

2. В Xcode Project Navigator, найдите группу **TestExample**

3. Перетащите следующие папки из Finder в Xcode:
   - `Network/` → в группу TestExample
   - `Models/` → в группу TestExample
   - `ViewModels/` → в группу TestExample
   - `Views/` → в группу TestExample

4. В диалоге:
   - ✅ **Убедитесь** что "Add to targets: TestExample" отмечен
   - ❌ **Снимите** галочку "Copy items if needed" (файлы уже на месте!)
   - ✅ **Выберите** "Create groups" (не "Create folder references")
   - Нажмите **"Finish"**

### Вариант B: Add Files (альтернатива)

1. Правый клик на **TestExample** группу в Project Navigator
2. Выберите **"Add Files to TestExample..."**
3. Выберите папки `Network`, `Models`, `ViewModels`, `Views`
4. Убедитесь:
   - ❌ **"Copy items if needed"** НЕ отмечено
   - ✅ **"Create groups"** выбрано
   - ✅ **"TestExample" target** отмечен
5. Нажмите **"Add"**

## Шаг 4: Обновите ContentView.swift

Файл уже обновлен, но проверьте что он содержит:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NetworkTestView()
    }
}
```

## Шаг 5: Build & Run

1. Выберите симулятор: **iPhone 15 Pro** (или любой iOS 18+)
2. Нажмите **Cmd+B** для сборки
3. Нажмите **Cmd+R** для запуска

## ✅ Проверка установки

После успешной сборки вы должны увидеть:

```
✓ Project Navigator содержит папки Network, Models, ViewModels, Views
✓ Build succeeded (0 errors, 0 warnings)
✓ В симуляторе открывается приложение с 3 вкладками
```

## 🧪 Тестирование функционала

### Test 1: Загрузка пользователей
1. Перейдите на вкладку **"Users"**
2. Нажмите **"Fetch Users"**
3. Должен появиться баннер: "✅ Загружено 10 пользователей"
4. Список должен показать 10 пользователей

### Test 2: Загрузка постов пользователя
1. Нажмите на любого пользователя в списке
2. Автоматически переключится на вкладку **"Posts"**
3. Должен появиться баннер: "✅ Загружено N постов пользователя"

### Test 3: Создание поста
1. Перейдите на вкладку **"Create"**
2. Заполните поля:
   - Title: "Test Post"
   - User ID: "1"
   - Body: "This is a test post from TestExample app"
3. Нажмите **"Create Post"**
4. Должен появиться баннер: "✅ Пост создан (ID: ...)"

### Test 4: Удаление поста
1. На вкладке **"Posts"**, нажмите **"All Posts"**
2. Swipe влево на любом посте
3. Нажмите красную кнопку **"Delete"**
4. Должен появиться баннер: "✅ Пост удален"

## 📁 Структура файлов после установки

```
TestExample/
├── TestExample/
│   ├── Network/
│   │   ├── APIClient.swift           ✅
│   │   └── APIDefinitions.swift      ✅
│   ├── Models/
│   │   ├── User.swift                ✅
│   │   └── Post.swift                ✅
│   ├── ViewModels/
│   │   └── NetworkTestViewModel.swift ✅
│   ├── Views/
│   │   └── NetworkTestView.swift     ✅
│   ├── ContentView.swift             ✅ (обновлен)
│   ├── TestExampleApp.swift
│   └── Assets.xcassets/
└── TestExample.xcodeproj
```

## ❌ Troubleshooting

### Ошибка: "No such module 'ASC'"

**Причина:** ASC package не добавлен в проект

**Решение:**
1. File → Add Package Dependencies...
2. Add Local → выберите `/Users/nikitaomelchenko/Documents/Projects/ASC/ASC`

---

### Ошибка: "Cannot find 'NetworkTestView' in scope"

**Причина:** Файлы не добавлены в проект или не добавлены к target

**Решение:**
1. Проверьте что все папки видны в Project Navigator
2. Выберите любой файл (например NetworkTestView.swift)
3. В File Inspector (справа) проверьте что **Target Membership: TestExample** отмечено

---

### Ошибка: "Multiple commands produce..."

**Причина:** Файлы были скопированы вместо создания ссылок

**Решение:**
1. Удалите добавленные файлы из проекта (Delete → Remove Reference)
2. Добавьте снова БЕЗ опции "Copy items if needed"

---

### Build успешный, но приложение показывает "Hello, world!"

**Причина:** ContentView.swift не обновлен

**Решение:**
1. Откройте ContentView.swift
2. Замените `Text("Hello, world!")` на `NetworkTestView()`
3. Rebuild (Cmd+Shift+K → Cmd+B)

---

## 📞 Поддержка

Если возникли проблемы:

1. Clean Build Folder: **Cmd+Shift+K**
2. Rebuild: **Cmd+B**
3. Restart Xcode
4. Проверьте версии:
   - Xcode 16.0+
   - iOS Deployment Target: 18.0
   - Swift Language Version: 6

## 🎉 Готово!

Теперь у вас есть полностью рабочее приложение для тестирования ASC библиотеки!

Все запросы логируются в Console (Cmd+Shift+Y) с emoji маркерами для лучшей читаемости.
