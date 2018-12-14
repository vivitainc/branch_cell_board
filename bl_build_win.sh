#!/bin/bash

PROGNAME=$(basename $0)
VERSION="${PROGNAME} v4.0"
echo
echo ${VERSION}
echo

DEFAULT_MICRO=328p
MICRO_OPTION="328p or 328pb"

DIR_BOOTLOADER_328P=bootloaders/atmega
BOOTLOADER_NAME_328P_SRC=ATmegaBOOT_168_atmega328_pro_8MHz.hex
BOOTLOADER_NAME_328P_DST=ATmegaBOOT_168_atmega328_pro_8MHz.hex
MAKE_OPTION_328P=atmega328_pro8

DIR_BOOTLOADER_328PB=bootloaders/atmega
BOOTLOADER_NAME_328PB_SRC=ATmegaBOOT_168_atmega328_pro_8MHz_pb.hex
BOOTLOADER_NAME_328PB_DST=ATmegaBOOT_168_atmega328_pro_8MHz_pb.hex
MAKE_OPTION_328PB=atmega328_pro8_pb

BASEDIR=$(cd $(dirname $0); pwd)
#echo ${BASEDIR}

function Usage() {
  echo 
  echo "Usage: ${PROGNAME} [Options]"
  echo 
  echo "Option: One of the options must be required"
  echo "  -h, --help              Help"
  echo "  -c, --clean             Clean"
  echo "  -m, --mcu <mcu_name>    Specify the target bootloader ${MICRO_OPTION}"
  echo
  exit 1
}

PARAM=()
for opt in "$@"; do
    case "${opt}" in
    '-h' | '--help' )
      Usage
      ;;
    '-m' | '--mcu' )
      # target bootloader
      if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
        echo "${PROGNAME}: $1 option requires an argument" 1>&2
        echo "Provide ${MICRO_OPTION}" 1>&2
        exit 1
      fi
      BL_ARG=("$2")
      shift 2
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

# Verify ${BL_ARG} and define ${FIXED_DIR_BOOTLOADER} and ${FIXED_BOOTLOADER_NAME_SRC} and ${FIXED_BOOTLOADER_NAME_DST} and ${FIXED_MAKE_OPTION}
if [ ! -n "${BL_ARG}" ]; then
  BL_TYPE=${DEFAULT_MICRO}
else
  BL_TYPE=${BL_ARG}
fi
BL_UPPER=`echo ${BL_TYPE} | tr '[a-z]' '[A-Z]'`
if [ "${BL_UPPER}" = "328P" ]; then
  FIXED_DIR_BOOTLOADER=${DIR_BOOTLOADER_328P}
  FIXED_BOOTLOADER_NAME_SRC=${BOOTLOADER_NAME_328P_SRC}
  FIXED_BOOTLOADER_NAME_DST=${BOOTLOADER_NAME_328P_DST}
  FIXED_MAKE_OPTION=${MAKE_OPTION_328P}
elif [ "${BL_UPPER}" = "328PB" ]; then
  FIXED_DIR_BOOTLOADER=${DIR_BOOTLOADER_328PB}
  FIXED_BOOTLOADER_NAME_SRC=${BOOTLOADER_NAME_328PB_SRC}
  FIXED_BOOTLOADER_NAME_DST=${BOOTLOADER_NAME_328PB_DST}
  FIXED_MAKE_OPTION=${MAKE_OPTION_328PB}
else
  echo "Cannot recognize -t/--target argument ${BL_ARG}" 1>&2
  echo "Provide ${MICRO_OPTION}" 1>&2
  exit 1
fi

if [ -n "${CLEAN_FLAG}" ]; then
  cd ${FIXED_DIR_BOOTLOADER}
  echo make clean
  make clean
  exit 0
fi

# Make
cd ${FIXED_DIR_BOOTLOADER}
echo make ${FIXED_MAKE_OPTION}
make ${FIXED_MAKE_OPTION}
cp ${FIXED_BOOTLOADER_NAME_SRC} ${USERPROFILE}/AppData/Local/Arduino15/packages/pololu-a-star/hardware/avr/4.0.2/${FIXED_DIR_BOOTLOADER}/${FIXED_BOOTLOADER_NAME_DST}
cd ../../

echo
echo Built ${FIXED_BOOTLOADER_NAME_SRC} in ${FIXED_DIR_BOOTLOADER}
echo Copied ${FIXED_BOOTLOADER_NAME_SRC} to ${USERPROFILE}/AppData/Local/Arduino15/packages/pololu-a-star/hardware/avr/4.0.2/${FIXED_DIR_BOOTLOADER}/${FIXED_BOOTLOADER_NAME_DST}
echo Build finished for ATmega${BL_UPPER}

exit 0

