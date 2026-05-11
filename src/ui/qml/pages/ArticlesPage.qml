import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: page

    background: Rectangle {
        color: "#121212"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        anchors.topMargin: 100
        spacing: 15

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            model: articlesModel   

            spacing: 10

            snapMode: ListView.SnapOneItem

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

    // Заголовок поверх ListView
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        height: 100
        color: "#121212"
        z: 10

        Label {
            anchors.fill: parent
            text: "📚 Статьи"
            color: "white"
            font.pixelSize: 28
            font.bold: true
            verticalAlignment: Text.AlignVCenter
        }
    }
}