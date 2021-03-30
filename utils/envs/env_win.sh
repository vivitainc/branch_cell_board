#!/bin/bash
PORT_PREFIX=COM
FTDI_DEV_NAMES=()

USER_PROFILE_="/$(echo ${USERPROFILE} | tr -d ':' | tr '\\' '/')"
DIR_ARDUINO='/c/Program Files (x86)/Arduino'
DIR_USER="${USER_PROFILE_}/Documents/Arduino"
DIR_USER2="${USER_PROFILE_}/AppData/Local/Arduino15/packages"
DIR_ARDUINO_BIN="${DIR_ARDUINO}/hardware/tools/avr/bin"

DIR_HARDWARE1="${DIR_ARDUINO}/hardware"
DIR_HARDWARE2="${DIR_USER}/hardware"
DIR_HARDWARE3="${DIR_USER2}"

DIR_TOOLS1="${DIR_ARDUINO}/tools-builder"
DIR_TOOLS2="${DIR_ARDUINO}/hardware/tools/avr"
DIR_TOOLS3="${DIR_USER2}"

DIR_BUILTIN_LIB="${DIR_ARDUINO}/libraries"
DIR_LIB="${DIR_USER}/libraries"

CONF1_DEFAULT_FILE="${DIR_ARDUINO}/hardware/tools/avr/etc/avrdude.conf"
CONF1_USR_FILE="${DIR_USER2}/arduino/tools/avrdude/6.3.0-arduino9/etc/avrdude.conf"
