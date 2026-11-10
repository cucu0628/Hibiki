import QtQuick
import "VellumGlyphs.js" as Glyphs

// Material Design glyph from the Symbols Nerd Font that Vellum Shell ships.
// `text` takes a readable icon name; unknown names are drawn as-is.
Text {
    id: icon

    property int iconSize: 18
    // Kept for call sites that toggle emphasis; Nerd glyphs have one weight.
    property bool filled: false

    property string name: ""

    text: Glyphs.codepoints[name] !== undefined ? String.fromCodePoint(Glyphs.codepoints[name]) : name
    font.family: "Symbols Nerd Font Mono"
    font.pixelSize: iconSize
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
