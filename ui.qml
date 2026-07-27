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

    // Editing is blocked until every settings line arrived, empty fields would save as zero
    readonly property var settingsLines: ["model", "general", "temps", "modes", "secret", "alarm"]
    property int loadedLines: 0
    readonly property bool settingsLoaded: loadedLines === (1 << settingsLines.length) - 1

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

    function setReal(field, value, decimals) {
        var number = Number(value)
        if (Number.isFinite(number)) {
            field.text = number.toFixed(decimals)
        }
    }

    function saveAllSettings() {
        if (!settingsLoaded) {
            return
        }

        sendCode("(save-general-settings "
            + boolAtom(softwareAdc)
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

        sendCode("(save-alarm-settings "
            + boolAtom(alarmTone)
            + " " + readReal(alarmSpeedThreshold, 1)
            + " " + readReal(alarmGyroThreshold, 1)
            + " " + readReal(alarmVoltage, 1)
            + ")")

        // A model change restarts lisp, which loads and applies everything on its own
        if (modelBox.currentIndex !== loadedModel) {
            sendCode("(save-model " + modelBox.currentIndex + ")")
        } else {
            sendCode("(finish-settings-save)")
        }
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
            showBatteryInIdle.checked = parseBoolToken(parts[2])
            setReal(minSpeed, parts[3], 1)
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
        } else if (parts[0] === "alarm") {
            alarmTone.checked = parseBoolToken(parts[1])
            setReal(alarmSpeedThreshold, parts[2], 1)
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
        running: !settingsLoaded
        onTriggered: sendCode("(send-settings)")
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

                        Label { text: "Speed (km/h)" }
                        TextField { id: ecoSpeed; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 150.0; decimals: 1 } }
                        TextField { id: driveSpeed; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 150.0; decimals: 1 } }
                        TextField { id: sportSpeed; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 300.0; decimals: 1 } }

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
                            columns: 4
                            rowSpacing: 4
                            columnSpacing: 6

                            Item { Layout.fillWidth: true }
                            Label { text: "Eco"; font.bold: true; Layout.fillWidth: true }
                            Label { text: "Drive"; font.bold: true; Layout.fillWidth: true }
                            Label { text: "Sport"; font.bold: true; Layout.fillWidth: true }

                            Label { text: "Speed (km/h)" }
                            TextField { id: secretEcoSpeed; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 300.0; decimals: 1 } }
                            TextField { id: secretDriveSpeed; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 400.0; decimals: 1 } }
                            TextField { id: secretSportSpeed; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0; top: 1000.0; decimals: 1 } }

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
                enabled: settingsLoaded
                onClicked: saveAllSettings()
            }

            Button {
                Layout.fillWidth: true
                text: "Reset"
                enabled: settingsLoaded
                onClicked: sendCode("(restore-settings-ui)")
            }
        }
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: !settingsLoaded
        visible: running
    }

    Connections {
        target: mCommands

        function onCustomAppDataReceived(data) {
            var message = data.toString().trim()

            if (message === "model-ok") {
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
