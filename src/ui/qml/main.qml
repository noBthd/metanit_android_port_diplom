import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    visible: true
    width: 390
    height: 844
    title: "Metanit C++"
    visibility: Qt.platform.os === "ios" ? Window.FullScreen : Window.Windowed

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
    property color pressedColor: networkService.darkTheme ? "#2c2c2e" : "#d1d1d6"

    color: bgColor

    /// Подсветка синтаксиса C++ — построчная, без конфликтов regex
    function highlightCpp(code) {
        var isDark = networkService.darkTheme
        var kwColor = isDark ? "#569cd6" : "#0000ff"
        var strColor = isDark ? "#ce9178" : "#a31515"
        var cmtColor = isDark ? "#6a9955" : "#008000"
        var numColor = isDark ? "#b5cea8" : "#098658"
        var typeColor = isDark ? "#4ec9b0" : "#267f99"
        var preColor = isDark ? "#c586c0" : "#af00db"
        var defColor = isDark ? "#d4d4d4" : "#333333"

        var kw = ["if","else","for","while","do","switch","case","break","continue","return",
                  "class","struct","enum","public","private","protected","virtual","override",
                  "const","static","namespace","using","typedef","template","typename",
                  "new","delete","try","catch","throw","nullptr","true","false","this",
                  "operator","friend","inline","extern","volatile","mutable","constexpr",
                  "noexcept","sizeof","decltype"]
        var types = ["int","float","double","char","bool","void","string","auto","size_t",
                     "unsigned","long","short","wchar_t","std","cout","cin","endl","vector",
                     "map","set","pair","array"]

        var lines = code.split("\n")
        var result = []

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            line = line.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;")
            var trimmed = line.replace(/^\s+/, "")

            if (trimmed.indexOf("//") === 0) {
                result.push('<span style="color:'+cmtColor+'">'+line+'</span>')
                continue
            }
            if (trimmed.indexOf("#") === 0) {
                result.push('<span style="color:'+preColor+'">'+line+'</span>')
                continue
            }

            line = line.replace(/"([^\"]*)"/g, '<span style="color:'+strColor+'">$1</span>')
            line = line.replace(/\b(\d+)\b/g, '<span style="color:'+numColor+'">$1</span>')

            var words = types.concat(kw)
            for (var w = 0; w < words.length; w++) {
                var word = words[w]
                var re = new RegExp("\\b(" + word + ")\\b", "g")
                var col = (w < types.length) ? typeColor : kwColor
                line = line.replace(re, '<span style="color:'+col+'">$1</span>')
            }

            result.push(line)
        }

        return '<pre style="color:'+defColor+';margin:0;white-space:pre-wrap">' + result.join("\n") + '</pre>'
    }    

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

                // Плавные iOS-подобные анимации переходов
                pushEnter: Transition { NumberAnimation { property: "x"; from: mainStack.width; to: 0; duration: 300; easing.type: Easing.OutCubic } }
                pushExit: Transition { NumberAnimation { property: "x"; from: 0; to: -mainStack.width/3; duration: 300; easing.type: Easing.OutCubic } }
                popEnter: Transition { NumberAnimation { property: "x"; from: -mainStack.width/3; to: 0; duration: 300; easing.type: Easing.OutCubic } }
                popExit: Transition { NumberAnimation { property: "x"; from: 0; to: mainStack.width; duration: 300; easing.type: Easing.OutCubic } }
            }
        }

        // ==================== Tab 1: Search ====================
        Item {
            StackView {
                id: searchStack
                anchors.fill: parent
                pushEnter: Transition { NumberAnimation { property: "x"; from: searchStack.width; to: 0; duration: 300; easing.type: Easing.OutCubic } }
                popExit: Transition { NumberAnimation { property: "x"; from: 0; to: searchStack.width; duration: 300; easing.type: Easing.OutCubic } }
                initialItem: searchPage
            }
        }

        // ==================== Tab 2: Favorites ====================
        Item {
            id: favoritesTab
            property var favList: []
            property var notesList: []

            function refreshFavorites() {
                if (networkService.isLoggedIn) {
                    networkService.fetchFavorites()
                    networkService.fetchAllNotes()
                }
            }

            Connections {
                target: networkService
                function onFavoritesLoaded(favorites) {
                    var items = []
                    for (var i = 0; i < favorites.length; i++)
                        items.push(favorites[i])
                    favoritesTab.favList = items
                }
                function onAllNotesLoaded(notes) {
                    var items = []
                    for (var i = 0; i < notes.length; i++)
                        if (notes[i].text && notes[i].text.length > 0)
                            items.push(notes[i])
                    favoritesTab.notesList = items
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

                // Logged in — favorites + notes
                Flickable {
                    anchors.fill: parent
                    contentHeight: favCol.height + 40
                    clip: true
                    visible: networkService.isLoggedIn

                    Column {
                        id: favCol
                        width: parent.width
                        topPadding: 50
                        spacing: 8

                        Text {
                            text: "Избранное"
                            color: textColor
                            font.pixelSize: 34
                            font.weight: Font.Bold
                            leftPadding: 20
                            bottomPadding: 8
                        }

                        // Empty state
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            visible: favoritesTab.favList.length === 0 && favoritesTab.notesList.length === 0
                            topPadding: 40

                            Text { text: "☆"; font.pixelSize: 40; color: textSecondary; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: "Пока пусто"; color: textSecondary; font.pixelSize: 17; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: "Нажмите ☆ в статье, чтобы добавить"; color: textSecondary; font.pixelSize: 14; anchors.horizontalCenter: parent.horizontalCenter }
                        }

                        // Favorites list
                        Repeater {
                            model: favoritesTab.favList

                            delegate: Rectangle {
                                width: parent.width - 32
                                anchors.horizontalCenter: parent.horizontalCenter
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

                        // Секция "Заметки"
                        Text {
                            text: "📝 Заметки"
                            color: textColor
                            font.pixelSize: 22
                            font.weight: Font.Bold
                            leftPadding: 20
                            topPadding: 20
                            bottomPadding: 8
                            visible: favoritesTab.notesList.length > 0
                        }

                        Repeater {
                            model: favoritesTab.notesList

                            delegate: Rectangle {
                                width: parent.width - 32
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: noteCol.height + 20
                                radius: 10
                                color: cardColor
                                border.color: separatorColor
                                border.width: 0.5

                                Column {
                                    id: noteCol
                                    width: parent.width - 24
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        text: modelData.file
                                        color: textSecondary
                                        font.pixelSize: 13
                                    }
                                    Text {
                                        text: modelData.text
                                        color: textColor
                                        font.pixelSize: 15
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        mainStack.pop(null)
                                        tabStack.currentIndex = 0
                                        mainStack.push(articleViewPage, {
                                            articleTitle: modelData.file,
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
        Item {
            StackView {
                id: settingsStack
                anchors.fill: parent
                pushEnter: Transition { NumberAnimation { property: "x"; from: settingsStack.width; to: 0; duration: 300; easing.type: Easing.OutCubic } }
                popExit: Transition { NumberAnimation { property: "x"; from: 0; to: settingsStack.width; duration: 300; easing.type: Easing.OutCubic } }
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
                    topPadding: 50
                    spacing: 20

                    Text {
                        text: "Настройки"
                        color: textColor
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
                                            text: networkService.displayName.length > 0 ? networkService.displayName[0].toUpperCase() : "?"
                                            color: textColor
                                            font.pixelSize: 18
                                            font.weight: Font.Bold
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            text: networkService.displayName
                                            color: textColor
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
                                    Text { text: "Редактировать профиль"; color: textColor; font.pixelSize: 17; Layout.fillWidth: true }
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
                                    Text { text: "Тема"; color: textColor; font.pixelSize: 17; Layout.fillWidth: true }
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
                                    Text { text: "Размер шрифта"; color: textColor; font.pixelSize: 17; Layout.fillWidth: true }

                                    Rectangle {
                                        width: 32; height: 28; radius: 6; color: pressedColor
                                        Text { anchors.centerIn: parent; text: "A-"; color: "#ffffff"; font.pixelSize: 14 }
                                        MouseArea { anchors.fill: parent; onClicked: if (networkService.fontSize > 12) networkService.setFontSize(networkService.fontSize - 1) }
                                    }

                                    Text { text: networkService.fontSize; color: textSecondary; font.pixelSize: 15 }

                                    Rectangle {
                                        width: 32; height: 28; radius: 6; color: pressedColor
                                        Text { anchors.centerIn: parent; text: "A+"; color: "#ffffff"; font.pixelSize: 14 }
                                        MouseArea { anchors.fill: parent; onClicked: if (networkService.fontSize < 24) networkService.setFontSize(networkService.fontSize + 1) }
                                    }

                                    Item { width: 8 }

                                    Rectangle {
                                        width: 60; height: 28; radius: 6
                                        color: networkService.fontSize === 16 ? pressedColor : "#0a84ff"
                                        Text { anchors.centerIn: parent; text: "Сброс"; color: "#ffffff"; font.pixelSize: 12 }
                                        MouseArea { anchors.fill: parent; onClicked: networkService.setFontSize(16) }
                                    }
                                }
                                Rectangle {
                                    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.leftMargin: 16
                                    anchors.right: parent.right; height: 0.5; color: separatorColor
                                }
                            }
                        }
                    }

                    // Секция "Сервер" — адрес API для загрузки статей
                    Text {
                        text: "СЕРВЕР"
                        color: textSecondary
                        font.pixelSize: 13
                        leftPadding: 36
                    }

                    Rectangle {
                        width: parent.width - 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 48
                        radius: 12
                        color: cardColor

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 8
                            spacing: 8

                            Text { text: "API:"; color: textSecondary; font.pixelSize: 14 }
                            TextInput {
                                id: serverUrlInput
                                Layout.fillWidth: true
                                color: textColor; font.pixelSize: 14
                                text: "http://172.20.10.11:8080"
                                verticalAlignment: TextInput.AlignVCenter
                            }
                            Rectangle {
                                width: 70; height: 30; radius: 6; color: "#0a84ff"
                                Text { anchors.centerIn: parent; text: "Применить"; color: "#ffffff"; font.pixelSize: 11 }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        networkService.setBaseUrl(serverUrlInput.text)
                                        networkService.fetchArticles()
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
                                        color: textColor
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
                                        color: textColor
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
                        color: textColor
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
                                color: textColor
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

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Платформа"; color: "#ebebf5"; font.pixelSize: 15; opacity: 0.6 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "iOS (Qt 6)"; color: "#ebebf5"; font.pixelSize: 15; opacity: 0.4 }
                                }
                                RowLayout {
                                    width: parent.width
                                    Text { text: "Backend"; color: "#ebebf5"; font.pixelSize: 15; opacity: 0.6 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "Go + PostgreSQL"; color: "#ebebf5"; font.pixelSize: 15; opacity: 0.4 }
                                }
                                RowLayout {
                                    width: parent.width
                                    Text { text: "Статей"; color: "#ebebf5"; font.pixelSize: 15; opacity: 0.6 }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        color: "#ebebf5"; font.pixelSize: 15; opacity: 0.4
                                        text: { var r = articlesModel.revision; return articlesModel.rowCount() }
                                    }
                                }
                                RowLayout {
                                    width: parent.width
                                    Text { text: "Глав"; color: "#ebebf5"; font.pixelSize: 15; opacity: 0.6 }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        color: "#ebebf5"; font.pixelSize: 15; opacity: 0.4
                                        text: { var r = articlesModel.revision; return articlesModel.getChapters().length }
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
                            color: textColor; font.pixelSize: 17; verticalAlignment: TextInput.AlignVCenter
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
                            color: textColor; font.pixelSize: 17; verticalAlignment: TextInput.AlignVCenter; echoMode: TextInput.Password
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
                            color: textColor; font.pixelSize: 17; verticalAlignment: TextInput.AlignVCenter; echoMode: TextInput.Password
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

            // Реактивный список глав — обновляется при загрузке из API
            property var chaptersData: {
                var rev = articlesModel.revision  // зависимость от revision
                return articlesModel.getChapters()
            }
            property int totalArticles: {
                var rev = articlesModel.revision
                return articlesModel.rowCount()
            }

            Flickable {
                anchors.fill: parent
                contentHeight: chaptersCol.height + 40
                clip: true

                Column {
                    id: chaptersCol
                    width: parent.width
                    topPadding: 50
                    spacing: 0

                    Text {
                        text: "C++ Учебник"
                        color: textColor
                        font.pixelSize: 34
                        font.weight: Font.Bold
                        leftPadding: 20
                        bottomPadding: 8
                    }

                    Text {
                        text: totalArticles + " статей · " + chaptersData.length + " глав"
                        color: textSecondary
                        font.pixelSize: 15
                        leftPadding: 20
                        bottomPadding: 20
                    }

                    // Сообщение если нет статей
                    Column {
                        width: parent.width - 64
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12
                        visible: totalArticles === 0
                        topPadding: 40

                        Text { text: "📡"; font.pixelSize: 48; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Нет подключения к серверу"; color: textColor; font.pixelSize: 18; font.weight: Font.Medium; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Проверьте адрес сервера в настройках\nи подключение к сети"; color: textSecondary; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; anchors.horizontalCenter: parent.horizontalCenter }
                        Rectangle {
                            width: 160; height: 40; radius: 10; color: "#0a84ff"
                            anchors.horizontalCenter: parent.horizontalCenter
                            Text { anchors.centerIn: parent; text: "Повторить"; color: "#ffffff"; font.pixelSize: 15 }
                            MouseArea { anchors.fill: parent; onClicked: networkService.fetchArticles() }
                        }
                    }

                    // Карточка прогресса (если авторизован)
                    Rectangle {
                        id: progressCard
                        width: parent.width - 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: networkService.isLoggedIn ? progressCol.height + 20 : 0
                        radius: 12; color: cardColor
                        visible: networkService.isLoggedIn
                        clip: true

                        property int pct: 0

                        Connections {
                            target: networkService
                            function onProgressLoaded(progress) { progressCard.pct = progress.percent || 0 }
                            function onAuthChanged() {
                                if (networkService.isLoggedIn) networkService.fetchProgress()
                                else progressCard.pct = 0
                            }
                            function onReadChecked() { networkService.fetchProgress() }
                        }

                        Component.onCompleted: {
                            if (networkService.isLoggedIn) networkService.fetchProgress()
                        }

                        Column {
                            id: progressCol
                            width: parent.width - 24; anchors.centerIn: parent; spacing: 8
                            Row {
                                spacing: 8
                                Text { text: "📊 Прогресс"; color: textColor; font.pixelSize: 15; font.weight: Font.Medium }
                                Text { text: progressCard.pct + "%"; color: "#0a84ff"; font.pixelSize: 15; font.weight: Font.Bold }
                            }
                            Rectangle {
                                width: parent.width; height: 6; radius: 3; color: separatorColor
                                Rectangle {
                                    width: Math.max(0, parent.width * progressCard.pct / 100)
                                    height: parent.height; radius: 3; color: "#30d158"
                                    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                }
                            }
                        }
                    }

                    Item { height: 8; width: 1 }


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
                                model: chaptersData

                                delegate: Item {
                                    width: chaptersList.width
                                    height: 58

                                    Rectangle {
                                        anchors.fill: parent
                                        color: chapterMa.pressed ? pressedColor : "transparent"

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
                                                    color: textColor
                                                    font.pixelSize: 14
                                                    font.weight: Font.Bold
                                                }
                                            }

                                            Column {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text {
                                                    text: modelData.name
                                                    color: textColor
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
                        color: textColor
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
                                        color: artMa.pressed ? pressedColor : "transparent"

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
            property string rawMd: ""
            property string noteText: ""

            Component.onCompleted: {
                rawMd = markdownService.loadMarkdown(articleFile)
                if (rawMd.indexOf("Загрузка") >= 0) {
                    networkService.fetchArticleContent(articleFile)
                } else {
                    articleBlocks = markdownService.parseBlocks(rawMd, networkService.darkTheme)
                }
                if(networkService.isLoggedIn){networkService.fetchNote(articleFile);networkService.checkRead(articleFile)}
            }

            Connections {
                target: networkService
                function onArticleContentLoaded(file, content) {
                    if (file === articleFile) {
                        markdownService.cacheContent(file, content)
                        rawMd = content
                        articleBlocks = markdownService.parseBlocks(content, networkService.darkTheme)
                    }
                }
                function onThemeChanged() {
                    if (rawMd.length > 0)
                        articleBlocks = markdownService.parseBlocks(rawMd, networkService.darkTheme)
                }
                function onNoteLoaded(file, text) { if(file===articleFile) noteText=text }
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

                // Кнопка "Поделиться"
                Rectangle {
                    id: shareBtn
                    width: 28; height: 28; radius: 6
                    anchors.right: favBtn.visible ? favBtn.left : parent.right
                    anchors.rightMargin: favBtn.visible ? 12 : 16
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 6
                    color: "transparent"
                    border.color: textSecondary; border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "↗"
                        color: textSecondary
                        font.pixelSize: 16
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            // Копируем контент в буфер обмена
                            shareTextEdit.text = rawMd
                            shareTextEdit.selectAll()
                            shareTextEdit.copy()
                            shareTextEdit.deselect()
                            shareLabel.visible = true
                            shareTimer.start()
                        }
                    }
                }

                // Скрытый TextEdit для копирования
                TextEdit { id: shareTextEdit; visible: false }

                // Уведомление "Скопировано"
                Text {
                    id: shareLabel
                    visible: false
                    text: "Скопировано в буфер"
                    color: "#30d158"
                    font.pixelSize: 12
                    anchors.right: shareBtn.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: shareBtn.verticalCenter
                }
                Timer {
                    id: shareTimer
                    interval: 2000
                    onTriggered: shareLabel.visible = false
                }

                // Кнопка "Избранное"
                Text {
                    id: favBtn
                    property bool isFav: false
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                    text: isFav ? "★" : "☆"
                    color: isFav ? "#ffd60a" : textSecondary
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
                        function onAuthChanged() {
                            if (!networkService.isLoggedIn) { favBtn.isFav = false }
                            else { networkService.checkFavorite(articleFile); networkService.checkRead(articleFile) }
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
                contentHeight: blocksColumn.height + (notesBlock.visible ? notesBlock.height + 20 : 0) + (readBlock.visible ? 70 : 0) + navButtons.height + 80
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

                // Заметки к статье
                Rectangle {
                    id: notesBlock
                    anchors.top: blocksColumn.bottom
                    anchors.topMargin: 20
                    anchors.left: parent.left; anchors.leftMargin: 16
                    anchors.right: parent.right; anchors.rightMargin: 16
                    height: notesCol.height + 24
                    radius: 10; color: cardColor; border.color: separatorColor; border.width: 0.5
                    visible: networkService.isLoggedIn

                    Column {
                        id: notesCol
                        width: parent.width - 24; anchors.centerIn: parent; spacing: 8

                        Text { text: "📝 Заметка"; color: textSecondary; font.pixelSize: 13 }

                        TextEdit {
                            id: noteInput; width: parent.width
                            color: textColor; font.pixelSize: 14
                            wrapMode: TextEdit.Wrap
                            text: noteText
                            Text { text: "Добавить заметку..."; color: textSecondary; font.pixelSize: 14
                                   visible: !noteInput.text && !noteInput.activeFocus; anchors.verticalCenter: parent.verticalCenter }
                        }

                        Rectangle {
                            width: 100; height: 28; radius: 6; color: "#0a84ff"
                            visible: noteInput.text !== noteText
                            Text { anchors.centerIn: parent; text: "Сохранить"; color: "#ffffff"; font.pixelSize: 12 }
                            MouseArea { anchors.fill: parent; onClicked: { networkService.saveNote(articleFile, noteInput.text); noteText = noteInput.text } }
                        }
                    }
                }
                // Кнопка "Отметить как прочитанное"
                Rectangle {
                    id: readBlock
                    anchors.top: notesBlock.visible ? notesBlock.bottom : blocksColumn.bottom
                    anchors.topMargin: 16
                    anchors.left: parent.left; anchors.leftMargin: 16
                    anchors.right: parent.right; anchors.rightMargin: 16
                    height: 48; radius: 10
                    color: readBlock.isRead ? "#1a3a1a" : cardColor
                    border.color: readBlock.isRead ? "#30d158" : separatorColor
                    border.width: 1
                    visible: networkService.isLoggedIn

                    property bool isRead: false

                    Connections {
                        target: networkService
                        function onReadChecked(file, read) { if (file === articleFile) readBlock.isRead = read }
                    }

                    Row {
                        anchors.centerIn: parent; spacing: 8
                        Text { text: readBlock.isRead ? "✅" : "✕"; font.pixelSize: 18; color: readBlock.isRead ? "#30d158" : textSecondary; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: readBlock.isRead ? "Прочитано (нажмите чтобы отменить)" : "Отметить как прочитанное"
                            color: readBlock.isRead ? "#30d158" : textColor
                            font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: networkService.markRead(articleFile)
                    }
                }

                // Кнопки навигации
                RowLayout {
                    id: navButtons
                    anchors.top: readBlock.visible ? readBlock.bottom : (notesBlock.visible ? notesBlock.bottom : blocksColumn.bottom)
                    anchors.topMargin: 16
                    anchors.left: parent.left; anchors.leftMargin: 16
                    anchors.right: parent.right; anchors.rightMargin: 16
                    spacing: 12

                    // Спейсер слева (если "Предыдущая" не видна, двигает "Следующая" вправо)
                    Item {
                        Layout.fillWidth: true
                        visible: {
                            var ch = parseInt(articleFile.split(".")[0])
                            var all = articlesModel.getArticlesForChapter(ch)
                            for (var i = 0; i < all.length; i++)
                                if (all[i].file === articleFile) return i === 0
                            return true
                        }
                    }

                    // Предыдущая статья
                    Rectangle {
                        Layout.preferredWidth: (navButtons.width - 12) / 2
                        height: 44; radius: 10
                        color: cardColor
                        border.color: separatorColor; border.width: 0.5
                        visible: {
                            var ch = parseInt(articleFile.split(".")[0])
                            var all = articlesModel.getArticlesForChapter(ch)
                            for (var i = 0; i < all.length; i++)
                                if (all[i].file === articleFile) return i > 0
                            return false
                        }

                        Text { anchors.centerIn: parent; text: "‹ Предыдущая"; color: "#0a84ff"; font.pixelSize: 15 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var ch = parseInt(articleFile.split(".")[0])
                                var all = articlesModel.getArticlesForChapter(ch)
                                for (var i = 0; i < all.length; i++) {
                                    if (all[i].file === articleFile && i > 0) {
                                        mainStack.replace(articleViewPage, { articleTitle: all[i-1].title, articleFile: all[i-1].file })
                                        break
                                    }
                                }
                            }
                        }
                    }

                    // Следующая статья
                    Rectangle {
                        Layout.preferredWidth: (navButtons.width - 12) / 2
                        height: 44; radius: 10
                        color: "#0a84ff"
                        visible: {
                            var ch = parseInt(articleFile.split(".")[0])
                            var all = articlesModel.getArticlesForChapter(ch)
                            for (var i = 0; i < all.length; i++)
                                if (all[i].file === articleFile) return i < all.length - 1
                            return false
                        }

                        Text { anchors.centerIn: parent; text: "Следующая ›"; color: "#ffffff"; font.pixelSize: 15 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var ch = parseInt(articleFile.split(".")[0])
                                var all = articlesModel.getArticlesForChapter(ch)
                                for (var i = 0; i < all.length; i++) {
                                    if (all[i].file === articleFile && i < all.length - 1) {
                                        mainStack.replace(articleViewPage, { articleTitle: all[i+1].title, articleFile: all[i+1].file })
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
                topPadding: 50
                spacing: 0

                Text {
                    text: "Поиск"
                    color: textColor
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
            property string rawMd: ""

            Component.onCompleted: {
                rawMd = markdownService.loadMarkdown(articleFile)
                if (rawMd.indexOf("Загрузка") >= 0) {
                    networkService.fetchArticleContent(articleFile)
                } else {
                    articleBlocks = markdownService.parseBlocks(rawMd, networkService.darkTheme)
                }
            }

            Connections {
                target: networkService
                function onArticleContentLoaded(file, content) {
                    if (file === articleFile) {
                        markdownService.cacheContent(file, content)
                        rawMd = content
                        articleBlocks = markdownService.parseBlocks(content, networkService.darkTheme)
                    }
                }
                function onThemeChanged() {
                    if (rawMd.length > 0)
                        articleBlocks = markdownService.parseBlocks(rawMd, networkService.darkTheme)
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

                // Code content — с подсветкой синтаксиса C++
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
                        textFormat: Text.RichText
                        text: highlightCpp(blockContent)
                        font.family: "Menlo"
                        font.pixelSize: 13
                        lineHeight: 1.5

                        Component.onCompleted: {
                            if (font.family !== "Menlo") font.family = "Courier New"
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
