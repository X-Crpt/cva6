    .option push
    .option norvc
    .option norelax
    .text
    .align  2
    .globl  AES_ENC_masked_asm
    .type   AES_ENC_masked_asm, @function

# void AES_ENC_masked_asm(uint32_t* state, uint8_t* Key)
# a0 = state, a1 = Key
AES_ENC_masked_asm:
    ld x10, 0(a0)
    ld x11, 8(a0)
    ld x12, 0(a1)
    ld x13, 8(a1)

    li x14, 2
    li x15, 4
    li x16, 6
    li x17, 8

    .insn r 0x7B, 1, 8, x0, x10, x11
    .insn r 0x7B, 1, 8, x6, x12, x13
    .insn r 0x7B, 1, 10, x0, x0, x0
    .insn r 0x7B, 1, 10, x0, x16, x16

    li x10, 1
    li x11, 3
    li x12, 5
    li x13, 7
    li x18, 9
    li x19, 10
    li x20, 11
    li x21, 12
    li x22, 13

    .insn r 0x7B, 1, 11, x0, x0, x0

    # ---- ROUND 1 ----
    aes64ks1i x7, x15, 0
    nop; nop; nop; nop; nop
    aes64ks2  x0, x15, x16
    aes64ks2  x0, x16, x13
    aes64esm x0, x19, x0
    aes64esm x0, x20, x0
    nop; nop; nop; nop; nop
    .insn r 0x7B, 1, 11, x0, x19, x19

    # ---- ROUND 2 ----
    aes64ks1i x7, x15, 1
    nop; nop; nop; nop; nop
    aes64ks2  x0, x15, x16
    aes64ks2  x0, x16, x13
    aes64esm x0, x0, x19
    nop; nop; nop; nop; nop
    aes64esm x0, x10, x19
    nop; nop; nop; nop; nop
    .insn r 0x7B, 1, 11, x0, x0, x0

    # ---- ROUND 3 ----
    aes64ks1i x7, x15, 2
    nop; nop; nop; nop; nop
    aes64ks2  x0, x15, x16
    aes64ks2  x0, x16, x13
    aes64esm x0, x19, x0
    aes64esm x0, x20, x0
    nop; nop; nop; nop; nop
    .insn r 0x7B, 1, 11, x0, x19, x19

    # ---- ROUND 4 ----
    aes64ks1i x7, x15, 3
    nop; nop; nop; nop; nop
    aes64ks2  x0, x15, x16
    aes64ks2  x0, x16, x13
    aes64esm x0, x0, x19
    nop; nop; nop; nop; nop
    aes64esm x0, x10, x19
    nop; nop; nop; nop; nop
    .insn r 0x7B, 1, 11, x0, x0, x0

    # ---- ROUND 5 ----
    aes64ks1i x7, x15, 4
    nop; nop; nop; nop; nop
    aes64ks2  x0, x15, x16
    aes64ks2  x0, x16, x13
    aes64esm x0, x19, x0
    aes64esm x0, x20, x0
    nop; nop; nop; nop; nop
    .insn r 0x7B, 1, 11, x0, x19, x19

    # ---- ROUND 6 ----
    aes64ks1i x7, x15, 5
    nop; nop; nop; nop; nop
    aes64ks2  x0, x15, x16
    aes64ks2  x0, x16, x13
    aes64esm x0, x0, x19
    nop; nop; nop; nop; nop
    aes64esm x0, x10, x19
    nop; nop; nop; nop; nop
    .insn r 0x7B, 1, 11, x0, x0, x0

    # ---- ROUND 7 ----
    aes64ks1i x7, x15, 6
    nop; nop; nop; nop; nop
    aes64ks2  x0, x15, x16
    aes64ks2  x0, x16, x13
    aes64esm x0, x19, x0
    aes64esm x0, x20, x0
    nop; nop; nop; nop; nop
    .insn r 0x7B, 1, 11, x0, x19, x19

    # ---- ROUND 8 ----
    aes64ks1i x7, x15, 7
    nop; nop; nop; nop; nop
    aes64ks2  x0, x15, x16
    aes64ks2  x0, x16, x13
    aes64esm x0, x0, x19
    nop; nop; nop; nop; nop
    aes64esm x0, x10, x19
    nop; nop; nop; nop; nop
    .insn r 0x7B, 1, 11, x0, x0, x0

    # ---- ROUND 9 ----
    aes64ks1i x7, x15, 8
    nop; nop; nop; nop; nop
    aes64ks2  x0, x15, x16
    aes64ks2  x0, x16, x13
    aes64esm x0, x19, x0
    aes64esm x0, x20, x0
    nop; nop; nop; nop; nop
    .insn r 0x7B, 1, 11, x0, x19, x19

    # ---- ROUND 10 ----
    aes64ks1i x7, x15, 9
    nop; nop; nop; nop; nop
    aes64ks2  x0, x15, x16
    aes64ks2  x0, x16, x13
    aes64es x0, x0, x19
    nop; nop; nop; nop; nop
    aes64es x0, x10, x19
    nop; nop; nop; nop; nop
    .insn r 0x7B, 1, 11, x0, x0, x0

    .insn r 0x7B, 1, 12, x0, x0, x14

    .insn r 0x7B, 1, 9, x15, x0, x0
    .insn r 0x7B, 1, 9, x16, x10, x10
    sd x15, 0(a0)
    sd x16, 8(a0)

    ret
    .size AES_ENC_masked_asm, .-AES_ENC_masked_asm
    .option pop
