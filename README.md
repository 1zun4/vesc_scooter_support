# VESC Scooter Support

Connect a Xiaomi or Ninebot dashboard to a VESC controller. Speed modes, secret modes,
lock with alarm, fully remappable button/lever gestures - everything configured from a
phone-friendly UI and stored on the ESC.

| General | Modes | Setup |
|---------|-------|-------|
| ![General](screenshots/general.jpg) | ![Modes](screenshots/modes.jpg) | ![Setup](screenshots/setup.jpg) |

## Requirements

VESC firmware 7.00, available at https://vesc-project.com/

## Installation

1. Connect to your VESC in VESC Tool and install this package
   (**VESC Packages -> Load Custom -> select the .vescpkg**, or from the package store once listed).
2. **Install the package on every VESC unit.** On dual-motor setups, switch to the second
   unit via **CAN forwarding** and install it there too - each unit runs its own copy.
3. Open the package UI (**Navigation Bar -> App UI**), go to the **Setup** tab and select
   the model **for each unit**:
   - the unit wired to the dashboard gets its dashboard model (**G30** or **M365/1S/PRO2**),
   - every other unit gets **Slave**.
4. Press **Save** - the script restarts with the chosen model. The model is stored per unit.
5. Configure everything else in the **General**, **Modes** and **Setup** tabs and press **Save**.

**Updating:** just install the new package over the old one - your settings are kept and
migrated automatically. To go back to defaults, use the **Reset** button in the UI.

## Models

One package for everything - the model is stored on the ESC and selected in the UI:

- **G30**: Ninebot G30 dashboard (Ninebot protocol)
- **M365/1S/PRO2**: Xiaomi M365, 1S, Essential and PRO 2 dashboards (Xiaomi protocol)
- **Slave**: secondary ESC in a dual setup - only runs the CAN code server, the master
  pushes the speed mode limits to it

## Features

### Speed modes
- Three speed modes (Eco / Drive / Sport) plus three **secret** modes, each with its own
  speed, current scale, watts and field weakening
- **Per-parameter apply toggles**: each parameter is only written to the motor config when
  its checkbox is enabled - separately for normal and secret modes. Disabled parameters
  never touch your VESC motor settings (e.g. keep your own field weakening setup)
- **Startup mode** selection (Eco / Drive / Sport, applied at boot)

### Gestures
Lock, mode switching, headlight and secret mode activation are all **fully remappable**:

- **Lever combination**: any mix of Brake / Throttle that must be held (or none)
- **Button presses**: 1-5 presses, or **No** - with "No" the gesture fires from the levers
  alone after holding the combination for half a second (no button press at all)
- **Locked**: restrict a gesture so it only works while the scooter is locked
  (e.g. secret mode only unlockable in locked state)
- Gestures only react at standstill (configurable button-active speed in Setup)
- Turning the scooter on (single press while off) always works, regardless of the mapping

### Lock & alarm
- Lock mode: motor braked when pushed, alarm with beeping and (optional) siren on
  gyro or wheel movement, configurable thresholds and volume
- Locking always leaves secret mode; unlocking restores it

### Comfort
- **Auto headlight**: turn the headlight on automatically at power on
- **Battery % at idle** on the dashboard, separately configurable for normal and secret modes
- Motor start speed (kick-start) and temperature warning icon with configurable thresholds
- Long button press turns the Dashboard off (not VESC itself)

### Robustness
- Throttle watchdog: throttle and brake are released if the dashboard link drops mid-ride
- Hardened UART frame parsing and supervised reader threads
- All settings stored on the ESC with versioned, automatic migrations between releases

Features to be added:
- [ ] App communication

## Wiring

<span style="color:rgb(184, 49, 47);">Red </span>to 5V \
<span style="color:rgb(209, 213, 216);">Black </span>to GND \
<span style="color:rgb(250, 197, 28);">Yellow </span>to TX (UART-HDX) \
<span style="color:rgb(97, 189, 109);">Green </span>to RX (Button) \
1k Ohm Resistor from <span style="color:rgb(251, 160, 38);">3.3V</span> to <span style="color:rgb(97, 189, 109);">RX (Button)</span>

![image](guide/imgs/23999.png)

## Tested Hardware

### BLE Displays
- Clone M365 PRO Dashboard ([AliExpress](https://s.click.aliexpress.com/e/_9JHFDN))
- Original DE-Edition PRO 2 Dashboard
- Original DE-Edition G30 Dashboard

### Known Compatible VESCs
- Spintend (Reliable & High Performance):
    - [Ubox Single Lite 100V 100A](https://spintend.com/collections/esc-based-on-vesc/products/single-ubox-aluminum-controller-100v-100a-based-on-vesc?ref=1zuna)
    - [Ubox Single 85V 250A V2](https://spintend.com/collections/esc-based-on-vesc/products/single-ubox-aluminum-controller-85v-250a-v2-based-on-vesc?ref=1zuna)
    - Dual Ubox Alu Lite 100V 100A (dual-motor setup, master + slave)

- Makerbase:
    - [Makerbase VESC 60100HP V2 60V 100A](https://s.click.aliexpress.com/e/_c4N2B2WD)
    - [Makerbase VESC 84100HP 84V 100A](https://de.aliexpress.com/item/1005006515708671.html?pdp_npi=4%40dis%21EUR%21%E2%82%AC+164%2C35%21%E2%82%AC+90%2C39%21%21%21186.38%21102.51%21%400b88abba17794626397951757e0f1c%2112000037495490277%21sh%21DE%212612418744%21X&spm=a2g0o.store_pc_allItems_or_groupList.new_all_items_2007473458239.1005006515708671&gatewayAdapt=glo2deu)
    - [Makerbase VESC 84200HP 84V 200A](https://s.click.aliexpress.com/e/_c4EFhPk1)

- 75100 Alu PCB (Not recommended):
    - [Makerbase 75100 Alu PCB](https://s.click.aliexpress.com/e/_DE9TKAl)
    - [Flipsky 75100 Alu PCB](https://s.click.aliexpress.com/e/_DEXNhX3)

- More recommended VESCs:
    - [MP2 300A 100V/150V VESC](https://github.com/badgineer/MP2-ESC)
    - and many more - use whatever you like.

## See Also

https://github.com/Koxx3/SmartESC_STM32_v2 (VESC firmware for Xiaomi ESCs)
