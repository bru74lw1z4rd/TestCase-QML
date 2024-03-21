import QtQuick
import QtQuick.Controls 
import QtQuick.Controls.Material 
import QtQml.Models 

import "qrc:/Elements/Texts"

Popup {
    id: root

    QtObject {
        id: privates

        readonly property real margins: 30
    }

    property color buttonsColor: Material.accent
    property string dialogText: ""

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    width: (Qt.platform.os === "ios" || Qt.platform.os === "android")
           ? ((applicationWindow.width - privates.margins < applicationWindow.height / 1.7) ? applicationWindow.width - privates.margins : applicationWindow.height / 1.2)
           : ((heading.implicitWidth > applicationWindow.width - privates.margins) ? applicationWindow.width - privates.margins : heading.implicitWidth)
    height: (heading.height + okButton.height) + (heading.anchors.margins * 2 + okButton.anchors.margins * 2)

    modal: true
    focus: true

    Material.theme: Material.Light

    clip: true

    function show(text) {
        dialogText = text
        root.open()
    }

    background: Rectangle {
        color: "white"

        radius: 20
    }

    Heading {
        id: heading

        text: dialogText
        textFormat: Text.StyledText

        font.bold: false
        font.pointSize: (Qt.platform.os === "ios" || Qt.platform.os === "android") ? 16 : 15

        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        horizontalAlignment: Text.AlignLeft

        linkColor: Material.accent

        onLinkActivated: {
            Qt.openUrlExternally(link)
        }

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right

            margins: 15
        }
    }

    SubHeading {
        id: okButton

        text: qsTr("OK")

        font.pointSize: (Qt.platform.os === "ios" || Qt.platform.os === "android") ? 15 : 12
        font.bold: true

        color: buttonsColor

        verticalAlignment: Text.AlignBottom

        maximumLineCount: 1

        textFormat: Text.PlainText
        wrapMode: Text.WordWrap

        elide: Text.ElideRight

        anchors {
            top: heading.bottom
            right: parent.right

            margins: 25
        }

        MouseArea {
            id: okButtonMouseArea

            anchors {
                fill: parent
            }

            onClicked: {
                close()
            }
        }
    }
}
