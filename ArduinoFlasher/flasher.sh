#!/usr/bin/env bash

PROGNAME=$(basename $0)
VERSION="${PROGNAME} v7.0"
echo
echo ${VERSION}
echo
BASEDIR=$(dirname $0)
#echo BASEDIR=${BASEDIR}

ENV_DIR="${BASEDIR}/../utils/envs"
source "${ENV_DIR}/env.sh"

DIR_INO_ROOT=examples
DIR_BUILD=build
USER_EEPROM_CSV_FILE=*eeprom_data*.csv

FW_HEX_SUFFIX="ino.with_bootloader.hex"
DEFAULT_MICRO=328pb
ISP_BAUDRATE=19200

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
  echo "        -f option is not set, then flash bootloader only"
  echo
  echo "  -h                         Help"
  echo "  -p <port number or name>   Port number or name to Arduino ISP"
  echo "  -B <baudrate>              Set baudrate to talk with Arduino ISP (default: 19200)"
  echo "  -b                         Set fuse bit, write BRANCH_TYPE into EEPROM"
  echo "  -f <sketch name>           Flash firmware w/ arduino bootloader"
  echo "  -F                         Force flash in avrdude even if device signature is invalid"
  echo
  exit 1
}

function GetBranchType() {
  local ino_file=${1}
  local branchtype_line=$(grep -E "^const(expr){0,1}\s+uint32_t\s+BRANCH_TYPE" ${ino_file})
  local branchtype=$(echo "${branchtype_line}" | sed -e 's|^.*BRANCH_TYPE *= *0x\([0-9a-fA-F]\{1,\}\);.*|\1|')

  echo ${branchtype:-0}
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
          'B')
            # ISP baudrate
            ISP_BAUDRATE="$2"
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

#echo "MCU_LOWER=${MCU_LOWER}"
#echo "MCU_UPPER=${MCU_UPPER}"

# Analysis ${FW_ARG} and create ${INO_DIR_NAME}, ${DIR_INO_ROOT}, ${REL_HEX_FILE} and ${REL_INO_FILE}
if [ -z "${FW_ARG}" ]; then
  echo
  echo 'Flash bootloader only'
  echo
else
  if [ -e "${FW_ARG}" ]; then
    if [ -f "${FW_ARG}" ] && [ ${FW_ARG##*.} = ino ]; then
      # If ${FW_ARG} is ino file full path
      INO_FILE_NAME=${FW_ARG##*/}
      INO_DIR_NAME=${INO_FILE_NAME%.*}
      DIR_INO_ROOT=${FW_ARG%%/${INO_DIR_NAME}*}
      REL_HEX_FILE="${FW_ARG%/*.ino}/${DIR_BUILD}/${INO_DIR_NAME}.${FW_HEX_SUFFIX}"
      REL_INO_FILE="${FW_ARG}"
      #echo "${FW_ARG} = ino file full path"
    elif [ -f "${FW_ARG}" ] && [ ${FW_ARG#*.} = ${FW_HEX_SUFFIX} ]; then
      # If ${FW_ARG} is hex file full path
      INO_FILE_NAME=${FW_ARG##*/}
      INO_DIR_NAME=${INO_FILE_NAME%%.*}
      DIR_INO_ROOT=${FW_ARG%%/${INO_DIR_NAME}*}
      REL_HEX_FILE="${FW_ARG}"
      REL_BUILD_DIR="${FW_ARG%/*}"
      REL_INO_FILE="${REL_BUILD_DIR%/${DIR_BUILD}}/${INO_DIR_NAME}.ino"
      #echo "${FW_ARG} = hex file full path"
    else
      # If ${FW_ARG} is ino directory full path
      INO_DIR_NAME=`basename ${FW_ARG}`
      DIR_INO_ROOT=${FW_ARG%%/${INO_DIR_NAME}*}
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
INO_ROOT : ${DIR_INO_ROOT}
FIRMWARE : $INO_DIR_NAME
FUSE     : $flg_fuse
-----------------------------

_EOS_
)

if [ -z "$com" ]; then
  echo "Error: -p option must be required"
  exit
fi

if [ -z "${FW_ARG}" ]; then
  # Flash
  echo avrdude -C "${CONF1_FILE}" ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b "${ISP_BAUDRATE}" -Uflash:w:${BOOTLOADER_SRC}
  avrdude -C "${CONF1_FILE}" ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b "${ISP_BAUDRATE}" -Uflash:w:${BOOTLOADER_SRC}:i
  # Fuse
  echo avrdude -C "${CONF1_FILE}" ${FORCE_OPTION} -v -D -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b "${ISP_BAUDRATE}" -Ulock:w:0x2F:m -Uefuse:w:0xF5:m -Uhfuse:w:0xD2:m -Ulfuse:w:0xFF:m
  avrdude -C "${CONF1_FILE}" ${FORCE_OPTION} -v -D -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b "${ISP_BAUDRATE}" -Ulock:w:0x2F:m -Uefuse:w:0xF5:m -Uhfuse:w:0xD2:m -Ulfuse:w:0xFF:m

  echo
  echo "Successfully ${BOOTLOADER_SRC} flashed for ATmega${MCU_UPPER}."
  exit 0
else
  DIR_INO_PATH=${DIR_INO_ROOT}/${INO_DIR_NAME}
  DIR_REL_BUILD_PATH=${DIR_INO_PATH}/${DIR_BUILD}

  if [ ! -e "${DIR_REL_BUILD_PATH}" ]; then
    mkdir "${DIR_REL_BUILD_PATH}"
  fi

  if [ ! -e "${REL_HEX_FILE}" ]; then
    echo ${FW_ARG} not found
    ErrorMsg
  fi

  echo "Flash firmware w/bootloader to ATmega${MCU_UPPER}."

  # EEPROM erase setting
  echo avrdude -C "${CONF1_FILE}" ${FORCE_OPTION} -v -D -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b "${ISP_BAUDRATE}" -Uhfuse:w:0xDA:m
  avrdude -C "${CONF1_FILE}" ${FORCE_OPTION} -v -D -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b "${ISP_BAUDRATE}" -Uhfuse:w:0xDA:m
  if [ $? -ne 0 ]; then
    ErrorMsg
  fi

  # Flash firmware
  echo avrdude -C "${CONF1_FILE}" ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b "${ISP_BAUDRATE}" -Uflash:w:${DIR_REL_BUILD_PATH}/${INO_DIR_NAME}.${FW_HEX_SUFFIX}:i
  avrdude -C "${CONF1_FILE}" ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b "${ISP_BAUDRATE}" -Uflash:w:${DIR_REL_BUILD_PATH}/${INO_DIR_NAME}.${FW_HEX_SUFFIX}:i
  if [ $? -ne 0 ]; then
    ErrorMsg
  fi

  if [ -n "$flg_fuse" ]; then
    # Lock Bit Protection - BLB1 Mode 2 BLB12=0b1, BLB11=0b0: SPM is not allowed to write to the Boot Loader section.
    echo "Write Fuse bit etc to ATmega${MCU_UPPER}."
    echo avrdude -C "${CONF1_FILE}" ${FORCE_OPTION} -v -D -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b "${ISP_BAUDRATE}" -Ulock:w:0x2F:m -Uefuse:w:0xF5:m -Uhfuse:w:0xD2:m -Ulfuse:w:0xFF:m
    avrdude -C "${CONF1_FILE}" ${FORCE_OPTION} -v -D -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b "${ISP_BAUDRATE}" -Ulock:w:0x2F:m -Uefuse:w:0xF5:m -Uhfuse:w:0xD2:m -Ulfuse:w:0xFF:m
    if [ $? -ne 0 ]; then
      ErrorMsg
    fi

    if [ -n "${FW_ARG}" ]; then
      echo "Write BRANCH_TYPE into ATmega${MCU_UPPER} EEPROM."
      # Get BRANCH_TYPE
      readonly BRANCH_TYPE=$(GetBranchType ${REL_INO_FILE})
      echo BRANCH_TYPE=0x${BRANCH_TYPE}

      # Generate Hex file
      CSV_FILES="${DIR_INO_ROOT}/${INO_DIR_NAME}/${USER_EEPROM_CSV_FILE}"
      CSV_FILE_NUM=`ls ${CSV_FILES} | wc -l`
      CSV_FILE_PATH=`ls ${CSV_FILES}`
      if [ "${CSV_FILE_NUM}" -gt 1 ]; then
        echo
        echo 'Detected the below eeprom_data csv files. Put only a file.'
        echo "${CSV_FILE_PATH}"
        ErrorMsg
      elif [ -n "${CSV_FILE_PATH}" ]; then
        CSV_FILE_PATH="-d ${CSV_FILE_PATH}"
        echo "Try to read ${CSV_FILE_PATH}"
      else
        echo "Skip user EEPROM data flash."
      fi

      echo
      echo python ${BASEDIR}/hex_generator.py ${BRANCH_TYPE} ${EEPROM_HEX_FILE} ${CSV_FILE_PATH}
      python ${BASEDIR}/hex_generator.py ${BRANCH_TYPE} ${EEPROM_HEX_FILE} ${CSV_FILE_PATH}
      if [ $? -ne 0 ]; then
        echo
        echo 'May need python installation and "pip install IntelHex"'
        ErrorMsg
      fi

      # Flash BRANCH_TYPE to EEPROM
      echo avrdude -C "${CONF1_FILE}" ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b "${ISP_BAUDRATE}" -U eeprom:w:${BASEDIR}/${EEPROM_HEX_FILE}:i
      avrdude -C "${CONF1_FILE}" ${FORCE_OPTION} -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b "${ISP_BAUDRATE}" -U eeprom:w:${BASEDIR}/${EEPROM_HEX_FILE}:i
      if [ $? -ne 0 ]; then
        ErrorMsg
      fi

      rm ${BASEDIR}/${EEPROM_HEX_FILE}
      # Verify
      #echo "Verify BRANCH_TYPE."
      #avrdude -C "${CONF1_FILE}" -v -p atmega${MCU_LOWER} -c stk500v1 -P ${PORT_PREFIX}${com} -b "${ISP_BAUDRATE}" -U eeprom:r:${BASEDIR}/verify.hex:i
    fi
  fi

  if [ -n "${BRANCH_TYPE}" ]; then
    echo "0x${BRANCH_TYPE} has been written into EEPROM"
  fi
fi
