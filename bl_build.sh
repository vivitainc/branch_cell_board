#!/usr/bin/env bash

PROGNAME=$(basename $0)
VERSION="${PROGNAME} v5.0"
echo
echo ${VERSION}
echo
BASEDIR=$(dirname $0)
#echo BASEDIR=${BASEDIR}

CURRENT_DIR=`pwd -P`
export ENV_DIR="${CURRENT_DIR}/envs"
source "${ENV_DIR}/env.sh"

DIR_BOOTLOADER_328P=bootloaders/atmega
BOOTLOADER_NAME_328P_SRC=ATmegaBOOT_168_atmega328_pro_8MHz_vparts.hex
BOOTLOADER_NAME_328P_DST=ATmegaBOOT_168_atmega328_pro_8MHz_vparts.hex
MAKE_OPTION_328P=atmega328_pro8

DIR_BOOTLOADER_328PB=bootloaders/atmega
BOOTLOADER_NAME_328PB_SRC=ATmegaBOOT_168_atmega328_pro_8MHz_vparts.hex
BOOTLOADER_NAME_328PB_DST=ATmegaBOOT_168_atmega328_pro_8MHz_vparts.hex
MAKE_OPTION_328PB=atmega328_pro8

DEFAULT_MICRO=328pb

function Usage() {
  echo 
  echo "Usage: ${PROGNAME} [Options]"
  echo 
  echo "Option:"
  echo "  -h, --help              Help"
  echo "  -c, --clean             Clean"
  echo
  exit 1
}

PARAM=()
for opt in "$@"; do
    case "${opt}" in
    '-h' | '--help' )
      Usage
      ;;
    '-c' | '--clean' )
      CLEAN_FLAG=1
      shift
      ;;
    -* )
      echo "${PROGNAME}: $1 illegal option" 1>&2
      Usage
      ;;
    * )
      if [[ -n "$1" ]] && [[ ! "$1" =~ ^-+ ]]; then
          PARAM+=( "$1" ); shift
      fi
      ;;
    esac
done

# If ${CONF1_USR_FILE} does not exist, use ${CONF1_DEFAULT_FILE} instead
if [ ! -e "${CONF1_USR_FILE}" ]; then
  CONF1_FILE=${CONF1_DEFAULT_FILE}
else
  CONF1_FILE=${CONF1_USR_FILE}
fi

MCU_TYPE=${DEFAULT_MICRO}
MCU_UPPER=`echo ${MCU_TYPE} | tr '[a-z]' '[A-Z]'`
FIXED_DIR_BOOTLOADER=${DIR_BOOTLOADER_328PB}
FIXED_BOOTLOADER_NAME_SRC=${BOOTLOADER_NAME_328PB_SRC}
FIXED_BOOTLOADER_NAME_DST=${BOOTLOADER_NAME_328PB_DST}
FIXED_DIR_BOOTLOADER_SRC=${DIR_BOOTLOADER_328PB}
FIXED_DIR_BOOTLOADER_DST=${DIR_POLOLU_BOARD}/${DIR_BOOTLOADER_328PB}
FIXED_MAKE_OPTION=${MAKE_OPTION_328PB}

FIXED_SRC_BOOTLOADER_FILE=${SRC_BOOTLOADER_328PB_FILE}
FIXED_DST_BOOTLOADER_DIR=${DST_BOOTLOADER_328PB_DIR}
FIXED_DST_BOOTLOADER_FILE=${DST_BOOTLOADER_328PB_FILE}

if [ -n "${CLEAN_FLAG}" ]; then
  cd ${FIXED_DIR_BOOTLOADER_SRC}
  echo make clean
  make clean
  exit 0
fi

# Make
cd ${FIXED_DIR_BOOTLOADER_SRC}
echo make ${FIXED_MAKE_OPTION}
make ${FIXED_MAKE_OPTION}

echo
echo Built ${FIXED_SRC_BOOTLOADER_FILE}
echo Build finished for ATmega${MCU_UPPER}

exit 0
