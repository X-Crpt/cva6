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
#include <time.h>
#include "AES_128_CBC.h"


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

static uint32_t g_state32 = 0;   // 0 means "not seeded yet"

static void prng_seed64(uint64_t seed) {
    // Fold 64→32 and avoid zero state
    uint32_t s = (uint32_t)(seed ^ (seed >> 32)) | 1u;
    g_state32 = s;
}

static uint32_t xorshift32_step(void) {
    uint32_t x = g_state32;
    x ^= x << 13; x ^= x >> 17; x ^= x << 5;
    g_state32 = x ? x : 0x9E3779B9u;
    return x;
}

static uint64_t getRandom64(void) {
    uint64_t hi = xorshift32_step();
    uint64_t lo = xorshift32_step();
    return (hi << 32) | lo;
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

    uint8_t iv[16] = {0};       // Initialization vector (seed for AES CBC)
    uint8_t ciphertext[16];     // Cipertext to be saved between on execution and another
    uint8_t plaintext[32] = {0};            //Plaintext is always zero
    AES_CTX ctx;
    uint8_t seed_prng[8] = {0};

    uint8_t ciphertext_fixed[16] = {
        0x3C, 0x4F, 0x12, 0xA7,
        0xD1, 0xB2, 0x09, 0xFF,
        0x45, 0x63, 0x1E, 0x8C,
        0xAA, 0x90, 0x33, 0x76
    };

    uint8_t key_dev[16] = {0x00, 0xff, 0x00, 0xff, 0x11, 0xee, 0x22, 0xdd, 0x33, 0xcc, 0x44, 0xbb, 0x55, 0xaa, 0x66, 0x99};
    uint32_t volatile * trigger = (uint32_t*)TRIGGER_CTRL;



    //Initialization UART
    //uint32_t freq, baud;  //TO BE SET
    //freq = 50000000;    //50 MHz
    //baud = 115200;      //115200 bps
    //init_uart(freq, baud);

    // Read seed input from UART
    //read_seed_input_from_uart(seed_input, AES_BLOCK_SIZE);
    uint8_t seed_input[AES_BLOCK_SIZE] = {
        0x0f, 0x47, 0x0e, 0x7f, 0x75, 0x9c, 0x47, 0x0f,
        0x42, 0xc6, 0xd3, 0x9c, 0xbc, 0x8e, 0x23, 0x25
    };
    memcpy(iv, seed_input, AES_BLOCK_SIZE);
    memcpy(seed_prng, seed_input, 16);

    AES_EncryptInit(&ctx, key, iv);

    uint64_t base_seed = 0;
    memcpy(&base_seed, seed_prng, 8);
    prng_seed64(base_seed);   // call once before the loop

    uint32_t num_traces = 3;

    for (uint32_t i = 0; i < num_traces; i++) {
        
        AES_Encrypt(&ctx, plaintext, ciphertext); 
        int lsb_check = ciphertext[0] & 0x01; // Check the LSB of the last byte (most significant byte of the 128-bit value)
        uint64_t rs1_randomness_seed = base_seed;
        uint64_t rs2_randomness_seed = getRandom64();   // advances each time
        asm volatile(".insn r 0x7B, 1, 5, x0, %[a], %[b]\n" : : [a]"r"(rs1_randomness_seed), [b]"r"(rs2_randomness_seed));

        if (lsb_check) {
            asm volatile ("": : : "memory");
            *trigger = 1 << TRIGGER_CTRL_START; //Putting high the trigger
            asm volatile ("": : : "memory");

            //AES_ENC_masked_dom((uint32_t*)ciphertext, key);
            AES_ENC_masked_dom((uint32_t*)ciphertext, key);

            asm volatile ("": : : "memory");
            *trigger = 1 << TRIGGER_CTRL_STOP;
            asm volatile ("": : : "memory");
        } else {

            asm volatile ("": : : "memory");
            *trigger = 1 << TRIGGER_CTRL_START; //Putting high the trigger
            asm volatile ("": : : "memory");

            //AES_ENC_masked_dom((uint32_t*)ciphertext, key);
            AES_ENC_masked_dom((uint32_t*)ciphertext_fixed, key);

            asm volatile ("": : : "memory");
            *trigger = 1 << TRIGGER_CTRL_STOP;
            asm volatile ("": : : "memory");
        }
    
        asm volatile(".insn r 0x7B, 1, 7, x0, x0, x0\n");  // Prng-rst
    }

    return 0;
}
