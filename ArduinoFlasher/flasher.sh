#!/usr/bin/env bash

PROGNAME=$(basename $0)
VERSION="${PROGNAME} v5.0"
echo
echo ${VERSION}
echo
BASEDIR=$(dirname $0)
#echo BASEDIR=${BASEDIR}

ENV_DIR="${BASEDIR}/../envs"
source "${ENV_DIR}/env.sh"

DIR_INO_ROOT=examples
DIR_BUILD=build

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
  echo "  -b                         Set fuse bit, write BRANCH_TYPE into EEPROM"
  echo "  -f <sketch name>           Flash firmware w/ arduino bootloader"
  echo "  -F                         Force flash in avrdude even if device signature is invalid"
  echo
  exit 1
}

function GetBranchType() {
  local ino_file=${1}
  local branchtype_line=$(grep -E "^const\s+uint32_t\s+BRANCH_TYPE" ${ino_file})
  local branchtype=$(echo "${branchtype_line}" | sed -e 's|^.*BRANCH_TYPE *= *0x\([0-9a-fA-F]\{1,\}\);.*|\1|')

  echo ${branchtype}
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
          'b')
            # Fuse bit, Lock bit etc.
            flg_fuse=1
            break
            ;;
          'F')
            # avrdude -F
            FORCE_OPTION="-F"
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

# Analysis ${FW_ARG} and create ${INO_DIR_NAME}, ${DIR_INO_ROOT}, ${REL_HEX_FILE} and ${REL_INO_FILE}
if [ -n "${FW_ARG}" ]; then
  if [ -e "${FW_ARG}" ]; then
    if [ -f "${FW_ARG}" ] && [ ${FW_ARG##*.} = ino ]; then
      # If ${FW_ARG} is ino file full path
      INO_FILE_NAME=${FW_ARG##*/}
      INO_DIR_NAME=${INO_FILE_NAME%.*}
      DIR_INO_ROOT=${FW_ARG%%/*}
      REL_HEX_FILE="${FW_ARG%/*.ino}/${DIR_BUILD}/${INO_DIR_NAME}.${FW_HEX_SUFFIX}"
      REL_INO_FILE="${FW_ARG}"
      #echo "${FW_ARG} = ino file full path"
    elif [ -f "${FW_ARG}" ] && [ ${FW_ARG#*.} = ${FW_HEX_SUFFIX} ]; then
      # If ${FW_ARG} is hex file full path
      INO_FILE_NAME=${FW_ARG##*/}
      INO_DIR_NAME=${INO_FILE_NAME%%.*}
      DIR_INO_ROOT=${FW_ARG%%/*}
      REL_HEX_FILE="${FW_ARG}"
      REL_BUILD_DIR="${FW_ARG%/*}"
      REL_INO_FILE="${REL_BUILD_DIR%/${DIR_BUILD}}/${INO_DIR_NAME}.ino"
      #echo "${FW_ARG} = hex file full path"
    else
      # If ${FW_ARG} is ino directory full path
      INO_DIR_NAME=`basename ${FW_ARG}`
      DIR_INO_ROOT=${FW_ARG%%/*}
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
  fi
  #echo "INO_DIR_NAME=${INO_DIR_NAME}"
  #echo "REL_HEX_FILE=${REL_HEX_FILE}"
  #echo "REL_INO_FILE=${REL_INO_FILE}"
fi

#echo "DIR_INO_ROOT=${DIR_INO_ROOT}"

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
OPTION-F : ${FORCE_OPTION}
PORT     : ${PORT_PREFIX}${com}
FIRMWARE : $INO_DIR_NAME
FUSE     : $flg_fuse
-----------------------------

_EOS_
)


if [ -z "$com" ]; then
  echo "Error: -p option must be required"
  exit
fi

DIR_INO_PATH=${DIR_INO_ROOT}/${INO_DIR_NAME}
DIR_REL_BUILD_PATH=${DIR_INO_PATH}/${DIR_BUILD}
if [ ! -e "${DIR_REL_BUILD_PATH}" ]; then
  mkdir "${DIR_REL_BUILD_PATH}"
fi

if [ -n "${FW_ARG}" ]; then
  if [ ! -e "${REL_HEX_FILE}" ]; then
    echo ${FW_ARG} not found
    ErrorMsg
  fi

  echo "Flash firmware w/bootloader to ATmega${MCU_UPPER}."

  # Copy ${SRC_BOARD_TXT_328PB_POLOLU} to ${DST_BOARD_TXT_328PB_POLOLU}
  if [ "${MCU_UPPER}" = "328PB" ]; then
    cp "${SRC_BOARD_TXT_328PB_POLOLU}" "${DST_BOARD_TXT_328PB_POLOLU}"
    echo "Copied ${SRC_BOARD_TXT_328PB_POLOLU} to ${DST_BOARD_TXT_328PB_POLOLU}"
  fi

  # Flash
  echo avrdude -C "${CONF1_FILE}" -C +"${CONF2_FILE}" ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -Uflash:w:${DIR_REL_BUILD_PATH}/${INO_DIR_NAME}.${FW_HEX_SUFFIX}:i
  avrdude -C "${CONF1_FILE}" -C +"${CONF2_FILE}" ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -Uflash:w:${DIR_REL_BUILD_PATH}/${INO_DIR_NAME}.${FW_HEX_SUFFIX}:i
  if [ $? -ne 0 ]; then
    ErrorMsg
  fi

  if [ -n "$flg_fuse" ]; then
    # Lock Bit Protection - BLB1 Mode 2 BLB12=0b1, BLB11=0b0: SPM is not allowed to write to the Boot Loader section.
    echo "Write Fuse bit etc to ATmega${MCU_UPPER}."
    echo avrdude -C "${CONF1_FILE}" -C +"${CONF2_FILE}" ${FORCE_OPTION} -v -D -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -Ulock:w:0x2F:m -Uefuse:w:0xF5:m -Uhfuse:w:0xD2:m -Ulfuse:w:0xFF:m
    avrdude -C "${CONF1_FILE}" -C +"${CONF2_FILE}" ${FORCE_OPTION} -v -D -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -Ulock:w:0x2F:m -Uefuse:w:0xF5:m -Uhfuse:w:0xD2:m -Ulfuse:w:0xFF:m
    if [ $? -ne 0 ]; then
      ErrorMsg
    fi

    if [ -n "${FW_ARG}" ]; then
      echo "Write BRANCH_TYPE into ATmega${MCU_UPPER} EEPROM."
      # Get BRANCH_TYPE
      readonly BRANCH_TYPE=$(GetBranchType ${REL_INO_FILE})
      echo BRANCH_TYPE=0x${BRANCH_TYPE}

      # Generate Hex file
      python ${BASEDIR}/hex_generator.py ${BRANCH_TYPE} ${EEPROM_HEX_FILE}
      if [ $? -ne 0 ]; then
        echo
        echo 'May need python installation and "pip install IntelHex"'
        ErrorMsg
      fi

      # Flash BRANCH_TYPE to EEPROM
      echo avrdude -C "${CONF1_FILE}" -C +"${CONF2_FILE}" ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -U eeprom:w:${BASEDIR}/${EEPROM_HEX_FILE}:i
      avrdude -C "${CONF1_FILE}" -C +"${CONF2_FILE}" ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -U eeprom:w:${BASEDIR}/${EEPROM_HEX_FILE}:i
      if [ $? -ne 0 ]; then
        ErrorMsg
      fi

      rm ${BASEDIR}/${EEPROM_HEX_FILE}
      # Verify
      #echo "Verify BRANCH_TYPE."
      #avrdude -C "${CONF1_FILE}" -C +"${CONF2_FILE}" -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b 19200 -U eeprom:r:${BASEDIR}/verify.hex:i
    fi
  fi

  if [ -n "${BRANCH_TYPE}" ]; then
    echo "0x${BRANCH_TYPE} has been written into EEPROM"
  fi
else
  echo "Error: -f option must be required"
  Usage
fi
