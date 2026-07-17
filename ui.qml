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

    // Boot mode dropdown index <-> speed mode value (2=eco, 1=drive, 4=sport)
    function bootModeValue() {
        return [2, 1, 4][bootMode.currentIndex]
    }

    function setBootMode(value) {
        bootMode.currentIndex = value === 2 ? 0 : (value === 1 ? 1 : 2)
    }

    function pressesIndex(box, token, fallback) {
        var n = Number.parseInt(token)
        box.currentIndex = Number.isNaN(n) ? fallback : n
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
            + " " + bootModeValue()
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
            + secretPresses.currentIndex
            + " " + comboFromBoxes(secretBrake, secretThrottle)
            + " " + boolAtom(secretRequiresLock)
            + " " + (lockPresses.currentIndex + 1)
            + " " + comboFromBoxes(lockBrake, lockThrottle)
            + " " + modePresses.currentIndex
            + " " + comboFromBoxes(modeBrake, modeThrottle)
            + " " + lightPresses.currentIndex
            + " " + comboFromBoxes(lightBrake, lightThrottle)
            + ")")

        sendCode("(save-misc-settings "
            + boolAtom(lightOnBoot)
            + " " + readReal(buttonSpeed, 1)
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
            setBootMode(Number.parseInt(parts[13]) || 4)
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
            pressesIndex(secretPresses, parts[1], 2)
            setBoxesFromCombo(Number.parseInt(parts[2]) || 0, secretBrake, secretThrottle)
            secretRequiresLock.checked = parseBoolToken(parts[3])
            var lp = Number.parseInt(parts[4])
            lockPresses.currentIndex = (Number.isNaN(lp) || lp < 1) ? 1 : lp - 1
            setBoxesFromCombo(Number.parseInt(parts[5]) || 0, lockBrake, lockThrottle)
            pressesIndex(modePresses, parts[6], 2)
            setBoxesFromCombo(Number.parseInt(parts[7]) || 0, modeBrake, modeThrottle)
            pressesIndex(lightPresses, parts[8], 1)
            setBoxesFromCombo(Number.parseInt(parts[9]) || 0, lightBrake, lightThrottle)
        } else if (parts[0] === "misc") {
            lightOnBoot.checked = parseBoolToken(parts[1])
            setReal(buttonSpeed, parts[2], 1)
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
                text: "Setup"
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
                enabled: !isSlave

                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 4

                        Label { text: "Riding"; font.bold: true }

                        CheckBox { id: showBatteryInIdle; text: "Battery % in Idle" }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Start Speed (km/h)"; Layout.fillWidth: true }
                            TextField { id: minSpeed; Layout.preferredWidth: 100; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 50.0; decimals: 1 } }
                        }

                        Label { text: "Buttons"; font.bold: true; Layout.topMargin: 8 }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Lock"; Layout.preferredWidth: 50 }
                            CheckBox { id: lockBrake; text: "Brake"; checked: true }
                            CheckBox { id: lockThrottle; text: "Throttle" }
                            Item { Layout.fillWidth: true }
                            ComboBox { id: lockPresses; Layout.preferredWidth: 76; model: ["1", "2", "3", "4", "5"]; currentIndex: 1 }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Modes"; Layout.preferredWidth: 50 }
                            CheckBox { id: modeBrake; text: "Brake" }
                            CheckBox { id: modeThrottle; text: "Throttle" }
                            Item { Layout.fillWidth: true }
                            ComboBox { id: modePresses; Layout.preferredWidth: 76; model: ["No", "1", "2", "3", "4", "5"]; currentIndex: 2 }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Light"; Layout.preferredWidth: 50 }
                            CheckBox { id: lightBrake; text: "Brake" }
                            CheckBox { id: lightThrottle; text: "Throttle" }
                            Item { Layout.fillWidth: true }
                            ComboBox { id: lightPresses; Layout.preferredWidth: 76; model: ["No", "1", "2", "3", "4", "5"]; currentIndex: 1 }
                        }

                        CheckBox { id: lightOnBoot; text: "Headlight on at power on" }

                        Label { text: "Alarm"; font.bold: true; Layout.topMargin: 8 }

                        CheckBox { id: alarmTone; text: "Alarm Tone" }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Speed Trigger (km/h)"; Layout.fillWidth: true }
                            TextField { id: alarmSpeedThreshold; Layout.preferredWidth: 100; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 50.0; decimals: 1 } }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Gyro Trigger (deg/s)"; Layout.fillWidth: true }
                            TextField { id: alarmGyroThreshold; Layout.preferredWidth: 100; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 1000.0; decimals: 1 } }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Volume (V)"; Layout.fillWidth: true }
                            TextField { id: alarmVoltage; Layout.preferredWidth: 100; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }
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

                        Label { text: "Normal"; font.bold: true }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Eco"; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                            Label { text: "Drive"; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                            Label { text: "Sport"; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                        }

                        CheckBox { id: applySpeed; text: "Speed (km/h)"; checked: true }
                        RowLayout {
                            Layout.fillWidth: true
                            TextField { id: ecoSpeed; enabled: applySpeed.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 150.0; decimals: 1 } }
                            TextField { id: driveSpeed; enabled: applySpeed.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 150.0; decimals: 1 } }
                            TextField { id: sportSpeed; enabled: applySpeed.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 300.0; decimals: 1 } }
                        }

                        CheckBox { id: applyCurrent; text: "Current Scale"; checked: true }
                        RowLayout {
                            Layout.fillWidth: true
                            TextField { id: ecoCurrent; enabled: applyCurrent.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 5.0; decimals: 2 } }
                            TextField { id: driveCurrent; enabled: applyCurrent.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 5.0; decimals: 2 } }
                            TextField { id: sportCurrent; enabled: applyCurrent.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 5.0; decimals: 2 } }
                        }

                        CheckBox { id: applyWatts; text: "Watts"; checked: true }
                        RowLayout {
                            Layout.fillWidth: true
                            TextField { id: ecoWatts; enabled: applyWatts.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 3000000.0; decimals: 0 } }
                            TextField { id: driveWatts; enabled: applyWatts.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 3000000.0; decimals: 0 } }
                            TextField { id: sportWatts; enabled: applyWatts.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 3000000.0; decimals: 0 } }
                        }

                        CheckBox { id: applyFw; text: "Field Weakening"; checked: true }
                        RowLayout {
                            Layout.fillWidth: true
                            TextField { id: ecoFw; enabled: applyFw.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }
                            TextField { id: driveFw; enabled: applyFw.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }
                            TextField { id: sportFw; enabled: applyFw.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Startup Mode"; Layout.fillWidth: true }
                            ComboBox { id: bootMode; Layout.preferredWidth: 110; model: ["Eco", "Drive", "Sport"]; currentIndex: 2 }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            Label { text: "Secret"; font.bold: true }
                            Item { Layout.fillWidth: true }
                            CheckBox { id: secretEnabled; text: "Enabled" }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Eco"; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                            Label { text: "Drive"; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                            Label { text: "Sport"; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                        }

                        CheckBox { id: secretApplySpeed; text: "Speed (km/h)"; checked: true }
                        RowLayout {
                            Layout.fillWidth: true
                            TextField { id: secretEcoSpeed; enabled: secretApplySpeed.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 300.0; decimals: 1 } }
                            TextField { id: secretDriveSpeed; enabled: secretApplySpeed.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 400.0; decimals: 1 } }
                            TextField { id: secretSportSpeed; enabled: secretApplySpeed.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 1000.0; decimals: 1 } }
                        }

                        CheckBox { id: secretApplyCurrent; text: "Current Scale"; checked: true }
                        RowLayout {
                            Layout.fillWidth: true
                            TextField { id: secretEcoCurrent; enabled: secretApplyCurrent.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 5.0; decimals: 2 } }
                            TextField { id: secretDriveCurrent; enabled: secretApplyCurrent.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 5.0; decimals: 2 } }
                            TextField { id: secretSportCurrent; enabled: secretApplyCurrent.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 5.0; decimals: 2 } }
                        }

                        CheckBox { id: secretApplyWatts; text: "Watts"; checked: true }
                        RowLayout {
                            Layout.fillWidth: true
                            TextField { id: secretEcoWatts; enabled: secretApplyWatts.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 3000000.0; decimals: 0 } }
                            TextField { id: secretDriveWatts; enabled: secretApplyWatts.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 3000000.0; decimals: 0 } }
                            TextField { id: secretSportWatts; enabled: secretApplyWatts.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 3000000.0; decimals: 0 } }
                        }

                        CheckBox { id: secretApplyFw; text: "Field Weakening"; checked: true }
                        RowLayout {
                            Layout.fillWidth: true
                            TextField { id: secretEcoFw; enabled: secretApplyFw.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }
                            TextField { id: secretDriveFw; enabled: secretApplyFw.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }
                            TextField { id: secretSportFw; enabled: secretApplyFw.checked; Layout.fillWidth: true; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 100.0; decimals: 1 } }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Secret"; Layout.preferredWidth: 50 }
                            CheckBox { id: secretBrake; text: "Brake"; checked: true }
                            CheckBox { id: secretThrottle; text: "Throttle"; checked: true }
                            Item { Layout.fillWidth: true }
                            ComboBox { id: secretPresses; Layout.preferredWidth: 76; model: ["No", "1", "2", "3", "4", "5"]; currentIndex: 2 }
                        }

                        CheckBox { id: secretRequiresLock; text: "Only while locked" }
                    }
                }
            }

            Page {
                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Model"; Layout.fillWidth: true }
                            ComboBox {
                                id: modelBox
                                Layout.preferredWidth: 170
                                model: ["G30", "M365/1S/PRO2", "Slave"]
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            enabled: !isSlave

                            Label { text: "Throttle & Brake"; font.bold: true; Layout.topMargin: 8 }

                            CheckBox { id: softwareAdc; text: "Software ADC" }

                            Label { text: "Min Throttle ADC: " + minAdcThrottle.value.toFixed(2) }
                            Slider { id: minAdcThrottle; Layout.fillWidth: true; from: 0.0; to: 1.0; stepSize: 0.01; snapMode: Slider.SnapAlways }

                            Label { text: "Min Brake ADC: " + minAdcBrake.value.toFixed(2) }
                            Slider { id: minAdcBrake; Layout.fillWidth: true; from: 0.0; to: 1.0; stepSize: 0.01; snapMode: Slider.SnapAlways }

                            Label { text: "Temperature"; font.bold: true; Layout.topMargin: 8 }

                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: "Motor Temp Warning (°C)"; Layout.fillWidth: true }
                                TextField { id: tempWarningMotor; Layout.preferredWidth: 100; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 200.0; decimals: 1 } }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: "FET Temp Warning (°C)"; Layout.fillWidth: true }
                                TextField { id: tempWarningFet; Layout.preferredWidth: 100; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 200.0; decimals: 1 } }
                            }

                            Label { text: "Button"; font.bold: true; Layout.topMargin: 8 }

                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: "Active below (km/h)"; Layout.fillWidth: true }
                                TextField { id: buttonSpeed; Layout.preferredWidth: 100; maximumLength: 7; validator: DoubleValidator { bottom: 0.0; top: 200.0; decimals: 1 } }
                            }
                        }
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
                    || message.startsWith("misc ")
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
