import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl
import QtQuick.Dialogs

import FileReader
import FileReader.FileReaderError

import "qrc:/Elements/Buttons"
import "qrc:/Elements/Images"
import "qrc:/Elements/Dialogs"
import "qrc:/Elements/Texts"

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

        function clearUi() {
            /* Очищаем предыдущие данные, если таковы имеются */
            barChart.model.clear()

            wordsCountText.text = ""
        }
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

            text: qsTr("Выберите файл для подсчета файлов")

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

            text: qsTr("Чтобы программа начала работала, требуется выбрать файл формата .txt")

            anchors {
                top: statusItemHeading.bottom
                left: parent.left
                right: parent.right
            }
        }
    }

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
            barChart.model.setProperty(itemIndex, "wordName", wordName)
            barChart.model.setProperty(itemIndex, "wordCount", wordCount)
            barChart.model.setProperty(itemIndex, "maxWordWidth", maxWordWidth)
        }

        anchors {
            top: informationBar.bottom
            left: informationBar.left
            right: informationBar.right
            bottom: actionItem.top

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

            ProgressBar { /// NOTE: не, ну должен же был я хоть немного в тестовом поугарать :p
                id: chatBar

                from: 0
                to: maxWordWidth

                value: wordCount

                Behavior on value {
                    NumberAnimation {
                        duration: 2000
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

    Item {
        id: actionItem

        height: mainWorkButton.height

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

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
                } else if (mainWorkButton.state === "idle" && barChart.model.count !== 0) {
                    privates.clearUi()
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

                        visible: (barChart.model.count !== 0) ? true : false
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
                    privates.clearUi()

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
    }

    /***************/
    /* Connections */
    /***************/

    Connections {
        target: fileReader

        function onDisableCanceling() {
            actionItem.enabled = false
        }

        function onErrorOccured(error) {
            if (mainWorkButton.state === "working") {
                mainWorkButton.state = "prepared"
            }

            informationDialog.show(qsTr("Не удалось запустить обработку файла!"))
        }

        function onCurrentProgressChanged() {
            if (fileReader.currentProgress >= fileReader.totalFileLength) {
                /* Включаем кнопки */
                actionItem.enabled = true

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

        function onRunningChanged() {
            /* Добваляем скелетоны */
            let skeletonsCount = (fileReader.totalFileLength >= privates.maxChartBars) ? privates.maxChartBars : fileReader.totalFileLength

            for (let i = 0; i < skeletonsCount; ++i) {
                barChart.addNewWord("...", 0, 50)
            }
        }

        function onMostUsableWordsChanged(words) {
            if (words.length <= privates.maxChartBars) {
                for (let i = 0; i < words.length; ++i) {
                    barChart.changeItemIndex(i, words[i][0], words[i][1], words[0][1])
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
