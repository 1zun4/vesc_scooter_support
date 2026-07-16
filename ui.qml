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

    function sendCode(str) {
        mCommands.sendCustomAppData(str + "\0")
    }

    function boolAtom(box) {
        return box.checked ? "true" : "false"
    }

    function parseBoolToken(token) {
        return token === "true" || token === "1"
    }

    // Lever combo codes: 0=brake+throttle, 1=brake only, 2=throttle only, 3=none
    function comboFromBoxes(brakeBox, throttleBox) {
        if (brakeBox.checked && throttleBox.checked) return 0
        if (brakeBox.checked) return 1
        if (throttleBox.checked) return 2
        return 3
    }

    function setBoxesFromCombo(combo, brakeBox, throttleBox) {
        brakeBox.checked = (combo === 0 || combo === 1)
        throttleBox.checked = (combo === 0 || combo === 2)
    }

    function readReal(field, decimals) {
        var number = Number.parseFloat(field.text)
        if (!Number.isFinite(number)) {
            number = 0
        }
        return number.toFixed(decimals)
    }

    function setReal(field, value, decimals) {
        var number = Number(value)
        if (Number.isFinite(number)) {
            field.text = number.toFixed(decimals)
        }
    }

    function saveAllSettings() {
        sendCode("(save-general-settings "
            + boolAtom(softwareAdc)
            + " " + minAdcThrottle.value.toFixed(2)
            + " " + minAdcBrake.value.toFixed(2)
            + " " + boolAtom(showBatteryInIdle)
            + " " + readReal(minSpeed, 1)
            + ")")

        sendCode("(save-temp-settings "
            + readReal(tempWarningMotor, 1)
            + " " + readReal(tempWarningFet, 1)
            + ")")

        sendCode("(save-mode-settings "
            + readReal(ecoSpeed, 1)
            + " " + readReal(ecoCurrent, 2)
            + " " + readReal(ecoWatts, 0)
            + " " + readReal(ecoFw, 1)
            + " " + readReal(driveSpeed, 1)
            + " " + readReal(driveCurrent, 2)
            + " " + readReal(driveWatts, 0)
            + " " + readReal(driveFw, 1)
            + " " + readReal(sportSpeed, 1)
            + " " + readReal(sportCurrent, 2)
            + " " + readReal(sportWatts, 0)
            + " " + readReal(sportFw, 1)
            + ")")

        sendCode("(save-secret-settings "
            + boolAtom(secretEnabled)
            + " " + readReal(secretEcoSpeed, 1)
            + " " + readReal(secretEcoCurrent, 2)
            + " " + readReal(secretEcoWatts, 0)
            + " " + readReal(secretEcoFw, 1)
            + " " + readReal(secretDriveSpeed, 1)
            + " " + readReal(secretDriveCurrent, 2)
            + " " + readReal(secretDriveWatts, 0)
            + " " + readReal(secretDriveFw, 1)
            + " " + readReal(secretSportSpeed, 1)
            + " " + readReal(secretSportCurrent, 2)
            + " " + readReal(secretSportWatts, 0)
            + " " + readReal(secretSportFw, 1)
            + ")")

        sendCode("(save-apply-settings "
            + boolAtom(applySpeed)
            + " " + boolAtom(applyCurrent)
            + " " + boolAtom(applyWatts)
            + " " + boolAtom(applyFw)
            + " " + boolAtom(secretApplySpeed)
            + " " + boolAtom(secretApplyCurrent)
            + " " + boolAtom(secretApplyWatts)
            + " " + boolAtom(secretApplyFw)
            + ")")

        sendCode("(save-gesture-settings "
            + secretPresses.value
            + " " + comboFromBoxes(secretBrake, secretThrottle)
            + " " + boolAtom(secretRequiresLock)
            + " " + lockPresses.value
            + " " + comboFromBoxes(lockBrake, lockThrottle)
            + ")")

        sendCode("(save-alarm-settings "
            + boolAtom(alarmTone)
            + " " + readReal(alarmSpeedThreshold, 1)
            + " " + readReal(alarmGyroThreshold, 1)
            + " " + readReal(alarmVoltage, 1)
            + ")")

        sendCode("(finish-settings-save)")

        // Model change needs a lisp restart, ack-gated via "model-ok"
        if (modelBox.currentIndex !== loadedModel) {
            sendCode("(save-model " + modelBox.currentIndex + ")")
        }
    }

    function getSettings() {
        sendCode("(send-settings)")
    }

    function applySettingsLine(line) {
        var parts = line.split(" ")

        if (parts[0] === "model") {
            loadedModel = Number.parseInt(parts[1])
            modelBox.currentIndex = loadedModel
        } else if (parts[0] === "general") {
            softwareAdc.checked = parseBoolToken(parts[1])
            minAdcThrottle.value = Number.parseFloat(parts[2]) || 0
            minAdcBrake.value = Number.parseFloat(parts[3]) || 0
            showBatteryInIdle.checked = parseBoolToken(parts[4])
            setReal(minSpeed, parts[5], 1)
        } else if (parts[0] === "temps") {
            setReal(tempWarningMotor, parts[1], 1)
            setReal(tempWarningFet, parts[2], 1)
        } else if (parts[0] === "modes") {
            setReal(ecoSpeed, parts[1], 1)
            setReal(ecoCurrent, parts[2], 2)
            setReal(ecoWatts, parts[3], 0)
            setReal(ecoFw, parts[4], 1)
            setReal(driveSpeed, parts[5], 1)
            setReal(driveCurrent, parts[6], 2)
            setReal(driveWatts, parts[7], 0)
            setReal(driveFw, parts[8], 1)
            setReal(sportSpeed, parts[9], 1)
            setReal(sportCurrent, parts[10], 2)
            setReal(sportWatts, parts[11], 0)
            setReal(sportFw, parts[12], 1)
        } else if (parts[0] === "secret") {
            secretEnabled.checked = parseBoolToken(parts[1])
            setReal(secretEcoSpeed, parts[2], 1)
            setReal(secretEcoCurrent, parts[3], 2)
            setReal(secretEcoWatts, parts[4], 0)
            setReal(secretEcoFw, parts[5], 1)
            setReal(secretDriveSpeed, parts[6], 1)
            setReal(secretDriveCurrent, parts[7], 2)
            setReal(secretDriveWatts, parts[8], 0)
            setReal(secretDriveFw, parts[9], 1)
            setReal(secretSportSpeed, parts[10], 1)
            setReal(secretSportCurrent, parts[11], 2)
            setReal(secretSportWatts, parts[12], 0)
            setReal(secretSportFw, parts[13], 1)
        } else if (parts[0] === "apply") {
            applySpeed.checked = parseBoolToken(parts[1])
            applyCurrent.checked = parseBoolToken(parts[2])
            applyWatts.checked = parseBoolToken(parts[3])
            applyFw.checked = parseBoolToken(parts[4])
            secretApplySpeed.checked = parseBoolToken(parts[5])
            secretApplyCurrent.checked = parseBoolToken(parts[6])
            secretApplyWatts.checked = parseBoolToken(parts[7])
            secretApplyFw.checked = parseBoolToken(parts[8])
        } else if (parts[0] === "gesture") {
            var sp = Number.parseInt(parts[1])
            secretPresses.value = Number.isNaN(sp) ? 2 : sp
            setBoxesFromCombo(Number.parseInt(parts[2]) || 0, secretBrake, secretThrottle)
            secretRequiresLock.checked = parseBoolToken(parts[3])
            var lp = Number.parseInt(parts[4])
            lockPresses.value = Number.isNaN(lp) ? 2 : lp
            setBoxesFromCombo(Number.parseInt(parts[5]) || 0, lockBrake, lockThrottle)
        } else if (parts[0] === "alarm") {
            alarmTone.checked = parseBoolToken(parts[1])
            setReal(alarmSpeedThreshold, parts[2], 1)
            setReal(alarmGyroThreshold, parts[3], 1)
            setReal(alarmVoltage, parts[4], 1)
        }
    }

    Component.onCompleted: {
        getSettings()
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

            property int buttons: 3
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

                            Label { text: "Min Throttle ADC" }
                            RowLayout {
                                Layout.fillWidth: true
                                Slider { id: minAdcThrottle; Layout.fillWidth: true; from: 0.0; to: 1.0; stepSize: 0.01; snapMode: Slider.SnapAlways }
                                Label { text: minAdcThrottle.value.toFixed(2); Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight }
                            }

                            Label { text: "Min Brake ADC" }
                            RowLayout {
                                Layout.fillWidth: true
                                Slider { id: minAdcBrake; Layout.fillWidth: true; from: 0.0; to: 1.0; stepSize: 0.01; snapMode: Slider.SnapAlways }
                                Label { text: minAdcBrake.value.toFixed(2); Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight }
                            }

                            CheckBox {
                                id: showBatteryInIdle
                                Layout.columnSpan: 2
                                text: "Battery % in Idle"
                            }

                            Label { text: "Start Speed (km/h)" }
                            TextField { id: minSpeed; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 50.0; decimals: 1 } }

                            Label { text: "Motor Temp Warning (°C)" }
                            TextField { id: tempWarningMotor; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 200.0; decimals: 1 } }

                            Label { text: "FET Temp Warning (°C)" }
                            TextField { id: tempWarningFet; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 200.0; decimals: 1 } }

                            RowLayout {
                                Layout.columnSpan: 2
                                Layout.fillWidth: true
                                Label { text: "Lock:" }
                                CheckBox { id: lockBrake; text: "Brake"; checked: true }
                                CheckBox { id: lockThrottle; text: "Throttle" }
                                SpinBox { id: lockPresses; from: 0; to: 5; Layout.preferredWidth: 110 }
                                Label { text: "presses (0=off)" }
                            }
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
                        columns: 4
                        rowSpacing: 4
                        columnSpacing: 6

                        Item { Layout.fillWidth: true }
                        Label { text: "Eco"; font.bold: true; Layout.fillWidth: true }
                        Label { text: "Drive"; font.bold: true; Layout.fillWidth: true }
                        Label { text: "Sport"; font.bold: true; Layout.fillWidth: true }

                        CheckBox { id: applySpeed; text: "Speed (km/h)"; checked: true }
                        TextField { id: ecoSpeed; enabled: applySpeed.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 150.0; decimals: 1 } }
                        TextField { id: driveSpeed; enabled: applySpeed.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 150.0; decimals: 1 } }
                        TextField { id: sportSpeed; enabled: applySpeed.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 300.0; decimals: 1 } }

                        CheckBox { id: applyCurrent; text: "Current Scale"; checked: true }
                        TextField { id: ecoCurrent; enabled: applyCurrent.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 5.0; decimals: 2 } }
                        TextField { id: driveCurrent; enabled: applyCurrent.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 5.0; decimals: 2 } }
                        TextField { id: sportCurrent; enabled: applyCurrent.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 5.0; decimals: 2 } }

                        CheckBox { id: applyWatts; text: "Watts"; checked: true }
                        TextField { id: ecoWatts; enabled: applyWatts.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 3000000.0; decimals: 0 } }
                        TextField { id: driveWatts; enabled: applyWatts.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 3000000.0; decimals: 0 } }
                        TextField { id: sportWatts; enabled: applyWatts.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 3000000.0; decimals: 0 } }

                        CheckBox { id: applyFw; text: "Field Weakening"; checked: true }
                        TextField { id: ecoFw; enabled: applyFw.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }
                        TextField { id: driveFw; enabled: applyFw.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }
                        TextField { id: sportFw; enabled: applyFw.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }

                        CheckBox { id: secretEnabled; text: "Secret Modes"; Layout.columnSpan: 4; font.bold: true }

                        CheckBox { id: secretApplySpeed; text: "Speed (km/h)"; checked: true }
                        TextField { id: secretEcoSpeed; enabled: secretApplySpeed.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 300.0; decimals: 1 } }
                        TextField { id: secretDriveSpeed; enabled: secretApplySpeed.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 400.0; decimals: 1 } }
                        TextField { id: secretSportSpeed; enabled: secretApplySpeed.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 1000.0; decimals: 1 } }

                        CheckBox { id: secretApplyCurrent; text: "Current Scale"; checked: true }
                        TextField { id: secretEcoCurrent; enabled: secretApplyCurrent.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 5.0; decimals: 2 } }
                        TextField { id: secretDriveCurrent; enabled: secretApplyCurrent.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 5.0; decimals: 2 } }
                        TextField { id: secretSportCurrent; enabled: secretApplyCurrent.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 5.0; decimals: 2 } }

                        CheckBox { id: secretApplyWatts; text: "Watts"; checked: true }
                        TextField { id: secretEcoWatts; enabled: secretApplyWatts.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 3000000.0; decimals: 0 } }
                        TextField { id: secretDriveWatts; enabled: secretApplyWatts.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 3000000.0; decimals: 0 } }
                        TextField { id: secretSportWatts; enabled: secretApplyWatts.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 3000000.0; decimals: 0 } }

                        CheckBox { id: secretApplyFw; text: "Field Weakening"; checked: true }
                        TextField { id: secretEcoFw; enabled: secretApplyFw.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }
                        TextField { id: secretDriveFw; enabled: secretApplyFw.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }
                        TextField { id: secretSportFw; enabled: secretApplyFw.checked; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }

                        RowLayout {
                            Layout.columnSpan: 4
                            Layout.fillWidth: true
                            Label { text: "Secret:" }
                            CheckBox { id: secretBrake; text: "Brake"; checked: true }
                            CheckBox { id: secretThrottle; text: "Throttle"; checked: true }
                            SpinBox { id: secretPresses; from: 0; to: 5; Layout.preferredWidth: 110 }
                            Label { text: "presses (0=off)" }
                        }

                        CheckBox { id: secretRequiresLock; text: "Only while locked"; Layout.columnSpan: 4 }
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

                        Label { text: "Speed Trigger (km/h)" }
                        TextField { id: alarmSpeedThreshold; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 50.0; decimals: 1 } }

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
                onClicked: getSettings()
            }

            Button {
                Layout.fillWidth: true
                text: "Save"
                onClicked: saveAllSettings()
            }

            Button {
                Layout.fillWidth: true
                text: "Reset"
                onClicked: sendCode("(restore-settings-ui)")
            }
        }
    }

    Connections {
        target: mCommands

        function onCustomAppDataReceived(data) {
            var message = data.toString().trim()

            if (message.startsWith("model ")
                    || message.startsWith("general ")
                    || message.startsWith("temps ")
                    || message.startsWith("modes ")
                    || message.startsWith("secret ")
                    || message.startsWith("apply ")
                    || message.startsWith("gesture ")
                    || message.startsWith("alarm ")) {
                applySettingsLine(message)
            } else if (message === "model-ok") {
                loadedModel = modelBox.currentIndex
                VescIf.emitStatusMessage("Model saved, restarting...", true)
                mCommands.lispSetRunning(false)
                restartTimer.start()
            } else if (message === "ok") {
                VescIf.emitStatusMessage("Scooter settings saved.", true)
            }
        }
    }
}
