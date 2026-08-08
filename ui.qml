import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Vedder.vesc.commands 1.0
import Vedder.vesc.utility 1.0

Item {
    id: root
    anchors.fill: parent

    property Commands mCommands: VescIf.commands()
    property int loadedModel: -1
    property bool isSlave: modelBox.currentIndex === 2
    readonly property string speedUnit: useMph.checked ? "mph" : "km/h"

    // Order matches the idle display modes in the lisp script
    readonly property var idleDisplayNames: [
        "Speed", "Battery %", "Motor Temp", "Controller Temp",
        "Voltage", "Trip", "Top Speed"
    ]

    // Order matches the secret combos in the lisp script
    readonly property var secretComboNames: [
        "Throttle + Brake + 2x Press", "Throttle + Brake + 3x Press",
        "Throttle + 3x Press", "Brake + 3x Press", "3x Press", "4x Press",
        "Throttle + Hold Button", "Brake + Power On"
    ]

    // Editing is blocked until every settings line arrived, empty fields would save as zero
    readonly property var settingsLines: ["model", "general", "temps", "modes", "secret", "alarm"]
    property int loadedLines: 0
    readonly property bool settingsLoaded: loadedLines === (1 << settingsLines.length) - 1

    // Commands still waiting to be confirmed by the script
    property var saveQueue: []
    property bool saving: false

    function sendCode(str) {
        mCommands.sendCustomAppData(str + "\0")
    }

    function boolAtom(box) {
        return box.checked ? "true" : "false"
    }

    function parseBoolToken(token) {
        return token === "true" || token === "1"
    }

    function readReal(field, decimals) {
        var number = Number.parseFloat(field.text)
        if (!Number.isFinite(number)) {
            number = 0
        }
        return number.toFixed(decimals)
    }

    function setIndex(box, value) {
        var index = Number.parseInt(value)
        if (Number.isInteger(index) && index >= 0 && index < box.count) {
            box.currentIndex = index
        }
    }

    function setReal(field, value, decimals) {
        var number = Number(value)
        if (Number.isFinite(number)) {
            field.text = number.toFixed(decimals)
        }
    }

    // Speeds are always stored in km/h, the fields only show mph
    readonly property real mphFactor: 0.621371

    // A field that was not edited gives back exactly what it was loaded with, so switching
    // the unit back and forth never rounds a speed away
    function speedToKmh(field, mph) {
        var number = Number.parseFloat(field.text)
        if (!Number.isFinite(number)) {
            return 0
        }
        if (!mph) {
            return number
        }
        if (number.toFixed(1) === (field.kmh * mphFactor).toFixed(1)) {
            return field.kmh
        }
        return number / mphFactor
    }

    function readSpeed(field) {
        return speedToKmh(field, useMph.checked).toFixed(1)
    }

    function setSpeed(field, value) {
        var number = Number(value)
        if (Number.isFinite(number)) {
            field.kmh = number
            field.text = (useMph.checked ? number * mphFactor : number).toFixed(1)
        }
    }

    function convertSpeedFields(toMph) {
        var fields = [minSpeed, ecoSpeed, driveSpeed, sportSpeed, secretMinSpeed,
            secretEcoSpeed, secretDriveSpeed, secretSportSpeed, alarmSpeedThreshold]
        for (var i = 0; i < fields.length; i++) {
            setSpeed(fields[i], speedToKmh(fields[i], !toMph))
        }
    }

    function saveAllSettings() {
        if (!settingsLoaded || saving) {
            return
        }

        var queue = []

        queue.push("(save-general-settings "
            + boolAtom(softwareAdc)
            + " " + boolAtom(useMph)
            + ")")

        queue.push("(save-temp-settings "
            + readReal(tempWarningMotor, 1)
            + " " + readReal(tempWarningFet, 1)
            + ")")

        queue.push("(save-mode-settings "
            + idleDisplay.currentIndex
            + " " + readSpeed(minSpeed)
            + " " + readSpeed(ecoSpeed)
            + " " + readReal(ecoCurrent, 2)
            + " " + readReal(ecoWatts, 0)
            + " " + readReal(ecoFw, 1)
            + " " + readSpeed(driveSpeed)
            + " " + readReal(driveCurrent, 2)
            + " " + readReal(driveWatts, 0)
            + " " + readReal(driveFw, 1)
            + " " + readSpeed(sportSpeed)
            + " " + readReal(sportCurrent, 2)
            + " " + readReal(sportWatts, 0)
            + " " + readReal(sportFw, 1)
            + ")")

        queue.push("(save-secret-settings "
            + boolAtom(secretEnabled)
            + " " + secretCombo.currentIndex
            + " " + secretIdleDisplay.currentIndex
            + " " + readSpeed(secretMinSpeed)
            + " " + readSpeed(secretEcoSpeed)
            + " " + readReal(secretEcoCurrent, 2)
            + " " + readReal(secretEcoWatts, 0)
            + " " + readReal(secretEcoFw, 1)
            + " " + readSpeed(secretDriveSpeed)
            + " " + readReal(secretDriveCurrent, 2)
            + " " + readReal(secretDriveWatts, 0)
            + " " + readReal(secretDriveFw, 1)
            + " " + readSpeed(secretSportSpeed)
            + " " + readReal(secretSportCurrent, 2)
            + " " + readReal(secretSportWatts, 0)
            + " " + readReal(secretSportFw, 1)
            + ")")

        queue.push("(save-alarm-settings "
            + boolAtom(alarmTone)
            + " " + readSpeed(alarmSpeedThreshold)
            + " " + readReal(alarmGyroThreshold, 1)
            + " " + readReal(alarmVoltage, 1)
            + ")")

        // A model change restarts lisp, which loads and applies everything on its own
        if (modelBox.currentIndex !== loadedModel) {
            queue.push("(save-model " + modelBox.currentIndex + ")")
        } else {
            queue.push("(finish-settings-save)")
        }

        saveQueue = queue
        saving = true
        sendSaveStep()
    }

    // Writing a setting locks the VESC while it writes flash, which drops anything that
    // arrives meanwhile. One command at a time, and only once the last one was confirmed.
    function sendSaveStep() {
        if (saveQueue.length === 0) {
            saving = false
            return
        }

        ackTimer.restart()
        sendCode(saveQueue[0])
    }

    function saveStepDone(ok) {
        if (!saving) {
            return
        }

        ackTimer.stop()

        if (!ok) {
            abortSave()
            return
        }

        saveQueue = saveQueue.slice(1)
        sendSaveStep()
    }

    function abortSave() {
        ackTimer.stop()
        saving = false
        saveQueue = []
        VescIf.emitStatusMessage("Saving failed, please try again.", false)
        getSettings()
    }

    function getSettings() {
        loadedLines = 0
        sendCode("(send-settings)")
    }

    function applySettingsLine(line) {
        var parts = line.split(" ")
        var index = settingsLines.indexOf(parts[0])

        if (index < 0) {
            return
        }

        if (parts[0] === "model") {
            loadedModel = Number.parseInt(parts[1])
            modelBox.currentIndex = loadedModel
        } else if (parts[0] === "general") {
            softwareAdc.checked = parseBoolToken(parts[1])
            useMph.checked = parseBoolToken(parts[2])
        } else if (parts[0] === "temps") {
            setReal(tempWarningMotor, parts[1], 1)
            setReal(tempWarningFet, parts[2], 1)
        } else if (parts[0] === "modes") {
            setIndex(idleDisplay, parts[1])
            setSpeed(minSpeed, parts[2])
            setSpeed(ecoSpeed, parts[3])
            setReal(ecoCurrent, parts[4], 2)
            setReal(ecoWatts, parts[5], 0)
            setReal(ecoFw, parts[6], 1)
            setSpeed(driveSpeed, parts[7])
            setReal(driveCurrent, parts[8], 2)
            setReal(driveWatts, parts[9], 0)
            setReal(driveFw, parts[10], 1)
            setSpeed(sportSpeed, parts[11])
            setReal(sportCurrent, parts[12], 2)
            setReal(sportWatts, parts[13], 0)
            setReal(sportFw, parts[14], 1)
        } else if (parts[0] === "secret") {
            secretEnabled.checked = parseBoolToken(parts[1])
            setIndex(secretCombo, parts[2])
            setIndex(secretIdleDisplay, parts[3])
            setSpeed(secretMinSpeed, parts[4])
            setSpeed(secretEcoSpeed, parts[5])
            setReal(secretEcoCurrent, parts[6], 2)
            setReal(secretEcoWatts, parts[7], 0)
            setReal(secretEcoFw, parts[8], 1)
            setSpeed(secretDriveSpeed, parts[9])
            setReal(secretDriveCurrent, parts[10], 2)
            setReal(secretDriveWatts, parts[11], 0)
            setReal(secretDriveFw, parts[12], 1)
            setSpeed(secretSportSpeed, parts[13])
            setReal(secretSportCurrent, parts[14], 2)
            setReal(secretSportWatts, parts[15], 0)
            setReal(secretSportFw, parts[16], 1)
        } else if (parts[0] === "alarm") {
            alarmTone.checked = parseBoolToken(parts[1])
            setSpeed(alarmSpeedThreshold, parts[2])
            setReal(alarmGyroThreshold, parts[3], 1)
            setReal(alarmVoltage, parts[4], 1)
        }

        loadedLines |= 1 << index
    }

    Component.onCompleted: {
        getSettings()
    }

    // Lisp may still be starting up, keep asking until everything is here
    Timer {
        id: retryTimer
        interval: 2000
        repeat: true
        running: !settingsLoaded && !saving
        onTriggered: sendCode("(send-settings)")
    }

    // Never resend the pending command, a second ack would skip the next one
    Timer {
        id: ackTimer
        interval: 5000
        onTriggered: abortSave()
    }

    Timer {
        id: restartTimer
        interval: 400
        onTriggered: {
            mCommands.lispSetRunning(true)
            reloadTimer.start()
        }
    }

    Timer {
        id: reloadTimer
        interval: 1500
        onTriggered: getSettings()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        TabBar {
            id: tabBar
            currentIndex: swipeView.currentIndex
            Layout.fillWidth: true
            implicitWidth: 0
            clip: true
            enabled: settingsLoaded

            property int buttons: 4
            property int buttonWidth: 90

            TabButton {
                text: "General"
                width: Math.max(tabBar.buttonWidth, tabBar.width / tabBar.buttons)
            }
            TabButton {
                text: "Modes"
                width: Math.max(tabBar.buttonWidth, tabBar.width / tabBar.buttons)
            }
            TabButton {
                text: "Secret"
                width: Math.max(tabBar.buttonWidth, tabBar.width / tabBar.buttons)
            }
            TabButton {
                text: "Alarm"
                width: Math.max(tabBar.buttonWidth, tabBar.width / tabBar.buttons)
            }
        }

        SwipeView {
            id: swipeView
            currentIndex: tabBar.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            enabled: settingsLoaded
            opacity: settingsLoaded ? 1.0 : 0.0

            Page {
                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 4

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: 4
                            columnSpacing: 8

                            Label { text: "Model" }
                            ComboBox {
                                id: modelBox
                                Layout.fillWidth: true
                                model: ["G30", "M365/1S/PRO2", "Slave"]
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: 4
                            columnSpacing: 8
                            enabled: !isSlave

                            CheckBox {
                                id: softwareAdc
                                Layout.columnSpan: 2
                                text: "Software ADC"
                            }

                            CheckBox {
                                id: useMph
                                Layout.columnSpan: 2
                                text: "Use mph"
                                onCheckedChanged: if (root.settingsLoaded) root.convertSpeedFields(checked)
                            }

                            Label { text: "Motor Temp Warning (°C)" }
                            TextField { id: tempWarningMotor; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 200.0; decimals: 1 } }

                            Label { text: "FET Temp Warning (°C)" }
                            TextField { id: tempWarningFet; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 200.0; decimals: 1 } }
                        }
                    }
                }
            }

            Page {
                enabled: !isSlave

                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 4

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: 4
                            columnSpacing: 8

                            Label { text: "Show While Idle" }
                            ComboBox { id: idleDisplay; Layout.fillWidth: true; model: root.idleDisplayNames }

                            Label { text: "Start Speed (" + root.speedUnit + ")" }
                            TextField { id: minSpeed; property real kmh: 0; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 50.0; decimals: 1 } }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 4
                            rowSpacing: 4
                            columnSpacing: 6

                            Item { Layout.fillWidth: true }
                            Label { text: "Eco"; font.bold: true; Layout.fillWidth: true }
                            Label { text: "Drive"; font.bold: true; Layout.fillWidth: true }
                            Label { text: "Sport"; font.bold: true; Layout.fillWidth: true }

                            Label { text: "Speed (" + root.speedUnit + ")" }
                            TextField { id: ecoSpeed; property real kmh: 0; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 150.0; decimals: 1 } }
                            TextField { id: driveSpeed; property real kmh: 0; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 150.0; decimals: 1 } }
                            TextField { id: sportSpeed; property real kmh: 0; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 300.0; decimals: 1 } }

                            Label { text: "Current Scale" }
                            TextField { id: ecoCurrent; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 5.0; decimals: 2 } }
                            TextField { id: driveCurrent; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 5.0; decimals: 2 } }
                            TextField { id: sportCurrent; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 5.0; decimals: 2 } }

                            Label { text: "Watts" }
                            TextField { id: ecoWatts; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 3000000.0; decimals: 0 } }
                            TextField { id: driveWatts; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 3000000.0; decimals: 0 } }
                            TextField { id: sportWatts; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 3000000.0; decimals: 0 } }

                            Label { text: "Field Weakening" }
                            TextField { id: ecoFw; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }
                            TextField { id: driveFw; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }
                            TextField { id: sportFw; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }
                        }
                    }
                }
            }

            Page {
                enabled: !isSlave

                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 4

                        CheckBox {
                            id: secretEnabled
                            text: "Enabled"
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: 4
                            columnSpacing: 8

                            Label { text: "Activate With" }
                            ComboBox { id: secretCombo; Layout.fillWidth: true; model: root.secretComboNames }

                            Label { text: "Show While Idle" }
                            ComboBox { id: secretIdleDisplay; Layout.fillWidth: true; model: root.idleDisplayNames }

                            Label { text: "Start Speed (" + root.speedUnit + ")" }
                            TextField { id: secretMinSpeed; property real kmh: 0; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 50.0; decimals: 1 } }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 4
                            rowSpacing: 4
                            columnSpacing: 6

                            Item { Layout.fillWidth: true }
                            Label { text: "Eco"; font.bold: true; Layout.fillWidth: true }
                            Label { text: "Drive"; font.bold: true; Layout.fillWidth: true }
                            Label { text: "Sport"; font.bold: true; Layout.fillWidth: true }

                            Label { text: "Speed (" + root.speedUnit + ")" }
                            TextField { id: secretEcoSpeed; property real kmh: 0; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 300.0; decimals: 1 } }
                            TextField { id: secretDriveSpeed; property real kmh: 0; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 400.0; decimals: 1 } }
                            TextField { id: secretSportSpeed; property real kmh: 0; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 1000.0; decimals: 1 } }

                            Label { text: "Current Scale" }
                            TextField { id: secretEcoCurrent; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 5.0; decimals: 2 } }
                            TextField { id: secretDriveCurrent; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 5.0; decimals: 2 } }
                            TextField { id: secretSportCurrent; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 5.0; decimals: 2 } }

                            Label { text: "Watts" }
                            TextField { id: secretEcoWatts; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 3000000.0; decimals: 0 } }
                            TextField { id: secretDriveWatts; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 3000000.0; decimals: 0 } }
                            TextField { id: secretSportWatts; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 3000000.0; decimals: 0 } }

                            Label { text: "Field Weakening" }
                            TextField { id: secretEcoFw; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }
                            TextField { id: secretDriveFw; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }
                            TextField { id: secretSportFw; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }
                        }
                    }
                }
            }

            Page {
                enabled: !isSlave

                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    clip: true

                    GridLayout {
                        width: parent.width
                        columns: 2
                        rowSpacing: 4
                        columnSpacing: 8

                        CheckBox {
                            id: alarmTone
                            Layout.columnSpan: 2
                            text: "Alarm Tone"
                        }

                        Label { text: "Speed Trigger (" + root.speedUnit + ")" }
                        TextField { id: alarmSpeedThreshold; property real kmh: 0; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 50.0; decimals: 1 } }

                        Label { text: "Gyro Trigger (deg/s)" }
                        TextField { id: alarmGyroThreshold; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 1000.0; decimals: 1 } }

                        Label { text: "Volume (V)" }
                        TextField { id: alarmVoltage; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Button {
                Layout.fillWidth: true
                text: "Load"
                enabled: !saving
                onClicked: getSettings()
            }

            Button {
                Layout.fillWidth: true
                text: "Save"
                enabled: settingsLoaded && !saving
                onClicked: saveAllSettings()
            }

            Button {
                Layout.fillWidth: true
                text: "Reset"
                enabled: settingsLoaded && !saving
                onClicked: sendCode("(restore-settings-ui)")
            }
        }
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: !settingsLoaded || saving
        visible: running
    }

    Connections {
        target: mCommands

        function onCustomAppDataReceived(data) {
            var message = data.toString().trim()

            if (message === "ack") {
                saveStepDone(true)
            } else if (message === "err") {
                saveStepDone(false)
            } else if (message === "model-ok") {
                // Lisp is about to be stopped, so no ack follows this one
                ackTimer.stop()
                saving = false
                saveQueue = []
                loadedModel = modelBox.currentIndex
                loadedLines = 0
                VescIf.emitStatusMessage("Model saved, restarting...", true)
                mCommands.lispSetRunning(false)
                restartTimer.start()
            } else if (message === "ok") {
                VescIf.emitStatusMessage("Scooter settings saved.", true)
            } else {
                applySettingsLine(message)
            }
        }
    }
}
