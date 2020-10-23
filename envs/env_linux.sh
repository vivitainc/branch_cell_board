#!/bin/bash
PORT_PREFIX=/dev/
FTDI_DEV_NAMES=($(ls -1 ${PORT_PREFIX} | grep 'ttyUSB'))

DIR_ARDUINO=/Arduino/arduino-1.8.12
DIR_USER=${HOME}/.arduino15
DIR_USER2=${HOME}/.arduino15/packages
DIR_ARDUINO_BIN=${DIR_ARDUINO}/hardware/tools/avr/bin

DIR_HARDWARE1=${DIR_ARDUINO}/hardware
DIR_HARDWARE2=${DIR_USER}/hardware
DIR_HARDWARE3=${DIR_USER2}

DIR_TOOLS1=${DIR_ARDUINO}/tools-builder
DIR_TOOLS2=${DIR_ARDUINO}/hardware/tools/avr
DIR_TOOLS3=${DIR_USER2}

DIR_BUILTIN_LIB=${DIR_ARDUINO}/libraries
DIR_LIB=${DIR_USER}/libraries

DST_BOOTLOADER_328P_DIR=${DIR_ARDUINO}/hardware/arduino/avr/bootloaders/atmega
DST_BOOTLOADER_328PB_DIR=${DIR_USER2}/pololu-a-star/hardware/avr/4.0.2/bootloaders/atmega

DST_BOOTLOADER_328P_FILE=ATmegaBOOT_168_atmega328_pro_8MHz_vparts.hex
SRC_BOOTLOADER_328P_FILE=bootloaders/atmega/ATmegaBOOT_168_atmega328_pro_8MHz_vparts.hex

DST_BOOTLOADER_328PB_FILE=ATmegaBOOT_168_atmega328_pro_8MHz_vparts.hex
SRC_BOOTLOADER_328PB_FILE=bootloaders/atmega/ATmegaBOOT_168_atmega328_pro_8MHz_vparts.hex
DST_BOARD_TXT_328PB_POLOLU=${DIR_USER2}/pololu-a-star/hardware/avr/4.0.2/boards.txt
SRC_BOARD_TXT_328PB_POLOLU=pololu-a-star/boards.txt

CONF1_DEFAULT_FILE=${DIR_ARDUINO}/hardware/tools/avr/etc/avrdude.conf
CONF1_USR_FILE=${DIR_USER2}/arduino/tools/avrdude/6.3.0-arduino9/etc/avrdude.conf
CONF2_FILE=${DIR_USER2}/pololu-a-star/hardware/avr/4.0.2/extra_avrdude.conf
