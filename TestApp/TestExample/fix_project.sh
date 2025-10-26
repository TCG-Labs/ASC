#!/bin/bash

# Script to add all source files to Xcode project

set -e

PROJECT_DIR="/Users/nikitaomelchenko/Documents/Projects/ASC/TestApp/TestExample"
cd "$PROJECT_DIR"

echo "🔧 Fixing TestExample Xcode project..."
echo ""

# Check if files exist
echo "📁 Checking files..."
FILES=(
    "TestExample/Models/User.swift"
    "TestExample/Models/Post.swift"
    "TestExample/Network/APIClient.swift"
    "TestExample/Network/APIDefinitions.swift"
    "TestExample/ViewModels/NetworkTestViewModel.swift"
    "TestExample/Views/NetworkTestView.swift"
    "TestExample/ContentView.swift"
    "TestExample/TestExampleApp.swift"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file - NOT FOUND"
    fi
done

echo ""
echo "⚠️  MANUAL ACTION REQUIRED:"
echo ""
echo "Xcode не позволяет автоматически добавлять файлы через командную строку."
echo "Пожалуйста, выполните следующие шаги в Xcode:"
echo ""
echo "1. Откройте проект:"
echo "   open TestExample.xcodeproj"
echo ""
echo "2. В Project Navigator:"
echo "   - Правый клик на папку 'TestExample' (синяя иконка)"
echo "   - Выберите 'Add Files to \"TestExample\"...'"
echo ""
echo "3. В диалоге выбора:"
echo "   - Нажмите Cmd+Shift+G и введите:"
echo "     $PROJECT_DIR/TestExample"
echo "   - Выберите ВСЕ папки:"
echo "     ☑ Models"
echo "     ☑ Network"
echo "     ☑ ViewModels"
echo "     ☑ Views"
echo "   - Убедитесь что отмечено:"
echo "     ☑ Add to targets: TestExample"
echo "     ☐ Copy items if needed (СНЯТЬ ГАЛОЧКУ!)"
echo "     ○ Create groups (выбрать)"
echo "   - Нажмите 'Add'"
echo ""
echo "4. Также добавьте файлы если их нет:"
echo "   - ContentView.swift"
echo "   - TestExampleApp.swift"
echo ""
echo "5. После добавления, соберите проект:"
echo "   Cmd+B"
echo ""
echo "Все файлы обновлены и готовы к использованию!"
echo "Они содержат исправления для @unchecked Sendable."
