import QtQuick
import QtQuick.Controls 

Text {
    color: "#333333"

    textFormat: Text.PlainText
    elide: Text.ElideRight

    font.family: nunitoSemiBold.name
    font.pointSize: 26
    font.bold: true

    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter

    wrapMode: Text.WordWrap
}
