/****************************************************************************************
# Simple custom test:       aes_asm_single_encryption_masked.c
# Author:                   Alessandra Dolmeta
# Description: 
/****************************************************************************************/


#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "util.h"
#include "aes_asm_masked.h"
#include "trigger_auto.h"
#include "uart.h"
#include <time.h>


#define AES_BLOCK_SIZE 16

void reverse_pt(uint32_t *pt) {
    uint32_t temp[4];  // Temporary buffer for the reversed values

    // Reverse word order AND byte order in each 32-bit word
    for (int i = 0; i < 4; i++) {
        uint32_t word = pt[3 - i];  // Reverse word order
        temp[i] = ((word & 0x000000FF) << 24) | 
                  ((word & 0x0000FF00) << 8)  | 
                  ((word & 0x00FF0000) >> 8)  | 
                  ((word & 0xFF000000) >> 24); // Reverse byte order
    }

    // Copy back the reversed data into pt
    memcpy(pt, temp, AES_BLOCK_SIZE);
}

static uint32_t xorshift32(void)
{
    // You can pick any nonzero initial seed.
    static uint32_t state = 0x12345678u;

    uint32_t x = state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    state = x;

    return x;
}

// Combine two 32-bit xorshift outputs into one 64-bit value.
static uint64_t getRandom64(void)
{
    uint64_t high = (uint64_t)xorshift32();
    uint64_t low  = (uint64_t)xorshift32();
    return (high << 32) | low;
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
    uint8_t  ct_ref[16] = {0x39, 0x25, 0x84, 0x1D, 0x02, 0xDC, 0x09, 0xFB, 0xDC, 0x11, 0x85, 0x97, 0x19, 0x6A, 0x0B, 0x32};
    uint8_t ct[16] = {};
    uint64_t start_cycles, end_cycles;
    uint64_t total_enc_cycles = 0;
    
    uint32_t volatile * trigger = (uint32_t*)TRIGGER_CTRL;

    uint64_t rs1_fixed = getRandom64();
    uint64_t rs2_fixed = getRandom64();
    asm volatile (".insn r 0x7B, 1, 5, x0, %[input_a], %[input_b]\n" : : [input_a] "r" (rs1_fixed), [input_b] "r" (rs2_fixed) :  );
    
    rs1_fixed = getRandom64();
    rs2_fixed = getRandom64();
    asm volatile (".insn r 0x7B, 1, 5, x0, %[input_a], %[input_b]\n" : : [input_a] "r" (rs1_fixed), [input_b] "r" (rs2_fixed) :  );


    *trigger = 1 << TRIGGER_CTRL_START;
    start_cycles = read_csr(mcycle);
    //AES_ENC_masked_dom((uint32_t*)pt, key);
    AES_ENC_masked_dom_more_rand((uint32_t*)pt, key);
    end_cycles = read_csr(mcycle);

    *trigger = 1 << TRIGGER_CTRL_STOP;
    //reverse_pt(pt);

    total_enc_cycles = (end_cycles - start_cycles);

    //print_uart_block((uint8_t *)&total_enc_cycles, sizeof(total_enc_cycles));
    print_uart_block(pt, AES_BLOCK_SIZE);
    print_uart_block(ct_ref, AES_BLOCK_SIZE);

    return 0;
}








