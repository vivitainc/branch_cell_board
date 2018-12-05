#!/bin/bash

PROGNAME=$(basename $0)
VERSION="${PROGNAME} v1.1"
echo
echo ${VERSION}
echo

cd bootloaders/optiboot
make clean
make atmega328pb_8mhz
cp optiboot_atmega328pb_8mhz.hex ${USERPROFILE}/AppData/Local/Arduino15/packages/pololu-a-star/hardware/avr/4.0.2/bootloaders/optiboot
cd ../../

echo
echo Copied optiboot_atmega328pb_8mhz.hex to ${USERPROFILE}/AppData/Local/Arduino15/packages/pololu-a-star/hardware/avr/4.0.2/bootloaders/optiboot

exit 0

