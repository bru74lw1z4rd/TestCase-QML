import QtQuick
import QtQuick.Controls

import "qrc:/Elements/Images"
import "qrc:/Elements/Texts"

Item {
    id: statusItem

    height: 200
    width: applicationWindow.width / 2

    visible: (barChart.model.count > 0) ? false : true

    anchors {
        centerIn: parent
    }

    SvgImage {
        id: statusItemIcon

        height: 80
        width: height

        imageSource: "qrc:/emoji/smart.svg"

        anchors {
            horizontalCenter: parent.horizontalCenter

            top: parent.top
        }
    }

    Heading {
        id: statusItemHeading

        text: qsTr("Выберите файл для подсчета слов")

        font.pointSize: 23

        anchors {
            top: statusItemIcon.bottom
            left: parent.left
            right: parent.right

            topMargin: 10
        }
    }

    SubHeading {
        id: statusItemSubHeading

        text: qsTr("Для начала работы, требуется выбрать файл формата .txt")

        anchors {
            top: statusItemHeading.bottom
            left: parent.left
            right: parent.right

            topMargin: 5
        }
    }
}
