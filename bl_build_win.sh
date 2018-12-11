#!/bin/bash

PROGNAME=$(basename $0)
VERSION="${PROGNAME} v2.0"
echo
echo ${VERSION}
echo
BOOTLOADER_NAME=optiboot_atmega328pb7800_8mhz.hex

cd bootloaders/optiboot
make clean
make atmega328pb_8mhz
cp ${BOOTLOADER_NAME} ${USERPROFILE}/AppData/Local/Arduino15/packages/pololu-a-star/hardware/avr/4.0.2/bootloaders/optiboot
cd ../../

echo
echo Copied ${BOOTLOADER_NAME} to ${USERPROFILE}/AppData/Local/Arduino15/packages/pololu-a-star/hardware/avr/4.0.2/bootloaders/optiboot

exit 0

