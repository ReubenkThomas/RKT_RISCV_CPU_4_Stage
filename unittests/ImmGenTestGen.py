#!/usr/bin/python

# Description: 
#   Test generator for the ImmGen module for the RISC-V Processor
#
# Output:
#   Testvectors in binary format found in ./immgentestvectors.input
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

def bin_21(num):
    return binifier(list("{0:21b}".format(num)))

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

opcodes = \
{ 
    "ARITHMETIC":   "0010011",
    "LOAD":         "0000011",
    "STORE":        "0100011",
    "BRANCH":       "1100011",
    "JAL":          "1101111",
    "JALR":         "1100111",
    "AUIPC":        "0010111",
    "LUI":          "0110111"
    #"SYSCALL":      "1110011"
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

def gen_vector(f7, imm1, rs2, rs1, f3, imm2, rd, op, result):
    """
    Inputs:
        op:  string that is the opcode
        f7:  string that is the f7 (it doesn't matter so it will be hardset to '0' * 7)
        f3:  string that is the f3 (it doesn't matter so it will be hardset to '0' * 3)
        rs1: string that is the rs1 (hardset to '0' * 5)
        rs1: string that is the rs1 (hardset to '0' * 5)
        rd:  string that is the rd (hardset to '0' * 5)
        imm1: string that is the first segment of the immediate (in the order of the instruction)
        imm2: string that is the second segment of the immediate (in the order of the instruction)
    Output:
    """
    lst = [f7, imm1, rs2, rs1, f3, imm2, rd, op, result]
    write_lst = vet_lst(lst)
    #print(lst)
    
    return ''.join(write_lst)

DEFAULT_F7 = "0" * 7
DEFAULT_F3 = "0" * 3
DEFAULT_REG = "0" * 5
EMPTY = ""

def lst_to_str(lst):
    ret_str = ""
    for x in lst:
        ret_str += x
    return ret_str

def arithmetic(op, imm):
    binary = list("{0:12b}".format(imm))
    # binary in the correct order, so sign extend it 
    imm_str = lst_to_str(binary)
    return gen_vector( 
                    f7=EMPTY, 
                    imm1=imm_str, 
                    rs2=EMPTY, 
                    rs1=DEFAULT_REG,
                    f3=DEFAULT_F3, 
                    imm2=EMPTY,
                    rd=DEFAULT_REG, 
                    op=op, 
                    result=bin_12(imm))

def store(op, imm):
    binary = list("{0:12b}".format(imm))
    #print(binary)
    imm_str = lst_to_str(binary)
    imm_str = vet(imm_str)
    imm1 = imm_str[:7]
    #print(imm1)
    imm2 = imm_str[7:]
    #print(imm2)
    return gen_vector( 
                    f7=EMPTY, 
                    imm1=imm1, 
                    rs2=DEFAULT_REG, 
                    rs1=DEFAULT_REG,
                    f3=DEFAULT_F3, 
                    imm2=imm2,
                    rd=EMPTY, 
                    op=op, 
                    result=bin_12(imm))

def branch(op, imm):
    binary = list("{0:13b}".format(imm))
    #print(binary)
    imm_str = lst_to_str(binary)
    imm1 = imm_str[0] + imm_str[2:8]
    imm2 = imm_str[8:12] + imm_str[1]
    return gen_vector( 
                    f7=EMPTY, 
                    imm1=imm1, 
                    rs2=DEFAULT_REG, 
                    rs1=DEFAULT_REG,
                    f3=DEFAULT_F3, 
                    imm2=imm2,
                    rd=EMPTY, 
                    op=op, 
                    result=bin_13(imm))

def u_type(op, imm):
    binary = list("{0:20b}".format(imm))
    imm_str = lst_to_str(binary)
    return gen_vector( 
                    f7=EMPTY, 
                    imm1=imm_str, 
                    rs2=EMPTY, 
                    rs1=EMPTY,
                    f3=EMPTY, 
                    imm2=EMPTY,
                    rd=DEFAULT_REG, 
                    op=op, 
                    result=pad_right(imm))
    
def jump(op, imm):
    binary = list("{0:21b}".format(imm))
    #print(binary, len(binary))
    imm_str = lst_to_str(binary)
    imm1 = imm_str[0] + imm_str[10:20] + imm_str[9] + imm_str[1:9]
    imm1 = vet(imm1)
    return gen_vector( 
                    f7=EMPTY, 
                    imm1=imm1, 
                    rs2=EMPTY, 
                    rs1=EMPTY,
                    f3=EMPTY, 
                    imm2=EMPTY,
                    rd=DEFAULT_REG, 
                    op=op, 
                    result=bin_21(imm))



random.seed(os.urandom(32))
file = open('immgentestvectors.input', 'w')
loops = 1000 # Update this to have more tests, but also update the loops variable in ImmGenTestVectorTestBench.v
w = ""
for i in range(loops):
    for opcode, binary in opcodes.items():
        
        op = binary
        imm_12 = random.randint(0, 0xfff)
        imm_13 = random.randint(0, 0x1ffe) 
        imm_13 = imm_13 - 1 if imm_13 % 2 == 1 else imm_13
        imm_20 = random.randint(0, 0xfffff)
        imm_21 = random.randint(0, 0x1ffffe)
        imm_21 = imm_21 - 1 if imm_21 % 2 == 1 else imm_21
        imm_32 = random.randint(0, 0xffffffff)
        if opcode == "ARITHMETIC":
            data = arithmetic(op, imm_12)
            pass
        elif opcode == "LOAD": 
            data = arithmetic(op, imm_12)
            pass
        elif opcode == "STORE":
            data = store(op, imm_12)
            pass
        elif opcode == "BRANCH":
            data = branch(op, imm_13)
            pass
        elif opcode == "JAL":
            data = jump(op, imm_21)
            pass
        elif opcode == "JALR":
            data = arithmetic(op, imm_12)
            pass
        elif opcode == "AUIPC":
            data = u_type(op, imm_20)
            pass
        elif opcode == "LUI":
            data = u_type(op, imm_20)
            pass
        # elif opcode == "SYSCALL":
            
        #     pass
        w += data + "\n"

#print(w)
#print(len(w) - 8)
#print(8 * 32 * 2 * loops)
file.write(w)
