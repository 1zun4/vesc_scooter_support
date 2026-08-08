# VESC Einbau
**mit Xiaomi Display Support**

## Vorwort
Du möchtest einen VESC verwenden, aber hast dich bisher noch nicht dazu entscheiden, denn du möchtest nicht auf das Xiaomi Display verzichten und hast keine Lust auf komplizierte Verkabelung des Lichts, Bremsen, Gashebels und weiteren Komponenten. \
Dann ist mein Guide für den Einbau eines VESC in den Xiaomi Mi Scooter Pro (2) (auch andere Scooter wie G30 sind unterstützt - sind im Ablauf leicht anders - Erwähnung beachten !!), das richtige, denn hiermit können wir Kompromisslos die Verwendung eines VESC im Xiaomi ermöglichen. \

Zu diesem Beitrag <u>bitte</u> auch den [Haftungsausschluss der Nutzungsbedingungen - Pkt.8 beachten!](https://rollerplausch.com/help/terms/)

### **Was ist ein VESC?**
Ein VESC ist ein Motorsteuergerät so wie der Xiaomi ESC oder auch Controller genannt. Es gibt etliche verschiedene VESC, denn der Name "VESC" ist lediglich die Bezeichnung für die Open-Source Software des Steuergerätes. Es gibt daher etliche Motorsteuergeräte die sich VESC nennen können und ansteuerbar sind über das VESC Ökosystem. Damit auch kompatibel mit diesem Guide! \

(Ich spreche hier nicht über die VESC Firmware (SmartESC) für Xiaomi ESCs, sondern um Drittanbieter ESCs mit VESC firmware)

### **Warum ein VESC verwenden?**
Das kann mehrere Gründe haben:

* Mehr Einstellungsmöglichkeiten und Einsatzzwecke
* Höheres Leistungspotenzial, effizienter und geräuschloser durch höhere Schaltfrequenzen
* Field Weakening
* Schöne Smartphone App mit Realtime Übersicht
* Leichte Modifikation der Firmware (Open-Source)
* Große Kompatibilität mit jedem Motor (selbst ohne Hallsensor im Sensorless Modus)

### **Warum keinen VESC verwenden?**
Das kann mehrere Gründe haben:

* Bisher keine Unterstützung für das Xiaomi BMS Protokoll **(OHNE BMS KOMMUNIKATION LIMITIERT AUF 19A - KEINE VERWENDUNG!)**
* Kein Rücklicht - aufgrund fehlender Pins.
* Benötigter Aufwand, Geschick und Geduld. Auch bei Problemen die auftreten können beim Einbau und der Verwendung.
* **Risiko **besteht Schäden an den Komponenten zu hinterlassen, durch die falsche Konfiguration eines VESC.

### **Für dieses Guide verwendete Mittel:**
1x VESC (Flipsky 75100 - siehe "Kompatible VESCs") \
1x VESC Bluetooth Modul (Optional): 1x V6 NRF51 Wireless Bluetooth Modul ([AliExpress](https://s.click.aliexpress.com/e/_DcAvYD5)) \
3x 5mm Goldstecker F&M: ([AliExpress](https://s.click.aliexpress.com/e/_DkptS3h)) \
1x 7P JST 2,0mm Pitch Anschluss Kabel PH2.0 Stecker: ([AliExpress](https://s.click.aliexpress.com/e/_DFwOR2j)) \
1x 6P JST 2,0mm Pitch Anschluss Kabel PH2.0 Stecker: ([AliExpress](https://s.click.aliexpress.com/e/_DFwOR2j)) \
1x 1-3k Ohm Widerstand

Übliches Lötwerkzeug: T100 Lötkolben, Lötzinn und Lötpaste

<details>
<summary>Kompatible VESCs</summary>

<u>75100 Box:</u> \
-> Makerbase 75100 VESC ([AliExpress](https://s.click.aliexpress.com/e/_DmJxqxr) - 75€) \
-> Flipsky 75100 VESC ([Banggood](https://banggood.onelink.me/zMT7/zmenvmm2) - mit Honey Add-On um die 87-89€)

<u>75100 Alu PCB (**Absolute Empfehlung**):</u> \
-> Makerbase 75100 Alu PCB ([AliExpress](https://s.click.aliexpress.com/e/_DE9TKAl) - 95€) \
    -> Flipsky 75100 Alu PCB ([AliExpress](https://s.click.aliexpress.com/e/_DEXNhX3) - 151€)

<u>75200 Alu PCB (Top Performance):</u> \
-> Makerbase 75200 Alu PCB ([AliExpress](https://s.click.aliexpress.com/e/_Dk3ucKd) - 143€) \
-> Flipsky 75200 Alu PCB ([AliExpress](https://s.click.aliexpress.com/e/_DkxlJbj) - 266€)

<u>Weitere Empfehlungen:</u> \
Single Ubox 80v 100A Alu PCB ([Spintend](https://spintend.com/collections/frontpage/products/single-ubox-aluminum-controller-80v-100a-based-on-vesc)) \
MP2 300A 100V/150V VESC ([GitHub](https://github.com/badgineer/CCC_ESC) - Selbstbau)

*und viele weitere.*
</details>

## Schritte

<details>
<summary>Einbau und Vorbereitungen</summary>

## Vorbereitung des BLE / Display
Beim Xiaomi (Pro 2) überprüfen wir ob die BLE Firmware aktueller als 1.2.8 ist. Falls nicht updaten wir diese mit der SH Utility App. \
Beim G30 flashen wir vorerst die **Pro 1** Xiaomi BLE (0.9.0 - 1.2.2) Firmware auf das Display via ST-Link. Diese sind baugleich jedoch von der Software unterschiedlich!

Erfahrungsmäßig läuft das Skript deutlich reibungsloser mit der 1.2.8+ firmware, sollte aber auch wenn nicht möglich auf älteren BLE Versionen (bspw. Pro 1 oder G30 BLE) laufen.

## Vorbereitung der Verkabelung
![image](imgs/19947.jpg)

**Allgemeine Verkabelung (Strom, Motor):**

Als aller erstes haben wir das Rot (+) und Schwarz (-) Kabel für die Verbindung mit dem Akku, dort löten wir einen XT60/(oder XT90) Stecker an. \
Als nächstes gibt es es die 3x Phase Kabel für den Motor, dafür verwenden wir die 5mm Goldstecker und löten diese an die Kabel des VESCs (sowie an die Kabel des Motors). \
Für die Hallsensor Kabel des Motors verwenden wir ein 6P JST PH2.0 Stecker (oder missbrauchen den mitgelieferten Hallsensor Adapter) und verbinden GND, 5V und die HALL Pins (Reihenfolge ist bei einem VESC unwichtig - diese erkennt er automatisch). TEMP lassen wir dabei jedoch frei, wenn kein Temp Sensor am Motor vorhanden ist.

**Verkabelung für das Display**

Hierfür nutzen wir den COMM Anschluss, dieser verfügt über einen 5V, 3.3V, TX, RX und GND Pin welche wir für das Display verwenden. \
Das Original Xiaomi Display Kabel für das Xiaomi BLE verfügt über Drähte für 5V, Button, Dataline und GND.

Nun wie verbinden wir diese mit dem VESC? Wir können uns hierfür die Farben der Drähte zu nutzen machen (Nur bei den original Kabel - die Aftermarket Kabel haben häufig andere Farben - in dem Fall lieber mit der Pin Belegung abgleichen).

Wir nehmen dafür einen 7P JST 2,0mm PH2.0 Stecker und verbinden ihn wie folgt: \
<span style="color:rgb(184, 49, 47);">Rot </span>auf 5V \
<span style="color:rgb(209, 213, 216);">Schwarz </span>auf GND \
<span style="color:rgb(250, 197, 28);">Gelb </span>auf TX (UART-HDX) \
<span style="color:rgb(97, 189, 109);">Grün </span>auf RX (Button) \
1k Ohm Widerstand von <span style="color:rgb(251, 160, 38);">3.3V</span> auf <span style="color:rgb(97, 189, 109);">RX (Button)</span>

Optional: Um die Spannung zu filtern verwenden wir Kondensatoren auf <span style="color:rgb(184, 49, 47);">5V</span>+<span style="color:rgb(209, 213, 216);">GND</span>, und <span style="color:rgb(251, 160, 38);">3.3V</span>+<span style="color:rgb(209, 213, 216);">GND</span>.

![image](imgs/23999.png)

## Montieren des VESC
Wie ihr den VESC montiert ist euch überlassen, jedoch empfehle ich die direkte Befestigung der MOSFETs an einer Heatsink mit Kontakt am Gehäuse des Scooter.

**Beispiele:**
<details>
<summary>Flipsky 75100 - Original Heatsink</summary>

Beim Flipsky 75100 demontiert ihr vorerst das schwarze Gehäuse und nehmt die Platine heraus. An den MOSFETs befindet sich nun eine Aluminium Heatsink, welche ihr nun durch das Bohren von 3x Löchern an der Seite des Scooters befestigen könnt.

![image](imgs/19945.jpg)
</details>

<details>
<summary>Flipsky 75100 - Custom Heatsink</summary>

![image](imgs/42322.jpg)
![image](imgs/42323.jpg)
![image](imgs/42324.jpg)
</details>

</details>


<details>

<summary>Konfiguration des VESC</summary>


Erstmals müssen wir VESC Tool von der VESC Project Webseite ([VESC Project](https://vesc-project.com/)) herunterladen, um den Download zu erhalten müssen wir vorerst ein Konto erstellen und das kostenlose Paket "kaufen". Danach erhalten wir Zugriff auf die Downloads und wir laden nun das für unser Betriebssystem entsprechende VESC Tool herunter.

Um mit dem VESC Tool den VESC anzusteuern müssen wir diesen vorher mit dem mitgelieferten USB Kabel an einen Computer anschließen, alternativ geht auch die Verbindung über Bluetooth.

## Firmware Upgrade auf VESC 7.00
Falls unser VESC noch mit einer älteren Firmware ausgeliefert wurde, müssen wir diesen vorerst auf VESC 7.00 updaten, denn wir benötigen für die Integration des Xiaomi/NineBot Display (BLE Modul) das Lisp-Skript Feature, welches erlaubt in der Programmiersprache Lisp geschriebene Skripte auszuführen.

Damit wir den VESC upgraden können benötigen wir erstmals die neue Firmware. Diese können wir uns entweder selbst kompilieren oder wir laden sie herunter von GitHub.

<u>Jetzt fängt der eigentliche Firmware Upgrade an.</u>

* Verbinde dich mit VESC Tool mit dem VESC über den AutoConnect Knopf
* Updaten wir den Bootloader
* Gehe in den Firmware Tab
* Klicke auf den Reiter "Bootloader"
* Wähle "generic" aus (oder die andere übrige Auswahl)
* Drücke auf den Upload Button (Knopf mit Pfeil nach unten)
* Warte bis der Vorgang abgeschlossen ist.
* Updaten wir die eigentliche Firmware
* Klicke auf den Reiter "Included Files" und aktiviere die Option "Show non-default firmwares".
* Wähle nun deine Hardware Version aus (Flipsky 75100 V2: 75_100_V2, Ubox Single: UBOX_SINGLE_100)
-> Beim ersten Mal: Firmware direkt von [GitHub](https://github.com/vedderb/vesc_fw_archive/tree/main/7.00/) herunterladen und bei "Custom files" auswählen.
* Wähle nun die Firmware: VESC_default_no_hw_limits.bin (damit entsperren wir auch jegliche Limitierungen - für Power User nützlich)
* Drücke auf den Upload Button (Knopf mit Pfeil nach unten)
* Warte auf den Abschluss des Uploads und auf den Dialog. Warte bis der VESC sich neugestartet hat und verbinde dich nun wieder. (10+ Sekunden)
* Nun sollte dein VESC mit der aktuellen VESC 7.00 laufen.

## **Allgemeine Konfiguration des VESC**

**ACHTUNG**: Der Motor muss frei liegen! Der Motor wird sich beim Setup nämlich anfangen zu drehen und erschrecke dich nicht vor den Geräuschen!

* Verbinde dich mit VESC Tool mit dem VESC
* Drücke den "Setup Motors FOC" Knopf
* Beim Dialog "Load default Parameters" auf "No".
* Bei der Auswahl des Motors auf "Generic" und auf "Next", dann "Large Outrunner" und auf Next, beim Dialog auf "Yes".
* Bei der Konfiguration des Akku beim Feld "Battery Cells Series" die Anzahl der Zellen in Serie angeben (36V - 10 Stück, 48V - 13S Stück ... usw), bei "Battery capacity" die Amperestunden deines Akkus. Nun ist wichtig "Advanced" aktivieren. Bei "Battery Current Regen" die maximalen Ampere die durch Regeneration zurück in den Akku fließen dürfen. Bei "Battery Current Max" die maximalen Ampere die aus dem Akku gezogen dürfen werden (bspw. 30A). Dann auf Next.
* Direct Drive aktivieren (wir haben schließlich keine Gänge an unserem Scooter), den Durchmesser des Rads und die Anzahl der Magneten angeben (Das ist nicht so wichtig - denn dies dient lediglich der Messung der Geschwindigkeit). Nun können wir auf "Run Detection" drücken. Beim Dialog auf "No". denn wir nutzen nur einen Controller, bei mehreren auf "Yes".
* Nun startet der Erkennungsprozess und der Motor fängt an zu fiepsen und sich zu drehen.
* Nun können wir auf "FWD" drücken und erkennen ob der Motor sich falsch herum dreht oder nicht, wenn er sich falsch herum dreht dann aktiviere den "Inverted" Regler, der wird den Motor nun richtig herum drehen lassen. Dann auf "Finish".
* Wir sind nun mit den Basics fertig und können mit der Einbindung des Displays weitermachen.

</details>

<details>
<summary>Installation und Konfiguration der Display Integration</summary>

Das Skript muss nicht mehr von Hand in den Lisp Tab kopiert werden. VESC Scooter Support liegt als fertiges Paket im VESC Package Store.

**Installation:**

* Verbinde den vorher vorbereiteten Displaystecker mit dem COMM Anschluss.
* Öffne VESC Tool und verbinde dich mit dem VESC über Bluetooth, USB oder WLAN.
* Gehe auf **VESC Packages** und drücke **Update Archive**.
* Wähle unter **Applications** den Eintrag **VESC Scooter Support** und drücke **Install**.
* Öffne die App UI (VESC Tool -> Navigationsleiste -> App UI), wähle dein **Model** und drücke **Save**.
* Begutachte nun dein Display und schaue ob der Batteriestand ersichtlich ist.

![image](imgs/package-store.png)

Am Handy über den Package Store:

[![Setup am Handy](https://img.youtube.com/vi/QSrFjhdogBE/mqdefault.jpg)](https://youtu.be/QSrFjhdogBE)

Am PC über **VESC Packages -> Load Custom** mit der `.vescpkg` aus den [Releases](https://github.com/1zun4/vesc_scooter_support/releases). So kommst du an Versionen, die noch nicht im Store sind:

[![Setup am PC](https://img.youtube.com/vi/1xDxqPKV9qQ/mqdefault.jpg)](https://youtu.be/1xDxqPKV9qQ)

## Bedienung am Display

* Gashebel drücken beschleunigt ab der eingestellten Start Speed.
* Bremshebel drücken bremst mit dem Motor ab.
* Einmal drücken schaltet das Licht an und aus.
* Doppelt drücken wechselt den Speedmodus.
* Die unter **Activate With** eingestellte Knopfkombination aktiviert den geheimen Modus, ab Werk Gas und Bremse halten und doppelt drücken.
* Bremse halten und doppelt drücken sperrt den Scooter, der gleiche Ablauf entsperrt ihn wieder.
* Langes drücken schaltet den Scooter ab, einmal drücken schaltet ihn wieder an.

## Einstellungen in der App UI

Alle Einstellungen liegen in der App UI und werden im EEPROM des VESC gespeichert. Nach dem Ändern des Models startet das Skript von selbst neu.

Beim Update auf Version 2.1 werden alle Einstellungen einmalig auf die Werkseinstellungen zurückgesetzt, nur das Model bleibt erhalten.

<u>General:</u>

**Model**: `G30` für das Ninebot G30 Display, `M365/1S/PRO2` für Xiaomi M365, 1S, Essential und PRO 2, `Slave` für den zweiten ESC im Dual Setup. \
**Software ADC**: Gas und Bremse laufen über das Display. Ausgeschaltet laufen sie über die Hardware ADC Pins des VESC. \
**Motor Temp Warning (°C)** und **FET Temp Warning (°C)**: ab dieser Temperatur zeigt das Display das Warnsymbol.

<u>Modes:</u>

**Show While Idle**: was im Stand angezeigt wird (Speed, Battery %, Motor Temp, Controller Temp, Voltage, Trip, Top Speed). \
**Start Speed (km/h)**: ab dieser Geschwindigkeit werden Gas und Bremse freigegeben. \
**Speed (km/h)**, **Current Scale**, **Watts** und **Field Weakening** jeweils für Eco (Gehmodus), Drive (D) und Sport (S).

Speed gibt die maximale Geschwindigkeit an, Watts die maximale Leistung, Current Scale die prozentualen Phase Ampere von dem was im Motor Setup als Maximum eingestellt ist.

<u>Secret:</u>

**Enabled** schaltet den geheimen Modus frei. **Activate With** legt fest, womit er ein und ausgeschaltet wird:

* `Throttle + Brake + 2x Press`: Gas und Bremse halten und 2x drücken (Werkseinstellung).
* `Throttle + Brake + 3x Press`: Gas und Bremse halten und 3x drücken.
* `Throttle + 3x Press`: nur Gas halten und 3x drücken, für Scooter ohne angeschlossene Bremse.
* `Brake + 3x Press`: nur Bremse halten und 3x drücken.
* `3x Press`: 3x drücken, ohne Hebel.
* `4x Press`: 4x drücken, ohne Hebel.
* `Throttle + Hold Button`: Gas halten und den Knopf lang gedrückt halten, der Scooter schaltet dabei nicht ab.
* `Brake + Power On`: Bremse halten und den Scooter anschalten, er startet direkt im geheimen Modus. Ohne Bremse anschalten geht wieder zurück.

Die restlichen Felder sind die gleichen wie unter Modes.

<u>Alarm:</u>

**Alarm Tone**, **Speed Trigger (km/h)**, **Gyro Trigger (deg/s)** und **Volume (V)** für die Alarmanlage im gesperrten Zustand (Bremse halten und 2x Knopf drücken).

## Konfiguration der ADC App

Gas und Bremse gehen über die ADC App an den Motor, diese muss einmalig eingerichtet werden.

* **App Settings -> General**: **APP to Use** auf `ADC` stellen, dann **Write**.
* **App Settings -> ADC -> General**: **Control Type** `Current`, **Use Filter** `True`, **Safe Start** `Regular`, **Update Rate** `1000 Hz`.
* **App Settings -> ADC -> Mapping**: **ADC Mapping** öffnen, Gas und Bremse einmal komplett durchziehen und wieder loslassen, dann **Apply and Write**.

Im Dual Setup zusätzlich **Multiple VESCs Over CAN** aktivieren und das Paket auf dem zweiten ESC mit dem Model **Slave** installieren.

</details>
