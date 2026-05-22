; G30 dashboard support lisp script v1.3 by Izuna and AKA13
; Tested with VESC 7.00 on Spintend Ubox Single 85 200

; -> Installation
; UART Wiring: red=5V black=GND yellow=COM-TX (UART-HDX) green=COM-RX (button)+3.3V with 1K Resistor
; Guide (German): https://rollerplausch.com/threads/vesc-controller-einbau-1s-pro2-g30.6032/

; -> User parameters (change these to your needs)
(def software-adc 1)
(def min-adc-throttle 0.1)
(def min-adc-brake 0.1)
(def temp-warning-motor 100) ; temperature warning for motor in degree celsius
(def temp-warning-fet 80) ; temperature warning for fet in degree celsius
(def show-batt-in-idle 1)
(def min-speed 1) ; minimum speed in km/h to enable throttle and brake
(def button-safety-speed (/ 0.1 3.6)) ; disabling button above 0.1 km/h (due to safety reasons)

; Alarm parameters (foc-play-tone)
(def alarm-tone 1)
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
(def secret-enabled 1)
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

; Button handling
(def press-time (systime))
(def presses 0)

; Mode states
(def off 0)
(def lock 0)
(def speedmode 4)
(def light 0)
(def unlock 0)

; alarm states
(def alarm 0)
(def alarm-time (systime))

; sound feedback
(def feedback 0)

(defun adc-input(buffer) ; Frame 0x65
    {
        (let ((throttle (/(bufget-u8 uart-buf 5) 77.2)) ; 255/3.3 = 77.2
            (brake (/(bufget-u8 uart-buf 6) 77.2)))
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

        (if (or (or (= off 1) (= lock 1) (< current-speed min-speed)))
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

        ; mode field (1=drive, 2=eco, 4=sport, 8=charge, 16=off, 32=lock)
        (if (= off 1)
            (bufset-u8 tx-frame 7 16)
            (if (= lock 1)
                (bufset-u8 tx-frame 7 32) ; lock display
                (if (or (> (get-temp-fet) temp-warning-fet) (> (get-temp-mot) temp-warning-motor)) ; temp icon will show up above warning degree
                    (bufset-u8 tx-frame 7 (+ 128 speedmode))
                    (bufset-u8 tx-frame 7 speedmode)
                )
            )
        )

        ; batt field
        (if (= lock 1)
            (bufset-u8 tx-frame 8 0) ; lock display
            (bufset-u8 tx-frame 8 battery)
        )

        ; light field
        (if (= off 0)
            (if (> alarm 4)
                (bufset-u8 tx-frame 9 1) ; alarm on
                (bufset-u8 tx-frame 9 light)
            )
            (bufset-u8 tx-frame 9 0)
        )

        ; beep field
        (if (> feedback 0)
            {
                (bufset-u8 tx-frame 10 1)
                (set 'feedback (- feedback 1))
            }
            (bufset-u8 tx-frame 10 0)
        )

        (if (= lock 1)
            (bufset-u8 tx-frame 11 0) ; lock display
            (if (= (+ show-batt-in-idle unlock) 2)
                (if (> current-speed 1)
                    (bufset-u8 tx-frame 11 current-speed)
                    (bufset-u8 tx-frame 11 battery))
                (bufset-u8 tx-frame 11 current-speed)
            )
        )

        ; error field
        (if (> alarm 0)
            (bufset-u8 tx-frame 12 99) ; alarm active
            (bufset-u8 tx-frame 12 (get-fault))
        )

        ; calc crc

        (var crcout 0)
        (looprange i 2 13
        (set 'crcout (+ crcout (bufget-u8 tx-frame i))))
        (set 'crcout (bitwise-xor crcout 0xFFFF))
        (bufset-u8 tx-frame 13 crcout)
        (bufset-u8 tx-frame 14 (shr crcout 8))

        ; write
        (uart-write tx-frame)
    }
)

(defun read-frames()
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
                                        (handle-frame code)
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

(defun handle-frame(code)
    {
        (if (and (= code 0x65) (= software-adc 1))
            (adc-input uart-buf)
        )

        (if(= code 0x64)
            (update-dash uart-buf)
        )
    }
)

(defun handle-button()
    (if (= presses 1) ; single press
        (if (= off 1) ; is it off? turn on scooter again
            {
                (set 'off 0) ; turn on
                (set 'feedback 1) ; beep feedback
                (set 'unlock 0) ; Disable unlock on turn off
                (apply-mode) ; Apply mode on start-up
                (stats-reset) ; reset stats when turning on
            }
            (if (= lock 1) ; is it locked?
                (set 'feedback 1) ; beep feedback
                (set 'light (bitwise-xor light 1)) ; toggle light
            )

        )
        (if (>= presses 2) ; double press
            {
                (if (> (get-adc-decoded 1) min-adc-brake) ; if brake is pressed
                    (if (and (= secret-enabled 1) (> (get-adc-decoded 0) min-adc-throttle))
                        {
                            (set 'unlock (bitwise-xor unlock 1))
                            (set 'feedback 2) ; beep 2x
                            (apply-mode)
                        }
                        {
                            (set 'unlock 0)
                            (apply-mode)
                            (set 'lock (bitwise-xor lock 1)) ; lock on or off
                            (set 'light 0) ; turn off light when locking
                            (set 'feedback 1) ; beep feedback
                            (if (= lock 0)
                                (stop-alarm)
                            )
                        }
                    )
                    {
                        (if (= lock 0)
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
        (if (= (+ lock off) 0) ; it is locked and off?
            {
                (set 'light 0) ; turn off light
                (set 'feedback 1) ; beep feedback
                (set 'unlock 0) ; Disable unlock on turn off
                (apply-mode)
                (set 'off 1) ; turn off
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
    (if (= unlock 0)
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
            ((and (= lock 1) (or (> (abs (ix gyro 0)) alarm-gyro-threshold) (> (abs (ix gyro 1)) alarm-gyro-threshold) (> (abs (ix gyro 2)) alarm-gyro-threshold))) ; locked and moving
                (start-alarm)
            )
            ; wheel is moving while locked
            ((and (= lock 1) (> speed alarm-speed-threshold))
                (start-alarm)
            )
            ; not locked or not moving (> 3 seconds)
            ((or (= lock 0) (> (secs-since alarm-time) 3))
                (stop-alarm)
            )
        )

        ; lock power control
        (if (= lock 1)
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
                    (if (= alarm-tone 1)
                        (play-tone 0 4000 alarm-voltage)
                    )
                    (set 'feedback 1)
                }
            )
            ((= alarm 3) ; second tone
                {
                    (if (= alarm-tone 1)
                        (play-tone 2 7000 alarm-voltage)
                    )
                    (set 'feedback 1)
                }
            )
            ((= alarm 6) ; third tone
                {
                    (if (= alarm-tone 1)
                        (play-tone 1 2000 alarm-voltage)
                    )
                    (set 'feedback 1)
                }

            )
            ((= alarm 8) ; repeat alarm sound
                {
                    (if (= alarm-tone 1)
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

(defun button-logic()
    {
        ; Assume button is not pressed by default
        (var buttonold 0)
        (loopwhile t
            {
                (var button (gpio-read 'pin-rx))
                (sleep 0.03) ; wait 30 ms to debounce
                (var buttonconfirm (gpio-read 'pin-rx))
                (if (not (= button buttonconfirm))
                    (set 'button 0)
                )

                (if (> buttonold button)
                    {
                        (set 'presses (+ presses 1))
                        (set 'press-time (systime))
                    }
                    (button-apply button)
                )

                (set 'buttonold button)
                (handle-features)
            }
        )
    }
)

(defun button-apply(button)
    {
        (var time-passed (- (systime) press-time))
        (var is-active (or (= off 1) (<= (get-speed) button-safety-speed)))

        (if (> time-passed 2500) ; after 2500 ms
            (if (= button 0) ; check button is still pressed
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
        ; Packet handling
        (uart-start 115200 'half-duplex)
        (gpio-configure 'pin-rx 'pin-mode-in-pu)
        (define tx-frame (array-create 15))
        (bufset-u16 tx-frame 0 0x5AA5) ;Ninebot protocol
        (bufset-u8 tx-frame 2 0x06) ;Payload length is 5 bytes
        (bufset-u16 tx-frame 3 0x2021) ; Packet is from ESC to BLE
        (bufset-u16 tx-frame 5 0x6400) ; Packet is from ESC to BLE
        (def uart-buf (array-create 64))

        (if (= software-adc 1)
            (app-adc-detach 3 1)
            (app-adc-detach 3 0)
        )

        ; Apply mode on start-up
        (apply-mode)

        ; Spawn UART reading frames thread
        (spawn 150 read-frames)
        (button-logic) ; Start button logic in main thread - this will block the main thread
})

(image-save)
(main)
