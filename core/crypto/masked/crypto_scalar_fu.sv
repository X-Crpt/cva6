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
    input  logic                  issue_ready_i,
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

  ///////////////////////////////////////////// PRNG ///////////////////////////////////////
  logic [127:0]  prng_result_o;
  logic [127:0]  seed, seed_reg;
  prng_t prng_op_i;
  logic prng_en, prng_rst, prng_seed;
  logic prng_active, prng_update;
  logic prng_rst_global;
  generate 
    if (XLEN==64 && crypto_instr_pkg::RANDOM == 1) begin: M_PRNG

    always_comb
      begin
        if (opcode_i==PRNG) begin
            if (instr_i[27:25]==3'b101) begin
              prng_op_i = prng64_seed;
              seed      = {registers_i[0], registers_i[1]};
              prng_en   = 0;
              prng_seed = 1'b1;
              prng_rst  = 0;
            end
            else if (instr_i[27:25]==3'b110) begin
              prng_op_i = prng64_enable;
              prng_en   = 1'b1;
              prng_seed = 0;
              prng_rst  = 0;
            end
            else if (instr_i[27:25]==3'b111) begin
              prng_op_i = prng64_rst;
              prng_en   = 0;
              prng_seed = 0;
              prng_rst  = 1'b1;
            end
        end
        else begin
          prng_en   = 0;
          prng_seed = 0;
          prng_rst  = 0;
          seed      = 0;
        end 
      end

      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          seed_reg    <= 128'b0;
          prng_active <= '0;
          prng_update <= '0;
        end else if (prng_seed && issue_ready_i) begin
          seed_reg    <= seed;
          prng_active <= 1'b1;
          prng_update <= '0;  
        end else if (prng_en) begin
          seed_reg    <= seed_reg;
          prng_active <= '0;
          prng_update <= 1'b1; 
        end else if (prng_rst) begin
          seed_reg    <= 128'b0;
          prng_active <= '0; 
          prng_update <= '0;
        end else begin
          seed_reg    <= seed_reg;
          prng_active <= '0; 
          prng_update <= '0;
        end
    end
      
      assign prng_rst_global = prng_rst || ~rst_ni;

      simple_prng co_simple_prng (
        .clk(clk_i),                                // Clock input
        .rst(prng_rst_global),                      // Reset input (active high)
        .init_i(prng_active),                       // Set seed
        .en_i(prng_en),                             // Enable input
        .seed_i(seed_reg),                          // 128-bit seed
        .prng_o(prng_result_o)                      // 64-bit pseudo-random output
      );
    end
  endgenerate
  //////////////////////////////////////////////////////////////////////////////////////////
  
  
  //////////////////////////////////////////////////////////////////////////////////////////
  logic [XLEN-1:0]  store_result_o;
  logic [127:0]     xor_r_result_o;
  logic [XLEN-1:0]  input_RF_0, input_RF_1, input_RF_2;
  logic [XLEN-1:0]  address_RF;
  logic             write_en, read_en;
  logic             random;
  logic             add_round_key;
  logic             aes_round;
  logic             aes_key_exp;

  logic [63:0]      aes_comb_out0, aes_comb_out1;
  
  logic [4:0]       xor_temp1, xor_temp2, xor_temp3; 

  generate 
    if (XLEN==64 && crypto_instr_pkg::MASKED == 1) begin: M_RF
      always_comb
      begin
        if (opcode_i == LOAD) begin
          input_RF_0    = registers_i[0];
          input_RF_1    = registers_i[1];
          input_RF_2    = 0;
          address_RF    = rd_i;
          write_en      = 1'b1;
          read_en       = 0;
          random        = 0;
          add_round_key = 0;
          aes_key_exp   = 0;
          aes_round     = 0;
        end else if (opcode_i == STORE) begin
          address_RF    = registers_i[0];
          write_en      = 0;
          read_en       = 1'b1;
          random        = 0;
          add_round_key = 0;
          aes_key_exp   = 0;
          aes_round     = 0;
        end else if (opcode_i==XOR_R) begin
          address_RF    = registers_i[0][4:0];
          input_RF_0    = {59'b0, registers_i[1][4:0]};
          input_RF_1    = prng_result_o[63:0];
          input_RF_2    = prng_result_o[123:64];
          random        = 1'b1;
          write_en      = 1'b1;
          add_round_key = 0;
          aes_key_exp   = 0;
          aes_round     = 0;
        end else if (opcode_i==ADD_RK) begin
          address_RF    = '0;
          input_RF_0    = registers_i[0];  //pt
          input_RF_1    = registers_i[1];  //key
          input_RF_2    = '0;
          random        = 1'b0;
          write_en      = 1'b1;
          add_round_key = 1'b1;
          aes_key_exp   = 0;
          aes_round     = 0;
        end else if (opcode_i==AES64_1) begin

          if(instr_i[30]==1) begin //aes64ks2
            address_RF    = '0;
            input_RF_0    = registers_i[0]; 
            input_RF_1    = registers_i[1];  
            input_RF_2    = aes64_result_o;
            random        = 1'b0;
            write_en      = 1'b1;
            add_round_key = 1'b0;
            aes_round     = 1'b0;
            aes_key_exp   = 1'b1;
            read_en       = 1'b1;           
          end
          else begin
            if (instr_i[27:26]==2'b01 || instr_i[27:26]==2'b00) begin  //aes64esm or aes64es
              address_RF    = '0;
              input_RF_0    = registers_i[0];  
              input_RF_1    = registers_i[1];  
              input_RF_2    = aes64_result_o;
              random        = 1'b0;
              write_en      = 1'b1;
              add_round_key = 1'b0;
              aes_round     = 1'b1;
              aes_key_exp   = 0;
              read_en       = 1'b1;
            end
          end

        end else if (opcode_i==AES64_2) begin
          address_RF    = '0;
          input_RF_0    = {59'b0, rd_i};  
          input_RF_1    = registers_i[0];  
          input_RF_2    = aes64_result_o;
          random        = 1'b0;
          write_en      = 1'b1;
          add_round_key = 1'b0;
          aes_round     = 1'b0;
          aes_key_exp   = 1'b1;
          read_en       = 1'b1;
        end else begin
          write_en      = 0;
          read_en       = 0;
          random        = 0;
          add_round_key = 0;
          aes_round     = 0;
          aes_key_exp   = 0;
        end
      end
    end

    rf rf_i (
    .clk_i           (clk_i),
    .rst_ni          (rst_ni),
    .addr_i          (address_RF[3:0]), // Address for read/write
    .input0_i        (input_RF_0), // Input data 0
    .input1_i        (input_RF_1), // Input data 1
    .input2_i        (input_RF_2), // Input data 2
    .random_i        (random),
    .add_round_key_i (add_round_key),
    .aes_round_i     (aes_round),
    .aes_key_exp_i   (aes_key_exp),
    .write_en_i      (write_en),// Enable signal for writing
    .read_en_i       (read_en),   // Enable signal for reading
    .aes_comb_out0_o (aes_comb_out0),
    .aes_comb_out1_o (aes_comb_out1),
    .output_o        (store_result_o)// Output data
  );

  endgenerate



  ///////////////////////////////////////////// AES64 ///////////////////////////////////////
  logic [XLEN-1:0]  aes64_result_o;
  aes64_t aes64_op_i;
  logic aes64_en;

  logic [63:0] aes64_rs1, aes64_rs2;

  generate 
    if (XLEN==64 && crypto_instr_pkg::MAES == 1) begin: M_AES64
      always_comb
      begin
        if (opcode_i==AES64_1) begin
          aes64_en = 1;
          if(instr_i[30]==1) begin
            aes64_op_i = aes64_ks2;
            aes64_rs1  = aes_comb_out0;
            aes64_rs2  = aes_comb_out1;
          end
          else begin
            if (instr_i[27:26]==2'b00) begin
              aes64_op_i = aes64_es;
              aes64_rs1  = aes_comb_out0;
              aes64_rs2  = aes_comb_out1;
            end
            else if (instr_i[27:26]==2'b01) begin
              aes64_op_i = aes64_esm;
              aes64_rs1  = aes_comb_out0;
              aes64_rs2  = aes_comb_out1;
            end
            else if (instr_i[27:26]==2'b10) begin
              aes64_op_i = aes64_ds;
              aes64_rs1  = registers_i[0];
              aes64_rs2  = registers_i[1];
            end
            else if (instr_i[27:26]==2'b11) begin
              aes64_op_i = aes64_dsm;
              aes64_rs1  = registers_i[0];
              aes64_rs2  = registers_i[1];
            end
          end
        end
        else if (opcode_i==AES64_2) begin
          aes64_en = 1;
          if(instr_i[24]==1) begin
            aes64_op_i = aes64_ks1i;
            aes64_rs1  = aes_comb_out0;
            aes64_rs2  = registers_i[1];
          end
          else if(instr_i[24]==0) begin
            aes64_op_i = aes64_im;
            aes64_rs1  = registers_i[0];
            aes64_rs2  = registers_i[1];
          end
        end
        else begin
          aes64_en   = 0;
          aes64_rs1  = 0;
          aes64_rs2  = 0;
        end 
      end
      crypto_aes64 co_crypto_aes64(
      .aes64_en_i(aes64_en),
      .aes64_op_i(aes64_op_i),
      .aes64_rs1_i(aes64_rs1),
      .aes64_rs2_i(aes64_rs2),
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
        PRNG: begin
            result_n = 0;
            hartid_n = hartid_i;
            id_n     = id_i;
            valid_n  = 1'b1;
            rd_n     = rd_i;
            we_n     = 1'b1;
        end
        LOAD: begin
            result_n = 0;
            hartid_n = hartid_i;
            id_n     = id_i;
            valid_n  = 1'b1;
            rd_n     = rd_i;
            we_n     = 1'b1;
        end
        STORE: begin
            result_n = store_result_o;
            hartid_n = hartid_i;
            id_n     = id_i;
            valid_n  = 1'b1;
            rd_n     = rd_i;
            we_n     = 1'b1;
        end
        XOR_R: begin
            result_n = 0;
            hartid_n = hartid_i;
            id_n     = id_i;
            valid_n  = 1'b1;
            rd_n     = rd_i;
            we_n     = 1'b1;
        end
        ADD_RK: begin
            result_n = 0;
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