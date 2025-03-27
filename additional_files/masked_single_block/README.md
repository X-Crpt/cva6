# Masked_single_block


- **aes64-fix-r-zero-r**:
    - fixed randomness in input to the prng: `uint64_t rs1_fixed = 0x1234567812345678; uint64_t rs2_fixed = 0x1234567812345678;`
    - prng (dummy lfsr) not enable in the middle of execution; 
    - fized randomness inside the sbox: `all zero;`

- **aes64-rand-r-zero-r**:
    - fixed randomness in input to the prng: `uint64_t rs1_fixed = 0x1234567812345678; uint64_t rs2_fixed = 0x1234567812345678;`
    - prng (dummy lfsr) not enable in the middle of execution; 
    - fized randomness inside the sbox: `all zero;`