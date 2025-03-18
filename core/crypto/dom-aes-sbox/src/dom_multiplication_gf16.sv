module dom_multiplication_gf16 import aes_pkg::*;
#(
    parameter int          X_ID_WIDTH      =  4  // Width of ID field.
) (
    input logic [3:0] shareA_gf16_l_in,
    input logic [3:0] shareA_gf16_h_in,
    input logic [3:0] shareB_gf16_l_in,
    input logic [3:0] shareB_gf16_h_in,  
    input logic [3:0] fresh_randomness,
    output gf16_mult_res_t dom_multiplication_gf16_o
);

logic [3:0] AA_hl_mult; 
logic [3:0] AB_hl_mult; 
logic [3:0] BB_hl_mult; 
logic [3:0] BA_hl_mult; 
logic [3:0] AB_hl_mult_r;
logic [3:0] BA_hl_mult_r;
logic [3:0] shareA_result;
logic [3:0] shareB_result;

always_comb 
begin : dom_multiplication_gf16
    AA_hl_mult = multiplication_gf16(shareA_gf16_h_in, shareA_gf16_l_in);
    AB_hl_mult = multiplication_gf16(shareA_gf16_h_in, shareB_gf16_l_in);
    BB_hl_mult = multiplication_gf16(shareB_gf16_h_in, shareB_gf16_l_in);
    BA_hl_mult = multiplication_gf16(shareB_gf16_h_in, shareA_gf16_l_in);

    AB_hl_mult_r = AB_hl_mult ^ fresh_randomness;
    BA_hl_mult_r = BA_hl_mult ^ fresh_randomness;

    shareA_result = AA_hl_mult ^ AB_hl_mult_r;
    shareB_result = BB_hl_mult ^ BA_hl_mult_r;

    dom_multiplication_gf16_o[0] = shareA_result;
    dom_multiplication_gf16_o[1] = shareB_result;
    
end
    
endmodule