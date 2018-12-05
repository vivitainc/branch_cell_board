#!/bin/bash

PROGNAME=$(basename $0)
VERSION="${PROGNAME} v1.0 for 328pb"
echo
echo ${VERSION}
echo
BASEDIR=$(dirname $0)
#echo BASEDIR=${BASEDIR}

PORT_PREFIX=COM
ISP_DEV_NAME=

DIR_ARDUINO="C:\PROGRA~2\Arduino"
DIR_USER=${USERPROFILE}\\Documents\\Arduino
DIR_USER2=${USERPROFILE}\\AppData\\Local\\Arduino15\\packages
DIR_CURRENT=${PWD}
DIR_ARDUINO_BIN=${DIR_ARDUINO}\\hardware\\tools\\avr\\bin

DIR_HARDWARE1=${DIR_ARDUINO}\\hardware
DIR_HARDWARE2=${DIR_USER}\\hardware
DIR_HARDWARE3=${DIR_USER2}

DIR_TOOLS1=${DIR_ARDUINO}\\tools-builder
DIR_TOOLS2=${DIR_ARDUINO}\\hardware\\tools\\avr
DIR_TOOLS3=${DIR_USER2}

DIR_BUILTIN_LIB=${DIR_ARDUINO}\\libraries
DIR_LIB=${DIR_USER}\\libraries
CONF1_DEFAULT_FILE=${DIR_ARDUINO}\\hardware\\tools\\avr\\etc\\avrdude.conf
CONF1_USR_FILE=${DIR_USER2}\\arduino\\tools\\avrdude\\6.3.0-arduino9\\etc\\avrdude.conf
CONF2_FILE=${DIR_USER2}\\pololu-a-star\\hardware\\avr\\4.0.2\\extra_avrdude.conf

DIR_INO_ROOT=dump
DIR_BUILD=build
DUMP_DIR=dump
FW_ARG=flash

DIR_BOOTLOADER=bootloaders\\optiboot
BOOTLOADER_NAME=optiboot_atmega328pb_8mhz.hex

FW_HEX_SUFFIX="ino.with_bootloader.hex"
BOARD_328P_NAME="arduino:avr:vivi:cpu=8MHzatmega328"
BOARD_328PB_NAME="pololu-a-star:avr:a-star328PB:version=8mhz"
DEFAULT_MICRO=328pb
MICRO_OPTION="328p or 328pb"

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

function Usage() {
  echo 
  echo "Usage: ${PROGNAME} [Options]"
  echo 
  echo "Option: -p option must be required"
  echo "  -h                         Help"
  echo "  -p <port number or name>   Port number or name to Arduino ISP"
<< COMMENTOUT
  echo "  -b                         Set fuse bit"
  echo "  -u <max 6byte, hex>        Write 6byte unique id to EEPROM"
COMMENTOUT
#  echo "  -f <dump file name>        Dump file name"
#  echo "  -r                         Force recompile (also require -f option)"
  echo "  -m <mcu_name>              Specify the target MCU ${MICRO_OPTION}"
#  echo "  -F                         Force flash in avrdude even if device signature is invalid"
  echo
  exit 1
}

if [ $# = 0 ]; then
  Usage
fi

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
#          'f')
#            # firmware
#            FW_ARG=("$2")
#            shift
#            break
#            ;;
          'm')
            # mcu must need an arg
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
              echo "${PROGNAME}: -$1 option requires an argument"
              echo "Provide ${MICRO_OPTION}"
              exit
            fi
            MCU_ARG=("$2")
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

# Verify ${MCU_ARG} and define ${BOARD_NAME}, ${CONF_OPTION}, ${MCU_LOWER}, ${MCU_UPPER}
if [ ! -n "${MCU_ARG}" ]; then
  # If not provide -m option, use ${DEFAULT_MICRO}
  MCU_TYPE=${DEFAULT_MICRO}
else
  MCU_TYPE=${MCU_ARG}
fi
MCU_LOWER=`echo ${MCU_TYPE} | tr '[A-Z]' '[a-z]'`
MCU_UPPER=`echo ${MCU_TYPE} | tr '[a-z]' '[A-Z]'`
if [ "${MCU_UPPER}" = "328P" ]; then
  BOARD_NAME=${BOARD_328P_NAME}
  CONF_OPTION="-C ${CONF1_FILE}"
elif [ "${MCU_UPPER}" = "328PB" ]; then
  BOARD_NAME=${BOARD_328PB_NAME}
  CONF_OPTION="-C ${CONF1_FILE} -C +${CONF2_FILE}"
else
  echo "Cannot recognize -m argument ${MCU_ARG}"
  echo "Provide ${MICRO_OPTION}"
  exit
fi
#echo "MCU_ARG=${MCU_ARG}"
#echo "BOARD_NAME=${BOARD_NAME}"
#echo "CONF_OPTION=${CONF_OPTION}"
#echo "MCU_LOWER=${MCU_LOWER}"
#echo "MCU_UPPER=${MCU_UPPER}"

# Analysis ${FW_ARG} and create ${INO_DIR_NAME}, ${REL_HEX_FILE} and ${REL_INO_FILE}

if [ -n "${FW_ARG}" ]; then
  if [ -e "${FW_ARG}" ]; then
    if [ -f "${FW_ARG}" ] && [ ${FW_ARG##*.} = ino ]; then
      # If ${FW_ARG} is ino file full path
      INO_FILE_NAME=${FW_ARG##*/}
      INO_DIR_NAME=${INO_FILE_NAME%.*}
      REL_HEX_FILE="${FW_ARG%/*.ino}/${DIR_BUILD}/${INO_DIR_NAME}.${FW_HEX_SUFFIX}"
      REL_INO_FILE="${FW_ARG}"
      #echo "${FW_ARG} = ino file full path"
    elif [ -f "${FW_ARG}" ] && [ ${FW_ARG#*.} = ${FW_HEX_SUFFIX} ]; then
      # If ${FW_ARG} is hex file full path
      INO_FILE_NAME=${FW_ARG##*/}
      INO_DIR_NAME=${INO_FILE_NAME%%.*}
      REL_HEX_FILE="${FW_ARG}"
      REL_BUILD_DIR="${FW_ARG%/*}"
      REL_INO_FILE="${REL_BUILD_DIR%/${DIR_BUILD}}/${INO_DIR_NAME}.ino"
      #echo "${FW_ARG} = hex file full path"
    elif [ -f "${FW_ARG}" ] && [ ${FW_ARG#*.} != "" ]; then
      # If ${FW_ARG} is dump file full path
      INO_FILE_NAME=${FW_ARG##*/}
      INO_DIR_NAME=${INO_FILE_NAME%%.*}
    else
      # If ${FW_ARG} is ino directory full path
      INO_DIR_NAME=`basename ${FW_ARG}`
      REL_HEX_FILE="${FW_ARG}/${DIR_BUILD}/${INO_DIR_NAME}.${FW_HEX_SUFFIX}"
      REL_INO_FILE="${FW_ARG}/${INO_DIR_NAME}.ino"
      #echo "${FW_ARG} = ino directory path"
    fi
  elif [ -d "${DIR_INO_ROOT}/${FW_ARG}" ]; then
    # If ${FW_ARG} is ino directory name
    INO_DIR_NAME=${FW_ARG}
    REL_HEX_FILE="${DIR_INO_ROOT}/${INO_DIR_NAME}/${DIR_BUILD}/${INO_DIR_NAME}.${FW_HEX_SUFFIX}"
    REL_INO_FILE="${DIR_INO_ROOT}/${INO_DIR_NAME}/${INO_DIR_NAME}.ino"
    #echo "${FW_ARG} = ino directory name"
  elif [ ${FW_ARG#*.} != "" ]; then
    # If ${FW_ARG} is dump file full path
    INO_FILE_NAME=${FW_ARG##*/}
    INO_DIR_NAME=${INO_FILE_NAME%%.*}
  else
    INO_DIR_NAME=${FW_ARG}
  fi
  #echo "INO_DIR_NAME=${INO_DIR_NAME}"
  #echo "REL_HEX_FILE=${REL_HEX_FILE}"
  #echo "REL_INO_FILE=${REL_INO_FILE}"
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
FILENAME : $INO_DIR_NAME
-----------------------------

_EOS_
)


if [ -z "$com" ]; then
  echo "Error: -p option must be required"
  exit
fi

if [ -n "$flg_fuse" ]; then
  echo "Write Fuse bit etc to ATmega${MCU_UPPER}."
  #echo avrdude ${CONF_OPTION} ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -e -Ulock:w:0x3F:m -Uefuse:w:0xFD:m -Uhfuse:w:0xD2:m -Ulfuse:w:0xFF:m
  avrdude ${CONF_OPTION} ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -e -Ulock:w:0x3F:m -Uefuse:w:0xFD:m -Uhfuse:w:0xD2:m -Ulfuse:w:0xFF:m

fi

if [ -n "$uid" ]; then
  echo "Write UNIQUE ID to EEPROM to ATmega${MCU_UPPER}."
  # Generate Hex file
  python ${BASEDIR}/hex_generator.py $uid
  # Flash unique id to EEPROM
  #echo avrdude ${CONF_OPTION} ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -U eeprom:w:${BASEDIR}/eeprom.hex:i
  avrdude ${CONF_OPTION} ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -U eeprom:w:${BASEDIR}/eeprom.hex:i
  # Verify
  #echo "Verify the UNIQUE ID."
  #avrdude ${CONF_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -U eeprom:r:verify.hex:i
fi

DIR_INO_PATH=${DIR_INO_ROOT}/${INO_DIR_NAME}
DIR_REL_BUILD_PATH=${DIR_INO_PATH}/${DIR_BUILD}
#if [ ! -e "${DIR_REL_BUILD_PATH}" ]; then
#  mkdir "${DIR_REL_BUILD_PATH}"
#fi

#if [ -n "${FW_ARG}" ]; then
#  if [ -n "$flg_recompile" ] || [ ! -e "${REL_HEX_FILE}" ]; then
#    echo "Compile firmware w/bootloader for ATmega${MCU_UPPER}."
#
#    if [ -e "${DIR_REL_BUILD_PATH}/libraries" ]; then
#      rm -r "${DIR_REL_BUILD_PATH}/libraries"
#    fi
#    if [ -e "${DIR_REL_BUILD_PATH}/core" ]; then
#      rm -r "${DIR_REL_BUILD_PATH}/core"
#    fi
#    DIR_ABS_BUILD_PATH=$(cd $DIR_REL_BUILD_PATH && pwd)
#
#    # Compile
#    #echo arduino-builder -dump-prefs ${HARDWARE} ${TOOLS} -built-in-libraries "${DIR_BUILTIN_LIB}" -libraries "${DIR_LIB}" -fqbn="${BOARD_NAME}" -build-path "${DIR_ABS_BUILD_PATH}" -verbose ${DIR_INO_PATH}/${INO_DIR_NAME}.ino
#    arduino-builder -dump-prefs ${HARDWARE} ${TOOLS} -built-in-libraries "${DIR_BUILTIN_LIB}" -libraries "${DIR_LIB}" -fqbn="${BOARD_NAME}" -build-path "${DIR_ABS_BUILD_PATH}" -verbose ${DIR_INO_PATH}/${INO_DIR_NAME}.ino
#    #echo arduino-builder -compile ${HARDWARE} ${TOOLS} -built-in-libraries "${DIR_BUILTIN_LIB}" -libraries "${DIR_LIB}" -fqbn="${BOARD_NAME}" -build-path "${DIR_ABS_BUILD_PATH}" -verbose ${DIR_INO_PATH}/${INO_DIR_NAME}.ino
#    arduino-builder -compile ${HARDWARE} ${TOOLS} -built-in-libraries "${DIR_BUILTIN_LIB}" -libraries "${DIR_LIB}" -fqbn="${BOARD_NAME}" -build-path "${DIR_ABS_BUILD_PATH}" -verbose ${DIR_INO_PATH}/${INO_DIR_NAME}.ino
#  else
#    echo "Skip firmware compilation."
#  fi
#
#  echo "Flash firmware w/bootloader to ATmega${MCU_UPPER}."

  # Preserve EEPROM
  #if [ ! -n "$flg_fuse" ]; then
  #  #echo avrdude ${CONF_OPTION} ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -e -Uhfuse:w:0xD2:m
  #  avrdude ${CONF_OPTION} ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -e -Uhfuse:w:0xD2:m
  #fi

  # Fuse
  echo avrdude ${CONF_OPTION} ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200  -B 5 -e -Ulock:w:0x3F:m -Uefuse:w:0xFD:m -Uhfuse:w:0xD2:m -Ulfuse:w:0xFF:m
  avrdude ${CONF_OPTION} ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200  -B 5 -e -Ulock:w:0x3F:m -Uefuse:w:0xFD:m -Uhfuse:w:0xD2:m -Ulfuse:w:0xFF:m
  # Flash
  echo avrdude ${CONF_OPTION} ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -Uflash:w:${DIR_BOOTLOADER}/${BOOTLOADER_NAME}:i
  avrdude ${CONF_OPTION} ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -Uflash:w:${DIR_BOOTLOADER}/${BOOTLOADER_NAME}:i

  echo
  echo "Successfully ${DIR_BOOTLOADER}/${BOOTLOADER_NAME} flashed for ATmega${MCU_UPPER}."
#fi
