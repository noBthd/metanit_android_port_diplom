#!/bin/bash
set -e

echo "=== Metanit C++ — iOS Build ==="
echo ""

# === НАСТРОЙ ЭТИ ПУТИ ===
# Укажи путь к Qt iOS. Примеры:
#   ~/Qt/6.7.0/ios
#   ~/Qt/6.8.0/ios  
#   /opt/Qt/6.7.0/ios

QT_IOS_PATH=""

# Автопоиск Qt iOS
if [ -z "$QT_IOS_PATH" ]; then
    for dir in ~/Qt/*/ios /opt/Qt/*/ios /usr/local/Qt/*/ios; do
        if [ -d "$dir" ] && [ -f "$dir/bin/qt-cmake" ]; then
            QT_IOS_PATH="$dir"
            break
        fi
    done
fi

if [ -z "$QT_IOS_PATH" ] || [ ! -f "$QT_IOS_PATH/bin/qt-cmake" ]; then
    echo "❌ Qt iOS не найден!"
    echo ""
    echo "Установи Qt iOS через Qt Maintenance Tool, затем укажи путь:"
    echo "  1. Открой скрипт build_ios.sh"
    echo "  2. Заполни переменную QT_IOS_PATH"
    echo ""
    echo "Пример: QT_IOS_PATH=\"$HOME/Qt/6.7.0/ios\""
    exit 1
fi

echo "Qt iOS: $QT_IOS_PATH"
echo ""

# Создаём build-директорию
rm -rf build-ios
mkdir build-ios
cd build-ios

# Находим десктопную Qt (QT_HOST_PATH)
QT_HOST_PATH=""
for dir in /opt/homebrew/Cellar/qt/*/lib/cmake/Qt6 /opt/homebrew/lib/cmake/Qt6 ~/Qt/*/macos ~/Qt/*/gcc_64; do
    if [ -d "$dir" ]; then
        QT_HOST_PATH=$(cd "$dir/../../.." 2>/dev/null && pwd)
        break
    fi
done

if [ -z "$QT_HOST_PATH" ]; then
    echo "❌ Десктопная Qt не найдена для QT_HOST_PATH!"
    exit 1
fi

echo "Qt Host: $QT_HOST_PATH"

# Конфигурация
echo "→ Конфигурация CMake..."
"$QT_IOS_PATH/bin/qt-cmake" .. \
    -GXcode \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DQT_HOST_PATH="$QT_HOST_PATH"

echo ""
echo "✅ Проект сконфигурирован!"
echo ""
echo "Следующие шаги:"
echo "  1. open build-ios/metanit_port.xcodeproj"
echo "  2. В Xcode: выбери свой iPhone"
echo "  3. Signing & Capabilities → выбери свой Apple Team"
echo "  4. Нажми ▶ (Run)"
echo ""

# Открываем в Xcode
open metanit_port.xcodeproj
