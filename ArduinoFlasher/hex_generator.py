#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Make BRANCH_TYPE hex data
# pip install IntelHex at first

from __future__ import print_function
from intelhex import IntelHex
import sys
import os
import argparse
import csv
from typing import List

VERSION = "v2.0"

EEPROMSIZE = 1024 # Size of EEPROM
BRANCH_TYPE_BYTES = 4
SYSTEM_RESERVED_ADDR = EEPROMSIZE - BRANCH_TYPE_BYTES
USER_DATA_ADDR = 0

csvFilePath = str()

def init_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        'branch_type',
        type=str,
        help='branch_type to be written to EEPROM',
    )
    parser.add_argument(
        'hexfile',
        type=str,
        help='filename for intel hex',
    )
    parser.add_argument(
        '-d', '--user-data',
        type=str,
        help='Path to user data csv file',
    )
    parser.add_argument(
        '--version',
        action='version',
        version='%(prog)s ' + VERSION,
    )
    return parser.parse_args()


def ErrorMsg():
    print("Error: " + csvFilePath + " is invalid.")
    sys.exit(1)


def stoi(string: str) -> int:
    string = string.strip()
    try:
        value = int(string, 0)
    except ValueError as e:
        print("ValueError")
        print(e.args)
        ErrorMsg()
    if value < -32768 or value > 32767:
        print(str(value) + " cannot be converted to 2byte signed int.")
        ErrorMsg()
    return value


def itoh(value: int, size: int) -> str:
    if value >= 0:
        result = format(value, '0{0}X'.format(size))
    else:
        result = format(int('F' * size, 16) + value + 1, 'X')
    return result[-size:]


def strlist_to_bytes(list: List[str]) -> bytes:
    bytes_data = bytes()
    sum = 0
    for value in list:
        sum += 2
        decVal = stoi(value)
        hexVal = itoh(decVal, 4)
        if USER_DATA_ADDR + sum > SYSTEM_RESERVED_ADDR:
            print("User data overflow w/ " + str(sum) + " bytes.")
            ErrorMsg()
        print(str(decVal).ljust(6), end='')
        print(" => 0x", end='')
        print(hexVal)
        bytes_data += bytes.fromhex(hexVal)
    return bytes_data


def main(args: argparse.Namespace):
    brtype = args.branch_type
    hexfile = args.hexfile

    # Pad a numeric string with zeros
    brtype = brtype.zfill(BRANCH_TYPE_BYTES * 2)

    # Split string data into bytes (e.g. "AABBCCDD" -> b'\xaa\xbb\xcc\xdd'
    bytes_brtype = bytes.fromhex(brtype)

    '''
    # for debug
    print("bytes_brtype=", end='')
    print(bytes_brtype)
    '''

    ih = IntelHex()

    # Write out user defined data
    global csvFilePath
    csvFilePath = args.user_data
    if csvFilePath is not None:
        # if csvFilePath is given
        if os.path.exists(csvFilePath):
            with open(csvFilePath, 'r') as fp:
                csvList = list(csv.reader(fp))
                if len(csvList) > 0:
                    print("csvList has some contents")
                    flatList = [item for subList in csvList for item in subList]
                    print(flatList)
                    bytes_data = strlist_to_bytes(flatList)
                    if len(bytes_data) > 0:
                        ih.puts(USER_DATA_ADDR, bytes_data)
                else:
                    print(csvFilePath + " is empty")
                    ErrorMsg()
        else:
            print(csvFilePath + " not found. Skip user defined EEPROM data flash.")
            print()
    else:
        print("Skip user defined EEPROM data flash.")
        print()

    # Write out branchType
    ih.puts(SYSTEM_RESERVED_ADDR, bytes_brtype)

    hex_file_name = os.path.join(os.path.dirname(os.path.abspath(__file__)), hexfile)

    ih.dump()
    ih.write_hex_file(hex_file_name)

if __name__ == '__main__':
    print()
    print(os.path.basename(__file__) + " " + VERSION)
    print()
    ARGS = init_args()
    main(ARGS)
