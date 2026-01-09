void AES_Cipher(uint32_t* state,   uint32_t* RoundKey)
{
    uint64_t a5,a6,t0,t1,t2,t3,a7,t5;
    // %0 is t2, %1 is t3, %2 is t0, %3 is t1
    // %4 is a5, %5 is a6, %7 is a7, %8 is t5 
   
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