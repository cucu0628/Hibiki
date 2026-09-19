pragma Singleton

import QtQuick

QtObject {
    readonly property string sans: interFont.status === FontLoader.Ready
        ? interFont.name : "Noto Sans"
    readonly property string icons: materialFont.status === FontLoader.Ready
        ? materialFont.name : "Noto Sans"

    property FontLoader interFont: FontLoader {
        source: "file:///usr/share/quickshell/dms/DankCommon/assets/fonts/inter/InterVariable.ttf"
    }
    property FontLoader materialFont: FontLoader {
        source: "file:///usr/share/quickshell/dms/DankCommon/assets/fonts/material-design-icons/variablefont/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf"
    }
}
