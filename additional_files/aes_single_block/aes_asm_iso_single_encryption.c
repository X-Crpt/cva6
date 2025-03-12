/****************************************************************************************
# Simple custom test:       aes_asm_single_encryption_masked.c
# Author:                   Alessandra Dolmeta
# Description: 
/****************************************************************************************/


#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "aes_asm_iso.h"
#include "trigger_auto.h"
#include "uart.h"

void cv_xif_prng_init(uint32_t* a, uint32_t* b)
{
    asm volatile (
        "lw a1, %[input_a]\n"               //a0: x10
        "lw a0, %[input_b]\n"               //a1: x11
        ".insn r 0x7B, 1, 5, x0, a0, a1\n"  
        :     
        : [input_a] "m" (*a), [input_b] "m" (*b) // Input operands
        : 
    );
}

int main(int argc, char* arg[])
{

    uint8_t  key [16] = {0x2b ,0x7e ,0x15 ,0x16 ,0x28 ,0xae ,0xd2 ,0xa6 ,0xab ,0xf7 ,0x15 ,0x88 ,0x09 ,0xcf ,0x4f ,0x3c};
    //uint8_t  key [16] = {0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00};
    uint8_t  pt  [16] = {0x32 ,0x43 ,0xf6 ,0xa8 ,0x88 ,0x5a ,0x30 ,0x8d ,0x31 ,0x31 ,0x98 ,0xa2 ,0xe0 ,0x37 ,0x07 ,0x34};
    
    uint32_t volatile * trigger = (uint32_t*)TRIGGER_CTRL;

    //uint32_t rs1_fixed = 0xDEADBEEF;
    //uint32_t rs2_fixed = 0xDEADBEEF;
    uint32_t rs1_fixed = 0x00000000;
    uint32_t rs2_fixed = 0x00000000;
    
    *trigger = 1 << TRIGGER_CTRL_START;
 
    //cv_xif_prng_init(&rs1_fixed, &rs2_fixed);
    //AES_ENC_masked(pt, key);
    AES_ENC(pt, key);

    //asm volatile (".insn r 0x7B, 1, 7, x0, x0, x0\n" : : : );

    *trigger = 1 << TRIGGER_CTRL_STOP;

    return 0;
}
