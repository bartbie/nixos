pragma Singleton

import Quickshell
import "./theme.js" as JS

// ansi = {
//   Black = colorWithId "#090618" 1;
//   Red = colorWithId palette.autumnRed 2;
//   Green = colorWithId palette.autumnGreen 3;
//   Yellow = colorWithId palette.boatYellow2 4;
//   Blue = colorWithId palette.crystalBlue 5;
//   Magenta = colorWithId palette.oniViolet 6;
//   Cyan = colorWithId palette.waveAqua1 7;
//   White = colorWithId palette.oldWhite 8;
// };
// brights = {
//   "Bright Black" = colorWithId palette.fujiGray 9;
//   "Bright Red" = colorWithId palette.lotusRed3 10;
//   "Bright Green" = colorWithId palette.springGreen 11;
//   "Bright Yellow" = colorWithId palette.carpYellow 12;
//   "Bright Blue" = colorWithId palette.springBlue 13;
//   "Bright Magenta" = colorWithId palette.springViolet1 14;
//   "Bright Cyan" = colorWithId palette.waveAqua2 15;
//   "Bright White" = colorWithId palette.fujiWhite 16;
// };
//

Singleton {
    id: root

    readonly property var _p: JS.palette;

    readonly property string wsFocusedOnThisMonitor: _p.carpYellow;
    readonly property string wsFocusedOnOtherMonitor: _p.crystalBlue;
    readonly property string wsActive: _p.springGreen;
    readonly property string wsInactive: dimColor;
    readonly property string dimColor: _p.fujiGray;

    readonly property string audioColor: _p.oniViolet;
    readonly property string wifiColor: _p.crystalBlue;
    readonly property string cpuColor: _p.roninYellow;
    readonly property string ramColor: _p.carpYellow;
    readonly property string weatherColor: _p.waveAqua2;
    readonly property string batteryColor: _p.springGreen;
    readonly property string screencastColor: _p.autumnRed;

    readonly property string micActiveColor: _p.lotusGreen2;
    readonly property string micMutedColor: _p.autumnRed;
    readonly property string micIdleColor: _p.autumnGreen;
    readonly property string micOffColor: _p.fujiGray;

    readonly property string islandBg: JS.withAlpha(_p.sumiInk3, 1);
    readonly property string islandBorder: _p.sumiInk6;
    readonly property string fontColor: _p.fujiWhite;

    readonly property int islandPointSize: 14;
    readonly property int selectedPointSize: 18;
    readonly property int clockPointSize: 18;
}
