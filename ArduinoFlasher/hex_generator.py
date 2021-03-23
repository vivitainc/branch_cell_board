#coding: UTF-8
# Make BRANCH_TYPE hex data
# pip install IntelHex at first

from __future__ import print_function
from intelhex import IntelHex
import struct
import sys
import os

VERSION = "v1.0"
ID_CHAR_LEN = 8

args = sys.argv

uid = [0, 0, 0, 0, 0, 0, 0, 0]

print()
print(args[0] + " " + VERSION)
print()

if (len(args) != 3):
    print("Error: 2 params are needed")
    print("python hex_generator.py [BRANCH_TYPE] [filename]]")
    print("e.g.) python hex_generator.py 12345678 eeprom.hex")
    sys.exit(1)

s = args[1]
if (len(s) < 1) or (len(s) > ID_CHAR_LEN):
    print("Error: BRANCH_TYPE is too short or too long")
    sys.exit(1)

hexfile = args[2]
if (len(hexfile) < 1):
    print("Error: invalid file name")
    sys.exit(1)

# Pad a numeric string with zeros
s = s.zfill(ID_CHAR_LEN)

# Split string data into list each 2 char (e.g. "AABB" -> ["AA", "BB"])
strid = [(i + j) for (i ,j) in zip(s[0::2], s[1::2])]

'''
# for debug
print("strid=", end='')
print(strid)
'''

uidlen = len(strid)

for index in range(ID_CHAR_LEN):
    if(index >= (ID_CHAR_LEN - uidlen)):
        uid[index] = int(strid[index  - (ID_CHAR_LEN - uidlen)], 16)

'''
# for debug
for index, item in enumerate(uid):
    print("index:" + str(index) + ", value:" + str(item))
'''

ih = IntelHex()
fmt = str(ID_CHAR_LEN) + "B" # ID_CHAR_LEN unsigned char
EEPROMSIZE = 1024 # Size of EEPROM

ih.puts(EEPROMSIZE - ID_CHAR_LEN, struct.pack(fmt, uid[0], uid[1], uid[2], uid[3], uid[4], uid[5], uid[6], uid[7]))

hex_file_name = os.path.join(os.path.dirname(os.path.abspath(__file__)), hexfile)
#print("hex_file_name = " + hex_file_name)

ih.dump()
ih.write_hex_file(hex_file_name)
