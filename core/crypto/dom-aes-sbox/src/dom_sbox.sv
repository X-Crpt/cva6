module dom_sbox import aes_pkg::*;
#(
    parameter int          X_ID_WIDTH      =  4  // Width of ID field.
)(
    input  wire  clk_i,
    input  wire  rst_n,
    input  wire  valid_i,
    output logic ready_for_sbox_i,

    input wire [7: 0] shareA_in,
    input wire [7: 0] shareB_in,
    input wire [17:0] randombits_i,

    // Output signals
    output logic valid_o,
    input   wire ready_for_sbox_o,
    output logic [X_ID_WIDTH-1:0] instr_id_o,
    output logic [7:0] shareA_out,
    output logic [7:0] shareB_out
);

//Pipeline
wire STAGE_2_RDY, STAGE_3_RDY, STAGE_4_RDY, STAGE_5_RDY, STAGE_6_RDY; 

//Forward isomorphic transfrom
logic [7:0] sA_isomorphic_trans;
logic [7:0] sB_isomorphic_trans;


//shareA and shareB nibbles
logic [3:0] stage2_sA_nibble_high_reg, stage3_sA_nibble_high_reg, stage4_sA_nibble_high_reg, stage5_sA_nibble_high_reg;
logic [3:0] stage2_sA_nibble_low_reg,  stage3_sA_nibble_low_reg,  stage4_sA_nibble_low_reg,  stage5_sA_nibble_low_reg;
logic [3:0] stage2_sB_nibble_high_reg, stage3_sB_nibble_high_reg, stage4_sB_nibble_high_reg, stage5_sB_nibble_high_reg;
logic [3:0] stage2_sB_nibble_low_reg,  stage3_sB_nibble_low_reg,  stage4_sB_nibble_low_reg,  stage5_sB_nibble_low_reg;

//Inversion gf256
logic [3:0] stage2_sA_sum_nibbles, stage2_sB_sum_nibbles;

logic [3:0] stage2_sA_square_scale, stage2_sB_square_scale; 
logic [3:0] stage3_sA_square_scale_reg, stage3_sB_square_scale_reg;

gf16_mult_t stage2_multiplication_dom_gf16_before_reg;
gf16_mult_t stage3_multiplication_dom_gf16_reg;
gf16_mult_res_t stage3_multiplication_dom_gf16_after_reg; 


logic [3:0] stage3_sA_sum_multiply_gf16,     stage3_sB_sum_multiply_gf16;
logic [3:0] stage4_sA_sum_multiply_gf16_reg, stage4_sB_sum_multiply_gf16_reg;

// Inversion gf16
logic [1:0] stage3_sA_sum_gf4, stage3_sB_sum_gf4;
logic [1:0] stage3_sA_square_scale_gf4, stage3_sB_square_scale_gf4;

gf4_mult_t stage3_multiplication_dom_gf4_before_reg, stage4_multiplication_dom_gf4_reg;
logic [1:0] stage3_sA_square_gf4, stage3_sB_square_gf4;

gf4_mult_res_t stage4_multiplication_dom_gf4_after_reg;
logic [1:0] stage4_sA_multiply_gf4, stage4_sB_multiply_gf4;
logic [3:0] stage4_sA_square_scale_gf4_reg, stage4_sB_square_scale_gf4_reg;
logic [1:0] stage4_sA_inverted_sum_gf4, stage4_sB_inverted_sum_gf4;
logic [1:0] stage4_sA_sum_multiply_gf4, stage4_sB_sum_multiply_gf4;

gf4_mult_t stage4_result_h_before_reg_gf4, stage4_result_l_before_reg_gf4;
gf4_mult_t stage5_result_h_gf4_reg, stage5_result_l_gf4_reg;

gf16_inversion_t stage5_inversion_gf16_result;
logic [3:0] stage5_sA_inverted_gf16, stage5_sB_inverted_gf16;
gf16_mult_t stage5_multiplication_high_gf16_before_reg, stage5_multiplication_low_gf16_before_reg;
logic [7:0] stage6_sA_inversion_gf256_result, stage6_sB_inversion_gf256_result;
gf4_mult_res_t stage5_result_h_after_reg_gf4, stage5_result_l_after_reg_gf4;
gf16_mult_res_t stage6_multiplication_high_gf16_after_reg, stage6_multiplication_low_gf16_after_reg;
gf16_mult_t stage6_multiplication_dom_gf16_high_reg, stage6_multiplication_dom_gf16_low_reg;


logic stage2_valid, stage3_valid, stage4_valid, stage5_valid, stage6_valid;
logic [17:0] stage2_randombits, stage3_randombits, stage4_randombits, stage5_randombits;

logic [7:0] shareA_out_temp1, shareB_out_temp1; 
logic [7:0] shareA_out_temp2; 


//PIPELINE_FORWARD_DATA
assign STAGE_2_RDY = !stage2_valid || STAGE_3_RDY;
assign STAGE_3_RDY = !stage3_valid || STAGE_4_RDY;
assign STAGE_4_RDY = !stage4_valid || STAGE_5_RDY;
assign STAGE_5_RDY = !stage5_valid || STAGE_6_RDY;
assign STAGE_6_RDY = !stage6_valid || ready_for_sbox_o;


//Output signals
assign valid_o          = stage6_valid;
assign ready_for_sbox_i = STAGE_2_RDY;

always_ff @( posedge clk_i, negedge rst_n ) begin : SBOX_PIPELINE_REGISTERS
    if(!rst_n) begin 
        stage2_valid = 'b0;
        stage3_valid = 'b0;
        stage4_valid = 'b0;
        stage5_valid = 'b0;
        stage6_valid = 'b0; 
    end else 
    begin
        if(STAGE_6_RDY)
        begin
            //Register Between stage 5 & 6
            stage6_valid                       = stage5_valid;

            stage6_multiplication_dom_gf16_high_reg = stage5_multiplication_high_gf16_before_reg;
            stage6_multiplication_dom_gf16_low_reg  = stage5_multiplication_low_gf16_before_reg;

        end
        if(STAGE_5_RDY)
        begin
            //Register Between stage 4 & 5
            stage5_valid                       = stage4_valid;
            stage5_randombits                  = stage4_randombits;

            stage5_result_h_gf4_reg            = stage4_result_h_before_reg_gf4;             
            stage5_result_l_gf4_reg            = stage4_result_l_before_reg_gf4;

            stage5_sA_nibble_high_reg      = stage4_sA_nibble_high_reg;
            stage5_sA_nibble_low_reg       = stage4_sA_nibble_low_reg;
            stage5_sB_nibble_high_reg      = stage4_sB_nibble_high_reg;
            stage5_sB_nibble_low_reg       = stage4_sB_nibble_low_reg;
        end

        if(STAGE_4_RDY)
        begin
            //Register Between stage 3 & 4
            stage4_valid                       = stage3_valid;
            stage4_randombits                  = stage3_randombits;

            stage4_multiplication_dom_gf4_reg  = stage3_multiplication_dom_gf4_before_reg;
            stage4_sA_square_scale_gf4_reg     = stage3_sA_square_scale_gf4;
            stage4_sB_square_scale_gf4_reg     = stage3_sB_square_scale_gf4;

            stage4_sA_sum_multiply_gf16_reg    = stage3_sA_sum_multiply_gf16;
            stage4_sB_sum_multiply_gf16_reg    = stage3_sB_sum_multiply_gf16;            

            stage4_sA_nibble_high_reg      = stage3_sA_nibble_high_reg;
            stage4_sA_nibble_low_reg       = stage3_sA_nibble_low_reg;
            stage4_sB_nibble_high_reg      = stage3_sB_nibble_high_reg;
            stage4_sB_nibble_low_reg       = stage3_sB_nibble_low_reg;
        end

        if(STAGE_3_RDY)
        begin
            //Register Between stage 2 & 3
            stage3_valid                       = stage2_valid;
            stage3_randombits                  = stage2_randombits;

            stage3_multiplication_dom_gf16_reg = stage2_multiplication_dom_gf16_before_reg;
            stage3_sA_square_scale_reg     = stage2_sA_square_scale;
            stage3_sB_square_scale_reg     = stage2_sB_square_scale;

            stage3_sA_nibble_high_reg      = stage2_sA_nibble_high_reg;
            stage3_sA_nibble_low_reg       = stage2_sA_nibble_low_reg;
            stage3_sB_nibble_high_reg      = stage2_sB_nibble_high_reg;
            stage3_sB_nibble_low_reg       = stage2_sB_nibble_low_reg;
        end

        if(STAGE_2_RDY)
        begin
            if(valid_i) begin
                //Register Between stage 1 & 2
                stage2_valid                       = valid_i;
                stage2_randombits                  = randombits_i;

                stage2_sA_nibble_high_reg      = sA_isomorphic_trans[7:4];
                stage2_sA_nibble_low_reg       = sA_isomorphic_trans[3:0];
                stage2_sB_nibble_high_reg      = sB_isomorphic_trans[7:4];
                stage2_sB_nibble_low_reg       = sB_isomorphic_trans[3:0];
            end else begin
                //Register Between stage 1 & 2
                stage2_valid                       = 'b0;
                stage2_randombits                  = 'b0;

                stage2_sA_nibble_high_reg      = 'b0;
                stage2_sA_nibble_low_reg       = 'b0;
                stage2_sB_nibble_high_reg      = 'b0;
                stage2_sB_nibble_low_reg       = 'b0;
            end

        end
    end
end

//-------------------Stage 1--------------------------------------------------------
//ISOMORPHIC_TRANSFORM
isomorphic_mapping #(.X_ID_WIDTH(4))
iso_mapping_A (
    .byte_in(shareA_in),     
    .byte_out(sA_isomorphic_trans) 
);

isomorphic_mapping #(.X_ID_WIDTH(4))
iso_mapping_B (
    .byte_in(shareB_in),     
    .byte_out(sB_isomorphic_trans) 
);


//-------------------Stage 2---------------------------------
always_comb 
begin: STAGE2
    stage2_sA_sum_nibbles = stage2_sA_nibble_high_reg ^ stage2_sA_nibble_low_reg;
    stage2_sB_sum_nibbles = stage2_sB_nibble_high_reg ^ stage2_sB_nibble_low_reg;
end

square_scale_gf16 #(.X_ID_WIDTH(4))
square_scale_gf16_A (
    .nibble_in(stage2_sA_sum_nibbles),     
    .square_scale_gf16_o(stage2_sA_square_scale) 
);

square_scale_gf16 #(.X_ID_WIDTH(4))
square_scale_gf16_B (
    .nibble_in(stage2_sB_sum_nibbles),     
    .square_scale_gf16_o(stage2_sB_square_scale) 
);

dom_multiplication_before_reg_gf16 #(.X_ID_WIDTH(4))
dom_multiplication_before_reg_gf16_stage2_AB (
    .shareA_gf16_l_in(stage2_sA_nibble_low_reg),
    .shareA_gf16_h_in(stage2_sA_nibble_high_reg),
    .shareB_gf16_l_in(stage2_sB_nibble_low_reg),
    .shareB_gf16_h_in(stage2_sB_nibble_high_reg),
    .fresh_randomness(stage2_randombits[11:8]),
    .gf16_mult_out(stage2_multiplication_dom_gf16_before_reg)
);


//-------------------Stage 3---------------------------------
always_comb 
begin: STAGE3
    
    stage3_sA_sum_multiply_gf16 = stage3_multiplication_dom_gf16_after_reg.shareA ^ stage3_sA_square_scale_reg;
    stage3_sB_sum_multiply_gf16 = stage3_multiplication_dom_gf16_after_reg.shareB ^ stage3_sB_square_scale_reg;

    stage3_sA_sum_gf4 = stage3_sA_sum_multiply_gf16[3:2] ^ stage3_sA_sum_multiply_gf16[1:0];
    stage3_sB_sum_gf4 = stage3_sB_sum_multiply_gf16[3:2] ^ stage3_sB_sum_multiply_gf16[1:0];

    //stage3_sA_square_gf4       = square_gf4(stage3_sA_sum_gf4);
    //stage3_sB_square_gf4       = square_gf4(stage3_sB_sum_gf4);
    stage3_sA_square_gf4 = {stage3_sA_sum_gf4[0], stage3_sA_sum_gf4[1]};
    stage3_sB_square_gf4 = {stage3_sB_sum_gf4[0], stage3_sB_sum_gf4[1]};

    //stage3_sA_square_scale_gf4 = scale_N_gf4(stage3_sA_square_gf4);
    //stage3_sB_square_scale_gf4 = scale_N_gf4(stage3_sB_square_gf4);
    stage3_sA_square_scale_gf4 = {stage3_sA_square_gf4[0], stage3_sA_square_gf4[1] ^ stage3_sA_square_gf4[0]};
    stage3_sB_square_scale_gf4 = {stage3_sB_square_gf4[0], stage3_sB_square_gf4[1] ^ stage3_sB_square_gf4[0]};
end

dom_multiplication_after_reg_gf16 #(.X_ID_WIDTH(4))
dom_multiplication_after_reg_gf16_stage3 (
    .shares_i(stage3_multiplication_dom_gf16_reg),     
    .dom_multiplication_after_reg_gf16_o(stage3_multiplication_dom_gf16_after_reg) 
);

dom_multiplication_before_reg_gf4 #(.X_ID_WIDTH(4)) 
dom_multiplication_before_reg_gf4_stage3 (
    .shareA_l_in(stage3_sA_sum_multiply_gf16[1:0]),
    .shareA_h_in(stage3_sA_sum_multiply_gf16[3:2]),
    .shareB_l_in(stage3_sB_sum_multiply_gf16[1:0]),
    .shareB_h_in(stage3_sB_sum_multiply_gf16[3:2]),
    .fresh_randomness(stage3_randombits[13:12]),
    .gf4_mult_o(stage3_multiplication_dom_gf4_before_reg)
);


//-------------------Stage 4---------------------------------
always_comb 
begin: STAGE4
    stage4_sA_multiply_gf4 = stage4_multiplication_dom_gf4_after_reg.shareA;
    stage4_sB_multiply_gf4 = stage4_multiplication_dom_gf4_after_reg.shareB;

    stage4_sA_sum_multiply_gf4 = stage4_sA_multiply_gf4 ^ stage4_sA_square_scale_gf4_reg;
    stage4_sB_sum_multiply_gf4 = stage4_sB_multiply_gf4 ^ stage4_sB_square_scale_gf4_reg;

    //stage4_sA_inverted_sum_gf4 = inverse_gf4(stage4_sA_sum_multiply_gf4);
    //stage4_sB_inverted_sum_gf4 = inverse_gf4(stage4_sB_sum_multiply_gf4);
    stage4_sA_inverted_sum_gf4 = {stage4_sA_sum_multiply_gf4[0], stage4_sA_sum_multiply_gf4[1]};
    stage4_sB_inverted_sum_gf4 = {stage4_sB_sum_multiply_gf4[0], stage4_sB_sum_multiply_gf4[1]};

end

dom_multiplication_after_reg_gf4 #(.X_ID_WIDTH(4))
dom_multiplication_after_reg_gf4_stage4 (
    .shares_i(stage4_multiplication_dom_gf4_reg),     
    .dom_multiplication_after_reg_gf4_o(stage4_multiplication_dom_gf4_after_reg) 
);

dom_multiplication_before_reg_gf4 #(.X_ID_WIDTH(4)) 
dom_multiplication_before_reg_gf4_stage4_1 (
    .shareA_l_in(stage4_sA_sum_multiply_gf16_reg[1:0]),
    .shareA_h_in(stage4_sA_inverted_sum_gf4),
    .shareB_l_in(stage4_sB_sum_multiply_gf16_reg[1:0]),
    .shareB_h_in(stage4_sB_inverted_sum_gf4),
    .fresh_randomness(stage4_randombits[15:14]),
    .gf4_mult_o(stage4_result_h_before_reg_gf4)
);

dom_multiplication_before_reg_gf4 #(.X_ID_WIDTH(4)) 
dom_multiplication_before_reg_gf4_stage4_2 (
    .shareA_l_in(stage4_sA_sum_multiply_gf16_reg[3:2]),
    .shareA_h_in(stage4_sA_inverted_sum_gf4),
    .shareB_l_in(stage4_sB_sum_multiply_gf16_reg[3:2]),
    .shareB_h_in(stage4_sB_inverted_sum_gf4),
    .fresh_randomness(stage4_randombits[17:16]),
    .gf4_mult_o(stage4_result_l_before_reg_gf4)
);


//-------------------Stage 5---------------------------------
always_comb 
begin: STAGE5

    stage5_inversion_gf16_result.shareA = {stage5_result_h_after_reg_gf4.shareA, stage5_result_l_after_reg_gf4.shareA};
    stage5_inversion_gf16_result.shareB = {stage5_result_h_after_reg_gf4.shareB, stage5_result_l_after_reg_gf4.shareB};

    stage5_sA_inverted_gf16 = stage5_inversion_gf16_result.shareA;
    stage5_sB_inverted_gf16 = stage5_inversion_gf16_result.shareB;

end


dom_multiplication_after_reg_gf4 #(.X_ID_WIDTH(4))
dom_multiplication_after_reg_gf4_stage5_1 (
    .shares_i(stage5_result_h_gf4_reg),     
    .dom_multiplication_after_reg_gf4_o(stage5_result_h_after_reg_gf4) 
);

dom_multiplication_after_reg_gf4 #(.X_ID_WIDTH(4))
dom_multiplication_after_reg_gf4_stage5_2 (
    .shares_i(stage5_result_l_gf4_reg),     
    .dom_multiplication_after_reg_gf4_o(stage5_result_l_after_reg_gf4) 
);


dom_multiplication_before_reg_gf16 #(.X_ID_WIDTH(4))
dom_multiplication_before_reg_gf16_stage5_high (
    .shareA_gf16_l_in(stage5_sA_nibble_low_reg),
    .shareA_gf16_h_in(stage5_sA_inverted_gf16),
    .shareB_gf16_l_in(stage5_sB_nibble_low_reg),
    .shareB_gf16_h_in(stage5_sB_inverted_gf16),
    .fresh_randomness(stage5_randombits[3:0]),
    .gf16_mult_out(stage5_multiplication_high_gf16_before_reg)
);

dom_multiplication_before_reg_gf16 #(.X_ID_WIDTH(4))
dom_multiplication_before_reg_gf16_stage5_low (
    .shareA_gf16_l_in(stage5_sA_nibble_high_reg),
    .shareA_gf16_h_in(stage5_sA_inverted_gf16),
    .shareB_gf16_l_in(stage5_sB_nibble_high_reg),
    .shareB_gf16_h_in(stage5_sB_inverted_gf16),
    .fresh_randomness(stage5_randombits[7:4]),
    .gf16_mult_out(stage5_multiplication_low_gf16_before_reg)
);

//-------------------Stage 6---------------------------------
always_comb 
begin: STAGE6

    stage6_sA_inversion_gf256_result = {stage6_multiplication_high_gf16_after_reg.shareA, stage6_multiplication_low_gf16_after_reg.shareA};
    stage6_sB_inversion_gf256_result = {stage6_multiplication_high_gf16_after_reg.shareB, stage6_multiplication_low_gf16_after_reg.shareB};

end


dom_multiplication_after_reg_gf16 #(.X_ID_WIDTH(4))
dom_multiplication_after_reg_gf16_stage6_high (
    .shares_i(stage6_multiplication_dom_gf16_high_reg),     
    .dom_multiplication_after_reg_gf16_o(stage6_multiplication_high_gf16_after_reg) 
);

dom_multiplication_after_reg_gf16 #(.X_ID_WIDTH(4))
dom_multiplication_after_reg_gf16_stage6_low (
    .shares_i(stage6_multiplication_dom_gf16_low_reg),     
    .dom_multiplication_after_reg_gf16_o(stage6_multiplication_low_gf16_after_reg) 
);

inverse_isomorphic_mapping #(.X_ID_WIDTH(4))
inverse_iso_mapping_A (
    .byte_in(stage6_sA_inversion_gf256_result),     
    .byte_out(shareA_out_temp1) 
);

inverse_isomorphic_mapping #(.X_ID_WIDTH(4))
inverse_iso_mapping_B (
    .byte_in(stage6_sB_inversion_gf256_result),     
    .byte_out(shareB_out_temp1) 
);

affine_transformation_multiplication #(.X_ID_WIDTH(4))
affine_transformation_multiplication_A (
    .byte_in(shareA_out_temp1),     
    .byte_out(shareA_out_temp2) 
);

affine_transformation_multiplication #(.X_ID_WIDTH(4))
affine_transformation_multiplication_B (
    .byte_in(shareB_out_temp1),     
    .byte_out(shareB_out) 
);

affine_transformation_addition #(.X_ID_WIDTH(4))
affine_transformation_addition_A (
    .byte_in(shareA_out_temp2),     
    .byte_out(shareA_out) 
);


endmodule