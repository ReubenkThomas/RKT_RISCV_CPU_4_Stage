#!/usr/bin/python

# Description: 
#   Test generator for the LoadExtender module for the RISC-V Processor
#
# Output:
#   Testvectors in binary format found in ./loadextendertestvectors.input
#
# Authors:
#   Matthew Dharmawan and Reuben Koshy Thomas

import random
import os
from functools import reduce


def bin(x, width):
    if x < 0: x = (~x) + 1
    return ''.join([(x & (1 << i)) and '1' or '0' for i in range(width-1, -1, -1)])


# def sign_extend(value, bits):
#     sign_bit = 1 << (bits - 1)
#     return (value & (sign_bit - 1)) - (value & sign_bit)

def bin_12(num):
    return binifier(list("{0:12b}".format(num)))

def bin_13(num):
    return binifier(list("{0:13b}".format(num)))

def bin_32(num):
    return binifier(list("{0:32b}".format(num)))

def pad_right(num):
    binary = list("{0:20b}".format(num))
    for i in range(len(binary)):
        if binary[i] == ' ':
            binary[i] = '0'
    ret_str = ""
    for x in binary:
        ret_str += x
    return ret_str + "0" * 12

def binifier(binary):
    for i in range(len(binary)):
        if binary[i] == ' ':
            binary[i] = '0'
    sign = '1' if binary[0] == '1' else '0'
    
    bin_32 = (32 - len(binary)) * ['1' if binary[0] == '1' else '0'] + list(binary)
        #bin_32 = list(binary) + (32 - len(binary)) * ('1' if binary[0] else '0')
    for i in range(len(bin_32)):
        if bin_32[i] == ' ':
            bin_32[i] = '0'
    ret_str = ""
    for x in bin_32:
        ret_str += x
    return ret_str

lb = "000"
lbu = "100"
lh = "001"
lhu = "101"
lw = "010"

funct3 = \
{ 
    "SIGNED_BYTE"       : lb,
    "UNSIGNED_BYTE"     : lbu,
    "SIGNED_HALFWORD"   : lh,
    "UNSIGNED_HALFWORD" : lhu,
    "WORD"              : lw
}

def vet(string):
    ret_str = ""
    for i in string:
        if i == " ":
            ret_str += '0'
        else:
            ret_str += i
    return ret_str

def vet_lst(lst):
    ret_lst = []
    for i in lst:
        ret_lst.append(vet(i))
    return ret_lst

def gen_vector(DataR, f3, out):
    """
    Inputs:
        DataR: 32-bit data representing the word that was outputted by the DMEM. 
               The entire word will be shown (but only the instruction type will be checked)
        f3   : The funct3 of the instruction.
        out  : Expected output of the load instruction.
    Output:
        A 67-bit test vector in {DataR, f3, out} format.
    """
    lst = [DataR, f3, out]
    write_lst = vet_lst(lst)
    #print(lst)
    
    return ''.join(write_lst)

def lst_to_str(lst):
    ret_str = ""
    for x in lst:
        ret_str += x
    return ret_str

def ex_byte(s):
    word = vet(s)
    if s[24] == "1":
        return "1" * 24 + s[24:]
    else:
        return "0" * 24 + s[24:]


def ex(s, ftype, signed):
    if ftype == lb or ftype == lbu:
        i = 24
    elif ftype == lh or ftype == lhu:
        i = 16
    else:
        i = 0

    if signed:
        extend = "1" * i if s[i] == "1" else "0" * i
        return extend + s[i:]
    else:
        return "0" * i + s[i:]





    word = vet(s)
    if s[24] == "1":
        return "1" * 24 + s[24:]
    else:
        return "0" * 24 + s[24:]


random.seed(os.urandom(32))
file = open('loadextendertestvectors.input', 'w')
loops = 1000 # Update this to have more tests, but also update the loops variable in ImmGenTestVectorTestBench.v
w = ""
for i in range(loops):
    for f3, binary in funct3.items():
        
        # imm_12 = random.randint(0, 0xfff)
        # imm_13 = random.randint(0, 0x1ffe) 
        # imm_13 = imm_13 - 1 if imm_13 % 2 == 1 else imm_13
        # imm_20 = random.randint(0, 0xfffff)
        # imm_21 = random.randint(0, 0x1ffffe)
        # imm_21 = imm_21 - 1 if imm_21 % 2 == 1 else imm_21
        imm_32 = vet(bin_32(random.randint(0, 0xffffffff)))
        if f3 == "SIGNED_BYTE":
            data_imm = ex(s=imm_32, ftype=binary, signed=True)
            pass
        elif f3 == "UNSIGNED_BYTE":
            data_imm = ex(s=imm_32, ftype=binary, signed=False)
            pass
        elif f3 == "SIGNED_HALFWORD":
            data_imm = ex(s=imm_32, ftype=binary, signed=True)
            pass
        elif f3 == "UNSIGNED_HALFWORD":
            data_imm = ex(s=imm_32, ftype=binary, signed=False)
            pass
        elif f3 == "WORD":
            data_imm = ex(s=imm_32, ftype=binary, signed=True)
            pass
        
        data = gen_vector(imm_32, binary, data_imm)
        w += data + "\n"

#print(len(w) - 8)
#print(8 * 32 * 2 * loops)
file.write(w)
