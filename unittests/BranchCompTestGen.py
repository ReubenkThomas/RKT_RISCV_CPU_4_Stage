#!/usr/bin/python

# Description: 
#   Test generator for the BranchComp module for the RISC-V Processor
#
# Output:
#   Testvectors in binary format found in ./branchcomptestvectors.input
#
# Authors:
#   Matthew Dharmawan and Reuben Koshy Thomas

import random
import os
from functools import reduce

XOR = 0xffffffff

def bin_32(num):
    return binifier(list("{0:32b}".format(num)))

def vet(string):
    ret_str = ""
    for i in string:
        if i == " ":
            ret_str += '0'
        else:
            ret_str += i
    return ret_str

def two_comp(a, b):
    """
    Input: 2 integers, possibly negative
    Output: 32 bit representation of the number in a string format
    """
    # print(a, b)
    ret_a, ret_b = 0, 0
    if a >= 0:
        ret_a = vet("{0:32b}".format(a))
    else:
        pos_a = vet("{0:32b}".format(-a))
        neg_a = findTwoscomplement(pos_a)
        ret_a = neg_a
    if b >= 0:
        # print("bpositive")
        # print("{0:32b}".format(b))
        ret_b = vet("{0:32b}".format(b))
    else:
        # print("bnegaative")
        pos_b = vet("{0:32b}".format(-b))
        neg_b = findTwoscomplement(pos_b)
        ret_b = neg_b
    return ret_a, ret_b


def findTwoscomplement(strg):
    n = len(strg)
 
    # Traverse the string to get first
    # '1' from the last of string
    i = n - 1
    while(i >= 0):
        if (strg[i] == '1'):
            break
 
        i -= 1
 
    # If there exists no '1' concatenate 1
    # at the starting of string
    if (i == -1):
        return '1'+strg
 
    # Continue traversal after the
    # position of first '1'
    k = i - 1
    while(k >= 0):
         
        # Just flip the values
        if (strg[k] == '1'):
            strg = list(strg)
            strg[k] = '0'
            strg = ''.join(strg)
        else:
            strg = list(strg)
            strg[k] = '1'
            strg = ''.join(strg)
 
        k -= 1
 
    # return the modified string
    return strg


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
    return vet(ret_str)


OPCODE = "1100011"
f = lambda a, b: ("1" if a == b else "0", "1" if a < b else "0")
funct3 = \
    {
        "beq"  : "000",
        "bge"  : "101",
        "bgeu" : "111",
        "blt"  : "100",
        "bltu" : "110",
        "bne"  : "001",
    }

def gen_vector(f3, rs1, rs2, brun, breq, brlt):
    
    # Uncomment this if you want to see decimal outputs
    
    #print('Op: {0}, A: {1}, B: {2}, Out: {3}'.format(op, bin(A, 32), bin(B, 32), bin(REFout, 32)))
    # return ''
    return ''.join([f3, rs1, rs2, brun, breq, brlt])
    
SIGNED = "0"
UNSIGNED = "1"

loops = 1000
w = ""
file = open('branchcomptestvectors.input', 'w')
for i in range(loops):
    for op, f3 in funct3.items():
        Au = random.randint(0, 0xffffffff)
        Bu = random.randint(0, 0xffffffff)
        A = random.randint(-2**31, 2**31 - 1)
        B = random.randint(-2**31, 2**31 - 1)
        
        two_comp(A, B)
        if op == "beq":
            
            eq, lt = f(A, B)
            sA, sB = two_comp(A, B)
            data = gen_vector(f3, sA, sB, SIGNED, eq, lt)
            pass
        elif op == "bge":
            
            eq, lt = f(A, B)
            sA, sB = two_comp(A, B)
            
            data = gen_vector(f3, sA, sB, SIGNED, eq, lt)
            pass
        elif op == "bgeu":
            
            eq, lt = f(Au, Bu)
            sA, sB = two_comp(Au, Bu)
            data = gen_vector(f3, bin_32(Au), bin_32(Bu), UNSIGNED, eq, lt)
            pass
        elif op == "blt":
            # print(A, B)
            eq, lt = f(A, B)
            sA, sB = two_comp(A, B)
            # print(sA, sB)
            # print(len(sA), len(sB))
            data = gen_vector(f3, sA, sB, SIGNED, eq, lt)
            pass
        elif op == "bltu":
            
            eq, lt = f(Au, Bu)
            data = gen_vector(f3, bin_32(Au), bin_32(Bu), UNSIGNED, eq, lt)
            pass
        elif op == "bne":
            
            eq, lt = f(A, B)
            sA, sB = two_comp(A, B)
            data = gen_vector(f3, sA, sB, SIGNED, eq, lt)
            pass
        w += data + "\n"
        

file.write(w)
