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
DIR_HARDWARE4=${DIR_USER2}/viviware/hardware/avr

DIR_TOOLS1=${DIR_ARDUINO}/tools-builder
DIR_TOOLS2=${DIR_ARDUINO}/hardware/tools/avr
DIR_TOOLS3=${DIR_USER2}

DIR_BUILTIN_LIB=${DIR_ARDUINO}/libraries
DIR_LIB=${DIR_USER}/libraries

CONF1_DEFAULT_FILE=${DIR_ARDUINO}/hardware/tools/avr/etc/avrdude.conf
CONF1_USR_FILE=${DIR_USER2}/arduino/tools/avrdude/6.3.0-arduino9/etc/avrdude.conf
