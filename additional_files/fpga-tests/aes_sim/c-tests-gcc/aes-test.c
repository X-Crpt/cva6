/****************************************************************************************
# Simple custom test:       test.c
# Author:                   Alessandra Dolmeta
# Description: 
#                           AES-CBC taken from: https://github.com/halloweeks/AES-128-CBC
/****************************************************************************************/

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "AES_128_CBC.h"

#define OUTPUT_FILENAME "ciphertext_output.txt"

// Function to print ciphertext
void print_ciphertext(const uint8_t ciphertext[AES_BLOCK_SIZE]) {
    printf("Ciphertext: ");
    for (int i = 0; i < AES_BLOCK_SIZE; i++) {
        printf("%02X", ciphertext[i]);  // Print in hex format
    }
    printf("\n");
}

// Function to save ciphertext to a file
void save_ciphertext_to_file(const uint8_t ciphertext[AES_BLOCK_SIZE], FILE *file) {
    for (int i = 0; i < AES_BLOCK_SIZE; i++) {
        fprintf(file, "%02X", ciphertext[i]);  // Write hex values to file
    }
    fprintf(file, "\n");  // Newline for the next ciphertext
}

//********************** MAIN ******************************************/
int main() {

    uint8_t iv[AES_BLOCK_SIZE] = {0};       // Initialization vector (seed for AES CBC)
    uint8_t key[AES_BLOCK_SIZE] = {         // Initialize AES CBC key (128-bit / 16 bytes fixed)
        0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
        0xab, 0xf7, 0x97, 0x99, 0x89, 0xcf, 0xab, 0x12
    };
    uint8_t ciphertext[AES_BLOCK_SIZE];     // Ciphertext to be saved
    uint8_t plaintext[32] = {0};            // Plaintext is always zero
    AES_CTX ctx;

    uint8_t seed_input[AES_BLOCK_SIZE] = {
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
        0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F
    };
    memcpy(iv, seed_input, AES_BLOCK_SIZE);

    AES_EncryptInit(&ctx, key, iv);

    uint32_t num_traces = 100000;

    // Open file to save ciphertexts
    FILE *file = fopen(OUTPUT_FILENAME, "w");
    if (!file) {
        perror("Error opening file");
        return 1;
    }

    for (uint32_t i = 0; i < num_traces; i++) {
        AES_Encrypt(&ctx, plaintext, ciphertext);

        // Print ciphertext
        //print_ciphertext(ciphertext);

        // Save ciphertext to file
        save_ciphertext_to_file(ciphertext, file);
    }

    // Close file
    fclose(file);
    
    printf("Ciphertexts saved to %s\n", OUTPUT_FILENAME);
    
    return 0;
}
