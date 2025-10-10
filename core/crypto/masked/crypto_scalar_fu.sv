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

  logic prng_global_en;// prng_aes_en;

  assign prng_global_en = prng_en;// || prng_aes_en || prng_aes_en_q1 || prng_aes_en_q2 || prng_aes_en_q3 || prng_aes_en_q4 || prng_aes_en_q5;

  ///////////////////////////////////////////// PRNG ///////////////////////////////////////
  logic [143:0]  prng_result_o;
  logic [127:0]  seed, seed_reg;
  prng_t prng_op_i;
  logic prng_en, prng_rst, prng_seed;
  logic prng_active, prng_update;
  logic prng_rst_global;
  generate 
    if (XLEN==64 && crypto_instr_pkg::RANDOM == 1) begin: M_PRNG

    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (~rst_ni) begin
        prng_en <= 1'b0;
      end else begin
        if (opcode_i==PRNG) begin
          if (instr_i[27:25]==3'b101) begin
            prng_en <= 1'b1;   // Set enable on SEED
          end else if (instr_i[27:25]==3'b111) begin
            prng_en <= 1'b0;   // Clear enable on RESET
          end
        end
      end
    end

    always_comb
      begin
        //prng_en   = 0;
        prng_op_i = prng64_none;
        prng_seed = 0;
        prng_rst  = 0;
        seed      = 0;
        
        if (opcode_i==PRNG) begin
            if (instr_i[27:25]==3'b101) begin
              prng_op_i = prng64_seed;
              seed      = {registers_i[0], registers_i[1]};
              //prng_en   = 1'b1;
              prng_seed = 1'b1;
              prng_rst  = 0;
            end
            //else if (instr_i[27:25]==3'b110) begin
            //  prng_op_i = prng64_enable;
            //  //prng_en   = 1'b1;
            //  prng_seed = 0;
            //  prng_rst  = 0;
            //end
            else if (instr_i[27:25]==3'b111) begin
              prng_op_i = prng64_rst;
              //prng_en   = 0;
              prng_seed = 0;
              prng_rst  = 1'b1;
            end
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
        end else if (prng_en && ~prng_rst) begin
          seed_reg    <= seed_reg;
          prng_active <= '0;
          prng_update <= 1'b1; 
        end else if (prng_en && prng_rst) begin
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

      prng prng_i (
        .clk(clk_i),                                // Clock input
        .rst(prng_rst_global),                      // Reset input (active high)
        .init_i(prng_active),                       // Set seed
        .en_i(prng_global_en),                      // Enable input
        .seed_i(seed_reg),                          // 128-bit seed
        .prng_o(prng_result_o)                      // 64-bit pseudo-random output
      );


    end
  endgenerate
  //////////////////////////////////////////////////////////////////////////////////////////
  
  
  //////////////////////////////////////////////////////////////////////////////////////////
  logic [XLEN-1:0]  store_result_o;
  logic [127:0]     xor_r_result_o;
  logic [XLEN-1:0]  input_RF_0, input_RF_1, input_RF_2, input_RF_3;
  logic [XLEN-1:0]  address_RF;
  logic             write_en, read_en;
  logic             random;
  logic             add_round_key;
  logic             unmasking;
  logic             aes_round;
  logic             aes_key_exp_ks1, aes_key_exp_ks2;

  logic [63:0]      aes_comb_out0, aes_comb_out1, aes_comb_out2, aes_comb_out3;
  
  logic [4:0]       xor_temp1, xor_temp2, xor_temp3; 
  
  logic [4:0] opcode_q1, opcode_q2, opcode_q3, opcode_q4, opcode_q5;
  logic [2:0] instr_q1, instr_q2, instr_q3, instr_q4, instr_q5;
  //logic prng_aes_en_q1, prng_aes_en_q2, prng_aes_en_q3, prng_aes_en_q4, prng_aes_en_q5;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      opcode_q1 <= '0;       opcode_q2 <= '0;       opcode_q3 <= '0;       opcode_q4 <= '0;       opcode_q5 <= '0; 
      instr_q1  <= '0;       instr_q2  <= '0;       instr_q3  <= '0;       instr_q4  <= '0;       instr_q5  <= '0;
      //prng_aes_en_q1 <= '0; prng_aes_en_q2 <= '0; prng_aes_en_q3 <= '0; prng_aes_en_q4 <= '0; prng_aes_en_q5 <= '0; 
      end
      else begin
        opcode_q1 <= opcode_i;
        instr_q1  <= {instr_i[30], instr_i[27:26]};
        //prng_aes_en_q1 <= prng_aes_en;

        opcode_q2 <= opcode_q1;
        instr_q2  <= instr_q1;
        //prng_aes_en_q2 <= prng_aes_en_q1;

        opcode_q3 <= opcode_q2;
        instr_q3  <= instr_q2;
        //prng_aes_en_q3 <= prng_aes_en_q2;

        opcode_q4 <= opcode_q3;
        instr_q4  <= instr_q3;
        //prng_aes_en_q4 <= prng_aes_en_q3;

        opcode_q5 <= opcode_q4;
        instr_q5  <= instr_q4;
        //prng_aes_en_q5 <= prng_aes_en_q4;
      end
  end

  generate 
    if (XLEN==64 && crypto_instr_pkg::MASKED == 1) begin: M_RF
      
      always_comb begin
        write_en         = 1'b0;
        read_en          = 1'b0;
        random           = 1'b0;
        add_round_key    = 1'b0;
        unmasking        = 1'b0;
        aes_round        = 1'b0;
        aes_key_exp_ks2  = 1'b0;
        aes_key_exp_ks1  = 1'b0;
        address_RF       = '0;
        input_RF_0       = '0;
        input_RF_1       = '0;
        input_RF_2       = '0;
        input_RF_3       = '0;

        //prng_aes_en      = '0;

        //----------------------------------
        // A) READ logic (use opcode_i, instr_i)
        //----------------------------------
        unique case (opcode_i)

          LOAD: begin
            address_RF      = rd_i;
            input_RF_0      = registers_i[0];
            input_RF_1      = registers_i[1];
            write_en        = 1'b1;   
          end

          STORE: begin
            address_RF      = registers_i[0];
            read_en         = 1'b1;  
          end

          XOR_R: begin
            address_RF      = registers_i[0][4:0];
            input_RF_0        = {59'b0, registers_i[1][4:0]};
            input_RF_1        = prng_result_o[63:0];
            input_RF_2        = prng_result_o[127:64];
            random          = 1'b1;
            write_en        = 1'b1;
          end

          ADD_RK: begin
            input_RF_0      = registers_i[0];  //pt
            input_RF_1      = registers_i[1];  //key
            address_RF      = rd_i;
            write_en        = 1'b1;
            add_round_key   = 1'b1;
          end

          UNMASK: begin
            input_RF_0      = registers_i[0];  
            input_RF_1      = registers_i[1];  
            write_en        = 1'b1;
            unmasking       = 1'b1;
          end

          // AES64_1 ( = aes64 instruction ) :
          AES64_1: begin
            // - If instr_i[30] == 1 => aes64_ks2
            if (instr_i[30]) begin
              // aes64ks2 uses immediate signals
              address_RF      = '0;
              input_RF_0      = registers_i[0];
              input_RF_1      = registers_i[1];
              input_RF_2      = aes64_result_share0_o;  
              input_RF_3      = aes64_result_share1_o;  
              aes_key_exp_ks2 = 1'b1;
              read_en         = 1'b1;
              write_en        = 1'b1;
            end
            // - If instr_i[27:26]==2'b00 or 2'b01 => aes64_es/aes64_esm => we only do the *read* part now
            //   The *write* part will happen 5 cycles later (see below).
            else if ( (instr_i[27:26] == 2'b00) || (instr_i[27:26] == 2'b01) ) begin
              // READ side of aes64_es / aes64_esm
              address_RF        = rd_i;
              input_RF_0        = registers_i[0];  
              input_RF_1        = registers_i[1];  
              aes_round         = 1'b1;
              read_en           = 1'b1;
              write_en          = 1'b1; //TBD: maybe we can avoid the pipeline inside

              //prng_aes_en      = 1'b1;
            end
          end

          // AES64_2 ( = aes64_ks1i instruction ) :
          AES64_2: begin
            input_RF_0        = {59'b0, rd_i};  
            input_RF_1        = registers_i[0];  
            read_en           = 1'b1;
            write_en          = 1'b1;
            aes_key_exp_ks1   = 1'b1;
            //prng_aes_en       = 1'b1;
          end

          default: begin
            // do nothing, remain at defaults
          end

        endcase

        //-------------------------------------------
        // B) WRITE logic (use opcode_q5, instr_q5)
        //-------------------------------------------
        // After the pipeline delays, if the delayed instruction was aes64_es / aes64_esm or aes64_ks1i,
        // now we perform the final write to the register file, using the final AES results.
        //-------------------------------------------
        unique case (opcode_q5)

          // Delayed AES64_1 => aes64_es / aes64_esm
          AES64_1: begin
            // Check if the original instruction was the aes/esm variant:
            if (!instr_q5[2] && ((instr_q5[1:0] == 2'b00) || (instr_q5[1:0] == 2'b01))) begin
              // This is the final write for aes64_es / aes64_esm
              input_RF_2       = aes64_result_share0_o;
              input_RF_3       = aes64_result_share1_o;
            end
          end

          // Delayed AES64_2 => aes64_ks1i
          AES64_2: begin
            // Final write for aes64_ks1i
            input_RF_2       = aes64_result_share0_o;
            input_RF_3       = aes64_result_share1_o;
          end

          default: begin
            // no delayed write
          end

        endcase
      end


    rf rf_i (
    .clk_i               (clk_i),
    .rst_ni              (rst_ni),
    .addr_i              (address_RF[4:0]), // Address for read/write
    .input0_i            (input_RF_0), // Input data 0
    .input1_i            (input_RF_1), // Input data 1
    .input2_i            (input_RF_2), // Input data 2
    .input3_i            (input_RF_3),
    .random_i            (random),
    .add_round_key_i     (add_round_key),
    .unmasking_i         (unmasking),
    .aes_round_i         (aes_round),
    .aes_key_exp_ks1_i   (aes_key_exp_ks1),
    .aes_key_exp_ks2_i   (aes_key_exp_ks2),
    .write_en_i          (write_en),// Enable signal for writing
    .read_en_i           (read_en),   // Enable signal for reading
    .aes_comb_out0_o     (aes_comb_out0),
    .aes_comb_out1_o     (aes_comb_out1),
    .aes_comb_out2_o     (aes_comb_out2),
    .aes_comb_out3_o     (aes_comb_out3),
    .output_o            (store_result_o)// Output data
  );

end
endgenerate



  ///////////////////////////////////////////// AES64 ///////////////////////////////////////
  logic [XLEN-1:0]  aes64_result_o, aes64_result_share0_o, aes64_result_share1_o;
  aes64_t aes64_op_i;
  logic aes64_en;
  logic valid_i;
  logic [17:0] randombits_i [7:0];

  logic [63:0] aes64_rs1, aes64_rs2, aes64_rs3, aes64_rs4;

  generate 
    if (XLEN==64 && crypto_instr_pkg::MAES == 1) begin: M_AES64
    always_comb begin
        // Default assignments to prevent latches
        aes64_en              = 1'b0;
        aes64_op_i            = aes64_none;
        aes64_rs1             = '0;
        aes64_rs2             = '0;
        aes64_rs3             = '0;
        aes64_rs4             = '0;
        valid_i               = 1'b0;

        if (opcode_i == AES64_1) begin
            aes64_en = 1'b1;
            if (instr_i[30] == 1'b1) begin  // - If instr_i[30] == 1 => aes64_ks2
                aes64_op_i = aes64_ks2;
                valid_i    = 1'b0;
                aes64_rs1  = aes_comb_out0;
                aes64_rs2  = aes_comb_out1;
                aes64_rs3  = aes_comb_out2;
                aes64_rs4  = aes_comb_out3;
            end else begin
                case (instr_i[27:26])
                    2'b00: begin
                        aes64_op_i = aes64_es;
                        aes64_rs1  = aes_comb_out0;
                        aes64_rs2  = aes_comb_out1;
                        aes64_rs3  = aes_comb_out2;
                        aes64_rs4  = aes_comb_out3;
                        valid_i    = 1'b1;
                    end
                    2'b01: begin
                        aes64_op_i = aes64_esm;
                        aes64_rs1  = aes_comb_out0;
                        aes64_rs2  = aes_comb_out1;
                        aes64_rs3  = aes_comb_out2;
                        aes64_rs4  = aes_comb_out3;
                        valid_i    = 1'b1;
                    end
                    default: begin
                        valid_i = 1'b0;
                    end
                endcase
            end
        end else if (opcode_i == AES64_2) begin
            aes64_en = 1'b1;
            if (instr_i[24] == 1'b1) begin
                aes64_op_i           = aes64_ks1i;
                aes64_rs1            = aes_comb_out0;
                aes64_rs2            = registers_i[1];
                aes64_rs3            = aes_comb_out1;
                valid_i              = 1'b1;
            end
        end
    end


  assign randombits_i[0] = prng_result_o[143:126];  // Bits 143 down to 126
  assign randombits_i[1] = prng_result_o[125:108];  // Bits 125 down to 108
  assign randombits_i[2] = prng_result_o[107:90];   // Bits 107 down to 90
  assign randombits_i[3] = prng_result_o[89:72];    // Bits 89 down to 72
  assign randombits_i[4] = prng_result_o[71:54];    // Bits 71 down to 54
  assign randombits_i[5] = prng_result_o[53:36];    // Bits 53 down to 36
  assign randombits_i[6] = prng_result_o[35:18];    // Bits 35 down to 18
  assign randombits_i[7] = prng_result_o[17:0];     // Bits 17 down to 0


    //assign randombits_i[0] = '0;
    //assign randombits_i[1] = '0;
    //assign randombits_i[2] = '0;
    //assign randombits_i[3] = '0;
    //assign randombits_i[4] = '0;
    //assign randombits_i[5] = '0;
    //assign randombits_i[6] = '0;
    //assign randombits_i[7] = '0;
    //assign randombits_i[0] = 18'h12345;
    //assign randombits_i[1] = 18'h1A2B3;
    //assign randombits_i[2] = 18'h2BCD0;
    //assign randombits_i[3] = 18'h17DEF;
    //assign randombits_i[4] = 18'h0ACE5;
    //assign randombits_i[5] = 18'h3F3F3;
    //assign randombits_i[6] = 18'h15555;
    //assign randombits_i[7] = 18'h3ABCD;

    crypto_aes64 co_crypto_aes64(
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .aes64_en_i(aes64_en),
    .aes64_op_i(aes64_op_i),
    .aes64_rs1_i(aes64_rs1),
    .aes64_rs2_i(aes64_rs2),
    .aes64_rs3_i(aes64_rs3),
    .aes64_rs4_i(aes64_rs4),
    .valid_i(valid_i),
    .aes64_rnum_i(instr_i[23:20]),
    .randombits_i(randombits_i),
    .aes64_result_share0_o(aes64_result_share0_o),
    .aes64_result_share1_o(aes64_result_share1_o)
    );
    end
  endgenerate


  //////////////////////////////////////////////////////////////////////////////////////
  always_comb begin
    case (opcode_i)
        AES64_1: begin
            result_n = aes64_result_o;
            hartid_n = hartid_i;
            id_n     = id_i;
            valid_n  = 1'b1;
            rd_n     = rd_i;
            we_n     = 1'b1;
        end
        AES64_2: begin
            result_n = aes64_result_o;
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
        UNMASK: begin
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

  assign result_o = result_q;
  assign hartid_o = hartid_q;
  assign id_o     = id_q;
  assign valid_o  = valid_q;
  assign rd_o     = rd_q;
  assign we_o     = we_q;


endmodule