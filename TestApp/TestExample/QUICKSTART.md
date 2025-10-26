# ⚡ Быстрый старт за 3 минуты

## 1️⃣ Открыть проект (30 сек)

```bash
cd /Users/nikitaomelchenko/Documents/Projects/ASC/TestApp/TestExample
open TestExample.xcodeproj
```

## 2️⃣ Добавить ASC Package (1 мин)

1. **File** → **Add Package Dependencies...**
2. **Add Local...** → выберите `/Users/nikitaomelchenko/Documents/Projects/ASC/ASC`
3. **Add Package**

## 3️⃣ Добавить файлы (1 мин)

### Вариант A: Drag & Drop
```bash
# Откройте Finder
open /Users/nikitaomelchenko/Documents/Projects/ASC/TestApp/TestExample/TestExample
```

Перетащите в Xcode Project Navigator:
- ✅ `Network/`
- ✅ `Models/`
- ✅ `ViewModels/`
- ✅ `Views/`

**ВАЖНО:** Снимите галочку "Copy items if needed"

### Вариант B: Автоматически
В Project Navigator:
- Правый клик на **TestExample**
- **Add Files to TestExample...**
- Выберите 4 папки
- ❌ **Снимите** "Copy items if needed"
- **Add**

## 4️⃣ Запустить (30 сек)

1. Выберите симулятор: **iPhone 15 Pro**
2. **Cmd+R**

## ✅ Готово!

Теперь протестируйте:
- Tab **Users** → **Fetch Users**
- Tab **Posts** → **All Posts**
- Tab **Create** → заполните форму → **Create Post**

---

## 🔧 Если что-то не работает

### "No such module 'ASC'"
→ Повторите шаг 2 (добавьте ASC package)

### "Cannot find 'NetworkTestView'"
→ Повторите шаг 3 (добавьте файлы в проект)

### Clean & Rebuild
```
Cmd+Shift+K  (Clean)
Cmd+B        (Build)
```

---

**Полная документация:** README.md
**Пошаговая установка:** SETUP.md
**Список файлов:** FILES.md
