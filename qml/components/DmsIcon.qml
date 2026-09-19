import QtQuick

Text {
    id: icon

    property bool filled: false
    property int iconSize: 20

    font.family: DmsFonts.icons
    font.pixelSize: iconSize
    font.weight: filled ? 500 : 400
    font.hintingPreference: Font.PreferNoHinting
    font.variableAxes: {
        "FILL": filled ? 1 : 0,
        "GRAD": -25,
        "opsz": 24,
        "wght": filled ? 500 : 400
    }
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
