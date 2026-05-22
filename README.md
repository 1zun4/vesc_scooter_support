# VESC Scooter Support
Allows you to connect your XIAOMI or NINEBOT display to VESC controller.

## How
Do you want to use your Xiaomi or NineBot BLE with a VESC controller? This is the right place for you! \
Read one of the guides below to get started.

- [DE Guide](/guide/DE.md)
- [German Rollerplausch Guide](https://rollerplausch.com/threads/vesc-controller-einbau-1s-pro2-g30.6032/)

## Which version should I use?

If you are running **VESC 7.00**, use these:
- **M365**: https://github.com/1zun4/vesc_scooter_support/blob/main/g30_dash.lisp
- **G30**: https://github.com/1zun4/vesc_scooter_support/blob/main/g30_dash.lisp
- **How-To** Video: https://www.youtube.com/watch?v=kX8PsaxfoXQ

## How do I wire it?
<span style="color:rgb(184, 49, 47);">Red </span>to 5V \
<span style="color:rgb(209, 213, 216);">Black </span>to GND \
<span style="color:rgb(250, 197, 28);">Yellow </span>to TX (UART-HDX) \
<span style="color:rgb(97, 189, 109);">Green </span>to RX (Button) \
1k Ohm Resistor from <span style="color:rgb(251, 160, 38);">3.3V</span> to <span style="color:rgb(97, 189, 109);">RX (Button)</span>

![image](guide/imgs/23999.png)

## Features
- [x] Multiple speed modes (Press twice)
- [x] Secret speed modes (Hold throttle and brake and press twice)
- [x] Lock mode with beeping and braking (Press twice while holding break)
- [x] Motor start speed feature (More secure)
- [x] Shutdown feature (Long press to turn off)
- [x] Battery Idle % on Secret Sport Mode
- [x] Temperature notification icon at 60°C

Features to be added:
- [ ] App communication
- [ ] More unlock combinations

## Tested on
### BLEs
- Clone M365 PRO Dashboard ([AliExpress](https://s.click.aliexpress.com/e/_9JHFDN))
- Original DE-Edition PRO 2 Dashboard
- Original DE-Edition G30 Dashboard

### Known compatible VESCs
- Spintend (Reliable & High Performance):
    - [Ubox Single Lite 100V 100A](https://spintend.com/collections/esc-based-on-vesc/products/single-ubox-aluminum-controller-100v-100a-based-on-vesc?ref=1zuna)
    - [Ubox Single 85V 250A V2](https://spintend.com/collections/esc-based-on-vesc/products/single-ubox-aluminum-controller-85v-250a-v2-based-on-vesc?ref=1zuna)

- Makerbase:
    - [Makerbase VESC 60100HP V2 60V 100A](https://s.click.aliexpress.com/e/_c4N2B2WD)
    - [Makerbase VESC 84100HP 84V 100A](https://de.aliexpress.com/item/1005006515708671.html?pdp_npi=4%40dis%21EUR%21%E2%82%AC+164%2C35%21%E2%82%AC+90%2C39%21%21%21186.38%21102.51%21%400b88abba17794626397951757e0f1c%2112000037495490277%21sh%21DE%212612418744%21X&spm=a2g0o.store_pc_allItems_or_groupList.new_all_items_2007473458239.1005006515708671&gatewayAdapt=glo2deu)
    - [Makerbase VESC 84200HP 84V 200A](https://s.click.aliexpress.com/e/_c4EFhPk1)

- 75100 Alu PCB (Not recommeded):
    - [Makerbase 75100 Alu PCB](https://s.click.aliexpress.com/e/_DE9TKAl)
    - [Flipsky 75100 Alu PCB](https://s.click.aliexpress.com/e/_DEXNhX3)

- More recommended VESCs:
    - [MP2 300A 100V/150V VESC](https://github.com/badgineer/MP2-ESC)
    - and many more... use whatever you like.

#### Requirements on VESC
Requires 7.00 VESC firmware. \
Can be found here: https://vesc-project.com/

## Worth to check out!
https://github.com/Koxx3/SmartESC_STM32_v2 (VESC firmware for Xiaomi ESCs)
