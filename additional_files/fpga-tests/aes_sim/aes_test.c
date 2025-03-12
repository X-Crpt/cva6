/****************************************************************************************
# Simple custom test:       test.c
# Author:                   Alessandra Dolmeta
# Description: 
#                           AES-CBC taken fro: https://github.com/halloweeks/AES-128-CBC
/****************************************************************************************/


#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "AES_128_CBC.h"
#include "trigger_auto.h"
#include "uart.h"
#include "aes_asm.h"


void print_ciphertext(const unsigned char ciphertext[AES_BLOCK_SIZE]) {
    print_uart("Ciphertext: ");

    for (int i = 0; i < AES_BLOCK_SIZE; i++) {
        print_uart_byte(ciphertext[i]);
    }
    
    print_uart("\n");
}

//**********************MAIN******************************************/
int main() {

    uint8_t iv[AES_BLOCK_SIZE] = {0};       // Initialization vector (seed for AES CBC)
    uint8_t key[AES_BLOCK_SIZE] = {         // Initialize AES CBC key (128 bit / 16 bytes fixed)
        0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
        0xab, 0xf7, 0x97, 0x99, 0x89, 0xcf, 0xab, 0x12
    };
    uint8_t ciphertext[AES_BLOCK_SIZE];     // Cipertext to be saved between on execution and another
    uint8_t plaintext[32] = {0};            //Plaintext is always zero
    //uint8_t seed_input[AES_BLOCK_SIZE] = {0};
    AES_CTX ctx;
    uint8_t key_dev[16] = {0x00, 0xff, 0x00, 0xff, 0x11, 0xee, 0x22, 0xdd, 0x33, 0xcc, 0x44, 0xbb, 0x55, 0xaa, 0x66, 0x99};


    uint32_t volatile * trigger = (uint32_t*)TRIGGER_CTRL;


    // De-activate trigger_GPIO
    *trigger = 1 << TRIGGER_CTRL_STOP;

    //Initialization UART
    uint32_t freq, baud;  //TO BE SET
    freq = 50000000;    //50 MHz
    baud = 115200;      //115200 bps
    init_uart(freq, baud);

    // Read seed input from UART
    //read_seed_input_from_uart(seed_input, AES_BLOCK_SIZE);
    uint8_t seed_input[AES_BLOCK_SIZE] = {
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
        0x08, 0x09, 0x0A,0x0B, 0x0C, 0x0D, 0x0E, 0x0F
    };
    memcpy(iv, seed_input, AES_BLOCK_SIZE);

    AES_EncryptInit(&ctx, key, iv);
    KeyExpansion_ENC(RoundKey, key_dev);


    uint32_t num_traces = 3;

    for (uint32_t i = 0; i < num_traces; i++) {
        
        AES_Encrypt(&ctx, plaintext, ciphertext); 
        //print_ciphertext(ciphertext);

        asm volatile ("": : : "memory");
        *trigger = 1 << TRIGGER_CTRL_START; //Putting high the trigger
        asm volatile ("": : : "memory");

        AES_Cipher((uint32_t*)ciphertext, RoundKey);

        asm volatile ("": : : "memory");
        *trigger = 1 << TRIGGER_CTRL_STOP;
        asm volatile ("": : : "memory");

    }

    return 0;
}





