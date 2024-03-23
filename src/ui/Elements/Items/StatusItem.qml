import QtQuick
import QtQuick.Controls

import "qrc:/Elements/Images"
import "qrc:/Elements/Texts"

Item {
    id: statusItem

    property string statusItemIconSource: "qrc:/emoji/smart.svg"
    property string statusItemHeading: qsTr("Выберите файл для подсчета слов")
    property string statusItemSubHeading: qsTr("Для начала работы, требуется выбрать файл формата .txt и нажать кнопку начать")

    anchors {
        centerIn: parent
    }

    SvgImage {
        id: iconImage

        height: 80
        width: height

        imageSource: statusItemIconSource

        anchors {
            horizontalCenter: parent.horizontalCenter

            top: parent.top
        }
    }

    Heading {
        id: heading

        text: statusItemHeading

        font.pointSize: 23

        anchors {
            top: iconImage.bottom
            left: parent.left
            right: parent.right

            topMargin: 10
        }
    }

    SubHeading {
        id: subHeading

        text: statusItemSubHeading

        anchors {
            top: heading.bottom
            left: parent.left
            right: parent.right

            topMargin: (Qt.platform.os === "ios" || Qt.platform.os === "android") ? 5 : 0
        }
    }
}
