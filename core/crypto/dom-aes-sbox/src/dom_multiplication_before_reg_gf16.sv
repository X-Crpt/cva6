module dom_multiplication_before_reg_gf16 import aes_pkg::*;
#(
    parameter int          X_ID_WIDTH      =  4  // Width of ID field.
) (
    input logic [3:0] shareA_gf16_l_in,
    input logic [3:0] shareA_gf16_h_in,
    input logic [3:0] shareB_gf16_l_in,
    input logic [3:0] shareB_gf16_h_in,
    input logic [3:0] fresh_randomness,
    output gf16_mult_t gf16_mult_out
);

logic [3:0] AA_hl_mult; 
logic [3:0] AB_hl_mult; 
logic [3:0] AB_hl_mult_r; 
logic [3:0] BB_hl_mult; 
logic [3:0] BA_hl_mult;
logic [3:0] BA_hl_mult_r;

multiplication_gf16 #(.X_ID_WIDTH(4))
multiplication_gf16_AA (
    .a_in(shareA_gf16_h_in),
    .b_in(shareA_gf16_l_in),
    .multiplication_gf16_o(AA_hl_mult)
);  

multiplication_gf16 #(.X_ID_WIDTH(4))
multiplication_gf16_AB (
    .a_in(shareA_gf16_h_in),
    .b_in(shareB_gf16_l_in),
    .multiplication_gf16_o(AB_hl_mult)
);  

multiplication_gf16 #(.X_ID_WIDTH(4))
multiplication_gf16_BB (
    .a_in(shareB_gf16_h_in),
    .b_in(shareB_gf16_l_in),
    .multiplication_gf16_o(BB_hl_mult)
);  

multiplication_gf16 #(.X_ID_WIDTH(4))
multiplication_gf16_BA (
    .a_in(shareB_gf16_h_in),
    .b_in(shareA_gf16_l_in),
    .multiplication_gf16_o(BA_hl_mult)
);  


always_comb 
begin : dom_multiplication_before_reg_gf16

    AB_hl_mult_r = AB_hl_mult ^ fresh_randomness;
    BA_hl_mult_r = BA_hl_mult ^ fresh_randomness;

    gf16_mult_out.AA = AA_hl_mult;
    gf16_mult_out.AB = AB_hl_mult_r;
    gf16_mult_out.BB = BB_hl_mult;
    gf16_mult_out.BA = BA_hl_mult_r;
    
end



endmodule