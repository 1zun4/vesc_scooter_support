; VESC Scooter Support lisp script v2.0 by Izuna, AKA13 and Netzpfuscher
; Supports G30 (Ninebot), M365/1S/PRO2 (Xiaomi) dashboards and Slave ESCs - model is set in the package UI
; Tested with VESC 7.00 on Spintend Ubox Single 85 200

; -> Installation
; UART Wiring: red=5V black=GND yellow=COM-TX (UART-HDX) green=COM-RX (button)+3.3V with 1K Resistor
; Guide (German): https://rollerplausch.com/threads/vesc-controller-einbau-1s-pro2-g30.6032/

; Defaults, overwritten from EEPROM on start
(def software-adc true)
(def temp-warning-motor 100) ; temperature warning for motor in degree celsius
(def temp-warning-fet 80) ; temperature warning for fet in degree celsius
(def show-batt-in-idle true)
(def min-speed 1) ; minimum speed in km/h to enable throttle and brake

; Alarm parameters (foc-play-tone)
(def alarm-tone true)
(def alarm-speed-threshold 0.5) ; speed in km/h to trigger alarm
(def alarm-gyro-threshold 10) ; change in degree/s to trigger alarm
(def alarm-voltage 24) ; voltage for alarm sound, higher = louder
;(def alarm-frequency) ; todo: not supported yet, lower = louder, current: 2=4000, 3=7000, 6=2000

; Speed modes (km/h, watts, current scale)
(def eco-speed (/ 7 3.6))
(def eco-current 0.6)
(def eco-watts 400)
(def eco-fw 0)
(def drive-speed (/ 17 3.6))
(def drive-current 0.7)
(def drive-watts 500)
(def drive-fw 0)
(def sport-speed (/ 22 3.6))
(def sport-current 1.0)
(def sport-watts 700)
(def sport-fw 0)

; Secret speed modes. To enable, press the button 2 times while holding break and throttle at the same time.
(def secret-enabled true)
(def secret-eco-speed (/ 27 3.6))
(def secret-eco-current 1.0)
(def secret-eco-watts 1200)
(def secret-eco-fw 0)
(def secret-drive-speed (/ 47 3.6))
(def secret-drive-current 1.0)
(def secret-drive-watts 1500000)
(def secret-drive-fw 0)
(def secret-sport-speed (/ 1000 3.6)) ; 1000 km/h easy
(def secret-sport-current 1.0)
(def secret-sport-watts 1500000)
(def secret-sport-fw 10)

; -> Code starts here (DO NOT CHANGE ANYTHING BELOW THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING)

; Load VESC CAN code serer
(import "pkg@://vesc_packages/lib_code_server/code_server.vescpkg" 'code-server)
(read-eval-program code-server)

; Model (0=G30, 1=M365/1S/PRO2, 2=Slave)
(def model 0)

; Protocol offsets, set per model in main
(def tx-base 7) ; first dash field in tx-frame
(def thr-idx 5) ; throttle byte in uart-buf
(def brk-idx 6) ; brake byte in uart-buf

; Button handling
(def press-time (systime))
(def presses 0)
(def last-button-state false)

; Mode states
(def off false)
(def lock false)
(def speedmode 4)
(def light false)
(def unlock false)

; alarm states
(def alarm 0)
(def alarm-time (systime))

; sound feedback
(def feedback 0)

@const-start

(def settings-version 300i32)
(def button-safety-speed (/ 0.1 3.6)) ; disabling button above 0.1 km/h (due to safety reasons)
(def min-adc-throttle 0.1) ; throttle and brake needed to reach the secret modes
(def min-adc-brake 0.1)

; Persistent settings: (label . (eeprom-offset type))
(def eeprom-addrs '(
    (ver-code              . (0 i))
    (software-adc          . (1 b))
    ; offsets 2 and 3 are free, never renumber in use
    (temp-warning-motor    . (4 f))
    (temp-warning-fet      . (5 f))
    (show-batt-in-idle     . (6 b))
    (min-speed-kmh         . (7 f))
    (alarm-tone            . (8 b))
    (alarm-speed-threshold . (9 f))
    (alarm-gyro-threshold  . (10 f))
    (alarm-voltage         . (11 f))
    (eco-speed-kmh         . (12 f))
    (eco-current           . (13 f))
    (eco-watts             . (14 f))
    (eco-fw                . (15 f))
    (drive-speed-kmh       . (16 f))
    (drive-current         . (17 f))
    (drive-watts           . (18 f))
    (drive-fw              . (19 f))
    (sport-speed-kmh       . (20 f))
    (sport-current         . (21 f))
    (sport-watts           . (22 f))
    (sport-fw              . (23 f))
    (secret-enabled        . (24 b))
    (secret-eco-speed-kmh  . (25 f))
    (secret-eco-current    . (26 f))
    (secret-eco-watts      . (27 f))
    (secret-eco-fw         . (28 f))
    (secret-drive-speed-kmh . (29 f))
    (secret-drive-current  . (30 f))
    (secret-drive-watts    . (31 f))
    (secret-drive-fw       . (32 f))
    (secret-sport-speed-kmh . (33 f))
    (secret-sport-current  . (34 f))
    (secret-sport-watts    . (35 f))
    (secret-sport-fw       . (36 f))
    (model                 . (37 i))
))

(defun read-setting (name)
    (let (
            (addr (first (assoc eeprom-addrs name)))
            (type (second (assoc eeprom-addrs name)))
        )
        (cond
            ((eq type 'i) (eeprom-read-i addr))
            ((eq type 'f) (eeprom-read-f addr))
            ((eq type 'b) (!= (eeprom-read-i addr) 0))
)))

(defun write-setting (name val)
    (let (
            (addr (first (assoc eeprom-addrs name)))
            (type (second (assoc eeprom-addrs name)))
        )
        (cond
            ((eq type 'i) (eeprom-store-i addr val))
            ((eq type 'f) (eeprom-store-f addr val))
            ((eq type 'b) (eeprom-store-i addr (if val 1 0)))
)))

(defun valid-model (m) ; eeprom reads nil when never written
    (and (not (eq m nil)) (>= m 0) (<= m 2))
)

(defun restore-defaults ()
    {
        (var cur-model (read-setting 'model)) ; keep model across restores
        (write-setting 'software-adc true)
        (write-setting 'temp-warning-motor 100.0)
        (write-setting 'temp-warning-fet 80.0)
        (write-setting 'show-batt-in-idle true)
        (write-setting 'min-speed-kmh 1.0)
        (write-setting 'alarm-tone true)
        (write-setting 'alarm-speed-threshold 0.5)
        (write-setting 'alarm-gyro-threshold 10.0)
        (write-setting 'alarm-voltage 24.0)
        (write-setting 'eco-speed-kmh 7.0)
        (write-setting 'eco-current 0.6)
        (write-setting 'eco-watts 400.0)
        (write-setting 'eco-fw 0.0)
        (write-setting 'drive-speed-kmh 17.0)
        (write-setting 'drive-current 0.7)
        (write-setting 'drive-watts 500.0)
        (write-setting 'drive-fw 0.0)
        (write-setting 'sport-speed-kmh 22.0)
        (write-setting 'sport-current 1.0)
        (write-setting 'sport-watts 700.0)
        (write-setting 'sport-fw 0.0)
        (write-setting 'secret-enabled true)
        (write-setting 'secret-eco-speed-kmh 27.0)
        (write-setting 'secret-eco-current 1.0)
        (write-setting 'secret-eco-watts 1200.0)
        (write-setting 'secret-eco-fw 0.0)
        (write-setting 'secret-drive-speed-kmh 47.0)
        (write-setting 'secret-drive-current 1.0)
        (write-setting 'secret-drive-watts 1500000.0)
        (write-setting 'secret-drive-fw 0.0)
        (write-setting 'secret-sport-speed-kmh 1000.0)
        (write-setting 'secret-sport-current 1.0)
        (write-setting 'secret-sport-watts 1500000.0)
        (write-setting 'secret-sport-fw 10.0)
        (write-setting 'model (if (valid-model cur-model) cur-model 0))
        (write-setting 'ver-code settings-version)
    }
)

(defun load-settings ()
    {
        (if (not-eq (read-setting 'ver-code) settings-version)
            (restore-defaults)
        )

        (set 'software-adc (read-setting 'software-adc))
        (set 'temp-warning-motor (read-setting 'temp-warning-motor))
        (set 'temp-warning-fet (read-setting 'temp-warning-fet))
        (set 'show-batt-in-idle (read-setting 'show-batt-in-idle))
        (set 'min-speed (read-setting 'min-speed-kmh))
        (set 'alarm-tone (read-setting 'alarm-tone))
        (set 'alarm-speed-threshold (read-setting 'alarm-speed-threshold))
        (set 'alarm-gyro-threshold (read-setting 'alarm-gyro-threshold))
        (set 'alarm-voltage (read-setting 'alarm-voltage))
        (set 'eco-speed (/ (read-setting 'eco-speed-kmh) 3.6))
        (set 'eco-current (read-setting 'eco-current))
        (set 'eco-watts (read-setting 'eco-watts))
        (set 'eco-fw (read-setting 'eco-fw))
        (set 'drive-speed (/ (read-setting 'drive-speed-kmh) 3.6))
        (set 'drive-current (read-setting 'drive-current))
        (set 'drive-watts (read-setting 'drive-watts))
        (set 'drive-fw (read-setting 'drive-fw))
        (set 'sport-speed (/ (read-setting 'sport-speed-kmh) 3.6))
        (set 'sport-current (read-setting 'sport-current))
        (set 'sport-watts (read-setting 'sport-watts))
        (set 'sport-fw (read-setting 'sport-fw))
        (set 'secret-enabled (read-setting 'secret-enabled))
        (set 'secret-eco-speed (/ (read-setting 'secret-eco-speed-kmh) 3.6))
        (set 'secret-eco-current (read-setting 'secret-eco-current))
        (set 'secret-eco-watts (read-setting 'secret-eco-watts))
        (set 'secret-eco-fw (read-setting 'secret-eco-fw))
        (set 'secret-drive-speed (/ (read-setting 'secret-drive-speed-kmh) 3.6))
        (set 'secret-drive-current (read-setting 'secret-drive-current))
        (set 'secret-drive-watts (read-setting 'secret-drive-watts))
        (set 'secret-drive-fw (read-setting 'secret-drive-fw))
        (set 'secret-sport-speed (/ (read-setting 'secret-sport-speed-kmh) 3.6))
        (set 'secret-sport-current (read-setting 'secret-sport-current))
        (set 'secret-sport-watts (read-setting 'secret-sport-watts))
        (set 'secret-sport-fw (read-setting 'secret-sport-fw))

        (var m (read-setting 'model))
        (if (not (valid-model m)) {
            (setq m 0)
            (write-setting 'model m)
        })
        (set 'model m)
    }
)

(defun apply-software-adc ()
    (if software-adc
        (app-adc-detach 3 1)
        (app-adc-detach 3 0)
    )
)

(defun apply-runtime-settings ()
    {
        (load-settings)
        (if (!= model 2) { ; slave must not push conf to the master
            (apply-software-adc)
            (apply-mode)
        })
    }
)

(defun save-general-settings (adc show-batt min-speed-kmh)
    {
        (write-setting 'software-adc adc)
        (write-setting 'show-batt-in-idle show-batt)
        (write-setting 'min-speed-kmh min-speed-kmh)
    }
)

(defun save-temp-settings (motor-warning fet-warning)
    {
        (write-setting 'temp-warning-motor motor-warning)
        (write-setting 'temp-warning-fet fet-warning)
    }
)

(defun save-mode-settings (
        eco-speed-kmh eco-current eco-watts eco-fw
        drive-speed-kmh drive-current drive-watts drive-fw
        sport-speed-kmh sport-current sport-watts sport-fw)
    {
        (write-setting 'eco-speed-kmh eco-speed-kmh)
        (write-setting 'eco-current eco-current)
        (write-setting 'eco-watts eco-watts)
        (write-setting 'eco-fw eco-fw)
        (write-setting 'drive-speed-kmh drive-speed-kmh)
        (write-setting 'drive-current drive-current)
        (write-setting 'drive-watts drive-watts)
        (write-setting 'drive-fw drive-fw)
        (write-setting 'sport-speed-kmh sport-speed-kmh)
        (write-setting 'sport-current sport-current)
        (write-setting 'sport-watts sport-watts)
        (write-setting 'sport-fw sport-fw)
    }
)

(defun save-secret-settings (
        enabled
        eco-speed-kmh eco-current eco-watts eco-fw
        drive-speed-kmh drive-current drive-watts drive-fw
        sport-speed-kmh sport-current sport-watts sport-fw)
    {
        (write-setting 'secret-enabled enabled)
        (write-setting 'secret-eco-speed-kmh eco-speed-kmh)
        (write-setting 'secret-eco-current eco-current)
        (write-setting 'secret-eco-watts eco-watts)
        (write-setting 'secret-eco-fw eco-fw)
        (write-setting 'secret-drive-speed-kmh drive-speed-kmh)
        (write-setting 'secret-drive-current drive-current)
        (write-setting 'secret-drive-watts drive-watts)
        (write-setting 'secret-drive-fw drive-fw)
        (write-setting 'secret-sport-speed-kmh sport-speed-kmh)
        (write-setting 'secret-sport-current sport-current)
        (write-setting 'secret-sport-watts sport-watts)
        (write-setting 'secret-sport-fw sport-fw)
    }
)

(defun save-alarm-settings (tone speed-threshold gyro-threshold voltage)
    {
        (write-setting 'alarm-tone tone)
        (write-setting 'alarm-speed-threshold speed-threshold)
        (write-setting 'alarm-gyro-threshold gyro-threshold)
        (write-setting 'alarm-voltage voltage)
    }
)

; UI restarts lisp after "model-ok" so the new model takes effect
(defun save-model (m)
    {
        (write-setting 'model (if (valid-model m) m 0))
        (send-data "model-ok")
    }
)

(defun finish-settings-save ()
    {
        (apply-runtime-settings)
        (send-settings)
        (send-data "ok")
    }
)

(defun restore-settings-ui ()
    {
        (restore-defaults)
        (finish-settings-save)
    }
)

(defun send-settings ()
    {
        (send-data (str-merge
            "model "
            (str-from-n (read-setting 'model) "%d")
        ))
        (send-data (str-merge
            "general "
            (if (read-setting 'software-adc) "true " "false ")
            (if (read-setting 'show-batt-in-idle) "true " "false ")
            (str-from-n (read-setting 'min-speed-kmh) "%.1f")
        ))
        (send-data (str-merge
            "temps "
            (str-from-n (read-setting 'temp-warning-motor) "%.1f ")
            (str-from-n (read-setting 'temp-warning-fet) "%.1f")
        ))
        (send-data (str-merge
            "modes "
            (str-from-n (read-setting 'eco-speed-kmh) "%.1f ")
            (str-from-n (read-setting 'eco-current) "%.2f ")
            (str-from-n (read-setting 'eco-watts) "%.0f ")
            (str-from-n (read-setting 'eco-fw) "%.1f ")
            (str-from-n (read-setting 'drive-speed-kmh) "%.1f ")
            (str-from-n (read-setting 'drive-current) "%.2f ")
            (str-from-n (read-setting 'drive-watts) "%.0f ")
            (str-from-n (read-setting 'drive-fw) "%.1f ")
            (str-from-n (read-setting 'sport-speed-kmh) "%.1f ")
            (str-from-n (read-setting 'sport-current) "%.2f ")
            (str-from-n (read-setting 'sport-watts) "%.0f ")
            (str-from-n (read-setting 'sport-fw) "%.1f")
        ))
        (send-data (str-merge
            "secret "
            (if (read-setting 'secret-enabled) "true " "false ")
            (str-from-n (read-setting 'secret-eco-speed-kmh) "%.1f ")
            (str-from-n (read-setting 'secret-eco-current) "%.2f ")
            (str-from-n (read-setting 'secret-eco-watts) "%.0f ")
            (str-from-n (read-setting 'secret-eco-fw) "%.1f ")
            (str-from-n (read-setting 'secret-drive-speed-kmh) "%.1f ")
            (str-from-n (read-setting 'secret-drive-current) "%.2f ")
            (str-from-n (read-setting 'secret-drive-watts) "%.0f ")
            (str-from-n (read-setting 'secret-drive-fw) "%.1f ")
            (str-from-n (read-setting 'secret-sport-speed-kmh) "%.1f ")
            (str-from-n (read-setting 'secret-sport-current) "%.2f ")
            (str-from-n (read-setting 'secret-sport-watts) "%.0f ")
            (str-from-n (read-setting 'secret-sport-fw) "%.1f")
        ))
        (send-data (str-merge
            "alarm "
            (if (read-setting 'alarm-tone) "true " "false ")
            (str-from-n (read-setting 'alarm-speed-threshold) "%.1f ")
            (str-from-n (read-setting 'alarm-gyro-threshold) "%.1f ")
            (str-from-n (read-setting 'alarm-voltage) "%.1f")
        ))
    }
)

(defun event-handler ()
    (loopwhile t
        (recv
            ((event-data-rx . (? data)) (trap (eval (read data))))
            (_ nil)
)))

(defun adc-input(buffer) ; Frame 0x65
    {
        (let ((throttle (/(bufget-u8 uart-buf thr-idx) 77.2)) ; 255/3.3 = 77.2
            (brake (/(bufget-u8 uart-buf brk-idx) 77.2)))
            {
                (if (< throttle 0)
                    (setf throttle 0))
                (if (> throttle 3.3)
                    (setf throttle 3.3))
                (if (< brake 0)
                    (setf brake 0))
                (if (> brake 3.3)
                    (setf brake 3.3))

                ; Pass through throttle and brake to VESC
                (app-adc-override 0 throttle)
                (app-adc-override 1 brake)
            }
        )
    }
)

(defun handle-features()
    {
        (var current-speed (* (get-lowest-speed) 3.6))

        (if (or off lock (< current-speed min-speed))
            (if (not (app-is-output-disabled)) ; Disable output when scooter is turned off
                {
                    (app-adc-override 0 0)
                    (app-adc-override 1 0)
                    (app-disable-output -1)
                    (set-current 0)
                    ; rcode canset
                    ;(loopforeach i (can-list-devs)
                    ;    (canset-current i 0)
                    ;)
                }
            )
            (if (app-is-output-disabled) ; Enable output when scooter is turned on
                (app-disable-output 0)
            )
        )

        (handle-lock (abs current-speed))
    }
)

(defun update-dash(buffer) ; Frame 0x64
    {
        (var current-speed (abs (* (get-lowest-speed) 3.6)))
        (var battery (*(get-batt) 100))
        (var crc-end (- (buflen tx-frame) 2)) ; crc bytes at end of frame

        ; mode field (1=drive, 2=eco, 4=sport, 8=charge, 16=off, 32=lock)
        (if off
            (bufset-u8 tx-frame tx-base 16)
            (if lock
                (bufset-u8 tx-frame tx-base 32) ; lock display
                (if (or (> (get-temp-fet) temp-warning-fet) (> (get-temp-mot) temp-warning-motor)) ; temp icon will show up above warning degree
                    (bufset-u8 tx-frame tx-base (+ 128 speedmode))
                    (bufset-u8 tx-frame tx-base speedmode)
                )
            )
        )

        ; batt field
        (if lock
            (bufset-u8 tx-frame (+ tx-base 1) 0) ; lock display
            (bufset-u8 tx-frame (+ tx-base 1) battery)
        )

        ; light field
        (if (not off)
            (if (> alarm 4)
                (bufset-u8 tx-frame (+ tx-base 2) 1) ; alarm on
                (bufset-u8 tx-frame (+ tx-base 2) (if light 1 0))
            )
            (bufset-u8 tx-frame (+ tx-base 2) 0)
        )

        ; beep field
        (if (> feedback 0)
            {
                (bufset-u8 tx-frame (+ tx-base 3) 1)
                (set 'feedback (- feedback 1))
            }
            (bufset-u8 tx-frame (+ tx-base 3) 0)
        )

        ; speed field
        (if lock
            (bufset-u8 tx-frame (+ tx-base 4) 0) ; lock display
            (if (and show-batt-in-idle unlock)
                (if (> current-speed 1)
                    (bufset-u8 tx-frame (+ tx-base 4) current-speed)
                    (bufset-u8 tx-frame (+ tx-base 4) battery))
                (bufset-u8 tx-frame (+ tx-base 4) current-speed)
            )
        )

        ; error field
        (if (> alarm 0)
            (bufset-u8 tx-frame (+ tx-base 5) 99) ; alarm active
            (bufset-u8 tx-frame (+ tx-base 5) (get-fault))
        )

        ; calc crc

        (var crcout 0)
        (looprange i 2 crc-end
        (set 'crcout (+ crcout (bufget-u8 tx-frame i))))
        (set 'crcout (bitwise-xor crcout 0xFFFF))
        (bufset-u8 tx-frame crc-end crcout)
        (bufset-u8 tx-frame (+ crc-end 1) (shr crcout 8))

        ; write
        (uart-write tx-frame)
    }
)

(defun read-frames-g30()
    (loopwhile t
        {
            (uart-read-bytes uart-buf 3 0)
            (if (= (bufget-u16 uart-buf 0) 0x5aa5)
                {
                    (var len (bufget-u8 uart-buf 2))
                    (var crc len)
                    (if (and (> len 0) (< len 60)) ; max 64 bytes
                        {
                            (uart-read-bytes uart-buf (+ len 6) 0) ;read remaining 6 bytes + payload, overwrite buffer

                            (let ((code (bufget-u8 uart-buf 2)) (checksum (bufget-u16 uart-buf (+ len 4))))
                                {
                                    (looprange i 0 (+ len 4) (set 'crc (+ crc (bufget-u8 uart-buf i))))

                                    (if (= checksum (bitwise-and (+ (shr (bitwise-xor crc 0xFFFF) 8) (shl (bitwise-xor crc 0xFFFF) 8)) 65535)) ;If the calculated checksum matches with sent checksum, forward comman
                                        {
                                            (if (and (= code 0x65) software-adc)
                                                (adc-input uart-buf)
                                            )
                                            (if (= code 0x64) ; dash reply only on 0x64
                                                (update-dash uart-buf)
                                            )
                                        }
                                    )
                                }
                            )
                        }
                    )
                }
            )
        }
    )
)

(defun read-frames-m365()
    (loopwhile t
        {
            (uart-read-bytes uart-buf 3 0)
            (if (= (bufget-u16 uart-buf 0) 0x55aa)
                {
                    (var len (bufget-u8 uart-buf 2))
                    (var crc len)
                    (if (and (> len 0) (< len 60)) ; max 64 bytes
                        {
                            (uart-read-bytes uart-buf (+ len 4) 0)
                            (looprange i 0 len
                                (set 'crc (+ crc (bufget-u8 uart-buf i))))
                            (if (=(+(shl(bufget-u8 uart-buf (+ len 2))8) (bufget-u8 uart-buf (+ len 1))) (bitwise-xor crc 0xFFFF))
                                {
                                    (if (and (= (bufget-u8 uart-buf 1) 0x65) software-adc)
                                        (adc-input uart-buf)
                                    )
                                    (update-dash uart-buf) ; dash expects a reply on every frame
                                }
                            )
                        }
                    )
                }
            )
        }
    )
)

(defun handle-button()
    (if (= presses 1) ; single press
        (if off ; is it off? turn on scooter again
            {
                (set 'off false) ; turn on
                (set 'feedback 1) ; beep feedback
                (set 'unlock false) ; Disable unlock on turn off
                (apply-mode) ; Apply mode on start-up
                (stats-reset) ; reset stats when turning on
            }
            (if lock ; is it locked?
                (set 'feedback 1) ; beep feedback
                (set 'light (not light)) ; toggle light
            )

        )
        (if (>= presses 2) ; double press
            {
                (if (> (get-adc-decoded 1) min-adc-brake) ; if brake is pressed
                    (if (and secret-enabled (> (get-adc-decoded 0) min-adc-throttle))
                        {
                            (set 'unlock (not unlock))
                            (set 'feedback 2) ; beep 2x
                            (apply-mode)
                        }
                        {
                            (set 'unlock false)
                            (apply-mode)
                            (set 'lock (not lock)) ; lock on or off
                            (set 'light false) ; turn off light when locking
                            (set 'feedback 1) ; beep feedback
                            (if (not lock)
                                (stop-alarm)
                            )
                        }
                    )
                    {
                        (if (not lock)
                            {
                                (cond
                                    ((= speedmode 1) (set 'speedmode 4))
                                    ((= speedmode 2) (set 'speedmode 1))
                                    ((= speedmode 4) (set 'speedmode 2))
                                )
                                (apply-mode)
                            }
                        )
                    }
                )
            }
        )
    )
)

(defun handle-holding-button()
    {
        (if (and (not lock) (not off)) ; it is locked and off?
            {
                (set 'light false) ; turn off light
                (set 'feedback 1) ; beep feedback
                (set 'unlock false) ; Disable unlock on turn off
                (apply-mode)
                (set 'off true) ; turn off
            }
        )
    }
)

(defun reset-button()
    {
        (set 'press-time (systime)) ; reset press time again
        (set 'presses 0)
    }
)

; Speed mode implementation
(defun apply-mode()
    (if (not unlock)
        (cond
            ((= speedmode 1) (configure-speed drive-speed drive-watts drive-current drive-fw))
            ((= speedmode 2) (configure-speed eco-speed eco-watts eco-current eco-fw))
            ((= speedmode 4) (configure-speed sport-speed sport-watts sport-current sport-fw))
        )
        (cond
            ((= speedmode 1) (configure-speed secret-drive-speed secret-drive-watts secret-drive-current secret-drive-fw))
            ((= speedmode 2) (configure-speed secret-eco-speed secret-eco-watts secret-eco-current secret-eco-fw))
            ((= speedmode 4) (configure-speed secret-sport-speed secret-sport-watts secret-sport-current secret-sport-fw))
        )
    )
)

(defun configure-speed(speed watts current fw)
    {
        (set-param 'max-speed speed)
        (set-param 'l-watt-max watts)
        (set-param 'l-current-max-scale current)
        (set-param 'foc-fw-current-max fw)
    }
)

(defun set-param(param value)
    {
        (conf-set param value)
        (loopforeach id (can-list-devs)
            (looprange i 0 5 {
                (if (eq (rcode-run id 0.1 `(conf-set (quote ,param) ,value)) t) (break t))
                false
            })
        )
    }
)

(defun start-alarm()
    (if (= alarm 0)
        {
            (set 'alarm 1)
            (set 'alarm-time (systime))
            (print "Alarm started")
        }
    )
)

(defun stop-alarm()
    (if (> alarm 0)
        {
            (set 'alarm 0)
            (set-brake-rel 0)
            (stop-tone)
            (print "Alarm stopped")
        }
    )
)

(defun handle-lock(speed)
    {
        ; alarm detection
        (var gyro (get-gyro))
        (cond
            ; gyro detects movement while locked
            ((and lock (or (> (abs (ix gyro 0)) alarm-gyro-threshold) (> (abs (ix gyro 1)) alarm-gyro-threshold) (> (abs (ix gyro 2)) alarm-gyro-threshold))) ; locked and moving
                (start-alarm)
            )
            ; wheel is moving while locked
            ((and lock (> speed alarm-speed-threshold))
                (start-alarm)
            )
            ; not locked or not moving (> 3 seconds)
            ((or (not lock) (> (secs-since alarm-time) 3))
                (stop-alarm)
            )
        )

        ; lock power control
        (if lock
            {
                (set-current-rel 0) ; No current input when locked
                (if (and (> alarm 0) (> speed 0.0))
                    (set-brake-rel 1) ; Full power brake
                    (set-brake-rel 0) ; No brake
                )
            }
        )

        ; alarm sound handling
        (cond
            ((= alarm 2) ; first tone
                {
                    (if alarm-tone
                        (play-tone 0 4000 alarm-voltage)
                    )
                    (set 'feedback 1)
                }
            )
            ((= alarm 3) ; second tone
                {
                    (if alarm-tone
                        (play-tone 2 7000 alarm-voltage)
                    )
                    (set 'feedback 1)
                }
            )
            ((= alarm 6) ; third tone
                {
                    (if alarm-tone
                        (play-tone 1 2000 alarm-voltage)
                    )
                    (set 'feedback 1)
                }

            )
            ((= alarm 8) ; repeat alarm sound
                {
                    (if alarm-tone
                        (stop-tone)
                    )
                    (set 'feedback 1)
                    (set 'alarm 1) ; reset alarm to 1
                }
            )
        )

        ; count up alarm state
        (if (> alarm 0)
            (set 'alarm (+ alarm 1))
        )
    }
)

(defun play-tone(channel freq voltage)
    {
        (foc-play-tone channel freq voltage)
        (loopforeach id (can-list-devs)
            (rcode-run-noret id `(foc-play-tone ,channel ,freq ,voltage))
        )
    }
)

(defun stop-tone()
    {
        (foc-play-stop)
        (loopforeach id (can-list-devs)
            (rcode-run-noret id '(foc-play-stop))
        )
    }
)

(defun get-lowest-speed()
    {
        (var speed (get-speed))
        (loopforeach i (can-list-devs)
            {
                (var can-speed (canget-speed i))
                (if (< can-speed speed)
                    (set 'speed can-speed)
                )
            }
        )

        speed
    }
)

; finds gyro that does not respond with (0,0,0)
(defunret get-gyro()
    {
        (var gyro (get-imu-gyro))
        (if (and (= (length gyro) 3)
                (or (> (abs (ix gyro 0)) 0)
                (> (abs (ix gyro 1)) 0)
                (> (abs (ix gyro 2)) 0)))
            (return gyro)
        )

        (loopforeach i (can-list-devs)
            {
                (var can-gyro (rcode-run i 0.5 '(get-imu-gyro)))

                (if (and (eq (type-of can-gyro) 'type-list)
                        (= (length can-gyro) 3)
                        (or (> (abs (ix can-gyro 0)) 0)
                        (> (abs (ix can-gyro 1)) 0)
                        (> (abs (ix can-gyro 2)) 0)))
                    (return can-gyro)
                )
            }
        )

        gyro
    }
)

(defun read-button-pin()
    {
        (var sample-num 3)
        (var sample-sum 0)

        (looprange i 0 sample-num {
            (sleep 0.02)
            (setq sample-sum (+ sample-sum (gpio-read 'pin-rx)))
        })

        (= (if (> sample-sum (/ sample-num 2)) 1 0) 0)
    }
)

(defun button-logic()
    {
        (loopwhile t
            {
                (var button-state (read-button-pin))

                (if (and button-state (not last-button-state))
                    {
                        (set 'presses (+ presses 1))
                        (set 'press-time (systime))
                    }
                )

                (button-apply button-state)

                (set 'last-button-state button-state)
                (handle-features)
            }
        )
    }
)

(defun button-apply(button)
    {
        (var time-passed (- (systime) press-time))
        (var is-active (or off (<= (get-speed) button-safety-speed)))

        (if (> time-passed 2500) ; after 2500 ms
            (if button ; check button is still pressed
                (if (> time-passed 6000) ; long press after 6000 ms
                    {
                        (if is-active
                            (handle-holding-button)
                        )
                        (reset-button) ; reset button
                    }
                )
                (if (> presses 0) ; if presses > 0
                    {
                        (if is-active
                            (handle-button) ; handle button presses
                        )
                        (reset-button) ; reset button
                    }
                )
            )
        )
    }
)

(defun main () {
        (load-settings)

        (event-register-handler (spawn event-handler))
        (event-enable 'event-data-rx)

        (if (= model 2) { ; Slave: code server only, model stays switchable over CAN
            (start-code-server)
        } {
            ; Packet handling
            (uart-start 115200 'half-duplex)
            (gpio-configure 'pin-rx 'pin-mode-in-pu)
            (def uart-buf (array-create 64))

            (if (= model 1) {
                (define tx-frame (array-create 14))
                (bufset-u16 tx-frame 0 0x55AA) ;Xiaomi protocol
                (bufset-u16 tx-frame 2 0x0821)
                (bufset-u16 tx-frame 4 0x6400) ; Packet is from ESC to BLE
                (set 'tx-base 6)
                (set 'thr-idx 4)
                (set 'brk-idx 5)
            } {
                (define tx-frame (array-create 15))
                (bufset-u16 tx-frame 0 0x5AA5) ;Ninebot protocol
                (bufset-u8 tx-frame 2 0x06) ;Payload length is 5 bytes
                (bufset-u16 tx-frame 3 0x2021) ; Packet is from ESC to BLE
                (bufset-u16 tx-frame 5 0x6400) ; Packet is from ESC to BLE
                (set 'tx-base 7)
                (set 'thr-idx 5)
                (set 'brk-idx 6)
            })

            (apply-software-adc)

            ; Apply mode on start-up
            (apply-mode)

            ; Spawn UART reading frames thread
            (if (= model 1)
                (spawn 150 read-frames-m365)
                (spawn 150 read-frames-g30)
            )
            (button-logic) ; Start button logic in main thread - this will block the main thread
        })
})

@const-end

(image-save)
(main)
