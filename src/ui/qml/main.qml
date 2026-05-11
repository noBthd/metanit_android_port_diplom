import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    visible: true
    width: 900
    height: 600
    title: "Metanit Port"

    RowLayout {
        anchors.fill: parent

        Rectangle {
            width: 220
            height: parent.height
            color: "#1e1e1e"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Label {
                    text: "Metanit"
                    color: "white"
                    font.pixelSize: 20
                    Layout.alignment: Qt.AlignHCenter
                }

                Button {
                    text: "📚 Статьи"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: stackView.push("qrc:/qml/pages/ArticlesPage.qml")
                }

                Button {
                    text: "🔎 Поиск"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: stackView.push("qrc:/qml/pages/SearchPage.qml")
                }

                Button {
                    text: "⚙️ Настройки"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: stackView.push("qrc:/qml/pages/SettingsPage.qml")
                }

                Item { Layout.fillHeight: true }
            }
        }

        StackView {
            id: stackView
            Layout.fillWidth: true
            Layout.fillHeight: true

            initialItem: Rectangle {
                color: "#121212"

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        text: "Добро пожаловать 👋"
                        color: "white"
                        font.pixelSize: 28
                    }

                    Text {
                        text: "Выбери раздел слева"
                        color: "#aaaaaa"
                        font.pixelSize: 16
                    }
                }
            }
        }
    }
}