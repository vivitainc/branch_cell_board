#!/bin/bash

ENV_DIR=${ENV_DIR:-"$(pwd -P)"}
OS_NAME=$(uname)
EEPROM_HEX_FILE=eeprom.hex
BOOTLOADER_SRC=bootloaders/atmega/ATmegaBOOT_168_atmega328_pro_8MHz_vparts.hex
DIR_BOOTLOADER=$(dirname ${BOOTLOADER_SRC})

if [[ "${OS_NAME}" =~ MINGW.* ]]; then
  echo source ${ENV_DIR}/env_win.sh
  source ${ENV_DIR}/env_win.sh
elif [ "${OS_NAME}" == 'Darwin' ]; then
  echo source ${ENV_DIR}/env_mac.sh
  source ${ENV_DIR}/env_mac.sh
else
  echo source ${ENV_DIR}/env_linux.sh
  source ${ENV_DIR}/env_linux.sh
fi
