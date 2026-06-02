import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    visible: true
    width: 390
    height: 844
    title: "Metanit C++"

    // === Theme colors ===
    property color bgColor: networkService.darkTheme ? "#000000" : "#f2f2f7"
    property color cardColor: networkService.darkTheme ? "#1c1c1e" : "#ffffff"
    property color textColor: networkService.darkTheme ? "#ffffff" : "#000000"
    property color textSecondary: networkService.darkTheme ? "#8e8e93" : "#6e6e73"
    property color separatorColor: networkService.darkTheme ? "#38383a" : "#c6c6c8"
    property color tabBarColor: networkService.darkTheme ? "#1c1c1e" : "#f9f9f9"
    property color articleTextColor: networkService.darkTheme ? "#e0e0e0" : "#1c1c1e"
    property color codeBlockBg: networkService.darkTheme ? "#161622" : "#f0f0f5"
    property color codeBlockBorder: networkService.darkTheme ? "#3a3a4e" : "#d0d0d8"
    property color codeTextColor: networkService.darkTheme ? "#d4d4d4" : "#333333"
    property color inputBgColor: networkService.darkTheme ? "#1c1c1e" : "#e8e8ed"

    color: bgColor

    // iOS-style tab bar — учитываем safe area снизу
    footer: Rectangle {
        width: parent.width
        height: 56 + safeBottomMargin
        color: tabBarColor

        // Отступ для safe area (iPhone с вырезом)
        property int safeBottomMargin: Qt.platform.os === "ios" ? 34 : 0

        Rectangle {
            width: parent.width
            height: 0.5
            color: separatorColor
        }

        RowLayout {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: parent.safeBottomMargin
            spacing: 0

            Repeater {
                model: [
                    { icon: "📖", name: "Главная",    idx: 0 },
                    { icon: "🔍", name: "Поиск",      idx: 1 },
                    { icon: "⭐", name: "Избранное",   idx: 2 },
                    { icon: "⚙️", name: "Настройки",  idx: 3 }
                ]

                delegate: Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: modelData.icon
                            font.pixelSize: 22
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: tabStack.currentIndex === modelData.idx ? 1.0 : 0.45
                        }
                        Text {
                            text: modelData.name
                            color: tabStack.currentIndex === modelData.idx ? "#0a84ff" : "#8e8e93"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: tabStack.currentIndex = modelData.idx
                    }
                }
            }
        }
    }

    StackLayout {
        id: tabStack
        anchors.fill: parent

        // ==================== Tab 0: Chapters ====================
        Item {
            StackView {
                id: mainStack
                anchors.fill: parent
                initialItem: chaptersPage
            }
        }

        // ==================== Tab 1: Search ====================
        Item {
            StackView {
                id: searchStack
                anchors.fill: parent
                initialItem: searchPage
            }
        }

        // ==================== Tab 2: Favorites ====================
        Item {
            id: favoritesTab
            property var favList: []

            function refreshFavorites() {
                if (networkService.isLoggedIn)
                    networkService.fetchFavorites()
            }

            Connections {
                target: networkService
                function onFavoritesLoaded(favorites) {
                    var items = []
                    for (var i = 0; i < favorites.length; i++)
                        items.push(favorites[i])
                    favoritesTab.favList = items
                }
                function onFavoriteToggled(file, isFavorite) { favoritesTab.refreshFavorites() }
                function onAuthChanged() { favoritesTab.refreshFavorites() }
            }

            Component.onCompleted: refreshFavorites()
            onVisibleChanged: if (visible) refreshFavorites()

            Rectangle {
                anchors.fill: parent
                color: bgColor

                // Not logged in
                Column {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: !networkService.isLoggedIn

                    Text { text: "⭐"; font.pixelSize: 48; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "Избранное"; color: textColor; font.pixelSize: 22; font.weight: Font.Bold; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "Войдите в профиль, чтобы\nсохранять статьи в избранное"; color: textSecondary; font.pixelSize: 15; horizontalAlignment: Text.AlignHCenter; anchors.horizontalCenter: parent.horizontalCenter }
                    Rectangle {
                        width: 200; height: 44; radius: 10; color: "#0a84ff"
                        anchors.horizontalCenter: parent.horizontalCenter
                        Text { anchors.centerIn: parent; text: "Войти"; color: "#ffffff"; font.pixelSize: 17; font.weight: Font.Medium }
                        MouseArea { anchors.fill: parent; onClicked: tabStack.currentIndex = 3 }
                    }
                }

                // Logged in — favorites list
                Column {
                    anchors.fill: parent
                    topPadding: 70
                    visible: networkService.isLoggedIn

                    Text {
                        text: "Избранное"
                        color: textColor
                        font.pixelSize: 34
                        font.weight: Font.Bold
                        leftPadding: 20
                        bottomPadding: 16
                    }

                    // Empty state
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8
                        visible: favoritesTab.favList.length === 0
                        topPadding: 60

                        Text { text: "☆"; font.pixelSize: 40; color: textSecondary; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Пока пусто"; color: textSecondary; font.pixelSize: 17; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Нажмите ☆ в статье, чтобы добавить"; color: textSecondary; font.pixelSize: 14; anchors.horizontalCenter: parent.horizontalCenter }
                    }

                    // List of favorites
                    ListView {
                        width: parent.width - 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: parent.height - 120
                        clip: true
                        visible: favoritesTab.favList.length > 0
                        model: favoritesTab.favList

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: Math.max(56, favTitle.implicitHeight + 30)
                            color: "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 4; anchors.rightMargin: 4
                                spacing: 8

                                Column {
                                    Layout.fillWidth: true; spacing: 2
                                    Text {
                                        id: favTitle
                                        text: modelData.title
                                        color: textColor; font.pixelSize: 17
                                        width: parent.width; wrapMode: Text.WordWrap
                                    }
                                    Text {
                                        text: "Глава " + modelData.chapter + " · " + modelData.chapterName
                                        color: textSecondary; font.pixelSize: 13
                                    }
                                }

                                Text { text: "›"; color: "#48484a"; font.pixelSize: 22 }
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left; anchors.right: parent.right
                                height: 0.5; color: separatorColor
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    // Сначала возвращаемся к корню, потом открываем статью
                                    mainStack.pop(null)
                                    tabStack.currentIndex = 0
                                    mainStack.push(articleViewPage, {
                                        articleTitle: modelData.title,
                                        articleFile: modelData.file
                                    })
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==================== Tab 3: Settings ====================
        Item {
            StackView {
                id: settingsStack
                anchors.fill: parent
                initialItem: settingsPage
            }
        }
    }

    // ==================== Settings Page ====================
    Component {
        id: settingsPage

        Rectangle {
            color: bgColor

            Flickable {
                anchors.fill: parent
                contentHeight: settCol.height + 40
                clip: true

                Column {
                    id: settCol
                    width: parent.width
                    topPadding: 70
                    spacing: 20

                    Text {
                        text: "Настройки"
                        color: "#ffffff"
                        font.pixelSize: 34
                        font.weight: Font.Bold
                        leftPadding: 20
                    }

                    // === Profile section ===
                    Text {
                        text: "ПРОФИЛЬ"
                        color: textSecondary
                        font.pixelSize: 13
                        leftPadding: 36
                    }

                    Rectangle {
                        width: parent.width - 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: profileCol.height
                        radius: 12
                        color: cardColor
                        clip: true

                        Column {
                            id: profileCol
                            width: parent.width

                            // Logged in state
                            Item {
                                width: parent.width
                                height: 58
                                visible: networkService.isLoggedIn

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 12

                                    Rectangle {
                                        width: 36; height: 36; radius: 18
                                        color: "#0a84ff"
                                        Text {
                                            anchors.centerIn: parent
                                            text: networkService.username.length > 0 ? networkService.username[0].toUpperCase() : "?"
                                            color: "#ffffff"
                                            font.pixelSize: 18
                                            font.weight: Font.Bold
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            text: networkService.username
                                            color: "#ffffff"
                                            font.pixelSize: 17
                                        }
                                        Text {
                                            text: "Авторизован"
                                            color: "#30d158"
                                            font.pixelSize: 13
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left; anchors.leftMargin: 16
                                    anchors.right: parent.right
                                    height: 0.5; color: separatorColor
                                    visible: networkService.isLoggedIn
                                }
                            }

                            // Logout button
                            Item {
                                width: parent.width; height: 48
                                visible: networkService.isLoggedIn

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left; anchors.leftMargin: 16
                                    anchors.right: parent.right
                                    height: 0.5; color: separatorColor
                                }

                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                                    Text { text: "Редактировать профиль"; color: "#ffffff"; font.pixelSize: 17; Layout.fillWidth: true }
                                    Text { text: "›"; color: "#48484a"; font.pixelSize: 22 }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: settingsStack.push(editProfilePage)
                                }
                            }

                            // Logout
                            Item {
                                width: parent.width; height: 48
                                visible: networkService.isLoggedIn
                                Text { anchors.centerIn: parent; text: "Выйти из аккаунта"; color: "#ff453a"; font.pixelSize: 17 }
                                MouseArea { anchors.fill: parent; onClicked: networkService.logout() }
                            }

                            // Not logged in: Login / Register buttons
                            Item {
                                width: parent.width
                                height: 48
                                visible: !networkService.isLoggedIn

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16

                                    Text {
                                        text: "Войти или зарегистрироваться"
                                        color: "#0a84ff"
                                        font.pixelSize: 17
                                        Layout.fillWidth: true
                                    }
                                    Text { text: "›"; color: "#48484a"; font.pixelSize: 22 }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: settingsStack.push(authPage)
                                }
                            }
                        }
                    }

                    // === Основные ===
                    Text {
                        text: "ОСНОВНЫЕ"
                        color: textSecondary
                        font.pixelSize: 13
                        leftPadding: 36
                    }

                    // Секция "Основные" — пустая, заглушки
                    Rectangle {
                        width: parent.width - 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: settingsMainCol.height
                        radius: 12
                        color: cardColor
                        clip: true

                        Column {
                            id: settingsMainCol
                            width: parent.width

                            // Тема
                            Item {
                                width: parent.width; height: 48
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                                    Text { text: "Тема"; color: "#ffffff"; font.pixelSize: 17; Layout.fillWidth: true }
                                    Text {
                                        text: networkService.darkTheme ? "Тёмная" : "Светлая"
                                        color: "#0a84ff"; font.pixelSize: 17
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: networkService.setDarkTheme(!networkService.darkTheme)
                                }
                                Rectangle {
                                    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.leftMargin: 16
                                    anchors.right: parent.right; height: 0.5; color: separatorColor
                                }
                            }

                            // Размер шрифта
                            Item {
                                width: parent.width; height: 48
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                                    Text { text: "Размер шрифта"; color: "#ffffff"; font.pixelSize: 17; Layout.fillWidth: true }

                                    Rectangle {
                                        width: 32; height: 28; radius: 6; color: "#2c2c2e"
                                        Text { anchors.centerIn: parent; text: "A-"; color: "#ffffff"; font.pixelSize: 14 }
                                        MouseArea { anchors.fill: parent; onClicked: if (networkService.fontSize > 12) networkService.setFontSize(networkService.fontSize - 1) }
                                    }

                                    Text { text: networkService.fontSize; color: textSecondary; font.pixelSize: 15 }

                                    Rectangle {
                                        width: 32; height: 28; radius: 6; color: "#2c2c2e"
                                        Text { anchors.centerIn: parent; text: "A+"; color: "#ffffff"; font.pixelSize: 14 }
                                        MouseArea { anchors.fill: parent; onClicked: if (networkService.fontSize < 24) networkService.setFontSize(networkService.fontSize + 1) }
                                    }

                                    Item { width: 8 }

                                    Rectangle {
                                        width: 60; height: 28; radius: 6
                                        color: networkService.fontSize === 16 ? "#2c2c2e" : "#0a84ff"
                                        Text { anchors.centerIn: parent; text: "Сброс"; color: "#ffffff"; font.pixelSize: 12 }
                                        MouseArea { anchors.fill: parent; onClicked: networkService.setFontSize(16) }
                                    }
                                }
                                Rectangle {
                                    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.leftMargin: 16
                                    anchors.right: parent.right; height: 0.5; color: separatorColor
                                }
                            }

                            // Заглушка: Кэш
                            Item {
                                width: parent.width
                                height: 48
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    Text {
                                        text: "Очистить кэш"
                                        color: "#ffffff"
                                        font.pixelSize: 17
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: "›"
                                        color: "#48484a"
                                        font.pixelSize: 22
                                    }
                                }
                            }
                        }
                    }

                    // Секция "Информация"
                    Text {
                        text: "ИНФОРМАЦИЯ"
                        color: textSecondary
                        font.pixelSize: 13
                        leftPadding: 36
                    }

                    Rectangle {
                        width: parent.width - 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: settingsInfoCol.height
                        radius: 12
                        color: cardColor
                        clip: true

                        Column {
                            id: settingsInfoCol
                            width: parent.width

                            // О проекте
                            Item {
                                width: parent.width
                                height: 48

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    Text {
                                        text: "О проекте"
                                        color: "#ffffff"
                                        font.pixelSize: 17
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: "›"
                                        color: "#48484a"
                                        font.pixelSize: 22
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.leftMargin: 16
                                    anchors.right: parent.right
                                    height: 0.5
                                    color: separatorColor
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: settingsStack.push(aboutPage)
                                }
                            }

                            // Версия
                            Item {
                                width: parent.width
                                height: 48
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    Text {
                                        text: "Версия"
                                        color: "#ffffff"
                                        font.pixelSize: 17
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: "1.0.0"
                                        color: textSecondary
                                        font.pixelSize: 17
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ==================== About Page (inside Settings) ====================
    Component {
        id: aboutPage

        Rectangle {
            color: bgColor

            Flickable {
                anchors.fill: parent
                contentHeight: aboutCol.height + 120
                clip: true

                Column {
                    id: aboutCol
                    width: parent.width
                    topPadding: 16
                    spacing: 0

                    // Back
                    Item {
                        width: parent.width
                        height: 44
                        MouseArea {
                            anchors.fill: aboutBackRow
                            anchors.margins: -8
                            onClicked: settingsStack.pop()
                        }
                        Row {
                            id: aboutBackRow
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: 8
                            spacing: 4
                            Text { text: "‹"; color: "#0a84ff"; font.pixelSize: 28; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Настройки"; color: "#0a84ff"; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }

                    Text {
                        text: "О проекте"
                        color: "#ffffff"
                        font.pixelSize: 28
                        font.weight: Font.Bold
                        leftPadding: 20
                        bottomPadding: 20
                    }

                    Rectangle {
                        width: parent.width - 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: aboutContent.height + 32
                        radius: 12
                        color: cardColor

                        Column {
                            id: aboutContent
                            width: parent.width - 32
                            anchors.centerIn: parent
                            spacing: 16

                            Text {
                                text: "Metanit C++ Port"
                                color: "#ffffff"
                                font.pixelSize: 20
                                font.weight: Font.DemiBold
                            }

                            Text {
                                width: parent.width
                                text: "Мобильное приложение для изучения C++ на основе материалов metanit.com.\n\nПриложение разработано в рамках дипломного проекта с использованием Qt/QML (C++) для iOS и Go-сервисов для сбора данных."
                                color: "#ebebf5"
                                font.pixelSize: 15
                                wrapMode: Text.WordWrap
                                lineHeight: 1.4
                                opacity: 0.6
                            }

                            Rectangle { width: parent.width; height: 0.5; color: separatorColor }

                            Column {
                                width: parent.width
                                spacing: 10

                                Repeater {
                                    model: [
                                        { lbl: "Платформа", val: "iOS (Qt 6)" },
                                        { lbl: "Backend",   val: "Go (crawler + parser)" },
                                        { lbl: "Статей",    val: "150" },
                                        { lbl: "Глав",      val: "17" }
                                    ]
                                    delegate: RowLayout {
                                        width: parent.width
                                        spacing: 8
                                        Text { text: modelData.lbl; color: "#ebebf5"; font.pixelSize: 15; opacity: 0.6 }
                                        Item { Layout.fillWidth: true }
                                        Text { text: modelData.val; color: "#ebebf5"; font.pixelSize: 15; opacity: 0.4 }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ==================== Auth Page (Login/Register) ====================
    Component {
        id: authPage

        Rectangle {
            color: bgColor
            property bool isRegister: false
            property string errorMsg: ""

            Connections {
                target: networkService
                function onAuthChanged() { if (networkService.isLoggedIn) settingsStack.pop() }
                function onAuthError(error) { errorMsg = error }
            }

            Flickable {
                anchors.fill: parent
                contentHeight: authCol.height + 120
                clip: true

                Column {
                    id: authCol
                    width: parent.width
                    topPadding: 16
                    spacing: 16

                    Item {
                        width: parent.width; height: 44
                        MouseArea {
                            anchors.fill: authBackRow; anchors.margins: -8
                            onClicked: settingsStack.pop()
                        }
                        Row {
                            id: authBackRow
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: 8; spacing: 4
                            Text { text: "‹"; color: "#0a84ff"; font.pixelSize: 28; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Настройки"; color: "#0a84ff"; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }

                    Text {
                        text: isRegister ? "Регистрация" : "Вход"
                        color: textColor; font.pixelSize: 28; font.weight: Font.Bold; leftPadding: 20
                    }

                    Text {
                        text: errorMsg; color: "#ff453a"; font.pixelSize: 14
                        leftPadding: 20; visible: errorMsg.length > 0
                        width: parent.width - 40; wrapMode: Text.WordWrap
                    }

                    // Display name (register only)
                    Rectangle {
                        width: parent.width - 32; anchors.horizontalCenter: parent.horizontalCenter
                        height: 48; radius: 10; color: inputBgColor
                        visible: isRegister

                        TextInput {
                            id: nameInput
                            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                            color: textColor; font.pixelSize: 17
                            verticalAlignment: TextInput.AlignVCenter
                            Text { text: "Как вас называть?"; color: textSecondary; font.pixelSize: 17
                                   visible: !nameInput.text && !nameInput.activeFocus; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }

                    // Username
                    Rectangle {
                        width: parent.width - 32; anchors.horizontalCenter: parent.horizontalCenter
                        height: 48; radius: 10; color: inputBgColor
                        TextInput {
                            id: usernameInput
                            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                            color: textColor; font.pixelSize: 17
                            verticalAlignment: TextInput.AlignVCenter
                            inputMethodHints: Qt.ImhNoAutoUppercase
                            Text { text: "Логин"; color: textSecondary; font.pixelSize: 17
                                   visible: !usernameInput.text && !usernameInput.activeFocus; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }

                    // Password
                    Rectangle {
                        width: parent.width - 32; anchors.horizontalCenter: parent.horizontalCenter
                        height: 48; radius: 10; color: inputBgColor
                        TextInput {
                            id: passwordInput
                            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                            color: textColor; font.pixelSize: 17
                            verticalAlignment: TextInput.AlignVCenter; echoMode: TextInput.Password
                            Text { text: "Пароль"; color: textSecondary; font.pixelSize: 17
                                   visible: !passwordInput.text && !passwordInput.activeFocus; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }

                    // Confirm password (register only)
                    Rectangle {
                        width: parent.width - 32; anchors.horizontalCenter: parent.horizontalCenter
                        height: 48; radius: 10; color: inputBgColor
                        visible: isRegister
                        TextInput {
                            id: passwordConfirmInput
                            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                            color: textColor; font.pixelSize: 17
                            verticalAlignment: TextInput.AlignVCenter; echoMode: TextInput.Password
                            Text { text: "Повторите пароль"; color: textSecondary; font.pixelSize: 17
                                   visible: !passwordConfirmInput.text && !passwordConfirmInput.activeFocus; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }

                    // Submit
                    Rectangle {
                        width: parent.width - 32; height: 48; radius: 10
                        anchors.horizontalCenter: parent.horizontalCenter; color: "#0a84ff"
                        Text { anchors.centerIn: parent; text: isRegister ? "Зарегистрироваться" : "Войти"
                               color: "#ffffff"; font.pixelSize: 17; font.weight: Font.Medium }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                errorMsg = ""
                                if (isRegister) {
                                    if (passwordInput.text !== passwordConfirmInput.text) {
                                        errorMsg = "Пароли не совпадают"
                                        return
                                    }
                                    if (nameInput.text.length === 0) {
                                        errorMsg = "Введите имя"
                                        return
                                    }
                                    networkService.registerUser(usernameInput.text, passwordInput.text, nameInput.text)
                                } else {
                                    networkService.login(usernameInput.text, passwordInput.text)
                                }
                            }
                        }
                    }

                    Text {
                        text: isRegister ? "Уже есть аккаунт? Войти" : "Нет аккаунта? Зарегистрироваться"
                        color: "#0a84ff"; font.pixelSize: 15; anchors.horizontalCenter: parent.horizontalCenter
                        MouseArea { anchors.fill: parent; onClicked: { isRegister = !isRegister; errorMsg = "" } }
                    }
                }
            }
        }
    }

    // ==================== Edit Profile Page ====================
    Component {
        id: editProfilePage

        Rectangle {
            color: bgColor
            property string errorMsg: ""
            property string successMsg: ""

            Connections {
                target: networkService
                function onProfileUpdated() { successMsg = "Сохранено ✓"; errorMsg = "" }
                function onProfileError(error) { errorMsg = error; successMsg = "" }
            }

            Flickable {
                anchors.fill: parent
                contentHeight: editCol.height + 120
                clip: true

                Column {
                    id: editCol
                    width: parent.width
                    topPadding: 16
                    spacing: 16

                    Item {
                        width: parent.width; height: 44
                        MouseArea {
                            anchors.fill: editBackRow; anchors.margins: -8
                            onClicked: settingsStack.pop()
                        }
                        Row {
                            id: editBackRow
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: 8; spacing: 4
                            Text { text: "‹"; color: "#0a84ff"; font.pixelSize: 28; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Настройки"; color: "#0a84ff"; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }

                    Text { text: "Редактирование\nпрофиля"; color: textColor; font.pixelSize: 28; font.weight: Font.Bold; leftPadding: 20; lineHeight: 1.2 }

                    Text { text: errorMsg; color: "#ff453a"; font.pixelSize: 14; leftPadding: 20; visible: errorMsg.length > 0; width: parent.width - 40; wrapMode: Text.WordWrap }
                    Text { text: successMsg; color: "#30d158"; font.pixelSize: 14; leftPadding: 20; visible: successMsg.length > 0 }

                    // Display name
                    Text { text: "ИМЯ"; color: textSecondary; font.pixelSize: 13; leftPadding: 36 }
                    Rectangle {
                        width: parent.width - 32; anchors.horizontalCenter: parent.horizontalCenter
                        height: 48; radius: 10; color: inputBgColor
                        TextInput {
                            id: editNameInput; text: networkService.displayName
                            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                            color: "#ffffff"; font.pixelSize: 17; verticalAlignment: TextInput.AlignVCenter
                        }
                    }

                    // Change password section
                    Text { text: "ИЗМЕНИТЬ ПАРОЛЬ"; color: textSecondary; font.pixelSize: 13; leftPadding: 36 }
                    Rectangle {
                        width: parent.width - 32; anchors.horizontalCenter: parent.horizontalCenter
                        height: 48; radius: 10; color: inputBgColor
                        TextInput {
                            id: editOldPassInput
                            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                            color: "#ffffff"; font.pixelSize: 17; verticalAlignment: TextInput.AlignVCenter; echoMode: TextInput.Password
                            Text { text: "Текущий пароль"; color: textSecondary; font.pixelSize: 17
                                   visible: !editOldPassInput.text && !editOldPassInput.activeFocus; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                    Rectangle {
                        width: parent.width - 32; anchors.horizontalCenter: parent.horizontalCenter
                        height: 48; radius: 10; color: inputBgColor
                        TextInput {
                            id: editNewPassInput
                            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                            color: "#ffffff"; font.pixelSize: 17; verticalAlignment: TextInput.AlignVCenter; echoMode: TextInput.Password
                            Text { text: "Новый пароль"; color: textSecondary; font.pixelSize: 17
                                   visible: !editNewPassInput.text && !editNewPassInput.activeFocus; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }

                    // Save button
                    Rectangle {
                        width: parent.width - 32; height: 48; radius: 10
                        anchors.horizontalCenter: parent.horizontalCenter; color: "#0a84ff"
                        Text { anchors.centerIn: parent; text: "Сохранить"; color: "#ffffff"; font.pixelSize: 17; font.weight: Font.Medium }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                errorMsg = ""; successMsg = ""
                                networkService.updateProfile(editNameInput.text, editOldPassInput.text, editNewPassInput.text)
                            }
                        }
                    }
                }
            }
        }
    }

    // ==================== Chapters Page ====================
    Component {
        id: chaptersPage

        Rectangle {
            color: bgColor

            Flickable {
                anchors.fill: parent
                contentHeight: chaptersCol.height + 40
                clip: true

                Column {
                    id: chaptersCol
                    width: parent.width
                    topPadding: 70
                    spacing: 0

                    Text {
                        text: "C++ Учебник"
                        color: "#ffffff"
                        font.pixelSize: 34
                        font.weight: Font.Bold
                        leftPadding: 20
                        bottomPadding: 8
                    }

                    Text {
                        text: articlesModel.rowCount() + " статей · " + articlesModel.getChapters().length + " глав"
                        color: textSecondary
                        font.pixelSize: 15
                        leftPadding: 20
                        bottomPadding: 20
                    }

                    Rectangle {
                        width: parent.width - 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: chaptersList.height
                        radius: 12
                        color: cardColor
                        clip: true

                        Column {
                            id: chaptersList
                            width: parent.width

                            Repeater {
                                model: articlesModel.getChapters()

                                delegate: Item {
                                    width: chaptersList.width
                                    height: 58

                                    Rectangle {
                                        anchors.fill: parent
                                        color: chapterMa.pressed ? "#2c2c2e" : "transparent"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 16
                                            spacing: 12

                                            Rectangle {
                                                width: 32; height: 32; radius: 8
                                                color: {
                                                    var c = ["#0a84ff","#30d158","#ff9f0a","#ff453a",
                                                             "#bf5af2","#64d2ff","#ffd60a","#ff375f",
                                                             "#ac8e68","#0a84ff","#30d158","#ff9f0a",
                                                             "#ff453a","#bf5af2","#64d2ff","#ffd60a","#ff375f"];
                                                    return c[Math.abs(modelData.chapter) % c.length];
                                                }
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.chapter
                                                    color: "#ffffff"
                                                    font.pixelSize: 14
                                                    font.weight: Font.Bold
                                                }
                                            }

                                            Column {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text {
                                                    text: modelData.name
                                                    color: "#ffffff"
                                                    font.pixelSize: 17
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }
                                                Text {
                                                    text: modelData.count + " статей"
                                                    color: textSecondary
                                                    font.pixelSize: 13
                                                }
                                            }

                                            Text { text: "›"; color: "#48484a"; font.pixelSize: 22 }
                                        }

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left; anchors.leftMargin: 60
                                            anchors.right: parent.right
                                            height: 0.5; color: separatorColor
                                            visible: index < articlesModel.getChapters().length - 1
                                        }

                                        MouseArea {
                                            id: chapterMa
                                            anchors.fill: parent
                                            onClicked: {
                                                mainStack.push(articlesListPage, {
                                                    chapterNum: modelData.chapter,
                                                    chapterTitle: modelData.name
                                                })
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ==================== Articles in Chapter ====================
    Component {
        id: articlesListPage

        Rectangle {
            color: bgColor
            property int chapterNum: 0
            property string chapterTitle: ""

            Flickable {
                anchors.fill: parent
                contentHeight: artCol.height + 40
                clip: true

                Column {
                    id: artCol
                    width: parent.width
                    topPadding: 16
                    spacing: 0

                    Item {
                        width: parent.width; height: 44
                        MouseArea {
                            anchors.fill: backRow
                            anchors.margins: -8
                            onClicked: mainStack.pop()
                        }
                        Row {
                            id: backRow
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: 8; spacing: 4
                            Text { text: "‹"; color: "#0a84ff"; font.pixelSize: 28; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Назад"; color: "#0a84ff"; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }

                    Text {
                        text: chapterTitle
                        color: "#ffffff"
                        font.pixelSize: 28
                        font.weight: Font.Bold
                        leftPadding: 20; rightPadding: 20; bottomPadding: 16
                        width: parent.width
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        width: parent.width - 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: articlesList.height
                        radius: 12; color: cardColor; clip: true

                        Column {
                            id: articlesList
                            width: parent.width

                            Repeater {
                                model: articlesModel.getArticlesForChapter(chapterNum)

                                delegate: Item {
                                    width: articlesList.width
                                    height: Math.max(52, artTitle.implicitHeight + 24)

                                    Rectangle {
                                        anchors.fill: parent
                                        color: artMa.pressed ? "#2c2c2e" : "transparent"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16; anchors.rightMargin: 16
                                            spacing: 8

                                            Text {
                                                id: artTitle
                                                text: modelData.title
                                                color: textColor; font.pixelSize: 17
                                                Layout.fillWidth: true
                                                wrapMode: Text.WordWrap
                                            }
                                            Text { text: "›"; color: "#48484a"; font.pixelSize: 22 }
                                        }

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left; anchors.leftMargin: 16
                                            anchors.right: parent.right
                                            height: 0.5; color: separatorColor
                                            visible: index < articlesModel.getArticlesForChapter(chapterNum).length - 1
                                        }

                                        MouseArea {
                                            id: artMa
                                            anchors.fill: parent
                                            onClicked: {
                                                mainStack.push(articleViewPage, {
                                                    articleTitle: modelData.title,
                                                    articleFile: modelData.file
                                                })
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ==================== Article View (main tab) ====================
    Component {
        id: articleViewPage

        Rectangle {
            color: bgColor
            property string articleTitle: ""
            property string articleFile: ""
            property var articleBlocks: []

            /// Загрузка: сначала локально, если нет — из API
            Component.onCompleted: {
                var md = markdownService.loadMarkdown(articleFile)
                if (md.indexOf("Загрузка") >= 0) {
                    networkService.fetchArticleContent(articleFile)
                } else {
                    articleBlocks = markdownService.parseBlocks(md)
                }
            }

            Connections {
                target: networkService
                function onArticleContentLoaded(file, content) {
                    if (file === articleFile) {
                        markdownService.cacheContent(file, content)
                        articleBlocks = markdownService.parseBlocks(content)
                    }
                }
            }

            Rectangle {
                id: articleNav
                width: parent.width; height: 60
                color: bgColor; z: 10

                MouseArea {
                    anchors.fill: articleBackRow
                    anchors.margins: -8
                    onClicked: mainStack.pop()
                }
                Row {
                    id: articleBackRow
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                    leftPadding: 8; spacing: 4
                    Text { text: "‹"; color: "#0a84ff"; font.pixelSize: 28; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Назад"; color: "#0a84ff"; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter }
                }

                // Favorite button
                Text {
                    id: favBtn
                    property bool isFav: false
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                    text: isFav ? "★" : "☆"
                    color: isFav ? "#ffd60a" : "#8e8e93"
                    font.pixelSize: 24
                    visible: networkService.isLoggedIn

                    Connections {
                        target: networkService
                        function onFavoriteToggled(file, isFavorite) {
                            if (file === articleFile) favBtn.isFav = isFavorite
                        }
                        function onFavoriteChecked(file, isFavorite) {
                            if (file === articleFile) favBtn.isFav = isFavorite
                        }
                        // Сбрасываем звёздочку при выходе из аккаунта
                        function onAuthChanged() {
                            if (!networkService.isLoggedIn) favBtn.isFav = false
                            else networkService.checkFavorite(articleFile)
                        }
                    }

                    Component.onCompleted: {
                        if (networkService.isLoggedIn)
                            networkService.checkFavorite(articleFile)
                    }

                    MouseArea {
                        anchors.fill: parent; anchors.margins: -8
                        onClicked: networkService.toggleFavorite(articleFile)
                    }
                }

                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 0.5; color: separatorColor }
            }

            Flickable {
                anchors.top: articleNav.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                contentHeight: blocksColumn.height + navButtons.height + 60
                clip: true

                Column {
                    id: blocksColumn
                    width: parent.width - 32
                    x: 16
                    topPadding: 16
                    spacing: 4

                    Repeater {
                        model: articleBlocks

                        delegate: Loader {
                            width: blocksColumn.width
                            sourceComponent: modelData.type === "code" ? codeBlockComponent : textBlockComponent

                            property string blockContent: modelData.content
                            property string blockType: modelData.type
                        }
                    }
                }

                // Кнопки навигации: предыдущая / следующая статья
                Row {
                    id: navButtons
                    anchors.top: blocksColumn.bottom
                    anchors.topMargin: 24
                    anchors.left: parent.left; anchors.leftMargin: 16
                    anchors.right: parent.right; anchors.rightMargin: 16
                    spacing: 12

                    // Предыдущая статья
                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: 44; radius: 10
                        color: cardColor
                        border.color: separatorColor; border.width: 0.5
                        visible: {
                            var all = articlesModel.getArticlesForChapter(articleFile.split(".")[0])
                            for (var i = 0; i < all.length; i++)
                                if (all[i].file === articleFile) return i > 0
                            return false
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "‹ Предыдущая"
                            color: "#0a84ff"; font.pixelSize: 15
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var ch = parseInt(articleFile.split(".")[0])
                                var all = articlesModel.getArticlesForChapter(ch)
                                for (var i = 0; i < all.length; i++) {
                                    if (all[i].file === articleFile && i > 0) {
                                        mainStack.replace(articleViewPage, {
                                            articleTitle: all[i-1].title,
                                            articleFile: all[i-1].file
                                        })
                                        break
                                    }
                                }
                            }
                        }
                    }

                    // Следующая статья
                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: 44; radius: 10
                        color: "#0a84ff"
                        visible: {
                            var ch = parseInt(articleFile.split(".")[0])
                            var all = articlesModel.getArticlesForChapter(ch)
                            for (var i = 0; i < all.length; i++)
                                if (all[i].file === articleFile) return i < all.length - 1
                            return false
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Следующая ›"
                            color: "#ffffff"; font.pixelSize: 15
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var ch = parseInt(articleFile.split(".")[0])
                                var all = articlesModel.getArticlesForChapter(ch)
                                for (var i = 0; i < all.length; i++) {
                                    if (all[i].file === articleFile && i < all.length - 1) {
                                        mainStack.replace(articleViewPage, {
                                            articleTitle: all[i+1].title,
                                            articleFile: all[i+1].file
                                        })
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ==================== Search Page ====================
    Component {
        id: searchPage

        Rectangle {
            color: bgColor

            Column {
                anchors.fill: parent
                topPadding: 70
                spacing: 0

                Text {
                    text: "Поиск"
                    color: "#ffffff"
                    font.pixelSize: 34
                    font.weight: Font.Bold
                    leftPadding: 20
                    bottomPadding: 16
                }

                Rectangle {
                    width: parent.width - 32
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 38; radius: 10; color: inputBgColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10; anchors.rightMargin: 10
                        spacing: 6

                        Text { text: "🔍"; font.pixelSize: 14; opacity: 0.6 }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: textColor; font.pixelSize: 17

                            Text {
                                text: "Статьи, темы, ключевые слова"
                                color: textSecondary; font.pixelSize: 17
                                visible: !searchInput.text && !searchInput.activeFocus
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            onTextChanged: filterModel.filterText = text
                        }

                        Text {
                            text: "✕"; color: textSecondary; font.pixelSize: 16
                            visible: searchInput.text.length > 0
                            MouseArea {
                                anchors.fill: parent
                                onClicked: searchInput.text = ""
                            }
                        }
                    }
                }

                Item { height: 16; width: 1 }

                ListView {
                    width: parent.width - 32
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: parent.height - 180
                    clip: true
                    model: filterModel

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: Math.max(56, srchTitle.implicitHeight + 30)
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4; anchors.rightMargin: 4
                            spacing: 8

                            Column {
                                Layout.fillWidth: true; spacing: 2
                                Text {
                                    id: srchTitle; text: title
                                    color: textColor; font.pixelSize: 17
                                    width: parent.width; wrapMode: Text.WordWrap
                                }
                                Text {
                                    text: "Глава " + chapter + " · " + chapterName
                                    color: textSecondary; font.pixelSize: 13
                                }
                            }

                            Text { text: "›"; color: "#48484a"; font.pixelSize: 22 }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left; anchors.right: parent.right
                            height: 0.5; color: separatorColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                searchStack.push(articleViewSearchPage, {
                                    articleTitle: title,
                                    articleFile: file
                                })
                            }
                        }
                    }
                }
            }
        }
    }

    // ==================== Article View (search tab) ====================
    Component {
        id: articleViewSearchPage

        Rectangle {
            color: bgColor
            property string articleTitle: ""
            property string articleFile: ""
            property var articleBlocks: []

            /// Загрузка: сначала локально, если нет — из API
            Component.onCompleted: {
                var md = markdownService.loadMarkdown(articleFile)
                if (md.indexOf("Загрузка") >= 0) {
                    networkService.fetchArticleContent(articleFile)
                } else {
                    articleBlocks = markdownService.parseBlocks(md)
                }
            }

            Connections {
                target: networkService
                function onArticleContentLoaded(file, content) {
                    if (file === articleFile) {
                        markdownService.cacheContent(file, content)
                        articleBlocks = markdownService.parseBlocks(content)
                    }
                }
            }

            Rectangle {
                id: searchArticleNav
                width: parent.width; height: 60
                color: bgColor; z: 10

                MouseArea {
                    anchors.fill: searchBackRow
                    anchors.margins: -8
                    onClicked: searchStack.pop()
                }
                Row {
                    id: searchBackRow
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                    leftPadding: 8; spacing: 4
                    Text { text: "‹"; color: "#0a84ff"; font.pixelSize: 28; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Поиск"; color: "#0a84ff"; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 0.5; color: separatorColor }
            }

            Flickable {
                anchors.top: searchArticleNav.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                contentHeight: searchBlocksColumn.height + 40
                clip: true

                Column {
                    id: searchBlocksColumn
                    width: parent.width - 32
                    x: 16
                    topPadding: 16
                    spacing: 4

                    Repeater {
                        model: articleBlocks

                        delegate: Loader {
                            width: searchBlocksColumn.width
                            sourceComponent: modelData.type === "code" ? codeBlockComponent : textBlockComponent

                            property string blockContent: modelData.content
                            property string blockType: modelData.type
                        }
                    }
                }
            }
        }
    }

    // ==================== Shared Components ====================

    // Text block — renders HTML via Rich Text
    Component {
        id: textBlockComponent

        Text {
            width: parent ? parent.width : 100
            textFormat: Text.RichText
            wrapMode: Text.WordWrap
            color: articleTextColor
            font.pixelSize: networkService.fontSize
            lineHeight: 1.5
            text: blockContent
        }
    }

    // Code block — native QML with rounded corners, border, copy button
    Component {
        id: codeBlockComponent

        Rectangle {
            width: parent ? parent.width : 100
            height: codeCol.height
            radius: 10
            color: codeBlockBg
            border.color: codeBlockBorder
            border.width: 1

            Column {
                id: codeCol
                width: parent.width

                // Header with copy button
                Rectangle {
                    width: parent.width
                    height: 36
                    color: "transparent"

                    Text {
                        text: "C++"
                        color: "#6a6a7e"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: copyRow.width + 18
                        height: 24
                        radius: 5
                        color: copyMa.pressed ? "#3a3a4e" : "#2a2a3a"
                        border.color: codeBlockBorder
                        border.width: 0.5

                        Row {
                            id: copyRow
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                id: copyIcon
                                text: "📋"
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                id: copyLabel
                                text: "Скопировать"
                                color: "#8e8e9e"
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: copyMa
                            anchors.fill: parent
                            onClicked: {
                                codeTextEdit.selectAll()
                                codeTextEdit.copy()
                                codeTextEdit.deselect()
                                copyLabel.text = "Скопировано ✓"
                                copyLabel.color = "#30d158"
                                copyTimer.start()
                            }
                        }

                        Timer {
                            id: copyTimer
                            interval: 1500
                            onTriggered: {
                                copyLabel.text = "Скопировать"
                                copyLabel.color = "#8e8e9e"
                            }
                        }
                    }

                    // Separator
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        height: 0.5
                        color: "#2a2a3e"
                    }
                }

                // Code content — scrollable horizontally
                Flickable {
                    width: parent.width
                    height: codeText.height + 24
                    contentWidth: codeText.width + 28
                    clip: true
                    flickableDirection: Flickable.HorizontalFlick

                    Text {
                        id: codeText
                        x: 14
                        y: 12
                        text: blockContent
                        color: codeTextColor
                        font.family: "Menlo"
                        font.pixelSize: 13
                        lineHeight: 1.5

                        // Fallback font
                        Component.onCompleted: {
                            if (font.family !== "Menlo") {
                                font.family = "Courier New"
                            }
                        }
                    }
                }

                // Hidden TextEdit for copy functionality
                TextEdit {
                    id: codeTextEdit
                    visible: false
                    text: blockContent
                }
            }
        }
    }
}
