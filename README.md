# VESC Scooter Support
Allows you to connect a Xiaomi or Ninebot display to a VESC controller.

## Installation
Install this package, then pick your model in the app UI (VESC Tool -> Navigation Bar -> App UI).
Read one of the guides below to get started.

- [DE Guide](https://github.com/1zun4/vesc_scooter_support/blob/main/guide/DE.md)
- [German Rollerplausch Guide](https://rollerplausch.com/threads/vesc-controller-einbau-1s-pro2-g30.6032/)
- [How-To Video](https://www.youtube.com/watch?v=kX8PsaxfoXQ)

## Requirements
Requires VESC firmware 7.00, available at https://vesc-project.com/

## Models
One VESC package for everything:

- **G30**: Ninebot G30 dashboard (Ninebot protocol)
- **M365/1S/PRO2**: Xiaomi M365, 1S, Essential and PRO 2 dashboards (Xiaomi protocol)
- **Slave**: secondary ESC in a dual setup - only runs the CAN code server, the master controls it

After changing the model, save in the UI - the script restarts on its own with the new model.

## Wiring
<span style="color:rgb(184, 49, 47);">Red </span>to 5V \
<span style="color:rgb(209, 213, 216);">Black </span>to GND \
<span style="color:rgb(250, 197, 28);">Yellow </span>to TX (UART-HDX) \
<span style="color:rgb(97, 189, 109);">Green </span>to RX (Button) \
1k Ohm Resistor from <span style="color:rgb(251, 160, 38);">3.3V</span> to <span style="color:rgb(97, 189, 109);">RX (Button)</span>

![image](https://raw.githubusercontent.com/1zun4/vesc_scooter_support/main/guide/imgs/23999.png)

## Features
- [x] One package for G30, M365/1S/PRO2 and Slave ESCs
- [x] Settings in the UI
- [x] Speed mode switch (Press twice)
- [x] Secret speed mode (Hold throttle and brake and press twice)
- [x] Lock mode with alarm, beeping and braking (Press twice while holding brake)
- [x] Motor start speed feature (More secure)
- [x] Shutdown feature (Long press to turn off)
- [x] Battery Idle % on Secret Sport Mode
- [x] Temperature notification icon (configurable threshold)

## TODO
- [ ] App communication (support third-party Xiaomi/NineBot apps)
- [ ] More secret profile button combinations (e.g. 3x press without brake)
- [ ] Cruise control (throttle gesture in secret mode)
- [ ] Idle timeout (shut down after X seconds of inactivity)
- [ ] Rear light and brake light output
- [ ] mph/km display toggle
- [ ] Overmodulation factor per mode
- [ ] Throttle/brake plausibility check (detect disconnected sensor)
- [ ] Use BMS SoC for battery display when available
- [ ] Wheelie Control (take [vl_bike_39p](https://github.com/vedderb/vesc_pkg/tree/main/vl_bike_39p) and [dash35b](https://github.com/vedderb/vesc_pkg/tree/main/dash35b) pkg as reference)

## Tested Hardware
### BLE Displays
- Clone M365 PRO Dashboard ([AliExpress](https://s.click.aliexpress.com/e/_9JHFDN))
- Original DE-Edition PRO 2 Dashboard
- Original DE-Edition G30 Dashboard

### Known Compatible VESCs
- Spintend (Reliable & High Performance):
    - [Ubox Single Lite 100V 100A](https://spintend.com/collections/esc-based-on-vesc/products/single-ubox-aluminum-controller-100v-100a-based-on-vesc?ref=1zuna)
    - [Ubox Single 85V 250A V2](https://spintend.com/collections/esc-based-on-vesc/products/single-ubox-aluminum-controller-85v-250a-v2-based-on-vesc?ref=1zuna)

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
