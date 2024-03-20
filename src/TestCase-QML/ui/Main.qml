import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl
import QtQuick.Dialogs

import FileReader
import FileReader.FileReaderError

import "qrc:/Elements/Buttons"
import "qrc:/Elements/Dialogs"
import "qrc:/Elements/Texts"

/// TODO: очищать интерфейс
/// TODO: скелетоны

ApplicationWindow {
    id: applicationWindow

    width: 640
    height: 480

    visible: true

    title: qsTr("TestCase")

    minimumWidth: 640
    minimumHeight: 480

    QtObject {
        id: privates

        readonly property int maxChartBars: 15
    }

    /***********/
    /* Таймеры */
    /***********/

    Timer {
        id: dynamicWordsChangerTimer

        interval: 500
        running: (fileReader.paused === false && fileReader.running === true) ? true : false
        repeat: true

        onTriggered: {
            fileReader.getLastMostUsableWords()
        }
    }

    Timer {
        id: textCountTimer

        interval: 1000
        running: (fileReader.paused === false && fileReader.running === true) ? true : false
        repeat: true

        onTriggered: {
            wordsCountText.text = "Количество слов: " + fileReader.currentProgress
        }
    }

    /**********/
    /* Шрифты */
    /**********/

    FontLoader {
        id: nunitoSemiBold

        source: "qrc:/fonts/Nunito-SemiBold.ttf"
    }

    /**************/
    /* C++ классы */
    /**************/

    FileReader {
        id: fileReader
    }

    /*******************/
    /* Диалоговые окна */
    /*******************/

    InformationDialog {
        id: informationDialog
    }

    FileDialog {
        id: fileDialog

        nameFilters: [ "Text files (*.txt)" ]

        onAccepted: {
            if (fileReader.prepareFile(fileDialog.selectedFile) === false) {
                informationDialog.show(qsTr("Не удалось подготовить файл для дальнейшей обработки!"))
            } else {
                mainWorkButton.state = "prepared"
            }
        }
    }

    /********************/
    /* Элементы стринцы */
    /********************/

    Pane {
        id: informationBar

        height: (Qt.platform.os === "ios" || Qt.platform.os === "android") ? 60 : 80

        Material.elevation: 3
        Material.background: Material.accent
        Material.roundedScale: Material.NotRounded

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        Heading {
            id: titleText

            text: "2GIS FileReader"

            color: "#edeef2"

            font.pointSize: 18

            anchors {
                top: parent.top
                left: parent.left
                bottom: parent.bottom
            }
        }

        Heading {
            id: wordsCountText

            text: qsTr("Количество слов: 0")

            color: "#edeef2"

            font.pointSize: 16

            horizontalAlignment: Text.AlignRight

            wrapMode: Text.NoWrap

            anchors {
                top: parent.top
                left: titleText.right
                right: parent.right
                bottom: parent.bottom

                leftMargin: 10
            }
        }
    }

    ListView {
        id: barChart

        readonly property var barsPallete: [ "#007f5f", "#2b9348", "#55a630", "#80b918", "#168aad", "#52b69a", "#76c893", "#99d98c", "#b5e48c", "#56cfe1", "#64dfdf", "#64dfdf", "#72efdd", "#d9ed92", "#eeef20"]

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

        anchors {
            top: informationBar.bottom
            left: informationBar.left
            right: informationBar.right
            bottom: mainWorkButton.top

            topMargin: 20
            bottomMargin: 20
        }

        delegate: Item {
            height: 40
            width: barChart.width

            SubHeading {
                id: chartText

                width: (applicationWindow.width < 400) ? 100 : 200

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

    /// TODO: при рефакторинге объеденить в item
    ProgressBar {
        id: progressBar

        z: 1

        height: 40

        from: 0
        to: 100

        anchors {
            verticalCenter: cancelWorkButton.verticalCenter

            left: parent.left
            right: cancelWorkButton.left

            margins: 50
        }
    }

    RoundActionButton {
        id: cancelWorkButton

        height: mainWorkButton.height
        width: height

        iconSource: "qrc:/icons/cancel.svg"

        anchors {
            right: mainWorkButton.left
            bottom: mainWorkButton.bottom

            rightMargin: 10
        }

        onClicked: {
            /*
             * Обнуляем все состояния до начальных,
             * т.к. пользователь нажал кнопку отмены
             */

            if (mainWorkButton.state === "working" || mainWorkButton.state === "paused") {
                /*
                 * Если обработка была остановлена, возобновляем,
                 * чтобы в дальнейшем отменить операцию
                 */
                if (fileReader.paused === true) {
                    fileReader.resume()
                }

                fileReader.cancel()
            } else if (mainWorkButton.state === "prepared") {
                mainWorkButton.state = "idle"
            }
        }
    }

    RoundActionButton {
        id: mainWorkButton

        height: (Qt.platform.os === "ios" || Qt.platform.os === "android") ? 65 : 60
        width: height

        state: "idle"

        states: [
            State {
                name: "idle"

                PropertyChanges {
                    target: mainWorkButton

                    iconSource: "qrc:/icons/plus.svg"
                }

                PropertyChanges {
                    target: cancelWorkButton

                    visible: false
                }

                PropertyChanges {
                    target: progressBar

                    visible: false
                }
            },

            State {
                name: "prepared"

                PropertyChanges {
                    target: mainWorkButton

                    iconSource: "qrc:/icons/play.svg"
                }

                PropertyChanges {
                    target: cancelWorkButton

                    visible: true
                }

                PropertyChanges {
                    target: progressBar

                    visible: false
                }
            },

            State {
                name: "working"

                PropertyChanges {
                    target: mainWorkButton

                    iconSource: "qrc:/icons/pause.svg"
                }

                PropertyChanges {
                    target: cancelWorkButton

                    visible: true
                }

                PropertyChanges {
                    target: progressBar

                    visible: true
                }
            },

            State {
                name: "paused"

                PropertyChanges {
                    target: mainWorkButton

                    iconSource: "qrc:/icons/play.svg"
                }

                PropertyChanges {
                    target: cancelWorkButton

                    visible: true
                }

                PropertyChanges {
                    target: progressBar

                    visible: true
                }
            }
        ]

        anchors {
            right: parent.right
            bottom: parent.bottom

            margins: 10
        }

        onClicked: {
            if (state === "idle") {
                fileDialog.open()
            } else if (state === "prepared") {
                /* Начинаем обработку текстового файла */
                fileReader.startWork()

                /* Обновляем состояние кнопки */
                mainWorkButton.state = "working"
            } else if (state === "working" || state === "paused") {
                if (fileReader.paused === true) {
                    fileReader.resume()

                    mainWorkButton.state = "working"
                } else {
                    fileReader.pause()

                    mainWorkButton.state = "paused"
                }
            }
        }
    }
    ///

    /***************/
    /* Connections */
    /***************/

    Connections {
        target: fileReader

        function onErrorOccured(error) {
            if (mainWorkButton.state === "working") {
                mainWorkButton.state = "prepared"
            }

            informationDialog.show(qsTr("Не удалось запустить обработку файла!"))
        }

        function onCurrentProgressChanged() {
            if (fileReader.currentProgress >= fileReader.totalFileLength) {
                mainWorkButton.state = "idle"

                /* Обновления интерфейс конечными значениями */
                fileReader.getLastMostUsableWords()
                wordsCountText.text = "Количество слов: " + fileReader.currentProgress

                informationDialog.show(qsTr("Файл был успешно прочитан. Полную статистику по словам можно посмотреть на графике."))
            } else {
                progressBar.value = fileReader.currentProgress
            }
        }

        function onTotalFileLengthChanged() {
            progressBar.to = fileReader.totalFileLength
        }

        function onMostUsableWordsChanged(words) {
            if (words.length <= privates.maxChartBars) {
                barChart.model.clear()

                for (let i = 0; i < words.length; ++i) {

                    barChart.addNewWord(words[i][0], words[i][1], words[0][1])
                }
            }
        }

        function onWorkCanceledChanged() {
            mainWorkButton.state = "idle"

            progressBar.value = 0
            progressBar.to = 0

            informationDialog.show(qsTr("Обработка файла была успешна отменена!"))
        }
    }
}
