# What's this

This is a bootloader for VIVIWARE Cell Branch, which was forked from https://github.com/arduino/ArduinoCore-avr/tree/master/bootloaders/atmega

# Prerequisites

- Need installation of WinAVR-20100110-install.exe on Windows machine which can be got from each one
    - https://sourceforge.net/projects/winavr/files/WinAVR/20100110/
    - https://github.com/vivitainc/328pb_bootloader/raw/develop/tools/WinAVR-20100110-install.exe

# How to build bootloader

```
make -C bootloaders/atmega clean
make -C bootloaders/atmega
```

# How to flash bootloader

```
bash ArduinoFlasher/flasher.sh
```
