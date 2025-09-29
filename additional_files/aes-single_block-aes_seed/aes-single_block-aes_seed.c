/****************************************************************************************
# Simple custom test:       aes_asm_single_encryption_masked.c
# Author:                   Alessandra Dolmeta
# Description: 
/****************************************************************************************/


#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "AES_128_CBC.h"
#include "aes_asm_iso.h"
#include "uart.h"

#define CSR_AES 0x7A1 // TDATA1 CSR address
#define AES_BLOCK_SIZE 16

void print_uart_block(uint8_t *block, size_t length) {
    for (size_t i = 0; i < length; i++) {
        print_uart_byte(block[i]);
    }
    write_serial('\n'); // Newline after block output
}

int main(int argc, char* arg[])
{

    uint8_t iv[AES_BLOCK_SIZE] = {{0}};       // Initialization vector (seed for AES CBC)
    uint8_t key[AES_BLOCK_SIZE] = {{         // Initialize AES CBC key (128 bit / 16 bytes fixed)
        0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
        0xab, 0xf7, 0x97, 0x99, 0x89, 0xcf, 0xab, 0x12
    }};
    uint8_t ciphertext[AES_BLOCK_SIZE];      // Ciphertext to be saved between executions
    uint8_t plaintext[32] = {{0}};           // Plaintext is always zero
    AES_CTX ctx;

    // NOTE: key_dev order matches your provided program (00 ff 00 ff 11 ee ...)
    uint8_t key_dev[16] = {{0x00, 0xff, 0x00, 0xff, 0x11, 0xee, 0x22, 0xdd,
                            0x33, 0xcc, 0x44, 0xbb, 0x55, 0xaa, 0x66, 0x99}};

    uint8_t seed_input[AES_BLOCK_SIZE] = {
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
    };
    memcpy(iv, seed_input, AES_BLOCK_SIZE);

    AES_EncryptInit(&ctx, key, iv);

    uint32_t num_traces = 5;

    // perform n encryptions of the input (all zeros)
    for (int i = 0; i < num_traces; i++) {{
        print_uart_block(plaintext, AES_BLOCK_SIZE);

        AES_Encrypt(&ctx, plaintext, ciphertext);

        print_uart_block(ciphertext, AES_BLOCK_SIZE);
        // start to monitor
        //__asm__ volatile("csrrwi x0, %0, 1" : : "i"(CSR_AES));
        //AES_ENC((uint32_t*)ciphertext, key);
        // end to monitor
        //__asm__ volatile("csrrwi x0, %0, 0" : : "i"(CSR_AES));

        //print_uart_block(ciphertext, AES_BLOCK_SIZE);

    }}

    return 0;
}
