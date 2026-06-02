# Сборка для iOS

## 1. Установка Qt iOS компонентов

### Вариант A: через Qt Maintenance Tool (GUI)

```bash
# Открой Maintenance Tool
open ~/Qt/MaintenanceTool.app
```

1. Нажми **Add or remove components**
2. Раскрой **Qt** → **Qt 6.x.x** (твоя версия)
3. Поставь галочку на **iOS**
4. Нажми **Next** → **Update**
5. Дождись скачивания (~2-3 ГБ)

### Вариант B: через aqtinstall (CLI)

```bash
# Установи aqtinstall
pip3 install aqtinstall

# Посмотри доступные версии
aqt list-qt mac ios

# Установи (пример для Qt 6.7.0)
aqt install-qt mac ios 6.7.0 \
    --outputdir ~/Qt \
    --modules qtshadertools
```

### Вариант C: через Qt Online Installer

Скачай с [qt.io/download](https://www.qt.io/download-open-source) и при установке выбери iOS.

## 2. Проверка установки

```bash
# Должен существовать файл qt-cmake:
ls ~/Qt/6.*/ios/bin/qt-cmake

# Если нашёлся — всё готово
```

## 3. Сборка

```bash
cd diplom
./build_ios.sh
```

Скрипт автоматически найдёт Qt iOS, сконфигурирует проект и откроет Xcode.

## 4. В Xcode

1. **Подключи iPhone** кабелем к Mac
2. В верхней панели выбери своё устройство (не симулятор)
3. **Signing & Capabilities**:
   - Team → выбери свой Apple ID
   - Bundle Identifier → `com.diplom.metanit` (или свой)
4. Нажми **▶ Run**

### Первый запуск на устройстве

iPhone спросит «доверять ли разработчику»:
- Настройки → Основные → VPN и управление устройством → разработчик → Доверять

## 5. Подключение к API

iPhone должен быть в той же Wi-Fi сети, что и Mac с API-сервером.

```bash
# Узнай IP мака
ifconfig en0 | grep "inet "
# Например: 192.168.1.42
```

В `src/core/services/network_service.cpp` замени:
```cpp
m_baseUrl("http://192.168.1.42:8080")  // ← твой IP
```

И пересобери.

## Частые проблемы

| Проблема | Решение |
|----------|---------|
| `qt-cmake not found` | Установи Qt iOS через Maintenance Tool |
| `Code signing error` | Выбери Team в Xcode → Signing |
| `Untrusted developer` | На iPhone: Настройки → Основные → Управление устройством |
| `Network error` | Проверь что IP правильный и iPhone в той же Wi-Fi |
| `NSAppTransportSecurity` | Уже настроено в Info.plist — HTTP разрешён |
