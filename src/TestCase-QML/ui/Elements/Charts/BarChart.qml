import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl
import QtQuick.Dialogs

import FileReader
import FileReader.FileReaderError

import "qrc:/Elements/Buttons"
import "qrc:/Elements/Dialogs"
import "qrc:/Elements/Images"
import "qrc:/Elements/Items"
import "qrc:/Elements/Texts"

ListView {
    id: barChart

    readonly property string skeletonWordName: "..."

    clip: true
    interactive: true

    model: ListModel { }

    spacing: 40

    boundsBehavior: Flickable.StopAtBounds

    function addNewWord(wordName, wordCount, maxWordWidth) {
        if (barChart.count < privates.maxChartBars) {
            barChart.model.append({
                                      "wordName": wordName,
                                      "wordCount": wordCount,
                                      "maxWordWidth": maxWordWidth
                                  })
        }
    }

    function changeItemIndex(itemIndex, wordName, wordCount, maxWordWidth) {
        if (barChart.count < privates.maxChartBars) {
            barChart.model.set(itemIndex, {
                                   "wordName": wordName,
                                   "wordCount": wordCount,
                                   "maxWordWidth": maxWordWidth
                               })
        } else {
            barChart.model.setProperty(itemIndex, "wordName", wordName)
            barChart.model.setProperty(itemIndex, "wordCount", wordCount)
            barChart.model.setProperty(itemIndex, "maxWordWidth", maxWordWidth)
        }
    }

    function removeEmptySkeletons() {
        for (let i = 0; i < barChart.count; ++i) {
            if (barChart.model.get(i).wordName === skeletonWordName) {
                barChart.model.remove(i, 1)
            }
        }
    }

    delegate: Item {
        height: 40
        width: barChart.width

        SubHeading {
            id: chartText

            readonly property real maximumWidth: 200
            readonly property real minimumWidth: 125

            width: (Qt.platform.os === "ios" || Qt.platform.os === "android") ? minimumWidth : maximumWidth

            text: wordName

            font.pointSize: 12

            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.NoWrap

            anchors {
                verticalCenter: chatBar.verticalCenter

                left: parent.left

                leftMargin: 20
            }
        }

        ProgressBar {
            id: chatBar

            from: 0
            to: maxWordWidth

            value: wordCount

            Behavior on value {
                NumberAnimation {
                    duration: 1500
                    easing.type: Easing.OutQuart
                }
            }

            Behavior on to {
                NumberAnimation {
                    duration: 1000
                    easing.type: Easing.OutCubic
                }
            }

            contentItem: ProgressBarImpl {
                implicitHeight: 20

                color: chatBar.Material.accentColor

                progress: chatBar.position

                scale: chatBar.mirrored ? -1 : 1
                indeterminate: chatBar.visible && chatBar.indeterminate
            }

            background: Rectangle {
                y: (chatBar.height - height) / 2

                height: 20

                implicitWidth: 200
                implicitHeight: 20

                color: Qt.rgba(chatBar.Material.accentColor.r, chatBar.Material.accentColor.g, chatBar.Material.accentColor.b, 0.25)
            }

            anchors {
                top: parent.top
                left: chartText.right
                right: wordCountText.left
                bottom: parent.bottom

                leftMargin: 30
                rightMargin: 30
            }
        }

        SubHeading {
            id: wordCountText

            width: 65

            text: wordCount

            font.pointSize: 12

            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.NoWrap

            anchors {
                verticalCenter: chatBar.verticalCenter

                right: parent.right

                leftMargin: 20
            }
        }
    }
}
