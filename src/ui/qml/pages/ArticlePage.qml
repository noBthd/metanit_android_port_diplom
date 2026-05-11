import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: page

    property string articleTitle: ""
    property string articleContent: ""

    background: Rectangle {
        color: "#121212"
    }

    ScrollView {
        anchors.fill: parent

        Rectangle {
            width: parent.width
            color: "#121212"

            ColumnLayout {
                width: parent.width - 40

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 20

                spacing: 20

                Label {
                    text: articleTitle

                    color: "white"
                    font.pixelSize: 30
                    font.bold: true

                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#2a2a2a"
                }

                Text {
                    text: articleContent

                    color: "#dddddd"
                    font.pixelSize: 18

                    wrapMode: Text.WordWrap

                    Layout.fillWidth: true
                }
            }
        }
    }
}