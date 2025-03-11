module crypto_scalar_fu
  import crypto_instr_pkg::*;
#(
    parameter int unsigned NrRgprPorts = 2,
    parameter int unsigned XLEN = 64,
    parameter type hartid_t = logic,
    parameter type id_t = logic,
    parameter type registers_t = logic

) (
    input  logic                  clk_i,
    input  logic                  rst_ni,
    input  registers_t            registers_i,
    input  opcode_t               opcode_i,
    input  hartid_t               hartid_i,
    input  id_t                   id_i,
    input  logic       [     4:0] rd_i,
    input  logic       [    31:0] instr_i,
    output logic       [XLEN-1:0] result_o,
    output hartid_t               hartid_o,
    output id_t                   id_o,
    output logic       [     4:0] rd_o,
    output logic                  valid_o,
    output logic                  we_o
);

  logic [XLEN-1:0] result_n, result_q;
  hartid_t hartid_n, hartid_q;
  id_t id_n, id_q;
  logic valid_n, valid_q;
  logic [4:0] rd_n, rd_q;
  logic we_n, we_q;

  assign result_o = result_q;
  assign hartid_o = hartid_q;
  assign id_o     = id_q;
  assign valid_o  = valid_q;
  assign rd_o     = rd_q;
  assign we_o     = we_q;

  ///////////////////////////////////////////// AES32 ///////////////////////////////////////
  logic [XLEN-1:0]  aes32_result_o;
  generate 
    if (XLEN==32 && crypto_instr_pkg::MAES == 1) begin: M_AES32
      crypto_aes32 co_crypto_aes32(
        .aes32_op_i(instr_i[27:25]),
        .aes32_bs_i(instr_i[31:30]),
        .aes32_rs1_i(registers_i[0]),
        .aes32_rs2_i(registers_i[1]),
        .aes32_result_o(aes32_result_o)
      );
    end
  endgenerate
  ///////////////////////////////////////////// AES64 ///////////////////////////////////////
  logic [XLEN-1:0]  aes64_result_o;
  aes64_t aes64_op_i;
  logic aes64_en;
  generate 
    if (XLEN==64 && crypto_instr_pkg::MAES == 1) begin: M_AES64
      always_comb
      begin
        if (opcode_i==AES64_1) begin
          aes64_en = 1;
          if(instr_i[30]==1) begin
            aes64_op_i = aes64_ks2;
          end
          else begin
            if (instr_i[27:26]==2'b00) begin
              aes64_op_i = aes64_es;
            end
            else if (instr_i[27:26]==2'b01) begin
              aes64_op_i = aes64_esm;
            end
            else if (instr_i[27:26]==2'b10) begin
              aes64_op_i = aes64_ds;
            end
            else if (instr_i[27:26]==2'b11) begin
              aes64_op_i = aes64_dsm;
            end
          end
        end
        else if (opcode_i==AES64_2) begin
          aes64_en = 1;
          if(instr_i[24]==1) begin
            aes64_op_i = aes64_ks1i;
          end
          else if(instr_i[24]==0) begin
            aes64_op_i = aes64_im;
          end
        end
        else begin
          aes64_en = 0;
        end 
      end
      crypto_aes64 co_crypto_aes64(
      .aes64_en_i(aes64_en),
      .aes64_op_i(aes64_op_i),
      .aes64_rs1_i(registers_i[0]),
      .aes64_rs2_i(registers_i[1]),
      .aes64_rnum_i(instr_i[23:20]),
      .aes64_result_o(aes64_result_o)
      );
    end
  endgenerate
  ///////////////////////////////////////////// BREV8 ///////////////////////////////////////
  logic [XLEN-1:0]  brev8_result_o;
  generate 
    if (crypto_instr_pkg::METC == 1) begin: M_BREV8
      crypto_brev8 co_crypto_brev8(
          .brev8_rs1_i(registers_i[0]),
          .brev8_result_o(brev8_result_o)
      );
    end 
  endgenerate
  ///////////////////////////////////////////// PACK ///////////////////////////////////////
  logic [XLEN-1:0]  pack_result_o;
  logic [1:0]              pack_op_i;
  generate 
    if (crypto_instr_pkg::METC == 1) begin: M_PACK
      assign pack_op_i = {instr_i[13],instr_i[3]};

      crypto_pack co_crypto_pack(
        .pack_op_i(pack_op_i),
        .pack_rs1_i(registers_i[0]),
        .pack_rs2_i(registers_i[1]),
        .pack_result_o(pack_result_o)
      );
    end 
  endgenerate
  ///////////////////////////////////////////// SHA256 ///////////////////////////////////////
  logic [XLEN-1:0]  sha256_result_o;
  generate 
    if (crypto_instr_pkg::MSHA2 == 1) begin: M_SHA256
      crypto_sha256 co_crypto_sha256(
        .sha256_op_i(instr_i[21:20]),
        .sha256_rs1_i(registers_i[0]),
        .sha256_result_o(sha256_result_o)
      );
    end 
  endgenerate
  ///////////////////////////////////////////// SHA512 ///////////////////////////////////////
  logic [XLEN-1:0]  sha512_result_o;
  sha512_t sha512_op_i;
    generate
      if (XLEN ==64 && crypto_instr_pkg::MSHA2 == 1) begin
        always_comb
        begin
          if(instr_i[22:20]==6) begin
            sha512_op_i = sha512_SIG0;
          end
          else if(instr_i[22:20]==7) begin
            sha512_op_i = sha512_SIG1;
          end
          else if(instr_i[22:20]==4) begin
            sha512_op_i = sha512_SUM0;
          end
          else if(instr_i[22:20]==5) begin
            sha512_op_i = sha512_SUM1;
          end
        end
      end
      else if(crypto_instr_pkg::MSHA2 == 1) begin
        always_comb
        begin
          if(instr_i[27:25]==6) begin
            sha512_op_i = sha512_SIG0H;
          end
          else if (instr_i[27:25]==2) begin
            sha512_op_i = sha512_SIG0L;
          end
          else if (instr_i[27:25]==7) begin
            sha512_op_i = sha512_SIG1H;
          end
          else if (instr_i[27:25]==3) begin
            sha512_op_i = sha512_SIG1L;
          end
          else if (instr_i[27:25]==0) begin
            sha512_op_i = sha512_SUM0;
          end
          else if (instr_i[27:25]==1) begin
            sha512_op_i = sha512_SUM1;
          end
        end
    end
  endgenerate
  generate 
    if (crypto_instr_pkg::MSHA2 == 1) begin : M_SHA512
      crypto_sha512 co_crypto_sha512(
        .sha512_op_i(sha512_op_i),
        .sha512_rs1_i(registers_i[0]),
        .sha512_rs2_i(registers_i[1]),
        .sha512_result_o(sha512_result_o)
      );
    end
  endgenerate
  ///////////////////////////////////////////// SM3 ///////////////////////////////////////
  logic [XLEN-1:0]  sm3_result_o;
  generate 
    if (crypto_instr_pkg::MSM3 == 1) begin: M_SM3
      crypto_sm3 co_crypto_sm3(
        .sm3_op_i(instr_i[20]),
        .sm3_rs1_i(registers_i[0]),
        .sm3_result_o(sm3_result_o)
      );
    end
  endgenerate
  ///////////////////////////////////////////// SM4 ///////////////////////////////////////
  logic [XLEN-1:0]  sm4_result_o;
  generate 
    if (crypto_instr_pkg::MSM4 == 1) begin: M_SM4
      crypto_sm4 co_crypto_sm4(
        .sm4_op_i(instr_i[26]),
        .sm4_bs_i(instr_i[31:30]),
        .sm4_rs1_i(registers_i[0]),
        .sm4_rs2_i(registers_i[1]),
        .sm4_result_o(sm4_result_o)
      );
    end
  endgenerate
  ///////////////////////////////////////////// XPERM ///////////////////////////////////////
  logic [XLEN-1:0]  xperm_result_o;
  generate 
    if (crypto_instr_pkg::METC == 1) begin: M_XPERM
      crypto_xperm co_crypto_xperm(
        .xperm_op_i(instr_i[14]),
        .xperm_rs1_i(registers_i[0]),
        .xperm_rs2_i(registers_i[1]),
        .xperm_result_o(xperm_result_o)
      );
    end
  endgenerate
  ///////////////////////////////////////////// ZIP ///////////////////////////////////////
  logic [31:0]  zip_result_o;
  generate 
    if (XLEN==32 && crypto_instr_pkg::METC == 1) begin: M_ZIP
    crypto_zip co_crypto_zip(
      .zip_op_i(instr_i[14]),
      .zip_rs1_i(registers_i[0]),
      .zip_result_o(zip_result_o)
    );
    end
  endgenerate

  //////////////////////////////////////////////////////////////////////////////////////
  always_comb begin
    case (opcode_i)
        AES64_1, AES64_2: begin
            result_n = aes64_result_o;
            hartid_n = hartid_i;
            id_n     = id_i;
            valid_n  = 1'b1;
            rd_n     = rd_i;
            we_n     = 1'b1;
        end
        AES32: begin
            result_n = aes32_result_o;
            hartid_n = hartid_i;
            id_n     = id_i;
            valid_n  = 1'b1;
            rd_n     = rd_i;
            we_n     = 1'b1;
        end
        BREV8: begin
            result_n = brev8_result_o;
            hartid_n = hartid_i;
            id_n     = id_i;
            valid_n  = 1'b1;
            rd_n     = rd_i;
            we_n     = 1'b1;
        end
        PACK: begin
            result_n = pack_result_o;
            hartid_n = hartid_i;
            id_n     = id_i;
            valid_n  = 1'b1;
            rd_n     = rd_i;
            we_n     = 1'b1;
        end
        SHA256: begin
            result_n = sha256_result_o;
            hartid_n = hartid_i;
            id_n     = id_i;
            valid_n  = 1'b1;
            rd_n     = rd_i;
            we_n     = 1'b1;
        end
        SHA512: begin
            result_n = sha512_result_o;
            hartid_n = hartid_i;
            id_n     = id_i;
            valid_n  = 1'b1;
            rd_n     = rd_i;
            we_n     = 1'b1;
        end
        SM3: begin
            result_n = sm3_result_o;
            hartid_n = hartid_i;
            id_n     = id_i;
            valid_n  = 1'b1;
            rd_n     = rd_i;
            we_n     = 1'b1;
        end
        SM4: begin
            result_n = sm4_result_o;
            hartid_n = hartid_i;
            id_n     = id_i;
            valid_n  = 1'b1;
            rd_n     = rd_i;
            we_n     = 1'b1;
        end
        XPERM: begin
            result_n = xperm_result_o;
            hartid_n = hartid_i;
            id_n     = id_i;
            valid_n  = 1'b1;
            rd_n     = rd_i;
            we_n     = 1'b1;
        end
        ZIP: begin
            result_n = zip_result_o;
            hartid_n = hartid_i;
            id_n     = id_i;
            valid_n  = 1'b1;
            rd_n     = rd_i;
            we_n     = 1'b1;
        end
        default: begin
            result_n = '0;
            hartid_n = '0;
            id_n     = '0;
            valid_n  = '0;
            rd_n     = '0;
            we_n     = '0;
        end
    endcase
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni) begin
      result_q <= '0;
      hartid_q <= '0;
      id_q     <= '0;
      valid_q  <= '0;
      rd_q     <= '0;
      we_q     <= '0;
    end else begin
      result_q <= result_n;
      hartid_q <= hartid_n;
      id_q     <= id_n;
      valid_q  <= valid_n;
      rd_q     <= rd_n;
      we_q     <= we_n;
    end
  end

endmodule