import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

import "qrc:/Elements/Images"

RoundButton {
    id: root

    property string iconSource: ""
    property string iconColor: "white"

    highlighted: true

    contentItem: SvgImage {
        id: iconObject

        imageSource: iconSource
        imageColor: iconColor

        anchors {
            fill: parent

            margins: 12
        }
    }
}
