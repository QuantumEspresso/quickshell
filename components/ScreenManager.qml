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

    Component.onCompleted: startupAnim.start()

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
	updateResolutionSelector();
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
        if (window.activeEditIndex < 0) return;
        let monitor = monitorsModel.get(window.activeEditIndex);
        if (!monitor || !monitor.availableRes) return;
   
        for (let i = 0; i < monitor.availableRes.length; i++) {
            let r = monitor.availableRes[i];
            if (r.width === monitor.resW &&
                r.height === monitor.resH &&
                Math.round(r.refresh) === Math.round(monitor.rate)) {
                resolutionSelector.currentIndex = i;
                return;
            }
        }
        resolutionSelector.currentIndex = -1; // fallback
    }

    function enabledIndices() {
        let arr = []
        for (let i = 0; i < monitorsModel.count; i++) {
            let m = monitorsModel.get(i)
            if (!m.disabled) arr.push(i)
        }
        return arr
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
			    availableRes: (data[i].availableModes || []).map(function(m) {
                                let match = m.match(/(\d+)x(\d+)@([\d.]+)Hz/)
                                if (!match) return null
                            
                                return {
                                    width: parseInt(match[1]),
                                    height: parseInt(match[2]),
                                    refresh: parseFloat(match[3])
                                }
                            }).filter(function(v){ return v !== null })
                        });

                        if (data[i].focused) window.activeEditIndex = i;
                    }
                    updateResolutionSelector();
                    window.forceLayoutUpdate();
                } catch(e) {}
            }
        }
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
                    onClicked: {}
 
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
                    onClicked: {}
 
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
                    onClicked: {}
 
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
                        // MODE 1: SINGLE MONITOR
                        // --------------------------------------------------
                        Item {
                            anchors.fill: parent
                            visible: monitorsModel.count === 1
  
                            Item {
                                id: singleMonitorZoom
                                anchors.centerIn: parent
                                width: 380
                                height: 280
                                
                                property real baseScale: Math.min(1.0, 2200 / window.currentSimW)
                                scale: baseScale * window.monitorScale
                                opacity: window.introProgress
                                Behavior on baseScale { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
  
                                Rectangle {
                                    id: deskSurface
                                    width: 1000
                                    height: 14
                                    radius: 6
                                    anchors.top: standBase.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: window.mantle
                                    border.color: window.surface0
                                    border.width: 1
  
                                    Rectangle { 
                                        width: 24
                                        height: 350
                                        radius: 4
                                        color: window.crust
                                        anchors.top: parent.bottom
                                        anchors.topMargin: -5
                                        anchors.left: parent.left
                                        anchors.leftMargin: 100
                                        z: -1 
                                    }
                                    Rectangle { 
                                        width: 24
                                        height: 350
                                        radius: 4
                                        color: window.crust
                                        anchors.top: parent.bottom
                                        anchors.topMargin: -5
                                        anchors.right: parent.right
                                        anchors.rightMargin: 100
                                        z: -1 
                                    }
                                }
  
                                Rectangle {
                                    id: standBase
                                    width: 130
                                    height: 8
                                    radius: 4
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 20
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: window.surface1
                                }
                                
                                Rectangle {
                                    id: standNeck
                                    width: 34
                                    height: 70
                                    anchors.bottom: standBase.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: window.surface0
                                    Rectangle { 
                                        width: 10
                                        height: 30
                                        radius: 5
                                        anchors.centerIn: parent
                                        color: window.base 
                                    }
                                }
  
                                Rectangle {
                                    id: screenBezel
                                    width: 140 + (180 * (window.currentSimW / 1920))
                                    height: 90 + (90 * (window.currentSimH / 1080))
                                    anchors.bottom: standNeck.top
                                    anchors.bottomMargin: -10
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    radius: 12
                                    color: window.crust
                                    border.color: window.surface2
                                    border.width: 2
                                    
                                    Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
                                    Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
  
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        radius: 6
                                        color: window.surface0
                                        clip: true
  
                                        // This inner block handles the "powering on" visual delay
                                        Rectangle {
                                            anchors.fill: parent
                                            color: "transparent"
                                            opacity: window.screenLight
                                            
                                            gradient: Gradient {
                                                orientation: Gradient.Vertical
                                                GradientStop { 
                                                    position: 0.0
                                                    color: Qt.tint(window.surface0, Qt.alpha(window.selectedResAccent, 0.15))
                                                    Behavior on color { ColorAnimation { duration: 400 } } 
                                                }
                                                GradientStop { 
                                                    position: 1.0
                                                    color: Qt.tint(window.surface0, Qt.alpha(window.selectedRateAccent, 0.1))
                                                    Behavior on color { ColorAnimation { duration: 400 } } 
                                                }
                                            }
                                            
                                            Grid { 
                                                anchors.centerIn: parent
                                                rows: 10
                                                columns: 15
                                                spacing: 20
                                                Repeater { 
                                                    model: 150
                                                    Rectangle { width: 2; height: 2; radius: 1; color: Qt.alpha(window.text, 0.1) } 
                                                } 
                                            }
  
                                            Item {
                                                anchors.centerIn: parent
                                                scale: 1.0 / singleMonitorZoom.scale
                                                
                                                ColumnLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 4
                                                    Text { 
                                                        Layout.alignment: Qt.AlignHCenter
                                                        font.family: "Iosevka Nerd Font"
                                                        font.pixelSize: 38
                                                        color: window.selectedResAccent
                                                        text: "󰍹"
                                                        Behavior on color { ColorAnimation { duration: 400 } } 
                                                    }
                                                    Text { 
                                                        Layout.alignment: Qt.AlignHCenter
                                                        font.family: "JetBrains Mono"
                                                        font.weight: Font.Bold
                                                        font.pixelSize: 16
                                                        color: window.text
                                                        text: monitorsModel.count > 0 ? monitorsModel.get(0).name : "Unknown" 
                                                    }
                                                    Text { 
                                                        Layout.alignment: Qt.AlignHCenter
                                                        font.family: "JetBrains Mono"
                                                        font.pixelSize: 12
                                                        color: window.subtext0
                                                        text: window.currentSimW + "x" + window.currentSimH + " @ " + (monitorsModel.count > 0 ? monitorsModel.get(0).rate : "60") + "Hz" 
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
  
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
                            Layout.fillWidth: true
                            model: monitorsModel
                            textRole: "name"
                            currentIndex: window.activeEditIndex
           
                            onCurrentIndexChanged: {
                                if (currentIndex >= 0 && currentIndex < monitorsModel.count) {
                                    window.activeEditIndex = currentIndex;
                                }
                            }
                        }
           
                        // =====================
                        // Switch włącz/wyłącz monitor
			// =====================
                        Switch {
                            id: monitorSwitch
			    checked: window.activeEditIndex >= 0 ? !monitorsModel.get(window.activeEditIndex).disabled : false
			    onToggled: {
                                if (window.activeEditIndex >= 0) {
                                    monitorsModel.setProperty(
                                        window.activeEditIndex,
                                        "disabled",
                                        !checked
                                    )
                            
                                    delayedLayoutUpdate.restart()
                                }
                            }
                       
                            // Aktualizacja automatyczna, gdy zmienia się activeEditIndex lub disabled
                            Connections {
				target: monitorsModel
                                onCountChanged: {
                                    // Jeśli monitorów jest przynajmniej jeden, ustaw switch dla pierwszego
                                    if (monitorsModel.count > 0) {
                                        window.activeEditIndex = 0; // ustaw pierwszy monitor jako aktywny
                                        monitorSwitch.checked = !monitorsModel.get(window.activeEditIndex).disabled;
                                    }
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
                                    return m.description + "\nResolution: " + m.resW + "x" + m.resH + " @ " + m.rate + "Hz";
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
Rectangle {
    Layout.fillWidth: true
    height: 36
    radius: 8
    color: col(c.surface_container_high, "#2a2a2a")
    border.width: 1
    border.color: col(c.outline, "#444")

    Text {
        anchors.fill: parent
        anchors.margins: 8
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        color: col(c.on_surface, "#ffffff")

        text: {
            if (window.activeEditIndex < 0 || monitorsModel.count === 0)
                return ""

            let m = monitorsModel.get(window.activeEditIndex)
            if (!m) return ""

            return m.resW + "x" + m.resH + " @ " +
                   Number(m.rate).toFixed(2) + "Hz"
        }
    }
}

ComboBox {
    id: resolutionSelector
    Layout.fillWidth: true

    model: {
        if (window.activeEditIndex < 0 || monitorsModel.count === 0)
            return 0

        let m = monitorsModel.get(window.activeEditIndex)
        if (!m || !m.availableRes)
            return 0

        return m.availableRes.length
    }

    delegate: ItemDelegate {
        width: parent.width

        text: {
            let m = monitorsModel.get(window.activeEditIndex)
            if (!m || !m.availableRes || index >= m.availableRes.length)
                return ""

            let r = m.availableRes[index]
            return r.width + "x" + r.height + " @ " +
                   Number(r.refresh).toFixed(2) + "Hz"
        }
    }

    onActivated: function(index) {
        let m = monitorsModel.get(window.activeEditIndex)
        if (!m || !m.availableRes || index >= m.availableRes.length)
            return

        let r = m.availableRes[index]

        monitorsModel.setProperty(window.activeEditIndex, "resW", r.width)
        monitorsModel.setProperty(window.activeEditIndex, "resH", r.height)
        monitorsModel.setProperty(window.activeEditIndex, "rate", r.refresh)

        delayedLayoutUpdate.restart()
    }
Component.onCompleted: {
    let m = monitorsModel.get(window.activeEditIndex)
    console.log("RES COUNT:", m ? m.availableRes.length : "no monitor")
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
 
                ComboBox {
                    anchors.centerIn: parent
                    width: 300
                    model: monitorsModel
                    textRole: "name"
                }
            }
        }
}
