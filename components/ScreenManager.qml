import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.services as Services
import "../colors" as ColorsModule

Item {
    id: window
    //anchors.fill: parent
    implicitWidth:  450
    implicitHeight: 1000
    focus: true

    property var c: ColorsModule.Colors
    function col(v,f){ return v || f }
    function effectiveScale(m) {
        return (m.scale !== undefined ? m.scale : m.sysScale) || 1.0
    }
    // -------------------------------------------------------------------------
    // STATE & MATH
    // -------------------------------------------------------------------------
    property int activeEditIndex: 0
    property real uiScale: 0.10

    // staring values for restoration purposes
    property var initialSnapshot: []

    // Dynamically tracks whichever monitor is NOT currently selected
    property int stationaryIndex: monitorsModel.count === 2 ? (activeEditIndex === 0 ? 1 : 0) : 0
    
    // Wayland Absolute Anchor tracking
    property int originalLayoutOriginX: 0
    property int originalLayoutOriginY: 0

    ListModel {
        id: monitorsModel
    }
    
    // Replaced hardcoded accents with dynamic defaults
    property color selectedResAccent: window.mauve
    property color selectedRateAccent: window.blue

    property real currentSimW: monitorsModel.count > 0 ? monitorsModel.get(0).resW : 1920
    property real currentSimH: monitorsModel.count > 0 ? monitorsModel.get(0).resH : 1080

    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0
        to: Math.PI * 2
        duration: 90000
        loops: Animation.Infinite
        running: true
    }
    // -------------------------------------------------------------------------
    // FLUID STARTUP ANIMATIONS 
    // -------------------------------------------------------------------------
    property real introProgress: 0.0
    property real monitorScale: 0.85
    property real uiYOffset: 25
    property real screenLight: 0.0

    Component.onCompleted: {
        startupAnim.start()
        updateResolutionSelector()
    }

    ParallelAnimation {
        id: startupAnim
        // Overall window and UI wrapper fades in
        NumberAnimation { target: window; property: "introProgress"; from: 0.0; to: 1.0; duration: 900; easing.type: Easing.OutQuint }
        
        // Monitor physical body scales in slightly
        NumberAnimation { target: window; property: "monitorScale"; from: 0.85; to: 1.0; duration: 1200; easing.type: Easing.OutQuint }
        
        // UI slides upwards gently into place - INCREASED DURATION FOR SLOWER GLIDE
        NumberAnimation { target: window; property: "uiYOffset"; from: 25; to: 0; duration: 1800; easing.type: Easing.OutQuint }
        
        // Inner screen contents fade in slower (powering on effect)
        NumberAnimation { target: window; property: "screenLight"; from: 0.0; to: 1.0; duration: 1500; easing.type: Easing.InOutQuad }
    }
    property bool applyHovered: false
    property bool applyPressed: false

    onActiveEditIndexChanged: {
	menuTransitionAnim.restart();
    }

    // MATHEMATICAL PERIMETER GLUE: Forces a proposed coordinate to perfectly touch the stationary monitor
    function getPerimeterSnap(pX, pY, sX, sY, sW, sH, mW, mH, snapT) {
        let edges = [
            { x1: sX - mW, x2: sX + sW, y1: sY - mH, y2: sY - mH }, // Top Edge
            { x1: sX - mW, x2: sX + sW, y1: sY + sH, y2: sY + sH }, // Bottom Edge
            { x1: sX - mW, x2: sX - mW, y1: sY - mH, y2: sY + sH }, // Left Edge
            { x1: sX + sW, x2: sX + sW, y1: sY - mH, y2: sY + sH }  // Right Edge
        ];

        let bestX = pX;
        let bestY = pY;
        let minDist = 999999;

        for (let i = 0; i < 4; i++) {
            let e = edges[i];
            
            let cx = Math.max(e.x1, Math.min(pX, e.x2));
            let cy = Math.max(e.y1, Math.min(pY, e.y2));

            if (Math.abs(cx - sX) < snapT) cx = sX;
            if (Math.abs(cx - (sX + sW - mW)) < snapT) cx = sX + sW - mW;
            if (Math.abs(cx - (sX + sW/2 - mW/2)) < snapT) cx = sX + sW/2 - mW/2;
            
            if (Math.abs(cy - sY) < snapT) cy = sY;
            if (Math.abs(cy - (sY + sH - mH)) < snapT) cy = sY + sH - mH;
            if (Math.abs(cy - (sY + sH/2 - mH/2)) < snapT) cy = sY + sH/2 - mH/2;

            let dist = Math.hypot(pX - cx, pY - cy);
            if (dist < minDist) {
                minDist = dist;
                bestX = cx;
                bestY = cy;
            }
        }
        return { x: bestX, y: bestY };
    }

    function forceLayoutUpdate() {
        let enabled = enabledIndices()
        if (enabled.length < 2) return
 
        let idx = window.activeEditIndex
        let model = monitorsModel.get(idx)
        if (!model || model.disabled) return
 
        let mW = (model.resW / window.effectiveScale(model)) * window.uiScale
        let mH = (model.resH / window.effectiveScale(model)) * window.uiScale
 
        let best = { x: model.uiX, y: model.uiY, dist: 999999 }
 
        for (let i = 0; i < enabled.length; i++) {
            let otherIdx = enabled[i]
            if (otherIdx === idx) continue
 
            let other = monitorsModel.get(otherIdx)
 
            let oW = (other.resW / window.effectiveScale(other)) * window.uiScale
            let oH = (other.resH / window.effectiveScale(other)) * window.uiScale
 
            let snapped = window.getPerimeterSnap(
                model.uiX, model.uiY,
                other.uiX, other.uiY,
                oW, oH,
                mW, mH,
                20
            )
 
            let dist = Math.abs(snapped.x - model.uiX) + Math.abs(snapped.y - model.uiY)
 
            if (dist < best.dist) {
                best = { x: snapped.x, y: snapped.y, dist: dist }
            }
        }
 
        monitorsModel.setProperty(idx, "uiX", best.x)
        monitorsModel.setProperty(idx, "uiY", best.y)
    }


    function updateResolutionSelector() {
        if (window.activeEditIndex < 0) return
 
        let monitor = monitorsModel.get(window.activeEditIndex)
        if (!monitor || !monitor.availableRes) {
            resolutionSelector.parsedList = []
            resolutionSelector.currentIndex = -1
            return
        }
 
        let list
        try { list = JSON.parse(monitor.availableRes) }
        catch(e) { list = [] }
 
        resolutionSelector.parsedList = list
 
        // ustaw aktualny index
        for (let i = 0; i < list.length; i++) {
            let mode = list[i]
            if (!mode) continue
            let match = mode.match(/(\d+)x(\d+)@([\d.]+)/)
            if (!match) continue
 
            let w = parseInt(match[1])
            let h = parseInt(match[2])
            let r = parseFloat(match[3])
 
            if (w === monitor.resW && h === monitor.resH && Math.round(r) === Math.round(monitor.rate)) {
                resolutionSelector.currentIndex = i
                return
            }
        }
 
        resolutionSelector.currentIndex = -1
    }

    function enabledIndices() {
        let arr = []
        for (let i = 0; i < monitorsModel.count; i++) {
            let m = monitorsModel.get(i)
            if (!m.disabled) arr.push(i)
        }
        return arr
    }

    function takeSnapshot() {
        initialSnapshot = []
        for (let i = 0; i < monitorsModel.count; i++) {
            initialSnapshot.push(JSON.parse(JSON.stringify(monitorsModel.get(i))))
        }
    }

    function restoreSnapshot() {
        if (!initialSnapshot || initialSnapshot.length === 0)
            return

        monitorsModel.clear()
        for (let i = 0; i < initialSnapshot.length; i++) {
            monitorsModel.append(initialSnapshot[i])
        }

        delayedLayoutUpdate.restart()
    }

    function applyConfiguration() {
        for (let i = 0; i < monitorsModel.count; i++) {
            let m = monitorsModel.get(i)
 
            let x = Math.round(m.uiX / uiScale) + originalLayoutOriginX
            let y = Math.round(m.uiY / uiScale) + originalLayoutOriginY
 
            let cmd
 
            if (m.disabled) {
                cmd = `${m.name},disable`
            } else {
                cmd =
                    `${m.name},${m.resW}x${m.resH}@${Math.round(m.rate)},` +
                    `${x}x${y},${m.scale}`
            }
 
            applyProc.command = ["hyprctl", "keyword", "monitor", cmd]
            applyProc.running = true
        }
    }

    function buildKanshiProfile() {
        let profile = "profile auto {\n"
 
        for (let i = 0; i < monitorsModel.count; i++) {
            let m = monitorsModel.get(i)
            if (m.disabled) continue
 
            let x = Math.round(m.uiX / uiScale)
            let y = Math.round(m.uiY / uiScale)
 
            profile +=
                `  output ${m.name} ` +
                `mode ${m.resW}x${m.resH}@${Math.round(m.rate)}Hz ` +
                `position ${x},${y} ` +
                `scale ${m.scale}\n`
        }
 
        profile += "}\n"
        return profile
    }

    function saveConfiguration() {
        let profile = buildKanshiProfile()
 
        saveKanshiProc.command = [
            "bash",
            "-c",
            `mkdir -p ~/.config/kanshi && echo '${profile}' > ~/.config/kanshi/config`
        ]
        saveKanshiProc.running = true
    }

    Timer {
        id: delayedLayoutUpdate
        interval: 10
        running: false
        repeat: false
        onTriggered: window.forceLayoutUpdate()
    }

    // -------------------------------------------------------------------------
    // NATIVE SYSTEM PROCESSES 
    // -------------------------------------------------------------------------
    Process {
        id: displayPoller
        command: ["hyprctl", "monitors", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text.trim());
                    monitorsModel.clear();
                    
                    let minX = 999999, minY = 999999;

                    for (let i = 0; i < data.length; i++) {
                        if (data[i].x < minX) minX = data[i].x;
                        if (data[i].y < minY) minY = data[i].y;
                    }

                    window.originalLayoutOriginX = minX !== 999999 ? minX : 0;
                    window.originalLayoutOriginY = minY !== 999999 ? minY : 0;

                    for (let i = 0; i < data.length; i++) {
                        let scl = data[i].scale !== undefined ? data[i].scale : 1.0;
                        let normalizedX = (data[i].x - minX) * window.uiScale;
                        let normalizedY = (data[i].y - minY) * window.uiScale;

                        monitorsModel.append({
                            name: data[i].name,
                            resW: data[i].width,
                            resH: data[i].height,
                            sysScale: scl,
                            rate: data[i].refreshRate,
                            uiX: normalizedX,
			    uiY: normalizedY,
                            disabled: data[i].disabled || false,
			    scale: data[i].scale || 1.0,
			    description: data[i].description || data[i].name,
			    availableRes: JSON.stringify(data[i].availableModes || [])
                        });

                        if (data[i].focused) window.activeEditIndex = i;
                    }
                    updateResolutionSelector();
		    window.forceLayoutUpdate();
		    window.takeSnapshot();
                } catch(e) {}
            }
        }
    }

    Process {
	id: applyProc
	running: false
    }

    Process {
        id: saveKanshiProc
	running: false
    }

    // -------------------------------------------------------------------------
    // UI LAYOUT
    // -------------------------------------------------------------------------

        ColumnLayout {
            anchors.fill: parent
            spacing: 10
 
            // =========================
            // HEADER
            // =========================
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
 
                Text {
                    text: "Screen Manager"
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    color: col(c.on_surface, "#ffffff")
                }
 
                Button {
                    Layout.preferredWidth: 70
                    onClicked: window.applyConfiguration()
 
                    contentItem: Text {
                        text: "Apply"
                        color: col(c.on_surface, "#0af")
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 14
                    }
 
                    background: Rectangle {
                        radius: 10
                        color: col(c.primary_container, "#222")
                    }
                }
 
                Button {
                    Layout.preferredWidth: 70
                    onClicked: window.saveConfiguration()
 
                    contentItem: Text {
                        text: "Save"
                        color: col(c.on_surface, "#0af")
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 14
                    }
 
                    background: Rectangle {
                        radius: 10
                        color: col(c.primary_container, "#222")
                    }
                }
 
                Button {
                    Layout.preferredWidth: 80
                    onClicked: window.restoreSnapshot()
 
                    contentItem: Text {
                        text: "Restore"
                        color: col(c.on_surface, "#0af")
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 14
                    }
 
                    background: Rectangle {
                        radius: 10
                        color: col(c.primary_container, "#222")
                    }
                }
            }
 
            // =========================
            // MONITOR CANVAS
            // =========================
            Item {
                //anchors.fill: parent
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                scale: 0.95 + (0.05 * window.introProgress)
                opacity: window.introProgress
  
                Rectangle {
                    anchors.fill: parent
                    radius: 30
                    color: window.base
                    border.color: window.surface0
                    border.width: 1
                    clip: true
  
                    Rectangle {
                        width: parent.width * 0.8
                        height: width
                        radius: width / 2
                        x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * 150
                        y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * 100
                        opacity: 0.04
                        color: window.selectedResAccent
                        Behavior on color { ColorAnimation { duration: 1000 } }
                    }
                    Rectangle {
                        width: parent.width * 0.9
                        height: width
                        radius: width / 2
                        x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * -150
                        y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * -100
                        opacity: 0.04
                        color: window.selectedRateAccent
                        Behavior on color { ColorAnimation { duration: 1000 } }
                    }
  
                    // ==========================================
                    // LEFT SIDE VISUAL AREA
                    // ==========================================
                    Item {
                        id: leftVisualArea
                        width: 380
                        height: 300
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 20
  
                        // --------------------------------------------------
                        // MODE 2: MULTI-MONITOR
                        // --------------------------------------------------
                        Item {
                            anchors.fill: parent
                            visible: monitorsModel.count > 1
  
                            Item {
                                id: multiMonitorView
                                width: 380
                                height: 280
                                anchors.centerIn: parent
                                clip: true 
  
                                Grid {
                                    anchors.centerIn: parent
                                    rows: 25
                                    columns: 34
                                    spacing: 18
                                    Repeater { 
                                        model: 850
                                        Rectangle { width: 2; height: 2; radius: 1; color: Qt.alpha(window.text, 0.1) } 
                                    }
                                }
  
                                // Perfect mathematical scale: Centers the Bounding Box of both monitors
                                property real targetScale: {
                                    let enabled = window.enabledIndices()
                                    if (enabled.length === 0) return 1.0
        
                                    let minX = 999999
                                    let minY = 999999
                                    let maxX = -999999
                                    let maxY = -999999
        
                                    for (let i = 0; i < enabled.length; i++) {
                                        let m = monitorsModel.get(enabled[i])
        
                                        let w = (m.resW / window.effectiveScale(m)) * window.uiScale
                                        let h = (m.resH / window.effectiveScale(m)) * window.uiScale
        
                                        minX = Math.min(minX, m.uiX)
                                        minY = Math.min(minY, m.uiY)
                                        maxX = Math.max(maxX, m.uiX + w)
                                        maxY = Math.max(maxY, m.uiY + h)
                                    }
        
                                    let requiredW = (maxX - minX) + 80
                                    let requiredH = (maxY - minY) + 80
        
                                    return Math.min(1.8, Math.min(340 / requiredW, 240 / requiredH))
                                }

                                // Centering math: Keep the bounding box perfectly centered in the 380x280 view
				property real offsetX: {
                                    let enabled = window.enabledIndices()
                                    if (enabled.length === 0) return 0
        
                                    let minX = 999999
                                    let maxX = -999999
        
                                    for (let i = 0; i < enabled.length; i++) {
                                        let m = monitorsModel.get(enabled[i])
                                        let w = (m.resW / window.effectiveScale(m)) * window.uiScale
        
                                        minX = Math.min(minX, m.uiX)
                                        maxX = Math.max(maxX, m.uiX + w)
                                    }
        
                                    let centerX = minX + (maxX - minX) / 2
                                    return 190 - (centerX * targetScale)
                                }
                                
				property real offsetY: {
                                    let enabled = window.enabledIndices()
                                    if (enabled.length === 0) return 0
        
                                    let minY = 999999
                                    let maxY = -999999
        
                                    for (let i = 0; i < enabled.length; i++) {
                                        let m = monitorsModel.get(enabled[i])
                                        let h = (m.resH / window.effectiveScale(m)) * window.uiScale
        
                                        minY = Math.min(minY, m.uiY)
                                        maxY = Math.max(maxY, m.uiY + h)
                                    }
        
                                    let centerY = minY + (maxY - minY) / 2
                                    return 140 - (centerY * targetScale)
                                }
  
                                Item {
                                    id: transformNode
                                    x: multiMonitorView.offsetX
                                    y: multiMonitorView.offsetY
                                    scale: multiMonitorView.targetScale
                                    transformOrigin: Item.TopLeft
  
                                    Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                                    Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                                    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
  
                                    Repeater {
                                        id: monitorRepeater
                                        model: monitorsModel
  
                                        Item {
					    property bool isActive: window.activeEditIndex === index
					    visible: !model.disabled
  
                                            // THE VISIBLE SNAPPED MONITOR CARD
                                            Rectangle {
                                                id: monitorCard
                                                x: model.uiX
                                                y: model.uiY
                                                
                                                width: (model.resW / window.effectiveScale(model)) * window.uiScale
                                                height: (model.resH / window.effectiveScale(model)) * window.uiScale
                                                
                                                radius: 8
                                                color: isActive ? window.surface1 : window.crust
                                                border.color: isActive ? window.selectedResAccent : window.surface2
                                                border.width: isActive ? 2 : 1
                                                z: isActive ? 5 : 0
  
                                                Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                                                Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                                                
                                                Behavior on border.color { ColorAnimation { duration: 300 } }
                                                Behavior on color { ColorAnimation { duration: 300 } }
                                                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                                                Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
  
                                                Item {
                                                    anchors.centerIn: parent
                                                    width: 110
                                                    height: 80
                                                    
                                                    property real idealScale: Math.min(1.2, parent.width / 110, parent.height / 80) / transformNode.scale
                                                    property real maxPhysicalScale: Math.min((parent.width * 0.9) / width, (parent.height * 0.9) / height)
                                                    scale: Math.min(idealScale, maxPhysicalScale)
                                                    
                                                    ColumnLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 2
                                                        Text { 
                                                            Layout.alignment: Qt.AlignHCenter
                                                            font.family: "Iosevka Nerd Font"
                                                            font.pixelSize: 32
                                                            color: isActive ? window.selectedResAccent : window.text
                                                            text: "󰍹"
                                                            Behavior on color { ColorAnimation { duration: 300 } } 
                                                        }
                                                        Text { 
                                                            Layout.alignment: Qt.AlignHCenter
                                                            font.family: "JetBrains Mono"
                                                            font.weight: Font.Black
                                                            font.pixelSize: 13
                                                            color: window.text
                                                            text: model.name 
                                                        }
                                                        Text { 
                                                            Layout.alignment: Qt.AlignHCenter
                                                            font.family: "JetBrains Mono"
                                                            font.pixelSize: 10
                                                            color: window.subtext0
                                                            text: model.resW + "x" + model.resH + " @ " + model.rate + "Hz" 
                                                        }
                                                    }
                                                }
                                            }
  
                                            // THE INVISIBLE GHOST DRAGGER
                                            Item {
						id: ghostDrag
                                                visible: !model.disabled
                                                x: model.uiX
                                                y: model.uiY
                                                width: monitorCard.width
                                                height: monitorCard.height
                                                z: isActive ? 10 : 1
  
                                                MouseArea {
                                                    id: ghostMa
                                                    anchors.fill: parent
                                                    drag.target: ghostDrag
                                                    drag.axis: Drag.XAndYAxis
                                                    
                                                    onPressed: {
                                                        window.activeEditIndex = index;
                                                        ghostDrag.x = model.uiX;
                                                        ghostDrag.y = model.uiY;
                                                    }
  
                                                    onPositionChanged: {
                                                        if (!drag.active) return
             
                                                        let enabled = window.enabledIndices()
                                                        if (enabled.length < 2) return
             
                                                        let best = { x: ghostDrag.x, y: ghostDrag.y, dist: 999999 }
             
                                                        for (let i = 0; i < enabled.length; i++) {
                                                            let otherIdx = enabled[i]
                                                            if (otherIdx === index) continue
             
                                                            let other = monitorsModel.get(otherIdx)
             
                                                            let oW = (other.resW / window.effectiveScale(other)) * window.uiScale
                                                            let oH = (other.resH / window.effectiveScale(other)) * window.uiScale
             
                                                            let snapped = window.getPerimeterSnap(
                                                                ghostDrag.x, ghostDrag.y,
                                                                other.uiX, other.uiY,
                                                                oW, oH,
                                                                monitorCard.width,
                                                                monitorCard.height,
                                                                20
                                                            )
             
                                                            let dist = Math.abs(snapped.x - ghostDrag.x) + Math.abs(snapped.y - ghostDrag.y)
             
                                                            if (dist < best.dist)
                                                                best = { x: snapped.x, y: snapped.y, dist: dist }
                                                        }
             
                                                        monitorsModel.setProperty(index, "uiX", best.x)
                                                        monitorsModel.setProperty(index, "uiY", best.y)
                                                    }

                                                    onReleased: {
                                                        ghostDrag.x = model.uiX;
                                                        ghostDrag.y = model.uiY;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // =================================================
            // MONITOR CONFIGURATION
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 280
                radius: 12
                color: col(c.surface_container, "#1c1c1c")
                anchors.topMargin: 10
		clip: true

                ColumnLayout {
                    anchors.margins: 16
                    spacing: 12
            
                    // =====================
                    // Wybór monitora
                    // =====================
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
            
                        Text {
                            text: "Select Monitor:"
                            font.pixelSize: 14
                            color: col(c.on_surface, "#ffffff")
                            Layout.alignment: Qt.AlignVCenter
                        }
            
                        ComboBox {
                            id: monitorSelector
			    implicitWidth: 150
                            implicitHeight: 36
                            model: monitorsModel
                            textRole: "name"
			    currentIndex: window.activeEditIndex

			    contentItem: Text {
                                text: monitorSelector.displayText
                                color: col(c.on_surface, "#ffffff")
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                leftPadding: 8
			    }

			    indicator: Text {
                                text: "▾"
                                color: col(c.on_surface, "#ffffff")   // kolor strzałki
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            delegate: ItemDelegate {
                                width: parent.width
                                text: model.name
                                contentItem: Text {
                                    text: model.name
                                    color: col(c.on_surface, "#ffffff")
                                    verticalAlignment: Text.AlignVCenter
			        }
                                background: Rectangle {
                                    color: highlighted
                                           ? col(c.primary_container, "#333")
                                           : col(c.surface_container, "#1e1e1e")
                                }
                            }

			    background: Rectangle {
                                radius: 8
                                color: col(c.surface_container_high, "#2a2a2a")
                                border.width: 1
                                border.color: col(c.outline, "#444")
                            }

                            popup: Popup {
                                y: monitorSelector.height
                                width: monitorSelector.width
       
                                background: Rectangle {
                                    radius: 8
                                    color: col(c.surface_container, "#1e1e1e")
                                    border.color: col(c.outline, "#444")
                                }
       
                                contentItem: ListView {
                                    clip: true
                                    //implicitHeight: contentHeight
                                    model: monitorSelector.delegateModel
                                    currentIndex: monitorSelector.highlightedIndex
				    //implicitHeight: 150
				    implicitHeight: Math.min(contentHeight, 150)
                                    ScrollIndicator.vertical: ScrollIndicator { }
                                }
                            }

                            onCurrentIndexChanged: {
                                if (currentIndex >= 0 && currentIndex < monitorsModel.count) {
                                    window.activeEditIndex = currentIndex;
                                }
                            }
                        }
           
                        // =====================
                        // Switch włącz/wyłącz monitor
			// =====================
			Rectangle {
                            id: monitorSwitch
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 26
                            radius: height / 2
      
                            property bool checked: false
      
                            function refresh() {
                                if (window.activeEditIndex >= 0 && monitorsModel.count > 0) {
                                    let m = monitorsModel.get(window.activeEditIndex)
                                    checked = m ? !m.disabled : false
                                } else {
                                    checked = false
                                }
                            }
      
                            Component.onCompleted: refresh()
      
                            color: checked
                                ? col(c.primary, "#4a90e2")
                                : col(c.surface_container_high, "#333")
      
                            Rectangle {
                                width: 20
                                height: 20
                                radius: 10
                                y: 3
                                x: monitorSwitch.checked
                                    ? parent.width - width - 3
                                    : 3
      
                                color: col(c.on_surface, "#ffffff")
      
                                Behavior on x {
                                    NumberAnimation { duration: 150 }
                                }
                            }
      
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
      
                                onClicked: {
                                    if (window.activeEditIndex < 0)
                                        return
      
                                    monitorSwitch.checked = !monitorSwitch.checked
      
                                    monitorsModel.setProperty(
                                        window.activeEditIndex,
                                        "disabled",
                                        !monitorSwitch.checked
                                    )
      
                                    delayedLayoutUpdate.restart()
                                }
                            }
      
                            Connections {
                                target: window
                                function onActiveEditIndexChanged() {
                                    monitorSwitch.refresh()
                                }
                            }
      
                            Connections {
                                target: monitorsModel
                                function onCountChanged() {
                                    monitorSwitch.refresh()
                                }
                                function onDataChanged() {
                                    monitorSwitch.refresh()
                                }
                            }
                        }
		    }

                    // =====================
                    // Parametry monitora (pokazywane tylko jeśli monitor jest włączony)
                    // =====================

                    Item {
                        id: monitorDetails
                        visible: window.activeEditIndex >= 0 ? !monitorsModel.get(window.activeEditIndex).disabled : false
                        Layout.fillWidth: true
                    
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8
                    
                            Text {
                                text: {
                                    if (window.activeEditIndex < 0 || monitorsModel.count === 0) return "";
                                    let m = monitorsModel.get(window.activeEditIndex);
                                    return m.description;
                                }
                                font.pixelSize: 13
                                color: col(c.on_surface_variant, "#bbbbbb")
                            }
                    
                            // Skala
                            RowLayout {
                                spacing: 8
				Text { text: "Scale:"; font.pixelSize: 13; color: col(c.on_surface_variant, "#bbbbbb") }
				Slider {
                                    id: scaleSlider
                                    from: 0.5
                                    to: 3.0
                                    stepSize: 0.05
                                
                                    value: window.activeEditIndex >= 0 && monitorsModel.count > 0
                                           ? monitorsModel.get(window.activeEditIndex).scale || 1.0
                                           : 1.0
                                
                                    onMoved: {
                                        if (window.activeEditIndex >= 0) {
                                            monitorsModel.setProperty(window.activeEditIndex, "scale", value)
                                            delayedLayoutUpdate.restart()
                                        }
                                    }
                                }
                                Text { text: scaleSlider.value.toFixed(2) + "x"; font.pixelSize: 13; color: col(c.on_surface_variant, "#bbbbbb") }
                            }
                    
			    // Lista dostępnych rozdzielczości
			    ComboBox {
                               id: resolutionSelector
                               Layout.fillWidth: true
                             
                               property var parsedList: []
                             
                               model: parsedList
                             
                               // =========================
                               // TEKST WYBRANEJ WARTOŚCI
                               // =========================
                               contentItem: Text {
                                   text: resolutionSelector.displayText
                                   color: col(c.on_surface, "#ffffff")   // kolor czcionki
                                   verticalAlignment: Text.AlignVCenter
                                   elide: Text.ElideRight
                                   leftPadding: 8
                               }
                             
                               // =========================
                               // STRZAŁKA
                               // =========================
                               indicator: Text {
                                   text: "▾"
                                   color: col(c.on_surface, "#ffffff")
                                   anchors.right: parent.right
                                   anchors.rightMargin: 8
                                   anchors.verticalCenter: parent.verticalCenter
                               }
                             
                               // =========================
                               // TŁO COMBOBOX
                               // =========================
                               background: Rectangle {
                                   radius: 8                       // zaokrąglenie
                                   color: col(c.surface_container_high, "#2a2a2a")
                                   border.width: 1
                                   border.color: col(c.outline, "#444")
                               }
                             
                               // =========================
                               // ELEMENTY LISTY
                               // =========================
                               delegate: ItemDelegate {
                                   width: parent.width
                                   text: modelData ? modelData : ""
                             
                                   contentItem: Text {
                                       text: modelData ? modelData : ""
                                       color: highlighted
                                              ? col(c.on_primary, "#000000")
                                              : col(c.on_surface, "#ffffff")
                                       verticalAlignment: Text.AlignVCenter
                                       elide: Text.ElideRight
                                   }
                             
                                   background: Rectangle {
                                       radius: 6
                                       color: highlighted
                                              ? col(c.primary_container, "#333")
                                              : col(c.surface_container, "#1e1e1e")
                                   }
                               }
                             
                               // =========================
                               // POPUP TŁO
                               // =========================
                               popup: Popup {
                                   y: resolutionSelector.height
				   width: resolutionSelector.width
                             
                                   background: Rectangle {
				       radius: 8
                                       color: col(c.surface_container, "#1e1e1e")
                                       border.color: col(c.outline, "#444")
                                   }
                             
                                   contentItem: ListView {
                                       clip: true
                                       model: resolutionSelector.delegateModel
                                       currentIndex: resolutionSelector.highlightedIndex
                                       implicitHeight: Math.min(contentHeight, 150)
                                       ScrollIndicator.vertical: ScrollIndicator { }
                                   }
                               }
                             
                               // =========================
                               // LOGIKA (BEZ ZMIAN)
                               // =========================
                               onActivated: function(index) {
                                   let list = parsedList
                                   if (!list || index >= list.length) return
                             
                                   let mode = list[index]
                                   if (!mode) return
                             
                                   let match = mode.match(/(\d+)x(\d+)@([\d.]+)/)
                                   if (!match) return
                             
                                   monitorsModel.setProperty(window.activeEditIndex, "resW", parseInt(match[1]))
                                   monitorsModel.setProperty(window.activeEditIndex, "resH", parseInt(match[2]))
                                   monitorsModel.setProperty(window.activeEditIndex, "rate", parseFloat(match[3]))
                             
                                   delayedLayoutUpdate.restart()
                               }
                             
                               Connections {
                                   target: window
                                   function onActiveEditIndexChanged() {
                                       updateResolutionSelector()
                                   }
                               }
                            }
                        }
                    }
                }
	    }

            // =================================================
            // WALLPAPER SELECTOR
            // =================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 460
                radius: 12
                color: col(c.surface_container, "#1c1c1c")
 
            }
        }
}
