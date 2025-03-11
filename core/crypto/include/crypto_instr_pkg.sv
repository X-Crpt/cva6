///////////////////////////////////////////////////////////////////////
// File: crypto_instr_pkg.sv
// Date: 2024-10-28
// Author: Behnam Farnaghinejad <behnam.farnaghinejad@polito.it>
///////////////////////////////////////////////////////////////////////

package crypto_instr_pkg;
  
  localparam XLEN = riscv::XLEN;
  parameter bit MAES = 1;            // AES Algorithm
  parameter bit MSHA2 = 1;           // SHA2 Algorithm
  parameter bit MSM4  = 1;           // SM4 Algorithm
  parameter bit MSM3  = 1;           // SM3 Algorithm
  parameter bit METC = 0;            // Other useful instructions for Cryptography ( Bitmanip, Carry-less multiply, Crossbar permutation )
 
  typedef enum logic[3:0] {
    ILLEGAL = 4'b0000,
    AES32   = 4'b0001,
    AES64_1 = 4'b0010,
    AES64_2 = 4'b0011,
    BREV8   = 4'b0100,
    CLMUL   = 4'b0101,
    PACK    = 4'b0110,
    SHA256  = 4'b0111,
    SHA512  = 4'b1000,
    SM3     = 4'b1001,
    SM4     = 4'b1010,
    XPERM   = 4'b1011,
    ZIP     = 4'b1100
  } opcode_t;

  typedef enum {  
    aes64_ds, 
    aes64_dsm,
    aes64_es, 
    aes64_esm,
    aes64_ks2,
    aes64_im,
    aes64_ks1i
  } aes64_t;

  typedef enum { 
    sha512_SIG0H,   
    sha512_SIG0L, 
    sha512_SIG1H,   
    sha512_SIG1L,
    sha512_SUM0, //SUM0R in RV32
    sha512_SUM1, //SUM1R in RV32
    sha512_SIG0,
    sha512_SIG1
  } sha512_t;  

  typedef struct packed {
    logic accept;
    logic writeback;  // TODO depends on dualwrite
    logic [2:0] register_read;  // TODO Nr read ports
  } issue_resp_t;

  typedef struct packed {
    logic [31:0] instr;
    logic [31:0] mask;
    issue_resp_t resp;
    opcode_t     opcode;
  } copro_issue_resp_t;

  // 10 Types Possible instructions 
  parameter int unsigned NbInstr = 11;

  parameter copro_issue_resp_t CoproInstr[NbInstr] = '{
        '{        
          instr: 32'b00010_00_00000_00000_0_01_00000_0010011,  // SHA256 opcode - 4 Instructions
          mask:  32'b11111_11_11100_00000_1_11_00000_1111111,  
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b0, 1'b1}},
          opcode : SHA256
        },

        '{
          instr: 32'b01010_00_00000_00000_0_00_00000_0110011,  // SHA512-RS1/2 Operands opcode - 6 Instructions 
          mask:  32'b11110_11_00000_00000_1_11_00000_1111111,  
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b1, 1'b1}},
          opcode : SHA512
        },

        '{
          instr: 32'b00010_00_00100_00000_0_01_00000_0010011,  // SHA512-RS1 Operands opcode - 4 Instructions
          mask:  32'b11111_11_11100_00000_1_11_00000_1111111,  
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b0, 1'b1}},
          opcode : SHA512
        },

        '{
          instr: 32'b00010_00_01000_00000_0_01_00000_0010011,  // SM3 opcode - 2 Instructions
          mask:  32'b11111_11_11110_00000_1_11_00000_1111111,  
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b0, 1'b1}},
          opcode : SM3
        },

        '{
          instr: 32'b00101_00_00000_00000_0_00_00000_0110011,  // xperm opcode - 2 Instructions
          mask:  32'b11111_11_00000_00000_0_01_00000_1111111,  
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b1, 1'b1}},
          opcode : XPERM
        },

        '{
          instr: 32'b00110_00_00000_00000_0_00_00000_0110011,  // SM4 opcode - 2 Instructions
          mask:  32'b00111_01_00000_00000_1_11_00000_1111111,  
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b1, 1'b1}},
          opcode : SM4
        },

        '{
          instr: 32'b00100_00_00000_00000_0_00_00000_0110011,  // AES32 opcode - 4 Instructions 
          mask:  32'b00110_00_00000_00000_1_11_00000_1111111,  
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b1, 1'b1}},
          opcode : AES32
        },

        '{
          instr: 32'b00110_01_00000_00000_0_00_00000_0110011,  // AES64 opcode - 5 Instructions
          mask:  32'b10110_01_00000_00000_1_11_00000_1111111,  
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b1, 1'b1}},
          opcode : AES64_1
        },

        '{
          instr: 32'b00110_00_00000_00000_0_01_00000_0010011,  // AES64 opcode - 2 Instructions im-ks1i
          mask:  32'b11111_11_00000_00000_1_11_00000_1111111,  
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b0, 1'b1}},
          opcode : AES64_2
        },

        '{
          instr: 32'b00001_00_00000_00000_1_00_00000_0110011,  // PACK opcode - 3 Instructions 
          mask:  32'b11111_11_00000_00000_1_00_00000_1110111,  
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b1, 1'b1}},
          opcode : PACK
        },

        '{
          instr: 32'b01101_00_00111_00000_1_01_00000_0010011,  // brev8 opcode - 1 Instructions 
          mask:  32'b11111_11_11111_00000_1_11_00000_1111111,  
          resp : '{accept : 1'b1, writeback : 1'b1, register_read : {1'b0, 1'b0, 1'b1}},
          opcode : BREV8
        }

  };

endpackage
