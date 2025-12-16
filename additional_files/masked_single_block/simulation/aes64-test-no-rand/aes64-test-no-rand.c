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
#include "aes_dom.h"
#include "AES_128_CBC.h"

#define AES_BLOCK_SIZE 16

static void print_hex32(uint32_t x)
{
    // Print as 8 hex chars, big-endian style on screen.
    // Adjust if you already have a printf-like UART function.
    char buf[11];
    const char *hex = "0123456789ABCDEF";
    buf[0] = '0'; buf[1] = 'x';
    for (int i = 0; i < 8; i++) {
        buf[2 + i] = hex[(x >> (28 - 4*i)) & 0xF];
    }
    buf[10] = '\0';
    print_uart(buf);
}

static void print_aes_ctx(const char *tag, const AES_CTX *ctx)
{
    print_uart("\n====================\n");
    print_uart("AES_CTX: ");
    print_uart(tag);
    print_uart("\n");

    // IV (words)
    print_uart("IV words:\n");
    for (int i = 0; i < 4; i++) {
        print_uart("  iv");
        print_hex32((uint32_t)ctx->iv[i]);
        print_uart("\n");
    }

    // Roundkeys (words)
    print_uart("RoundKey words (44):\n");
    for (int i = 0; i < 44; i++) {
        print_uart("  rk");
        print_hex32((uint32_t)ctx->roundkey[i]);
        print_uart("\n");
    }

    print_uart("====================\n");
}

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

static uint32_t xorshift32_2(void)
{
    // You can pick any nonzero initial seed.
    static uint32_t state = 0x87654321u;
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


static uint64_t getRandom64_2(void)
{
    uint64_t high = (uint64_t)xorshift32_2();
    uint64_t low  = (uint64_t)xorshift32_2();
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
    
    uint8_t ciphertext[16];     // Cipertext to be saved between on execution and another
    uint8_t plaintext[32] = {0}; 
    uint8_t ciphertext_fixed[16] = {
        0x3C, 0x4F, 0x12, 0xA7,
        0xD1, 0xB2, 0x09, 0xFF,
        0x45, 0x63, 0x1E, 0x8C,
        0xAA, 0x90, 0x33, 0x76
    };

    uint8_t fixed[16] = {
        0x3C, 0x4F, 0x12, 0xA7,
        0xD1, 0xB2, 0x09, 0xFF,
        0x45, 0x63, 0x1E, 0x8C,
        0xAA, 0x90, 0x33, 0x76
    };  

    uint8_t seed_prng[8] = {0};
    uint8_t iv[16] = {0};
    AES_CTX ctx;
    uint32_t volatile * trigger = (uint32_t*)TRIGGER_CTRL;

    uint8_t seed_input[AES_BLOCK_SIZE*2] = {
        0x0f, 0x47, 0x0e, 0x7f, 0x75, 0x9c, 0x47, 0x0f,
        0x42, 0xc6, 0xd3, 0x9c, 0xbc, 0x8e, 0x23, 0x25
    };
    memcpy(iv, seed_input, AES_BLOCK_SIZE);
    memcpy(seed_prng, seed_input, 8);
    
    AES_EncryptInit(&ctx, key, iv);

    //uint64_t rs1_randomness_seed;
    //uint64_t rs2_randomness_seed;
    //rs1_randomness_seed = seed_prng;
    //rs2_randomness_seed = getRandom64();
    //asm volatile (".insn r 0x7B, 1, 5, x0, %[input_a], %[input_b]\n" : : [input_a] "r" (rs1_randomness_seed), [input_b] "r" (rs2_randomness_seed) :  );

    //print_aes_ctx("Before AES_EncryptInit", &ctx);
    print_uart_block(plaintext, AES_BLOCK_SIZE);
    AES_Encrypt(&ctx, plaintext, ciphertext);
    //print_aes_ctx("Before AES_EncryptInit", &ctx);
    print_uart("First ciphertext: ");
    print_uart_block(ciphertext, AES_BLOCK_SIZE);
    AES_ENC_masked_dom((uint32_t*)ciphertext, key);
    print_uart("Output AES-1 ciphertext: ");
    print_uart_block(ciphertext, AES_BLOCK_SIZE);

    //print_aes_ctx("Before AES_EncryptInit", &ctx);
    memcpy(plaintext, ciphertext, 16);
    print_uart_block(plaintext, AES_BLOCK_SIZE);
    AES_Encrypt(&ctx, plaintext, ciphertext);
    //print_aes_ctx("Before AES_EncryptInit", &ctx); 
    print_uart("Second ciphertext: ");
    print_uart_block(ciphertext, AES_BLOCK_SIZE);
    AES_ENC_masked_dom((uint32_t*)ciphertext, key);
    print_uart("Output AES-2 ciphertext: ");
    print_uart_block(ciphertext, AES_BLOCK_SIZE);

    //print_aes_ctx("Before AES_EncryptInit", &ctx);
    //memcpy(plaintext, ciphertext, 16);
    //AES_Encrypt(&ctx, plaintext, ciphertext);
    //print_aes_ctx("Before AES_EncryptInit", &ctx);
    //print_uart("Third ciphertext: ");
    //print_uart_block(ciphertext, AES_BLOCK_SIZE);
    //AES_ENC_masked_dom((uint32_t*)ciphertext, key);
    //print_uart("Output AES-3 ciphertext: ");
    //print_uart_block(ciphertext, AES_BLOCK_SIZE);
    

    print_uart("FIXED-TESTS!\n");
    print_uart("Input AES-FIXED ciphertext: ");
    print_uart_block(ciphertext_fixed, AES_BLOCK_SIZE);
    AES_ENC_masked_dom((uint32_t*)ciphertext_fixed, key);
    print_uart("Output AES-FIXED ciphertext: ");
    print_uart_block(ciphertext_fixed, AES_BLOCK_SIZE);

    memcpy(ciphertext_fixed, fixed, 16);
    print_uart("Input AES-FIXED ciphertext: ");
    print_uart_block(ciphertext_fixed, AES_BLOCK_SIZE);
    AES_ENC_masked_dom((uint32_t*)ciphertext_fixed, key);
    print_uart("Output AES-FIXED ciphertext: ");
    print_uart_block(ciphertext_fixed, AES_BLOCK_SIZE);

    //memcpy(ciphertext_fixed, fixed, 16);
    //print_uart("Input AES-FIXED ciphertext: ");
    //print_uart_block(ciphertext_fixed, AES_BLOCK_SIZE);
    //AES_ENC_masked_dom((uint32_t*)ciphertext_fixed, key);
    //print_uart("Output AES-FIXED ciphertext: ");
    //print_uart_block(ciphertext_fixed, AES_BLOCK_SIZE);
    

    return 0;
}
