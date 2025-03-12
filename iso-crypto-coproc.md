# Iso-crypto-coproc 

## Crypto Coprocessor with Dedicated Register File  
Extended the implementation to a cryptographic coprocessor that operates **exclusively with an external register file**, with all the intermediate results of AES-encryption indepedent of CVA6's RF.  

Added custom instructions to correctly manage data within the dedicated register file.

Modifications performed with respect to [crypto-coproc](https://github.com/X-Crpt/cva6/tree/crypto-coproc):
- added aes_asm_single_encryption_masked.c tests
- hardware file modified:
    - core/crypto/include/crypto_instr_pkg.sv: adding the new instructions needed: 
    - core/crypto/masked/crypto_scalar_fu.sv
    - core/crypto/masked/prng.sv
    - core/crypto/masked/rf.sv
- Flist.ariane
- core/Flist.cva6_gate
- core/Flist.cva6
- for the new instructions:
    - verif/env/corev-dv/custom/cvxif_custom_instr.sv
    - verif/env/corev-dv/custom/riscv_custom_instr_enum.sv
    - verif/env/corev-dv/custom/rv32x_instr.sv
    - verif/tests/custom/cv_xif/cvxif_macros.h