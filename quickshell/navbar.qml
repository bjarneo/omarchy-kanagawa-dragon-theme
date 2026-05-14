import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Kanagawa Dragon navbar. Sumi, bone, slate, autumn seal.
// Stillness over motion. One thin line, one accent.
// Inspired by the OmarchyQuickApps "zen" shell — kanji numerals share
// the typographic register of the 静 (stillness) character.
ShellRoot {
    id: root

    // ---------- Kanagawa Dragon palette ----------
    readonly property color paper:   "#181616"  // dragonBlack3
    readonly property color ink:     "#c5c9c5"  // dragonWhite
    readonly property color inkDeep: "#c8c093"  // oldWhite
    readonly property color sumi:    "#a6a69c"  // dragonGray
    readonly property color indigo:  "#658594"  // dragonBlue2
    readonly property color seal:    "#c4746e"  // autumnRed

    // Bar surface: smoked sumi with alpha, hairline in faint bone.
    readonly property color bg:     Qt.rgba(0.094, 0.086, 0.086, 0.94)
    readonly property color fg:     ink
    readonly property color muted:  sumi
    readonly property color accent: seal
    readonly property color warn:   seal
    readonly property color sep:    Qt.rgba(0.773, 0.788, 0.773, 0.18)

    readonly property string serif: "serif"
    readonly property string mono:  "JetBrainsMono Nerd Font"

    // Kanji numerals 〇 一 二 ... 十. They double as decoration since they
    // share the typographic register of the 静 character on the side.
    readonly property var kanjiNum: ["〇","一","二","三","四","五","六","七","八","九","十"]
    function indexKanji(n) { return n >= 0 && n <= 10 ? kanjiNum[n] : String(n); }

    // Icon codepoints that fall in BMP Private Use Area (U+E000-U+F8FF).
    // Authored via fromCodePoint so source stays ASCII-safe across tooling.
    readonly property string icoOmarchy: String.fromCodePoint(0xe900)
    readonly property string icoBtOn:    String.fromCodePoint(0xf294)
    readonly property string icoVol1:    String.fromCodePoint(0xf026)
    readonly property string icoVol2:    String.fromCodePoint(0xf027)
    readonly property string icoVol3:    String.fromCodePoint(0xf028)
    readonly property string icoMute:    String.fromCodePoint(0xeee8)

    readonly property int barHeight: 26

    // ---------- State ----------
    property int activeWs: 1
    property var existingWs: [1, 2, 3, 4, 5]

    property int cpuVal: 0
    property int memVal: 0
    property int batVal: 0
    property string batState: "Unknown"

    property string netIcon: "󰤯"
    property string btIcon:  "󰂲"
    property string audioIcon: ""  // set after Component init

    property string hh: "--"
    property string mm: "--"
    property string dd: "--"
    property string mon: "---"

    // ---------- Generic launcher ----------
    Process { id: runner; running: false }
    function run(cmd) {
        runner.command = ["bash", "-lc", cmd];
        runner.running = false;
        runner.running = true;
    }

    // ---------- Telemetry (1 Hz) ----------
    Process {
        id: tel
        running: false
        command: ["bash", "-lc",
            "read _ a b c d _ < <(grep '^cpu ' /proc/stat); "
            + "sleep 0.15; "
            + "read _ e f g h _ < <(grep '^cpu ' /proc/stat); "
            + "du=$(( (e+f+g) - (a+b+c) )); dt=$(( (e+f+g+h) - (a+b+c+d) )); "
            + "cpu=$(( dt>0 ? du*100/dt : 0 )); "
            + "mem=$(awk '/MemTotal/{t=$2}/MemAvailable/{m=$2}END{printf \"%d\",(t-m)*100/t}' /proc/meminfo); "
            + "bat=0; bst=Unknown; "
            + "if [ -d /sys/class/power_supply/BAT0 ]; then "
            + "  bat=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 0); "
            + "  bst=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo Unknown); "
            + "elif [ -d /sys/class/power_supply/BAT1 ]; then "
            + "  bat=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo 0); "
            + "  bst=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null || echo Unknown); "
            + "fi; "
            + "printf '%d|%d|%d|%s|%s|%s|%s|%s' "
            + "  \"$cpu\" \"$mem\" \"$bat\" \"$bst\" "
            + "  \"$(date +%H)\" \"$(date +%M)\" \"$(date +%d)\" \"$(date +%b | tr a-z A-Z)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.split("|");
                if (p.length === 8) {
                    root.cpuVal = parseInt(p[0]) || 0;
                    root.memVal = parseInt(p[1]) || 0;
                    root.batVal = parseInt(p[2]) || 0;
                    root.batState = p[3] || "Unknown";
                    root.hh = p[4]; root.mm = p[5];
                    root.dd = p[6]; root.mon = p[7];
                }
            }
        }
    }
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { tel.running = false; tel.running = true; } }

    // ---------- Workspaces (2 Hz) ----------
    Process {
        id: wsProbe
        running: false
        command: ["bash", "-lc",
            "act=$(hyprctl activeworkspace -j 2>/dev/null | sed -n 's/.*\"id\": *\\([0-9]*\\).*/\\1/p' | head -1); "
            + "ids=$(hyprctl workspaces -j 2>/dev/null | tr ',' '\\n' | sed -n 's/.*\"id\": *\\([0-9]*\\).*/\\1/p' | sort -nu | paste -sd,); "
            + "printf '%s|%s' \"${act:-1}\" \"${ids:-1}\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.split("|");
                if (p.length === 2) {
                    root.activeWs = parseInt(p[0]) || 1;
                    const have = p[1].split(",").map(s => parseInt(s)).filter(n => !isNaN(n));
                    root.existingWs = [...new Set([...have, 1, 2, 3, 4, 5])].sort((a,b) => a-b).slice(0, 9);
                }
            }
        }
    }
    Timer { interval: 500; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { wsProbe.running = false; wsProbe.running = true; } }

    // ---------- Network status ----------
    Process {
        id: netProbe
        running: false
        command: ["bash", "-lc",
            "type=none; "
            + "if ip -o link show | awk -F': ' '{print $2}' | grep -qE '^(en|eth)'; then "
            + "  if ip -o addr show | grep -qE '^[0-9]+: (en|eth)[^ ]*.*inet '; then type=eth; fi; "
            + "fi; "
            + "if [ \"$type\" = none ]; then "
            + "  s=$(nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | awk -F: '$1==\"*\"{print $2; exit}'); "
            + "  if [ -n \"$s\" ]; then type=wifi:$s; fi; "
            + "fi; printf '%s' \"$type\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = this.text.trim();
                if (t === "eth") root.netIcon = "󰀂";
                else if (t.startsWith("wifi:")) {
                    const sig = parseInt(t.split(":")[1]) || 0;
                    const ramp = ["󰤯","󰤟","󰤢","󰤥","󰤨"];
                    const idx = sig >= 80 ? 4 : sig >= 60 ? 3 : sig >= 40 ? 2 : sig >= 20 ? 1 : 0;
                    root.netIcon = ramp[idx];
                } else root.netIcon = "󰤮";
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { netProbe.running = false; netProbe.running = true; } }

    // ---------- Bluetooth status ----------
    Process {
        id: btProbe
        running: false
        command: ["bash", "-lc",
            "p=$(bluetoothctl show 2>/dev/null | grep -c 'Powered: yes' || echo 0); "
            + "c=$(bluetoothctl devices Connected 2>/dev/null | wc -l); "
            + "if [ \"$p\" = 0 ]; then echo off; "
            + "elif [ \"$c\" -gt 0 ]; then echo on-conn; "
            + "else echo on; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = this.text.trim();
                if (s === "off") root.btIcon = "󰂲";
                else if (s === "on-conn") root.btIcon = "󰂱";
                else root.btIcon = root.icoBtOn;
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { btProbe.running = false; btProbe.running = true; } }

    // ---------- Audio status ----------
    Process {
        id: audioProbe
        running: false
        command: ["bash", "-lc",
            "m=$(pamixer --get-mute 2>/dev/null || echo false); "
            + "if [ \"$m\" = true ]; then echo mute; else echo on; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.audioIcon = this.text.trim() === "mute" ? root.icoMute : root.icoVol3;
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { audioProbe.running = false; audioProbe.running = true; } }

    // ---------- Battery icon helper ----------
    function batteryIcon() {
        const charging = root.batState === "Charging" || root.batState === "Full";
        const c = root.batVal;
        if (charging) {
            const r = ["󰢜","󰂆","󰂇","󰂈","󰢝","󰂉","󰢞","󰂊","󰂋","󰂅"];
            return r[Math.min(9, Math.floor(c / 10))];
        }
        const r = ["󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"];
        return r[Math.min(9, Math.floor(c / 10))];
    }

    // ---------- Panel ----------
    PanelWindow {
        id: bar
        color: "transparent"
        anchors { top: true; left: true; right: true }
        implicitHeight: root.barHeight
        exclusiveZone: root.barHeight

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "omarchy-menu"

        Rectangle {
            anchors.fill: parent
            color: root.bg

            // Faint 静 (stillness) mark, the same character zen uses,
            // pinned to the right and barely visible. Pure decoration.
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: "静"
                color: Qt.rgba(0.773, 0.788, 0.773, 0.07)
                font.family: root.serif
                font.pixelSize: root.barHeight + 6
                font.weight: Font.Light
                z: 0
            }

            // Bottom hairline. One thin line.
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: root.sep
            }

            // Centre cluster: clock + date, anchored to screen centre.
            // Placed outside the RowLayout so its position is independent of
            // the side clusters' widths.
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.hh + ":" + root.mm
                    color: root.ink
                    font.family: root.mono
                    font.pixelSize: 12
                    font.letterSpacing: 2
                    font.weight: Font.Light
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1; height: 10
                    color: root.sumi
                    opacity: 0.4
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.dd + " " + root.mon
                    color: root.sumi
                    font.family: root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 2
                    font.italic: true
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 4

                // ----- Omarchy launcher (seal-red mark) -----
                Module {
                    glyph: root.icoOmarchy
                    color: root.seal
                    fontFamily: "omarchy"
                    fontSize: 14
                    onActivated: root.run("omarchy-menu")
                    onRightActivated: root.run("xdg-terminal-exec")
                }

                Separator {}

                // ----- Workspaces 1..10 as kanji 一二三...十 -----
                Repeater {
                    model: 10
                    delegate: Workspace {
                        required property int index
                        wsId: index + 1
                        label: root.indexKanji(index + 1)
                        active: root.activeWs === (index + 1)
                        present: root.existingWs.indexOf(index + 1) !== -1
                        onActivated: root.run("hyprctl dispatch workspace " + (index + 1))
                    }
                }

                // Flexible spacer; the clock is centre-anchored on the
                // surface above, so this just pushes the tray right.
                Item { Layout.fillWidth: true }

                Separator {}

                // ----- CPU -----
                Module {
                    glyph: "󰍛"
                    color: root.cpuVal > 80 ? root.seal : root.ink
                    onActivated: root.run("omarchy-launch-or-focus-tui btop")
                }

                // ----- Network -----
                Module {
                    glyph: root.netIcon
                    onActivated: root.run("omarchy-launch-wifi")
                }

                // ----- Bluetooth -----
                Module {
                    glyph: root.btIcon
                    onActivated: root.run("omarchy-launch-bluetooth")
                }

                // ----- Audio -----
                Module {
                    glyph: root.audioIcon
                    onActivated: root.run("omarchy-launch-audio")
                    onRightActivated: root.run("pamixer -t")
                }

                // ----- Battery -----
                Module {
                    glyph: root.batteryIcon()
                    color: root.batVal <= 10 ? root.seal : root.batVal <= 20 ? root.indigo : root.ink
                    onActivated: root.run("omarchy-menu power")
                }
            }
        }
    }

    // ---------- Components ----------
    component Separator: Rectangle {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 1
        Layout.preferredHeight: 12
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        color: root.sep
    }

    component Module: Item {
        property string glyph: ""
        property color color: root.ink
        property string fontFamily: root.mono
        property int fontSize: 12

        signal activated()
        signal rightActivated()

        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 24
        Layout.preferredHeight: root.barHeight

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 3
            anchors.bottomMargin: 3
            radius: 0
            color: mouse.containsMouse ? Qt.rgba(0.773, 0.788, 0.773, 0.08) : "transparent"
            Behavior on color { ColorAnimation { duration: 180 } }
        }

        Text {
            anchors.centerIn: parent
            text: glyph
            color: parent.color
            font.family: parent.fontFamily
            font.pixelSize: parent.fontSize
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: (e) => {
                if (e.button === Qt.RightButton) parent.rightActivated();
                else parent.activated();
            }
        }
    }

// Workspace cell. Active = seal red kanji + tiny vermillion dot.
    // Present = ink, no dot. Absent = sumi at low opacity.
    component Workspace: Item {
        property int wsId: 0
        property string label: ""
        property bool active: false
        property bool present: false
        signal activated()

        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 20
        Layout.preferredHeight: root.barHeight

        Text {
            id: kanji
            anchors.centerIn: parent
            text: label
            color: active ? root.seal : (present ? root.ink : root.sumi)
            opacity: active ? 1.0 : (present ? 0.75 : 0.35)
            font.family: root.serif
            font.pixelSize: active ? 14 : 12
            font.weight: Font.Light
            Behavior on color { ColorAnimation { duration: 220 } }
            Behavior on opacity { NumberAnimation { duration: 220 } }
            Behavior on font.pixelSize { NumberAnimation { duration: 220 } }
        }

        // Vermillion seal dot under the active kanji. Same accent as
        // the focused tile in zen.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: kanji.bottom
            anchors.topMargin: -1
            width: 3; height: 3; radius: 1.5
            color: root.seal
            opacity: active ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220 } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.activated()
        }
    }
}
