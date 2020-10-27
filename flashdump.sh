#!/usr/bin/env bash

PROGNAME=$(basename $0)
VERSION="${PROGNAME} v2.0 for 328pb"
echo
echo ${VERSION}
echo
BASEDIR=$(dirname $0)
#echo BASEDIR=${BASEDIR}

CURRENT_DIR=`pwd -P`
export ENV_DIR="${CURRENT_DIR}/envs"
source "${ENV_DIR}/env.sh"

FW_ARG=dump/flashdump

FW_HEX_SUFFIX="hex"
DUMP_NAME_SUFFIX="_32"
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
  echo "  -f <dump file name>        Dump file name"
  echo
  exit 1
}

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
          'f')
            # firmware
            FW_ARG=("$2")
            shift
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
FIXED_SRC_BOOTLOADER_FILE=${SRC_BOOTLOADER_328PB_FILE}
FIXED_DST_BOOTLOADER_DIR=${DST_BOOTLOADER_328PB_DIR}
FIXED_DST_BOOTLOADER_FILE=${DST_BOOTLOADER_328PB_FILE}

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
FILENAME : ${FW_ARG}
-----------------------------

_EOS_
)

if [ -z "$com" ]; then
  echo "Error: -p option must be required"
  exit
fi

OUT_DIR=$(dirname ${FW_ARG})
echo OUT_DIR=${OUT_DIR}
echo
if [ ! -e "${OUT_DIR}" ]; then
  mkdir -p "${OUT_DIR}"
fi

if [ -n "${FW_ARG}" ]; then
  # Dump
  echo avrdude -C "${CONF1_FILE}" -C +"${CONF2_FILE}" -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -Uflash:r:${FW_ARG}${DUMP_NAME_SUFFIX}.${FW_HEX_SUFFIX}:i
  avrdude -C "${CONF1_FILE}" -C +"${CONF2_FILE}" -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -Uflash:r:${FW_ARG}${DUMP_NAME_SUFFIX}.${FW_HEX_SUFFIX}:i
  echo python hex_converter16.py ${FW_ARG}${DUMP_NAME_SUFFIX}.${FW_HEX_SUFFIX} ${FW_ARG}.${FW_HEX_SUFFIX}
  python hex_converter16.py ${FW_ARG}${DUMP_NAME_SUFFIX}.${FW_HEX_SUFFIX} ${FW_ARG}.${FW_HEX_SUFFIX}
  rm ${FW_ARG}${DUMP_NAME_SUFFIX}.${FW_HEX_SUFFIX}
  echo
  echo "Successfully ${FW_ARG}.${FW_HEX_SUFFIX} retrieved for ATmega${MCU_UPPER}."
fi
