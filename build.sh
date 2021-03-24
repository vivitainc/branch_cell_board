#!/bin/bash

PROGNAME=$(basename $0)
VERSION="${PROGNAME} v6.0"
echo
echo ${VERSION}
echo

ENV_DIR="$(pwd -P)/utils/envs"
source "${ENV_DIR}/env.sh"

DIR_INO_ROOT=examples
DIR_BUILD=build
DIR_EX_LIB=externals
DIR_OWN_LIB=VivicoreSerial
DIR_WORKSPACE=_workspace
WINAVR_GCC='WinAVR-20100110'
DIR_WINAVR_GCC_BIN="/c/${WINAVR_GCC}/bin"
DIR_TMP_HARDWARE_PACKAGE="${DIR_HARDWARE4}/0.0.1"

DIR_SKETCH=sketch
FW_BIN_SUFFIX="ino.bin"
FW_HEX_SUFFIX="ino.hex"
FW_W_BL_HEX_SUFFIX="ino.with_bootloader.hex"
BUILD_OPTION_FILE="build.options.json"
BUILD_LOG_NAME="build.log"
BUILD_ERRLOG_NAME="error.log"
BOARD_TYPES=('branch' 'custom')
BOARD_TYPE_NUMBER=0
BOARD_328PB_NAME="viviware:avr:cell-328pb:version="
MCU_TYPE=328pb
ERROR_MESSAGES=()

HARDWARE="-hardware \"${DIR_HARDWARE1}\""

if [ -e "${DIR_HARDWARE2}" ]; then
    HARDWARE=${HARDWARE}" -hardware \"${DIR_HARDWARE2}\""
fi

if [ -e "${DIR_HARDWARE3}" ]; then
    HARDWARE=${HARDWARE}" -hardware \"${DIR_HARDWARE3}\""
fi

TOOLS="-tools \"${DIR_TOOLS1}\""

if [ -e "${DIR_TOOLS2}" ]; then
    TOOLS=${TOOLS}" -tools \"${DIR_TOOLS2}\""
fi

if [ -e "${DIR_TOOLS3}" ]; then
    TOOLS=${TOOLS}" -tools \"${DIR_TOOLS3}\""
fi

export PATH="${DIR_ARDUINO_BIN}:${DIR_ARDUINO}:$PATH"

#echo DIR_ARDUINO=${DIR_ARDUINO}
#echo HARDWARE=${HARDWARE}
#echo TOOLS=${TOOLS}
#echo DIR_BUILTIN_LIB=${DIR_BUILTIN_LIB}
#echo DIR_LIB=${DIR_LIB}

BASEDIR=$(cd $(dirname $0); pwd)
#echo ${BASEDIR}

function Clobber() {
  if [ -e "${DIR_WORKSPACE}" ]; then
    # Remove all libraries
    rm -rf ${DIR_WORKSPACE}
  fi
}

function ListBoardTypes() {
  local ret
  local sep

  for i in $(seq 0 $((${#BOARD_TYPES[@]} - 1))); do
    ret="${ret}${sep}${i} for ${BOARD_TYPES[${i}]}"
    sep=', '
  done

  echo "${ret}"
}

function Usage() {
  echo 
  echo "Usage: ${PROGNAME} [Options]"
  echo
  echo "Note: This script builds bootloader and applies them as ${DIR_TMP_HARDWARE_PACKAGE}."
  echo "      Install again VIVIWARE board package after build with this script."
  echo
  echo "Option: One of the options must be required"
  echo "  -h, --help              Help"
  echo "      --version           Show version"
  echo "  -f, --fw <fw_name>      Build a specific fw"
  echo "  -t, --board-type <num>  Build with board type number (default: $(ListBoardTypes))"
  echo "  -r, --rebuild           Clean and Rebuild"
  echo "  -c, --clean             Clean"
  echo "  -a, --all               Build all fw"
  echo "  -d, --dir <root_dir>    root dir when -a / -c / -r is given"
  echo
  exit 1
}

PARAM=()
for opt in "$@"; do
    case "${opt}" in
    '-h' | '--help' )
      Usage
      ;;
    '--version' )
      echo ${VERSION}
      exit 1
      ;;
    '-a' | '--all' )
      # Build all
      flg_build_all=1
      shift
      ;;
    '-c' | '--clean' )
      # Clean
      flg_clean=1
      shift
      ;;
    '-r' | '--rebuild' )
      # Rebuild
      flg_clean=1
      flg_build_all=1
      shift
      ;;
    '-t' | '--board-type' )
      if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
        echo "${PROGNAME}: $1 option requires an argument" 1>&2
        exit 1
      fi
      BOARD_TYPE_NUMBER="${2}"
      shift 2
      ;;
    '-f' | '--fw' )
      # firmware must need an arg
      if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
        echo "${PROGNAME}: $1 option requires an argument" 1>&2
        exit 1
      fi
      FW_ARG=("$2")
      shift 2
      ;;
    '-d' | '--dir' )
      # dir must need an arg
      if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
        echo "${PROGNAME}: $1 option requires an argument" 1>&2
        exit 1
      fi
      DIR_ARG=("$2")
      shift 2
      ;;
    '--' | '-' )
      shift
      PARAM+=( "$@" )
      break
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

# Arg without option
PARAM1="${PARAM}"; PARAM=("${PARAM[@]:1}")
#echo "PARAM1=${PARAM1}"
if [ -z "${FW_ARG}" ] && [ -z "${PARAM1}" ] && [ -z "${flg_clean}" ] && [ -z "${flg_build_all}" ]; then
  Usage
elif ! [[ "${BOARD_TYPE_NUMBER}" =~ [0-9]+ ]] || [ "${BOARD_TYPE_NUMBER}" -ge "${#BOARD_TYPES[@]}" ]; then
  echo
  echo "Cannot recognize -t/--board-type argument ${BOARD_TYPE_NUMBER}" 1>&2
  echo "Select one of $(ListBoardTypes)" 1>&2
  exit 1
elif [ ! -n "${FW_ARG}" ]; then
  # argument without -f|--fw option is treated as FW_ARG
  FW_ARG="${PARAM1}"
fi

MCU_UPPER=`echo ${MCU_TYPE} | tr '[a-z]' '[A-Z]'`
BOARD_TYPE=${BOARD_TYPES[${BOARD_TYPE_NUMBER}]}
BOARD_NAME=${BOARD_328PB_NAME}${BOARD_TYPE}

# Verify ${FW_ARG} and create ${INO_DIR_NAME}, ${DIR_INO_ROOT}, ${REL_INO_FILE}
if [ -n "${FW_ARG}" ]; then
  if [ -e "${FW_ARG}" ]; then
    if [ -f "${FW_ARG}" ] && [ ${FW_ARG##*.} = ino ]; then
      # If ${FW_ARG} is ino file full path
      INO_FILE_NAME=${FW_ARG##*/}
      INO_DIR_NAME=${INO_FILE_NAME%.*}
      DIR_INO_ROOT=${FW_ARG%%/${INO_DIR_NAME}*}
      REL_INO_FILE="${FW_ARG}"
      #echo "${FW_ARG} = ino file full path: ${REL_INO_FILE}"
    else
      # If ${FW_ARG} is ino directory full path
      INO_DIR_NAME=`basename ${FW_ARG}`
      DIR_INO_ROOT=${FW_ARG%%/${INO_DIR_NAME}*}
      REL_INO_FILE="${FW_ARG}/${INO_DIR_NAME}.ino"
      #echo "${FW_ARG} = ino directory path: ${REL_INO_FILE}"
    fi
  elif [ -d "${DIR_INO_ROOT}/${FW_ARG}" ]; then
    # If ${FW_ARG} is ino directory name
    INO_DIR_NAME=${FW_ARG}
    REL_INO_FILE="${DIR_INO_ROOT}/${INO_DIR_NAME}/${INO_DIR_NAME}.ino"
    #echo "${FW_ARG} = ino file name: ${REL_INO_FILE}"
  else
    echo "Cannot recognize -f/--fw argument ${FW_ARG}" 1>&2
    exit 1
  fi
  #echo "INO_DIR_NAME=${INO_DIR_NAME}"
  #echo "REL_INO_FILE=${REL_INO_FILE}"
fi

# Verify ${DIR_ARG} and create ${INO_DIR_NAME}, ${DIR_INO_ROOT}, ${REL_INO_FILE}
if [ -n "${DIR_ARG}" ]; then
  if [ -d "${DIR_ARG}" ]; then
    DIR_INO_ROOT=${DIR_ARG}
  fi
fi

#echo "DIR_INO_ROOT=${DIR_INO_ROOT}"

# In case of illegal option
if [[ -n "${PARAM[@]}" ]]; then
  echo "${PARAM[@]}"
  echo "Cannot recognize arguments" 1>&2
  Usage
fi

echo "----------------------------"
echo "MCU       = ${MCU_UPPER}"
echo "Clean     = ${flg_clean}"
echo "Build_all = ${flg_build_all}"
echo "INO_ROOT  = ${DIR_INO_ROOT}"
echo "FW        = ${INO_DIR_NAME}"
echo "BOARD_TYPE= ${BOARD_TYPE}"
echo "----------------------------"

function Clean() {
  if [ $# -eq 0 ]; then
    echo "Clean function needs an argument"
    exit 1
  fi
  ino_name=("$1")
  DIR_INO_PATH=${DIR_INO_ROOT}/${ino_name}
  DIR_REL_BUILD_PATH=${DIR_INO_PATH}/${DIR_BUILD}

  echo "Clean ${DIR_INO_PATH}"
  if [ -e "${DIR_REL_BUILD_PATH}" ]; then
    rm -r "${DIR_REL_BUILD_PATH}"
    #rm "${DIR_INO_PATH}/${BUILD_LOG_NAME}"
  fi
}

function GetSubmodules() {
  if ! [ -d .git ]; then
    echo "${FUNCNAME[0]} needs submodule libraries. Clone this repository but not use zip archive."
    exit 1
  fi

  if [ "$(git --no-pager submodule status | grep -cE '^(-|\+)')" -gt 0 ]; then
    git --no-pager submodule status | grep -E '^(-|\+)' | cut -d' ' -f2 | while read -r MODULE; do
      git submodule update --init "${MODULE}"
    done
  fi
}

function CompileBootloader() {
  if ! [ -d "${DIR_WINAVR_GCC_BIN}" ]; then
    echo "${WINAVR_GCC} must be instelled to compile bootloader"
    exit 1
  fi

  make -C ${DIR_BOOTLOADER} TOOLCHAIN_PREFIX="${DIR_WINAVR_GCC_BIN}/" clean all
  echo
  echo "Built $(ls ${DIR_BOOTLOADER}/*.hex) for ATmega${MCU_UPPER} with $("${DIR_WINAVR_GCC_BIN}/avr-gcc" --version | head -n 1)"
}

function InstallLocalPackage() {
  echo
  echo "Uninstall all package for VIVIWARE in ${DIR_HARDWARE4}"
  mkdir -p "${DIR_HARDWARE4}"
  rm -rf "${DIR_HARDWARE4:?}"/*

  echo
  echo "Install package as ${DIR_TMP_HARDWARE_PACKAGE}"
  mkdir -p "${DIR_TMP_HARDWARE_PACKAGE}"
  cp -rf ./* "${DIR_TMP_HARDWARE_PACKAGE}"/
}

function CompileFirmware() {
  if [ $# -eq 0 ]; then
    echo "ComplileFirmware function needs an argument"
    exit 1
  fi
  ino_name=("$1")

  DIR_INO_PATH=${DIR_INO_ROOT}/${ino_name}
  if [ ! -e ${DIR_INO_PATH}/${ino_name}.ino ]; then
    echo "Skip ${ino_name} due to no ino file"
    return
  fi
  DIR_REL_BUILD_PATH=${DIR_INO_PATH}/${DIR_BUILD}
  if [ ! -e "${DIR_REL_BUILD_PATH}" ]; then
    mkdir -p "${DIR_REL_BUILD_PATH}"
  elif [ -e "${DIR_REL_BUILD_PATH}/${DIR_SKETCH}" ]; then
    rm -r "${DIR_REL_BUILD_PATH}/${DIR_SKETCH}"
  fi

  #echo DIR_INO_PATH=${DIR_INO_PATH}
  #echo DIR_REL_BUILD_PATH=${DIR_REL_BUILD_PATH}

  DIR_ABS_BUILD_PATH=$(cd $DIR_REL_BUILD_PATH && pwd)
  #echo DIR_ABS_BUILD_PATH=${DIR_ABS_BUILD_PATH}

  # Backup existing fw binary
  if [ -e "${DIR_INO_ROOT}/${ino_name}/${DIR_BUILD}/${ino_name}.${FW_BIN_SUFFIX}" ]; then
    mv "${DIR_INO_ROOT}/${ino_name}/${DIR_BUILD}/${ino_name}.${FW_BIN_SUFFIX}" "${DIR_INO_ROOT}/${ino_name}/${DIR_BUILD}/${ino_name}.${FW_BIN_SUFFIX}.bak"
  fi
  if [ -e "${DIR_INO_ROOT}/${ino_name}/${DIR_BUILD}/${ino_name}.${FW_HEX_SUFFIX}" ]; then
    mv "${DIR_INO_ROOT}/${ino_name}/${DIR_BUILD}/${ino_name}.${FW_HEX_SUFFIX}" "${DIR_INO_ROOT}/${ino_name}/${DIR_BUILD}/${ino_name}.${FW_HEX_SUFFIX}.bak"
  fi
  if [ -e "${DIR_INO_ROOT}/${ino_name}/${DIR_BUILD}/${ino_name}.${FW_W_BL_HEX_SUFFIX}" ]; then
    mv "${DIR_INO_ROOT}/${ino_name}/${DIR_BUILD}/${ino_name}.${FW_W_BL_HEX_SUFFIX}" "${DIR_INO_ROOT}/${ino_name}/${DIR_BUILD}/${ino_name}.${FW_W_BL_HEX_SUFFIX}.bak"
  fi
  # Remove json to avoid build error when recompiling
  if [ -e "${DIR_INO_ROOT}/${ino_name}/${DIR_BUILD}/${BUILD_OPTION_FILE}" ]; then
    rm "${DIR_INO_ROOT}/${ino_name}/${DIR_BUILD}/${BUILD_OPTION_FILE}"
  fi
  # Specify workspace directory path including our own and external library
  if [ ! -d "${DIR_WORKSPACE}" ]; then
    DIR_WORKSPACE="${DIR_LIB}"
  fi

  # Compile
  echo "Building ${DIR_INO_PATH}/${ino_name}.ino for ATmega${MCU_UPPER} with $(avr-gcc --version | head -n 1)"

  #echo arduino-builder -dump-prefs ${HARDWARE} ${TOOLS} -built-in-libraries "${DIR_BUILTIN_LIB}" -libraries "${DIR_WORKSPACE}" -fqbn="${BOARD_NAME}" -build-path "${DIR_ABS_BUILD_PATH}" -verbose ${DIR_INO_PATH}/${ino_name}.ino
  eval "arduino-builder -dump-prefs ${HARDWARE} ${TOOLS} -built-in-libraries \"${DIR_BUILTIN_LIB}\" -libraries \"${DIR_WORKSPACE}\" -fqbn=\"${BOARD_NAME}\" -build-path \"${DIR_ABS_BUILD_PATH}\" -verbose \"${DIR_INO_PATH}/${ino_name}.ino\"" 1> "${DIR_ABS_BUILD_PATH}/${BUILD_LOG_NAME}" 2> "${DIR_ABS_BUILD_PATH}/${BUILD_ERRLOG_NAME}"

  #echo arduino-builder -compile ${HARDWARE} ${TOOLS} -built-in-libraries "${DIR_BUILTIN_LIB}" -libraries "${DIR_WORKSPACE}" -fqbn="${BOARD_NAME}" -build-path "${DIR_ABS_BUILD_PATH}" -verbose ${DIR_INO_PATH}/${ino_name}.ino
  eval "arduino-builder -warnings more -compile ${HARDWARE} ${TOOLS} -built-in-libraries \"${DIR_BUILTIN_LIB}\" -libraries \"${DIR_WORKSPACE}\" -fqbn=\"${BOARD_NAME}\" -build-path \"${DIR_ABS_BUILD_PATH}\" -verbose \"${DIR_INO_PATH}/${ino_name}.ino\"" 1>> "${DIR_ABS_BUILD_PATH}/${BUILD_LOG_NAME}" 2>> "${DIR_ABS_BUILD_PATH}/${BUILD_ERRLOG_NAME}"

  echo avr-objcopy -I ihex "${DIR_INO_ROOT}/${ino_name}/${DIR_BUILD}/${ino_name}.${FW_HEX_SUFFIX}" -O binary "${DIR_INO_ROOT}/${ino_name}/${DIR_BUILD}/${ino_name}.${FW_BIN_SUFFIX}"
  avr-objcopy -I ihex "${DIR_INO_ROOT}/${ino_name}/${DIR_BUILD}/${ino_name}.${FW_HEX_SUFFIX}" -O binary "${DIR_INO_ROOT}/${ino_name}/${DIR_BUILD}/${ino_name}.${FW_BIN_SUFFIX}"

  if [ -s "${DIR_ABS_BUILD_PATH}/${BUILD_ERRLOG_NAME}" ] ; then
    cat "${DIR_ABS_BUILD_PATH}/${BUILD_ERRLOG_NAME}"
  fi
}

function VerifyBuildResult() {
  if [ $# -eq 0 ]; then
    echo "VerifyBuildResult function needs an argument"
    exit 1
  fi
  ino_name=("$1")
  if [ ! -e "${DIR_INO_ROOT}/${ino_name}/${ino_name}.ino" ]; then
    # Skip verification in case of no ino file
    return
  fi
  if [ ! -e "${DIR_INO_ROOT}/${ino_name}/${DIR_BUILD}/${ino_name}.${FW_W_BL_HEX_SUFFIX}" ]; then
    echo "${ino_name} build failed! See ${DIR_INO_ROOT}/${ino_name}/${DIR_BUILD}/${BUILD_ERRLOG_NAME}"
  else
    echo "Successfully ${ino_name}.${FW_W_BL_HEX_SUFFIX} and ${ino_name}.${FW_HEX_SUFFIX} generated for ATmega${MCU_UPPER}."
  fi
}

function CheckRomRam() {
  if [ $# -eq 0 ]; then
    echo "VerifyBuildResult function needs an argument"
    exit 1
  fi
  ino_name=("$1")
  if [ ! -e "${DIR_INO_ROOT}/${ino_name}/${ino_name}.ino" ]; then
    # Skip verification in case of no ino file
    return
  fi
  if [ -e "${DIR_INO_ROOT}/${ino_name}/${DIR_BUILD}/${ino_name}.${FW_W_BL_HEX_SUFFIX}" ]; then
    echo "${ino_name} for ATmega${MCU_UPPER}"
    tail -n 2 "${DIR_INO_ROOT}/${ino_name}/${DIR_BUILD}/${BUILD_LOG_NAME}"
    echo
  fi
}

Clobber

ERR_SUBMODULES="$(GetSubmodules 2>&1 > /dev/null)"
if [ -n "${ERR_SUBMODULES}" ]; then
  ERROR_MESSAGES=("${ERROR_MESSAGES[@]}" "${ERR_SUBMODULES}")
fi

if [ -n "${flg_build_all}" ] || [ -n "${REL_INO_FILE}" ]; then
  # Copy root *.h *.cpp to ${DIR_WORKSPACE}
  #for lib_file in `\find . -maxdepth 1 -type f -name *.h | sed 's!^.*/!!'`; do
  for lib_file in *.cpp *.h; do
    if [ -f "${lib_file}" ]; then
      mkdir -p "${DIR_WORKSPACE}/${DIR_OWN_LIB}"
      cp "${lib_file}" "${DIR_WORKSPACE}/${DIR_OWN_LIB}"
      echo "Copied ${lib_file} to ${DIR_WORKSPACE}/${DIR_OWN_LIB}"
    fi
  done

  # Copy libraries directory to ${DIR_WORKSPACE}
  if [ -d "${DIR_EX_LIB}" ]; then
    cp -R ${DIR_EX_LIB}/* "${DIR_WORKSPACE}/"
    echo "Copied ${DIR_EX_LIB}/* to ${DIR_WORKSPACE}/"
  fi
fi

if [ -n "${FW_ARG}" ]; then
  if [ ! -e "${REL_INO_FILE}" ]; then
    echo "Cannot find ${REL_INO_FILE}"
    exit 1
  fi
fi

if [ ! -n "${FW_ARG}" ]; then
  LS_CMD="ls -1 ${DIR_INO_ROOT}"
  echo "Try to look into directories under ${DIR_INO_ROOT}"
else
  LS_CMD="echo ${INO_DIR_NAME}"
fi
#echo "LS_CMD=${LS_CMD}"

# Clean, Compile, and apply bootloader
if [ -n "${FW_ARG}" ] || [ -n "${flg_build_all}" ]; then
  if [ -d "${DIR_BOOTLOADER}" ]; then
    CompileBootloader
    InstallLocalPackage
  fi
fi

# Clean and Compile
for ino_dir in `${LS_CMD}`; do
  if [ ! -d "${DIR_INO_ROOT}/$ino_dir" ]; then
    continue
  fi
  if [ -n "${flg_clean}" ]; then
    Clean "$ino_dir"
  fi
  if [ -n "${FW_ARG}" ] || [ -n "${flg_build_all}" ]; then
    CompileFirmware "$ino_dir"
  fi
done

# Clean bootloader and package
if [ -d "${DIR_TMP_HARDWARE_PACKAGE}" ]; then
  rm -rf "${DIR_TMP_HARDWARE_PACKAGE}"
fi

# Verify compile results
if [ -n "${FW_ARG}" ] || [ -n "${flg_build_all}" ]; then
  echo
  echo "============================================================"
  for ino_dir in `${LS_CMD}`; do
    if [ ! -d "${DIR_INO_ROOT}/$ino_dir" ]; then
      continue
    fi
    CheckRomRam ${ino_dir}
  done
  echo "============================================================"
  for ino_dir in `${LS_CMD}`; do
    if [ ! -d "${DIR_INO_ROOT}/$ino_dir" ]; then
      continue
    fi
    VerifyBuildResult ${ino_dir}
  done
fi

if [ "${#ERROR_MESSAGES[@]}" -gt 0 ]; then
  ERROR_NOTICE="with below errors or warnings"
fi

echo
echo "Done ${ERROR_NOTICE}"
echo "${ERROR_MESSAGES[@]}"

exit 0

