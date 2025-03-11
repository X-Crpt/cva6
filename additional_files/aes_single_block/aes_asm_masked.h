#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

#define AES128 1
#define AES_BLOCKLEN 16 // Block length in bytes - AES is 128b block only
#define AES_KEYLEN 16   // Key length in bytes
#define AES_keyExpSize 44


uint32_t RoundKey[AES_keyExpSize];

void AES_ENC_masked(uint32_t* state,  uint8_t* Key);
void AES_Cipher(uint32_t* state,uint32_t* RoundKey);
void KeyExpansion_ENC(uint32_t* RoundKey,   uint8_t* Key);


#define MAX_COLUMNS 16

/*****************************************************************************/
/* Defines:                                                                  */
/*****************************************************************************/
// The number of columns comprising a state in AES. This is a  ant in AES. Value=4
#define Nb 4
#define Nk 4        // The number of 32 bit words in a key.
#define Nr 10       // The number of rounds in AES Cipher.


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
        
        ".insn r 0x7B, 1, 6, x0, x0, x0\n"   // Prng-enable
        ".insn r 0x7B, 1, 10, x0, x0, x0\n"
        ".insn r 0x7B, 1, 6, x0, x0, x0\n"   // Prng-enable
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
        //aes64-esm 1st share
        "aes64esm x0, x19, x0\n"
        "aes64esm x0, x20, x0\n"

        //aes64-esm 2nd share
        "aes64esm x0, x21, x14\n"
        "aes64esm x0, x22, x14\n"

        //Key Expansion 1 -----------------------
        "aes64ks1i x7, x15, 0\n"
        "aes64ks2  x0, x15, x16\n"
        "aes64ks2  x0, x16, x13\n"

        "aes64ks1i x9, x15, 0\n"
        "aes64ks2  x0, x15, x17\n"
        "aes64ks2  x0, x17, x18\n"

        // Add-Key RK1
        ".insn r 0x7B, 1, 11, x0, x19, x16\n"

        //---- ROUND 2 ---------------------------------------------------------------
        //aes64-esm 1st share
        "aes64esm x0, x0, x19\n"
        "aes64esm x0, x10, x19\n"

        //aes64-esm 2nd share
        "aes64esm x0, x14, x20\n"
        "aes64esm x0, x11, x20\n"

        //Key Expansion 2 -----------------------
        "aes64ks1i x7, x15, 1\n"
        "aes64ks2  x0, x15, x16\n"
        "aes64ks2  x0, x16, x13\n"

        "aes64ks1i x9, x15, 1\n"
        "aes64ks2  x0, x15, x17\n"
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

        "aes64ks1i x9, x15, 3\n"
        "aes64ks2  x0, x15, x17\n"
        "aes64ks2  x0, x17, x18\n"

        // Add-Key RK3
        ".insn r 0x7B, 1, 11, x0, x19, x16\n"       

        //---- ROUND 4 ---------------------------------------------------------------
        //aes64-esm 1st share
        "aes64esm x0, x0, x19\n"
        "aes64esm x0, x10, x19\n"

        //aes64-esm 2nd share
        "aes64esm x0, x14, x20\n"
        "aes64esm x0, x11, x20\n"

        //Key Expansion 4 -----------------------
        "aes64ks1i x7, x15, 4\n"
        "aes64ks2  x0, x15, x16\n"
        "aes64ks2  x0, x16, x13\n"

        "aes64ks1i x9, x15, 4\n"
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
        "aes64ks1i x7, x15, 5\n"
        "aes64ks2  x0, x15, x16\n"
        "aes64ks2  x0, x16, x13\n"

        "aes64ks1i x9, x15, 5\n"
        "aes64ks2  x0, x15, x17\n"
        "aes64ks2  x0, x17, x18\n"

        // Add-Key RK5
        ".insn r 0x7B, 1, 11, x0, x19, x16\n"  

        //---- ROUND 6 ---------------------------------------------------------------
        //aes64-esm 1st share
        "aes64esm x0, x0, x19\n"
        "aes64esm x0, x10, x19\n"

        //aes64-esm 2nd share
        "aes64esm x0, x14, x20\n"
        "aes64esm x0, x11, x20\n"

        //Key Expansion 6 -----------------------
        "aes64ks1i x7, x15, 6\n"
        "aes64ks2  x0, x15, x16\n"
        "aes64ks2  x0, x16, x13\n"

        "aes64ks1i x9, x15, 6\n"
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
        "aes64ks1i x7, x15, 7\n"
        "aes64ks2  x0, x15, x16\n"
        "aes64ks2  x0, x16, x13\n"

        "aes64ks1i x9, x15, 7\n"
        "aes64ks2  x0, x15, x17\n"
        "aes64ks2  x0, x17, x18\n"

        // Add-Key RK7
        ".insn r 0x7B, 1, 11, x0, x19, x16\n"  

        //---- ROUND 8 ---------------------------------------------------------------
        //aes64-esm 1st share
        "aes64esm x0, x0, x19\n"
        "aes64esm x0, x10, x19\n"

        //aes64-esm 2nd share
        "aes64esm x0, x14, x20\n"
        "aes64esm x0, x11, x20\n"

        //Key Expansion 8 -----------------------
        "aes64ks1i x7, x15, 8\n"
        "aes64ks2  x0, x15, x16\n"
        "aes64ks2  x0, x16, x13\n"

        "aes64ks1i x9, x15, 8\n"
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
        "aes64ks1i x7, x15, 9\n"
        "aes64ks2  x0, x15, x16\n"
        "aes64ks2  x0, x16, x13\n"

        "aes64ks1i x9, x15, 9\n"
        "aes64ks2  x0, x15, x17\n"
        "aes64ks2  x0, x17, x18\n"

        // Add-Key RK9
        ".insn r 0x7B, 1, 11, x0, x19, x16\n" 


        : [a2] "+r" (a2), [a3] "+r" (a3), [a4] "+r" (a4), [a5] "+r" (a5), [a6] "+r" (a6), [t0] "+r" (t0)
        : [key] "r" (Key), [state] "r" (state)
        : "memory"
    );
    
    //".insn r 0x7B, 1, 9, %[t5], x0, x0\n" 

}




// This function produces Nb(Nr+1) round keys. The round keys are used in each round to decrypt the states. 
void KeyExpansion_ENC(uint32_t* RoundKey,   uint8_t* Key)
{
    uint64_t a2,a3,t0;

    // %0	t0	Temporary register used to hold intermediate results during key expansion.
    // %1	a2	Holds the first 64 bits of the current round key during expansion.
    // %2	a3	Holds the second 64 bits of the current round key during expansion.
    // %3	RoundKey	Pointer to the output buffer where expanded round keys are stored.
    // %4	Key	Pointer to the input 128-bit AES key.

    asm volatile (

        "ld %1, 0(%4)\n"  //Use to load the initial 128bit key in two values
        "ld %2, 8(%4)\n"

        "sd %1, 0(%3)\n" //The initial key is stored in the RoundKey buffer 
        "sd %2, 8(%3)\n"
        //For each AES round (10 rounds in total for AES-128)
        "aes64ks1i %0, %2, 0\n"     // Generate the first part of the new key using aes64ks1i with a round constant
        "aes64ks2  %1, %0, %1\n"    // Generate the remaining parts of the new key using aes64ks2
        "aes64ks2  %2, %1, %2\n"

        "sd        %1, (0+16)(%3)\n" // Store the newly generated round key
        "sd        %2, (8+16)(%3)\n" // The offset increases by 16 bytes (128 bits) after each round
                                     // to ensure keys are stored sequentially in memory.
        "aes64ks1i %0, %2, 1\n"
        "aes64ks2  %1, %0, %1\n"
        "aes64ks2  %2, %1, %2\n"

        "sd        %1, (0+32)(%3)\n"
        "sd        %2, (8+32)(%3)\n"

        "aes64ks1i %0, %2, 2\n"
        "aes64ks2  %1, %0, %1\n"
        "aes64ks2  %2, %1, %2\n"

        "sd        %1, (0+48)(%3)\n"
        "sd        %2, (8+48)(%3)\n"

        "aes64ks1i %0, %2, 3\n"
        "aes64ks2  %1, %0, %1\n"
        "aes64ks2  %2, %1, %2\n"

        "sd        %1, (0+64)(%3)\n"
        "sd        %2, (8+64)(%3)\n"

        "aes64ks1i %0, %2, 4\n"
        "aes64ks2  %1, %0, %1\n"
        "aes64ks2  %2, %1, %2\n"

        "sd        %1, (0+80)(%3)\n"
        "sd        %2, (8+80)(%3)\n"

        "aes64ks1i %0, %2, 5\n"
        "aes64ks2  %1, %0, %1\n"
        "aes64ks2  %2, %1, %2\n"

        "sd        %1, (0+96)(%3)\n"
        "sd        %2, (8+96)(%3)\n"

        "aes64ks1i %0, %2, 6\n"
        "aes64ks2  %1, %0, %1\n"
        "aes64ks2  %2, %1, %2\n"

        "sd        %1, (0+112)(%3)\n"
        "sd        %2, (8+112)(%3)\n"

        "aes64ks1i %0, %2, 7\n"
        "aes64ks2  %1, %0, %1\n"
        "aes64ks2  %2, %1, %2\n"

        "sd        %1, (0+128)(%3)\n"
        "sd        %2, (8+128)(%3)\n"

        "aes64ks1i %0, %2, 8\n"
        "aes64ks2  %1, %0, %1\n"
        "aes64ks2  %2, %1, %2\n"

        "sd        %1, (0+144)(%3)\n"
        "sd        %2, (8+144)(%3)\n"

        "aes64ks1i %0, %2, 9\n"
        "aes64ks2  %1, %0, %1\n"
        "aes64ks2  %2, %1, %2\n"

        "sd        %1, (0+160)(%3)\n"
        "sd        %2, (8+160)(%3)\n"


        : "+r" (t0), "+r" (a2), "+r" (a3)
        : "r" (RoundKey), "r" (Key)
        : "memory"
    );

}


// Cipher is the main function that encrypts the PlainText.
void AES_Cipher(uint32_t* state,   uint32_t* RoundKey)
{
    uint64_t a5,a6,t0,t1,t2,t3,a7,t5;
    //%0 = t2       (register for intermediate operations)
    //%1 = t3       (register for intermediate operations)
    //%2 = t0       (register for intermediate operations)
    //%3 = t1       (register for intermediate operations)
    //%4 = a5       (first 64 bits of the AES state)
    //%5 = a6       (second 64 bits of the AES state)
    //%6 = a7       (temporary register for AES transformations)
    //%7 = t5       (temporary register for AES transformations)
    //%8 = RoundKey (pointer to the round keys)
    //%9 = state    (pointer to the AES state)
   
    asm volatile (
        // Load the state into a5 and a6
        "ld %4, 0(%9)\n" // Load first 64 bits of state into a5
        "ld %5, 8(%9)\n" // Load second 64 bits of state into a6

        // Load the next 128-bit round key
        "ld %0, (0+0)(%8)\n"  // Load first 64 bits of round key into t2
        "ld %1, (8+0)(%8)\n"  // Load second 64 bits of round key into t3
        "ld %2, (16+0)(%8)\n" // Load the third 64 bits of the round key into register t0 (%2)
        "ld %3, (24+0)(%8)\n" // Load the fourth 64 bits of the round key into register t1 (%3)
        
        // XOR state with round key (AddRoundKey)
        "xor %4, %4, %0\n"  // XOR state (a5) with round key (t2)
        "xor %5, %5, %1\n"  // XOR state (a6) with round key (t3)

        "aes64esm %6, %4, %5\n" // Perform AES round transformations
        "aes64esm %7, %5, %4\n"

        // XOR transformed state with the round key
        "xor %6, %6, %2\n"  // XOR result with next round key (t0)
        "xor %7, %7, %3\n"  // XOR result with next round key (t1)

        "aes64esm %4, %6, %7\n" // Perform AES round transformations
        "aes64esm %5, %7, %6\n" 
        
        // These lines load the next 128-bit round key into the registers
        "ld %0, (0+32)(%8)\n"
        "ld %1, (8+32)(%8)\n"

        "ld %2, (16+32)(%8)\n"
        "ld %3, (24+32)(%8)\n"

        // XOR state with round key
        "xor %4, %4, %0\n" //XOR the processed state (%4 and %5) with the newly loaded round key (%0 and %1)
        "xor %5, %5, %1\n"

        "aes64esm %6, %4, %5\n"
        "aes64esm %7, %5, %4\n"

        "xor %6, %6, %2\n"
        "xor %7, %7, %3\n"

        "aes64esm %4, %6, %7\n"
        "aes64esm %5, %7, %6\n"

        // Load the next 128-bit round key
        "ld %0, (0+64)(%8)\n"
        "ld %1, (8+64)(%8)\n"

        "ld %2, (16+64)(%8)\n"
        "ld %3, (24+64)(%8)\n"

        "xor %4, %4, %0\n"
        "xor %5, %5, %1\n"

        "aes64esm %6, %4, %5\n"
        "aes64esm %7, %5, %4\n"

        "xor %6, %6, %2\n"
        "xor %7, %7, %3\n"

        "aes64esm %4, %6, %7\n"
        "aes64esm %5, %7, %6\n"

        // Load the next 128-bit round key
        "ld %0, (0+96)(%8)\n"
        "ld %1, (8+96)(%8)\n"

        "ld %2, (16+96)(%8)\n"
        "ld %3, (24+96)(%8)\n"

        "xor %4, %4, %0\n"
        "xor %5, %5, %1\n"

        "aes64esm %6, %4, %5\n"
        "aes64esm %7, %5, %4\n"

        "xor %6, %6, %2\n"
        "xor %7, %7, %3\n"

        "aes64esm %4, %6, %7\n"
        "aes64esm %5, %7, %6\n"

        // Load the next 128-bit round key
        "ld %0, (0+128)(%8)\n"
        "ld %1, (8+128)(%8)\n"

        "ld %2, (16+128)(%8)\n"
        "ld %3, (24+128)(%8)\n"

        "xor %4, %4, %0\n"
        "xor %5, %5, %1\n"

        "aes64esm %6, %4, %5\n"
        "aes64esm %7, %5, %4\n"

        "xor %6, %6, %2\n"
        "xor %7, %7, %3\n"

        "aes64es %4, %6, %7\n"
        "aes64es %5, %7, %6\n"

        // Load the final round key
        "ld %0, (32+128)(%8)\n"
        "ld %1, (40+128)(%8)\n"
        // XOR state with the final round key
        "xor %4, %4, %0\n"
        "xor %5, %5, %1\n"

        // Store the final encrypted state back to memory
        "sd        %4, (0)(%9)\n"
        "sd        %5, (8)(%9)\n"

        : "+r" (t2), "+r" (t3), "+r" (t0), "+r" (t1), "+r" (a5), "+r" (a6), "+r" (a7), "+r" (t5)
        : "r" (RoundKey),"r" (state)
        : "memory"
    );
}