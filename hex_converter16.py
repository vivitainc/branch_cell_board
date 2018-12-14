#coding: UTF-8

# Prerequisite: pip install IntelHex

from intelhex import IntelHex
import struct
import sys
import os

args = sys.argv

if (len(args) != 3):
    print("Usage: python " + args[0] + " [input hex] [output hex]")
    sys.exit()

s = args[1]

ih = IntelHex()
ih.loadhex(args[1])
ih.write_hex_file(args[2], byte_count=16)
