import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "local.power-mode"
  ipcTarget: "local.power-mode"
  manageIpc: false

  property string activeProfile: "custom"
  property string profileName: "Custom Power Limit"
  property int cpuPL1: 35
  property int cpuPL2: 55
  property string cpuEPP: "balance_performance"
  property string platformProfile: "performance"
  property string gpuDraw: "0 W"
  property int gpuLimit: 60
  property string gpuTemp: "0 °C"

  property int previewCpuPL1: -1
  property int previewGpuLimit: -1

  readonly property var profileKeys: ["gpu", "cachy", "balanced", "cpu"]
  readonly property var profileLabels: ["GPU", "Cachy", "Balanced", "CPU"]

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function displayCpuPL1() {
    return previewCpuPL1 >= 0 ? previewCpuPL1 : cpuPL1
  }

  function displayGpuLimit() {
    return previewGpuLimit >= 0 ? previewGpuLimit : gpuLimit
  }

  function heroSubtitle() {
    var prof = activeProfile.toUpperCase()
    if (prof === "GPU") return "GPU MODE · 95W GPU / 35W CPU"
    if (prof === "CACHY") return "CACHYOS MAX · 95W GPU / 85W CPU"
    if (prof === "BALANCED") return "BALANCED · 60W GPU / 25W CPU"
    if (prof === "CPU") return "CPU MODE · 40W GPU / 85W CPU"
    return "CUSTOM · " + displayGpuLimit() + "W GPU / " + displayCpuPL1() + "W CPU"
  }

  function refresh() {
    if (!stateProc.running) stateProc.running = true
  }

  function setProfile(key) {
    previewCpuPL1 = -1
    previewGpuLimit = -1
    root.activeProfile = key
    if (key === "gpu") {
      root.cpuPL1 = 35
      root.gpuLimit = 95
    } else if (key === "cachy") {
      root.cpuPL1 = 85
      root.gpuLimit = 95
    } else if (key === "balanced") {
      root.cpuPL1 = 25
      root.gpuLimit = 60
    } else if (key === "cpu") {
      root.cpuPL1 = 85
      root.gpuLimit = 40
    }
    actionProc.command = ["power-mode", "--" + key]
    if (!actionProc.running) actionProc.running = true
  }

  function applyCustomLimits(cpu, gpu) {
    actionProc.command = ["power-mode", "--custom", String(cpu), String(gpu)]
    if (!actionProc.running) actionProc.running = true
  }

  IpcHandler {
    target: "local.power-mode"
    function open() { root.open() }
    function close() { root.close() }
    function toggle() { root.toggle() }
    function refresh() { root.refresh() }
  }

  Component.onCompleted: refresh()

  onOpenedChanged: {
    if (opened) {
      refresh()
      previewCpuPL1 = -1
      previewGpuLimit = -1
    }
  }

  Timer {
    interval: 3000
    running: root.opened
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: stateProc
    command: ["power-mode", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var d = JSON.parse(text)
          root.activeProfile = d.active_profile || "custom"
          root.profileName = d.profile_name || "Custom"
          root.cpuPL1 = parseInt(d.cpu_pl1_w) || 35
          root.cpuPL2 = parseInt(d.cpu_pl2_w) || 55
          root.cpuEPP = d.cpu_epp || "balance_performance"
          root.platformProfile = d.platform_profile || "performance"
          root.gpuDraw = d.gpu_power_draw || "0 W"
          root.gpuTemp = d.gpu_temp || "0 °C"

          var gLim = String(d.gpu_power_limit || "").replace("W", "").trim()
          root.gpuLimit = parseInt(gLim) || 60
        } catch (e) {}
      }
    }
  }

  Process {
    id: actionProc
    onExited: root.refresh()
  }

  Timer {
    id: applyDebounce
    interval: 350
    repeat: false
    onTriggered: {
      var c = root.displayCpuPL1()
      var g = root.displayGpuLimit()
      root.applyCustomLimits(c, g)
    }
  }

  // --- Bar Icon (Symbol Only) ---
  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "⚡"
    tooltipText: "Power Mode: " + root.activeProfile.toUpperCase() + " (" + root.cpuPL1 + "W / " + root.gpuLimit + "W)"
    onPressed: function(b) {
      root.toggle()
    }
  }

  // --- Popup Panel (Styled like Display / Monitor panel) ---
  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(panelColumn.implicitHeight, Style.space(560))

    ScrollView {
      id: scrollArea
      anchors.fill: parent
      clip: true
      ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
      ScrollBar.vertical.policy: panelColumn.implicitHeight > height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff

      Column {
        id: panelColumn
        width: scrollArea.availableWidth
        spacing: Style.space(14)

        // ---------- Hero: Power Icon · Title / Subtitle ----------
        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

          Text {
            id: heroIcon
            text: "⚡"
            color: root.barForeground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "Power Mode"
              color: root.barForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              text: root.heroSubtitle()
              color: Qt.darker(root.barForeground, 1.4)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }
        }

        // ---------- Section 1: Presets / Profiles ----------
        PanelSeparator {
          foreground: root.barForeground
        }

        Column {
          width: parent.width
          spacing: Style.space(8)

          PanelSectionHeader {
            text: "PROFILES"
            foreground: root.barForeground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          }

          Row {
            id: profileRow
            width: parent.width
            spacing: Style.space(6)

            readonly property real cellWidth: (width - spacing * (root.profileKeys.length - 1)) / root.profileKeys.length

            Repeater {
              model: root.profileKeys
              Button {
                required property string modelData
                required property int index

                width: profileRow.cellWidth
                text: root.profileLabels[index]
                fontSize: Style.font.bodySmall
                foreground: root.barForeground
                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                horizontalPadding: Style.space(4)
                verticalPadding: Style.space(6)
                bordered: true
                selected: root.activeProfile === modelData
                active: root.activeProfile === modelData
                onClicked: {
                  root.activeProfile = modelData
                  root.setProfile(modelData)
                }
              }
            }
          }
        }

        // ---------- Section 2: CPU Sustained Limit (PL1) ----------
        PanelSeparator {
          foreground: root.barForeground
        }

        Column {
          width: parent.width
          spacing: Style.space(6)

          Item {
            width: parent.width
            implicitHeight: Math.max(cpuHeader.implicitHeight, cpuValueLabel.implicitHeight)

            PanelSectionHeader {
              id: cpuHeader
              text: "CPU SUSTAINED (PL1)"
              foreground: root.barForeground
              fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              id: cpuValueLabel
              text: root.displayCpuPL1() + " W"
              color: Qt.darker(root.barForeground, 1.4)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              anchors.right: parent.right
              anchors.rightMargin: Style.space(6)
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          CursorSurface {
            id: cpuSliderRow
            width: parent.width
            height: cpuSlider.implicitHeight + Style.spacing.controlGap
            foreground: root.barForeground
            outline: true

            PanelSlider {
              id: cpuSlider
              bar: root.bar
              anchors.fill: parent
              anchors.leftMargin: Style.space(6)
              anchors.rightMargin: Style.space(6)
              minimum: 15
              maximum: 115
              step: 5
              integer: true
              value: root.displayCpuPL1()
              onMoved: function(v) {
                root.previewCpuPL1 = Math.round(v)
              }
              onReleased: function(v) {
                root.previewCpuPL1 = Math.round(v)
                applyDebounce.restart()
              }
            }
          }
        }

        // ---------- Section 3: GPU Power Limit (TGP) ----------
        PanelSeparator {
          foreground: root.barForeground
        }

        Column {
          width: parent.width
          spacing: Style.space(6)

          Item {
            width: parent.width
            implicitHeight: Math.max(gpuHeader.implicitHeight, gpuValueLabel.implicitHeight)

            PanelSectionHeader {
              id: gpuHeader
              text: "GPU POWER LIMIT (TGP)"
              foreground: root.barForeground
              fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              id: gpuValueLabel
              text: root.displayGpuLimit() + " W"
              color: Qt.darker(root.barForeground, 1.4)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              anchors.right: parent.right
              anchors.rightMargin: Style.space(6)
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          CursorSurface {
            id: gpuSliderRow
            width: parent.width
            height: gpuSlider.implicitHeight + Style.spacing.controlGap
            foreground: root.barForeground
            outline: true

            PanelSlider {
              id: gpuSlider
              bar: root.bar
              anchors.fill: parent
              anchors.leftMargin: Style.space(6)
              anchors.rightMargin: Style.space(6)
              minimum: 10
              maximum: 100
              step: 5
              integer: true
              value: root.displayGpuLimit()
              onMoved: function(v) {
                root.previewGpuLimit = Math.round(v)
              }
              onReleased: function(v) {
                root.previewGpuLimit = Math.round(v)
                applyDebounce.restart()
              }
            }
          }
        }

        // ---------- Section 4: Live Hardware Telemetry ----------
        PanelSeparator {
          foreground: root.barForeground
        }

        Column {
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: "LIVE TELEMETRY"
            foreground: root.barForeground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          }

          Row {
            width: parent.width
            spacing: Style.space(20)

            Column {
              width: (parent.width - parent.spacing) / 2
              spacing: Style.space(4)
              InfoPair { label: "CPU Burst (PL2)"; value: root.cpuPL2 + " W" }
              InfoPair { label: "CPU EPP"; value: root.formatEpp(root.cpuEPP) }
            }

            Column {
              width: (parent.width - parent.spacing) / 2
              spacing: Style.space(4)
              InfoPair { label: "GPU Draw"; value: root.gpuDraw }
              InfoPair { label: "GPU Temp"; value: root.gpuTemp }
            }
          }
        }
      }
    }
  }

  function formatEpp(epp) {
    var s = String(epp || "").toLowerCase()
    if (s.indexOf("balance_perf") >= 0) return "Balanced"
    if (s.indexOf("balance_power") >= 0) return "Power Saver"
    if (s.indexOf("perf") >= 0) return "Performance"
    if (s.indexOf("power") >= 0) return "Power Saver"
    return s ? s.charAt(0).toUpperCase() + s.slice(1) : "—"
  }

  component InfoPair: Item {
    property string label: ""
    property string value: ""

    width: parent.width
    implicitHeight: Math.max(lbl.implicitHeight, val.implicitHeight)

    Text {
      id: lbl
      text: label
      color: root.barForeground
      opacity: 0.6
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.bodySmall
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      elide: Text.ElideRight
      width: Math.min(implicitWidth, parent.width - val.implicitWidth - Style.space(6))
    }

    Text {
      id: val
      text: value
      color: root.barForeground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.bodySmall
      font.bold: true
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
