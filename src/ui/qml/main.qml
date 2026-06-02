import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    visible: true
    width: 390
    height: 844
    title: "Metanit C++"
    color: "#000000"

    // iOS-style tab bar
    footer: Rectangle {
        width: parent.width
        height: 83
        color: "#1c1c1e"

        Rectangle {
            width: parent.width
            height: 0.5
            color: "#38383a"
        }

        RowLayout {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: 28
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
            Rectangle {
                anchors.fill: parent
                color: "#000000"

                Column {
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        text: "⭐"
                        font.pixelSize: 48
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "Избранное"
                        color: "#ffffff"
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "Скоро появится"
                        color: "#8e8e93"
                        font.pixelSize: 15
                        anchors.horizontalCenter: parent.horizontalCenter
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
            color: "#000000"

            Flickable {
                anchors.fill: parent
                contentHeight: settCol.height + 120
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

                    // Секция "Основные" — пустая, заглушки
                    Rectangle {
                        width: parent.width - 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: settingsMainCol.height
                        radius: 12
                        color: "#1c1c1e"
                        clip: true

                        Column {
                            id: settingsMainCol
                            width: parent.width

                            // Заглушка: Тема
                            Item {
                                width: parent.width
                                height: 48
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    Text {
                                        text: "Тема"
                                        color: "#ffffff"
                                        font.pixelSize: 17
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: "Тёмная"
                                        color: "#8e8e93"
                                        font.pixelSize: 17
                                    }
                                }
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.leftMargin: 16
                                    anchors.right: parent.right
                                    height: 0.5
                                    color: "#38383a"
                                }
                            }

                            // Заглушка: Размер шрифта
                            Item {
                                width: parent.width
                                height: 48
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    Text {
                                        text: "Размер шрифта"
                                        color: "#ffffff"
                                        font.pixelSize: 17
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: "Стандартный"
                                        color: "#8e8e93"
                                        font.pixelSize: 17
                                    }
                                }
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.leftMargin: 16
                                    anchors.right: parent.right
                                    height: 0.5
                                    color: "#38383a"
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
                        color: "#8e8e93"
                        font.pixelSize: 13
                        leftPadding: 36
                    }

                    Rectangle {
                        width: parent.width - 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: settingsInfoCol.height
                        radius: 12
                        color: "#1c1c1e"
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
                                    color: "#38383a"
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
                                        color: "#8e8e93"
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
            color: "#000000"

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
                        color: "#1c1c1e"

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

                            Rectangle { width: parent.width; height: 0.5; color: "#38383a" }

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

    // ==================== Chapters Page ====================
    Component {
        id: chaptersPage

        Rectangle {
            color: "#000000"

            Flickable {
                anchors.fill: parent
                contentHeight: chaptersCol.height + 120
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
                        text: "150 статей · 17 глав"
                        color: "#8e8e93"
                        font.pixelSize: 15
                        leftPadding: 20
                        bottomPadding: 20
                    }

                    Rectangle {
                        width: parent.width - 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: chaptersList.height
                        radius: 12
                        color: "#1c1c1e"
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
                                                    return c[(modelData.chapter - 1) % c.length];
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
                                                    color: "#8e8e93"
                                                    font.pixelSize: 13
                                                }
                                            }

                                            Text { text: "›"; color: "#48484a"; font.pixelSize: 22 }
                                        }

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left; anchors.leftMargin: 60
                                            anchors.right: parent.right
                                            height: 0.5; color: "#38383a"
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
            color: "#000000"
            property int chapterNum: 0
            property string chapterTitle: ""

            Flickable {
                anchors.fill: parent
                contentHeight: artCol.height + 120
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
                        radius: 12; color: "#1c1c1e"; clip: true

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
                                                color: "#ffffff"; font.pixelSize: 17
                                                Layout.fillWidth: true
                                                wrapMode: Text.WordWrap
                                            }
                                            Text { text: "›"; color: "#48484a"; font.pixelSize: 22 }
                                        }

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left; anchors.leftMargin: 16
                                            anchors.right: parent.right
                                            height: 0.5; color: "#38383a"
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
            color: "#000000"
            property string articleTitle: ""
            property string articleFile: ""

            Rectangle {
                id: articleNav
                width: parent.width; height: 60
                color: "#000000"; z: 10

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
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 0.5; color: "#38383a" }
            }

            Flickable {
                anchors.top: articleNav.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                contentHeight: webContent.height + 40
                clip: true

                Text {
                    id: webContent
                    width: parent.width - 32
                    x: 16
                    topPadding: 16
                    textFormat: Text.RichText
                    wrapMode: Text.WordWrap
                    color: "#e0e0e0"
                    font.pixelSize: 16
                    lineHeight: 1.5

                    Component.onCompleted: {
                        var md = markdownService.loadMarkdown(articleFile)
                        text = markdownService.markdownToHtml(md)
                    }
                }
            }
        }
    }

    // ==================== Search Page ====================
    Component {
        id: searchPage

        Rectangle {
            color: "#000000"

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
                    height: 38; radius: 10; color: "#1c1c1e"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10; anchors.rightMargin: 10
                        spacing: 6

                        Text { text: "🔍"; font.pixelSize: 14; opacity: 0.6 }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: "#ffffff"; font.pixelSize: 17

                            Text {
                                text: "Статьи, темы, ключевые слова"
                                color: "#8e8e93"; font.pixelSize: 17
                                visible: !searchInput.text && !searchInput.activeFocus
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            onTextChanged: filterModel.filterText = text
                        }

                        Text {
                            text: "✕"; color: "#8e8e93"; font.pixelSize: 16
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
                                    color: "#ffffff"; font.pixelSize: 17
                                    width: parent.width; wrapMode: Text.WordWrap
                                }
                                Text {
                                    text: "Глава " + chapter + " · " + chapterName
                                    color: "#8e8e93"; font.pixelSize: 13
                                }
                            }

                            Text { text: "›"; color: "#48484a"; font.pixelSize: 22 }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left; anchors.right: parent.right
                            height: 0.5; color: "#38383a"
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
            color: "#000000"
            property string articleTitle: ""
            property string articleFile: ""

            Rectangle {
                id: searchArticleNav
                width: parent.width; height: 60
                color: "#000000"; z: 10

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
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 0.5; color: "#38383a" }
            }

            Flickable {
                anchors.top: searchArticleNav.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                contentHeight: searchWebContent.height + 40
                clip: true

                Text {
                    id: searchWebContent
                    width: parent.width - 32
                    x: 16
                    topPadding: 16
                    textFormat: Text.RichText
                    wrapMode: Text.WordWrap
                    color: "#e0e0e0"
                    font.pixelSize: 16
                    lineHeight: 1.5

                    Component.onCompleted: {
                        var md = markdownService.loadMarkdown(articleFile)
                        text = markdownService.markdownToHtml(md)
                    }
                }
            }
        }
    }
}
