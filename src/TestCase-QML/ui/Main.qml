import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Dialogs
import QtCharts

import FileReader
import FileReader.FileReaderError

import "qrc:/Elements/Buttons"
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

    Connections {
        target: fileReader

        function onTotalFileLengthChanged() {
            progressBar.to = fileReader.totalFileLength
        }

        function onCurrentProgressChanged() {
            if (fileReader.currentProgress === fileReader.totalFileLength) {
                mainWorkButton.state = "idle"

                informationDialog.show(qsTr("Файл был успешно прочитан. Полную статистику по словам можно посмотреть на графике."))
            } else {
                progressBar.value = fileReader.currentProgress
            }
        }

        function onNewWordFoundChanged(word) {
            // console.log(word)
        }

        function onErrorOccured(error) {
            if (mainWorkButton.state === "working") {
                mainWorkButton.state = "prepared"
            }

            informationDialog.show(qsTr("Не удалось запустить обработку файла!"))
        }

        function onWorkCanceledChanged() {
            mainWorkButton.state = "idle"

            progressBar.value = 0
            progressBar.to = 0

            informationDialog.show(qsTr("Обработка файла была успешна отменена!"))
        }
    }
}
