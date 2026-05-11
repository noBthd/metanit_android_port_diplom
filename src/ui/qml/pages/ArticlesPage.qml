import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: page

    background: Rectangle {
        color: "#121212"
    }

    ListModel {
        id: articlesModel

        ListElement {
            title: "C++ Введение"
            content: "C++ — мощный язык программирования..."
        }

        ListElement {
            title: "Переменные"
            content: "Переменные используются для хранения данных..."
        }

        ListElement {
            title: "Функции"
            content: "Функции позволяют переиспользовать код..."
        }

        ListElement {
            title: "ООП"
            content: "Объектно-ориентированное программирование..."
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Label {
            text: "📚 Статьи"

            color: "white"
            font.pixelSize: 28
            font.bold: true
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            model: articlesModel

            spacing: 10

            delegate: Rectangle {
                width: ListView.view.width
                height: 70
                radius: 12

                color: "#1e1e1e"

                border.color: "#2a2a2a"

                Text {
                    anchors.centerIn: parent

                    text: title

                    color: "white"
                    font.pixelSize: 18
                }

                MouseArea {
                    anchors.fill: parent

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        page.StackView.view.push(
                            "qrc:/qml/pages/ArticlePage.qml",
                            {
                                articleTitle: title,
                                articleContent: content
                            }
                        )
                    }
                }
            }
        }
    }
}