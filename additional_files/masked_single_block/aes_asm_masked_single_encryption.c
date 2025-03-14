/****************************************************************************************
# Simple custom test:       aes_asm_single_encryption_masked.c
# Author:                   Alessandra Dolmeta
# Description: 
/****************************************************************************************/


#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "aes_asm_masked.h"
#include "trigger_auto.h"
#include "uart.h"

#define AES_BLOCK_SIZE 16

void cv_xif_prng_init(uint64_t* a, uint64_t* b)
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

void print_uart_block(uint8_t *block, size_t length) {
    for (size_t i = 0; i < length; i++) {
        print_uart_byte(block[i]);
    }
    write_serial('\n'); // Newline after block output
}

int main(int argc, char* arg[])
{

    uint8_t  key [16] = {0x2b ,0x7e ,0x15 ,0x16 ,0x28 ,0xae ,0xd2 ,0xa6 ,0xab ,0xf7 ,0x15 ,0x88 ,0x09 ,0xcf ,0x4f ,0x3c};
    //uint8_t  key [16] = {0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00 ,0x00};
    uint8_t  pt  [16] = {0x32 ,0x43 ,0xf6 ,0xa8 ,0x88 ,0x5a ,0x30 ,0x8d ,0x31 ,0x31 ,0x98 ,0xa2 ,0xe0 ,0x37 ,0x07 ,0x34};
    uint8_t  ct[16] = {0x39, 0x25, 0x84, 0x1D, 0x02, 0xDC, 0x09, 0xFB, 0xDC, 0x11, 0x85, 0x97, 0x19, 0x6A, 0x0B, 0x32};
    
    uint32_t volatile * trigger = (uint32_t*)TRIGGER_CTRL;

    uint64_t rs1_fixed = 0x1234567812345678;
    uint64_t rs2_fixed = 0x1234567812345678;
    
    //cv_xif_prng_init((uint64_t*)rs1_fixed, (uint64_t*)rs2_fixed);
    asm volatile (
        ".insn r 0x7B, 1, 5, x0, %[input_a], %[input_b]\n"  
        :     
        : [input_a] "r" (rs1_fixed), [input_b] "r" (rs2_fixed) // Input operands
        : 
    );

    *trigger = 1 << TRIGGER_CTRL_START;
 
    AES_ENC_masked((uint32_t*)pt, key);
    //AES_ENC((uint32_t*)pt, key);

    *trigger = 1 << TRIGGER_CTRL_STOP;

    print_uart_block(pt, AES_BLOCK_SIZE);
    print_uart_block(ct, AES_BLOCK_SIZE);

    return 0;
}
