#!/usr/bin/env bash

PROGNAME=$(basename $0)
VERSION="${PROGNAME} v5.1"
echo
echo ${VERSION}
echo
BASEDIR=$(dirname $0)
#echo BASEDIR=${BASEDIR}

CURRENT_DIR=`pwd -P`
export ENV_DIR="${CURRENT_DIR}/envs"
source "${ENV_DIR}/env.sh"

DIR_BUILD=build
FW_ARG=flash

DIR_BOOTLOADER_328P=bootloaders/atmega
BOOTLOADER_NAME_328P_SRC=ATmegaBOOT_168_atmega328_pro_8MHz_vparts.hex

DIR_BOOTLOADER_328PB=bootloaders/atmega
BOOTLOADER_NAME_328PB_SRC=ATmegaBOOT_168_atmega328_pro_8MHz_vparts.hex

FW_HEX_SUFFIX="ino.with_bootloader.hex"
BOARD_328P_NAME="arduino:avr:vivi:cpu=Viviboot8MHz"
BOARD_328PB_NAME="pololu-a-star:avr:a-star328PB:version=8mhzVivita"
DEFAULT_MICRO=328pb

HARDWARE="-hardware "${DIR_HARDWARE1}

if [ -e "${DIR_HARDWARE2}" ]; then
    HARDWARE=${HARDWARE}" -hardware "${DIR_HARDWARE2}
fi

if [ -e "${DIR_HARDWARE3}" ]; then
    HARDWARE=${HARDWARE}" -hardware "${DIR_HARDWARE3}
fi

TOOLS="-tools "${DIR_TOOLS1}

if [ -e "${DIR_TOOLS2}" ]; then
    TOOLS=${TOOLS}" -tools "${DIR_TOOLS2}
fi

if [ -e "${DIR_TOOLS3}" ]; then
    TOOLS=${TOOLS}" -tools "${DIR_TOOLS3}
fi

export PATH="${DIR_ARDUINO_BIN}:${DIR_ARDUINO}:$PATH"

function ErrorMsg() {
  echo
  echo "Error occurred. Try again!"
  echo
  exit 1
}

function Usage() {
  echo
  echo "Usage: ${PROGNAME} [Options]"
  echo
  echo "Option: -p option must be required for Windows"
  echo "  -h                         Help"
  echo "  -p <port number or name>   Port number or name to Arduino ISP"
  echo "  -F                         Force flash in avrdude even if device signature is invalid"
  echo
  exit 1
}

#if [ $# = 0 ]; then
#  Usage
#fi

while(( $# > 0 )); do
  case "$1" in
    - | --)
      #オプション終端、以降すべて引数扱い
      shift
      #argc+=$#
      #argv+=("$@")
      break
      ;;
    --*)
      #ロングオプション
      ;;
    -*)
      #ショートオプション
      for (( i=1; i < ${#1}; i++));do # ${#1}は$1の文字数
        opt_name="${1:$i:1}"; # ${変数:offset:length}
        case "$opt_name" in
          'h')
            # help
            Usage
            ;;
          'p')
            # com port number
            com=($2)
            shift
            break
            ;;
          'F')
            # avrdude -F
            FORCE_OPTION="-F"
            break
            ;;
          esac
        done
      ;;

    * )
      echo "Unknown argument $1"
      Usage
  esac
  shift
done

# If ${CONF1_USR_FILE} does not exist, use ${CONF1_DEFAULT_FILE} instead
if [ ! -e "${CONF1_USR_FILE}" ]; then
  CONF1_FILE=${CONF1_DEFAULT_FILE}
else
  CONF1_FILE=${CONF1_USR_FILE}
fi

MCU_TYPE=${DEFAULT_MICRO}
MCU_LOWER=`echo ${MCU_TYPE} | tr '[A-Z]' '[a-z]'`
MCU_UPPER=`echo ${MCU_TYPE} | tr '[a-z]' '[A-Z]'`
BOARD_NAME=${BOARD_328PB_NAME}
FIXED_DIR_BOOTLOADER=${DIR_BOOTLOADER_328PB}
FIXED_BOOTLOADER_NAME_SRC=${BOOTLOADER_NAME_328PB_SRC}

#echo "BOARD_NAME=${BOARD_NAME}"
#echo "MCU_LOWER=${MCU_LOWER}"
#echo "MCU_UPPER=${MCU_UPPER}"

if [ -z "$com" ] && [ ${#ISP_DEV_NAMES[@]} -gt 1 ]; then
  echo "Error: -p option must be required with one of below devices"
  echo "$(for DEV in ${ISP_DEV_NAMES[@]}; do echo "  ${DEV}"; done)"
  exit 1
else
  ISP_DEV_NAME=${ISP_DEV_NAMES[0]}
fi

# Overwrite $com if ${ISP_DEV_NAME} is not empty
if [ -z "$com" ] && [ -n ${ISP_DEV_NAME} ]; then
  com=${ISP_DEV_NAME}
fi
# Eliminate ${PORT_PREFIX} in $com if it's duplicated
if [ -n ${PORT_PREFIX} ]; then
  com=`echo ${com##${PORT_PREFIX}}`
fi
#echo "com = ${com}"

(IFS="/"; cat <<_EOS_

-----------------------------
MCU      : ${MCU_UPPER}
PORT     : ${PORT_PREFIX}${com}
-----------------------------

_EOS_
)


if [ -z "$com" ]; then
  echo "Error: -p option must be required"
  exit
fi


DIR_REL_BUILD_PATH=${DUMP_DIR}
if [ ! -e "${DIR_REL_BUILD_PATH}" ]; then
  mkdir "${DIR_REL_BUILD_PATH}"
fi

DIR_INO_PATH=${DIR_INO_ROOT}/${INO_DIR_NAME}
DIR_REL_BUILD_PATH=${DIR_INO_PATH}/${DIR_BUILD}

# Flash
echo avrdude -C "${CONF1_FILE}" -C +"${CONF2_FILE}" ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -Uflash:w:${FIXED_DIR_BOOTLOADER}/${FIXED_BOOTLOADER_NAME_SRC}:i
avrdude -C "${CONF1_FILE}" -C +"${CONF2_FILE}" ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -Uflash:w:${FIXED_DIR_BOOTLOADER}/${FIXED_BOOTLOADER_NAME_SRC}:i
# Fuse
echo avrdude -C "${CONF1_FILE}" -C +"${CONF2_FILE}" ${FORCE_OPTION} -v -D -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -Ulock:w:0x2F:m -Uefuse:w:0xF5:m -Uhfuse:w:0xD2:m -Ulfuse:w:0xFF:m
avrdude -C "${CONF1_FILE}" -C +"${CONF2_FILE}" ${FORCE_OPTION} -v -D -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -Ulock:w:0x2F:m -Uefuse:w:0xF5:m -Uhfuse:w:0xD2:m -Ulfuse:w:0xFF:m

echo
echo "Successfully ${FIXED_DIR_BOOTLOADER}/${FIXED_BOOTLOADER_NAME_SRC} flashed for ATmega${MCU_UPPER}."
