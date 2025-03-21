#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

#define AES128 1
#define AES_BLOCKLEN 16 // Block length in bytes - AES is 128b block only
#define AES_KEYLEN 16   // Key length in bytes
#define AES_keyExpSize 44


uint32_t RoundKey[AES_keyExpSize];

#define MAX_COLUMNS 16

/*****************************************************************************/
/* Defines:                                                                  */
/*****************************************************************************/
// The number of columns comprising a state in AES. This is a  ant in AES. Value=4
#define Nb 4
#define Nk 4        // The number of 32 bit words in a key.
#define Nr 10       // The number of rounds in AES Cipher.

void AES_ENC_masked_dom(uint32_t* state,  uint8_t* Key)
{
    uint64_t a2, a3, a4, a5, a6;
    uint64_t t0;
    //      
    //Key      (pointer to the key)
    //state    (pointer to the AES state)

    asm volatile (
        // Load the state into registers a5 and a6
        "ld x10, 0(%[state])\n"               // Load first 64 bits of state into a2
        "ld x11, 8(%[state])\n"               // Load second 64 bits of state into a3
        "ld x12, 0(%[key])\n"                 // Load first 64 bits of key into a4
        "ld x13, 8(%[key])\n"                 // Load second 64 bits of key into a5

        "li x14, 2\n"
        "li x15, 4\n"
        "li x16, 6\n"
        "li x17, 8\n"

        ".insn r 0x7B, 1, 8, x0, x10, x11\n" // Load the state into reg0-reg1
        ".insn r 0x7B, 1, 8, x6, x12, x13\n" // Load the key   into reg6-reg7
        
        //".insn r 0x7B, 1, 6, x0, x0, x0\n"   // Prng-enable
        ".insn r 0x7B, 1, 10, x0, x0, x0\n"
        //".insn r 0x7B, 1, 6, x0, x0, x0\n"   // Prng-enable
        ".insn r 0x7B, 1, 10, x0, x16, x16\n"

        "li x10, 1\n"
        "li x11, 3\n"
        "li x12, 5\n"
        "li x13, 7\n"  
        "li x18, 9\n" 
        "li x19, 10\n"
        "li x20, 11\n"
        "li x21, 12\n"  
        "li x22, 13\n"

        //---- Initial Round Key [key] ------------------------------------------------
        ".insn r 0x7B, 1, 11, x0, x0, x16\n"

        //---- ROUND 1 ---------------------------------------------------------------
        //Key Expansion 1 -----------------------
        "aes64ks1i x7, x15, 0\n"
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        "aes64ks2  x0, x15, x16\n"
        "aes64ks2  x0, x16, x13\n"
        //"aes64ks1i x9, x12, 0\n"
        //"aes64ks2  x0, x12, x17\n"
        //"aes64ks2  x0, x17, x18\n"


        : [a2] "+r" (a2), [a3] "+r" (a3), [a4] "+r" (a4), [a5] "+r" (a5), [a6] "+r" (a6), [t0] "+r" (t0)
        : [key] "r" (Key), [state] "r" (state)
        : "memory"
    );
    
    //".insn r 0x7B, 1, 9, %[t5], x0, x0\n" 

}



void AES_ENC_masked(uint32_t* state,  uint8_t* Key)
{
    uint64_t a2, a3, a4, a5, a6;
    uint64_t t0;
    //      
    //Key      (pointer to the key)
    //state    (pointer to the AES state)

    asm volatile (
        // Load the state into registers a5 and a6
        "ld x10, 0(%[state])\n"               // Load first 64 bits of state into a2
        "ld x11, 8(%[state])\n"               // Load second 64 bits of state into a3
        "ld x12, 0(%[key])\n"                 // Load first 64 bits of key into a4
        "ld x13, 8(%[key])\n"                 // Load second 64 bits of key into a5

        "li x14, 2\n"
        "li x15, 4\n"
        "li x16, 6\n"
        "li x17, 8\n"

        ".insn r 0x7B, 1, 8, x0, x10, x11\n" // Load the state into reg0-reg1
        ".insn r 0x7B, 1, 8, x6, x12, x13\n" // Load the key   into reg6-reg7
        
        //".insn r 0x7B, 1, 6, x0, x0, x0\n"   // Prng-enable
        ".insn r 0x7B, 1, 10, x0, x0, x0\n"
        //".insn r 0x7B, 1, 6, x0, x0, x0\n"   // Prng-enable
        ".insn r 0x7B, 1, 10, x0, x16, x16\n"

        "li x10, 1\n"
        "li x11, 3\n"
        "li x12, 5\n"
        "li x13, 7\n"  
        "li x18, 9\n" 
        "li x19, 10\n"
        "li x20, 11\n"
        "li x21, 12\n"  
        "li x22, 13\n"

        //---- Initial Round Key [key] ------------------------------------------------
        ".insn r 0x7B, 1, 11, x0, x0, x16\n"

        //---- ROUND 1 ---------------------------------------------------------------
        //Key Expansion 1 -----------------------
        "aes64ks1i x7, x15, 0\n"
        "aes64ks2  x0, x15, x16\n"
        "aes64ks2  x0, x16, x13\n"

        "aes64ks1i x9, x12, 0\n"
        "aes64ks2  x0, x12, x17\n"
        "aes64ks2  x0, x17, x18\n"

            
        //aes64-esm 1st share
        "aes64esm x0, x19, x0\n"
        "aes64esm x0, x20, x0\n"

        //aes64-esm 2nd share
        "aes64esm x0, x21, x14\n"
        "aes64esm x0, x22, x14\n"

        // Add-Key RK1
        ".insn r 0x7B, 1, 11, x0, x19, x16\n"

        //---- ROUND 2 ---------------------------------------------------------------
        //aes64-esm 1st share
        "aes64esm x0, x0, x19\n"
        "aes64esm x0, x10, x19\n"

        //aes64-esm 2nd share
        "aes64esm x0, x14, x21\n"
        "aes64esm x0, x11, x21\n"

        //Key Expansion 2 -----------------------
        "aes64ks1i x7, x15, 1\n"
        "aes64ks2  x0, x15, x16\n"
        "aes64ks2  x0, x16, x13\n"

        "aes64ks1i x9, x12, 1\n"
        "aes64ks2  x0, x12, x17\n"
        "aes64ks2  x0, x17, x18\n"

        // Add-Key RK2
        ".insn r 0x7B, 1, 11, x0, x0, x16\n"

        //---- ROUND 3 ---------------------------------------------------------------
        //aes64-esm 1st share
        "aes64esm x0, x19, x0\n"
        "aes64esm x0, x20, x0\n"

        //aes64-esm 2nd share
        "aes64esm x0, x21, x14\n"
        "aes64esm x0, x22, x14\n"

        //Key Expansion 3 -----------------------
        "aes64ks1i x7, x15, 2\n"
        "aes64ks2  x0, x15, x16\n"
        "aes64ks2  x0, x16, x13\n"

        "aes64ks1i x9, x12, 2\n"
        "aes64ks2  x0, x12, x17\n"
        "aes64ks2  x0, x17, x18\n"

        // Add-Key RK3
        ".insn r 0x7B, 1, 11, x0, x19, x16\n"       

        //---- ROUND 4 ---------------------------------------------------------------
        //aes64-esm 1st share
        "aes64esm x0, x0, x19\n"
        "aes64esm x0, x10, x19\n"

        //aes64-esm 2nd share
        "aes64esm x0, x14, x21\n"
        "aes64esm x0, x11, x21\n"

        //Key Expansion 4 -----------------------
        "aes64ks1i x7, x15, 3\n"
        "aes64ks2  x0, x15, x16\n"
        "aes64ks2  x0, x16, x13\n"

        "aes64ks1i x9, x15, 3\n"
        "aes64ks2  x0, x15, x17\n"
        "aes64ks2  x0, x17, x18\n"

        // Add-Key RK4
        ".insn r 0x7B, 1, 11, x0, x0, x16\n"

        //---- ROUND 5 ---------------------------------------------------------------
        //aes64-esm 1st share
        "aes64esm x0, x19, x0\n"
        "aes64esm x0, x20, x0\n"

        //aes64-esm 2nd share
        "aes64esm x0, x21, x14\n"
        "aes64esm x0, x22, x14\n"

        //Key Expansion 5 -----------------------
        "aes64ks1i x7, x15, 4\n"
        "aes64ks2  x0, x15, x16\n"
        "aes64ks2  x0, x16, x13\n"

        "aes64ks1i x9, x15, 4\n"
        "aes64ks2  x0, x15, x17\n"
        "aes64ks2  x0, x17, x18\n"

        // Add-Key RK5
        ".insn r 0x7B, 1, 11, x0, x19, x16\n"  

        //---- ROUND 6 ---------------------------------------------------------------
        //aes64-esm 1st share
        "aes64esm x0, x0, x19\n"
        "aes64esm x0, x10, x19\n"

        //aes64-esm 2nd share
        "aes64esm x0, x14, x21\n"
        "aes64esm x0, x11, x21\n"

        //Key Expansion 6 -----------------------
        "aes64ks1i x7, x15, 5\n"
        "aes64ks2  x0, x15, x16\n"
        "aes64ks2  x0, x16, x13\n"

        "aes64ks1i x9, x15, 5\n"
        "aes64ks2  x0, x15, x17\n"
        "aes64ks2  x0, x17, x18\n"

        // Add-Key RK6
        ".insn r 0x7B, 1, 11, x0, x0, x16\n"     
        
        //---- ROUND 7 ---------------------------------------------------------------
        //aes64-esm 1st share
        "aes64esm x0, x19, x0\n"
        "aes64esm x0, x20, x0\n"

        //aes64-esm 2nd share
        "aes64esm x0, x21, x14\n"
        "aes64esm x0, x22, x14\n"

        //Key Expansion 7 -----------------------
        "aes64ks1i x7, x15, 6\n"
        "aes64ks2  x0, x15, x16\n"
        "aes64ks2  x0, x16, x13\n"

        "aes64ks1i x9, x15, 6\n"
        "aes64ks2  x0, x15, x17\n"
        "aes64ks2  x0, x17, x18\n"

        // Add-Key RK7
        ".insn r 0x7B, 1, 11, x0, x19, x16\n"  

        //---- ROUND 8 ---------------------------------------------------------------
        //aes64-esm 1st share
        "aes64esm x0, x0, x19\n"
        "aes64esm x0, x10, x19\n"

        //aes64-esm 2nd share
        "aes64esm x0, x14, x21\n"
        "aes64esm x0, x11, x21\n"

        //Key Expansion 8 -----------------------
        "aes64ks1i x7, x15, 7\n"
        "aes64ks2  x0, x15, x16\n"
        "aes64ks2  x0, x16, x13\n"

        "aes64ks1i x9, x15, 7\n"
        "aes64ks2  x0, x15, x17\n"
        "aes64ks2  x0, x17, x18\n"

        // Add-Key RK8
        ".insn r 0x7B, 1, 11, x0, x0, x16\n"  

        //---- ROUND 9 ---------------------------------------------------------------
        //aes64-esm 1st share
        "aes64esm x0, x19, x0\n"
        "aes64esm x0, x20, x0\n"

        //aes64-esm 2nd share
        "aes64esm x0, x21, x14\n"
        "aes64esm x0, x22, x14\n"

        //Key Expansion 9 -----------------------
        "aes64ks1i x7, x15, 8\n"
        "aes64ks2  x0, x15, x16\n"
        "aes64ks2  x0, x16, x13\n"

        "aes64ks1i x9, x15, 8\n"
        "aes64ks2  x0, x15, x17\n"
        "aes64ks2  x0, x17, x18\n"

        // Add-Key RK9
        ".insn r 0x7B, 1, 11, x0, x19, x16\n" 

        //---- ROUND 10 ---------------------------------------------------------------
        //aes64-es 1st share
        "aes64es x0, x0, x19\n"
        "aes64es x0, x10, x19\n"

        //aes64-es 2nd share
        "aes64esm x0, x14, x21\n"
        "aes64esm x0, x11, x21\n"

        //Key Expansion 10 -----------------------
        "aes64ks1i x7, x15, 9\n"
        "aes64ks2  x0, x15, x16\n"
        "aes64ks2  x0, x16, x13\n"

        "aes64ks1i x9, x15, 7\n"
        "aes64ks2  x0, x15, x17\n"
        "aes64ks2  x0, x17, x18\n"

        // Add-Key RK10
        ".insn r 0x7B, 1, 11, x0, x0, x16\n"  

        //Store the final-state
        ".insn r 0x7B, 1, 9, x15, x0, x0\n"
        ".insn r 0x7B, 1, 9, x16, x10, x0\n"

        //store
        "sd x15, 0(%[state])\n"
        "sd x16, 8(%[state])\n"


        : [a2] "+r" (a2), [a3] "+r" (a3), [a4] "+r" (a4), [a5] "+r" (a5), [a6] "+r" (a6), [t0] "+r" (t0)
        : [key] "r" (Key), [state] "r" (state)
        : "memory"
    );
    
    //".insn r 0x7B, 1, 9, %[t5], x0, x0\n" 

}


