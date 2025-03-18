module dom_multiplication_before_reg_gf4 import aes_pkg::*;
#(
    parameter int          X_ID_WIDTH      =  4  // Width of ID field.
) (
    input logic [1:0] shareA_l_in,
    input logic [1:0] shareA_h_in,
    input logic [1:0] shareB_l_in,
    input logic [1:0] shareB_h_in,
    input logic [1:0] fresh_randomness,
    output gf4_mult_t gf4_mult_o  
);

    logic [1:0] AA_hl_mult;
    logic [1:0] AB_hl_mult;
    logic [1:0] AB_hl_mult_r;
    logic [1:0] BB_hl_mult;
    logic [1:0] BA_hl_mult;
    logic [1:0] BA_hl_mult_r;


multiplication_gf4 #(.X_ID_WIDTH(4))
multiplication_gf4_AA (
    .a_in(shareA_h_in),
    .b_in(shareA_l_in),
    .multiplication_gf4_o(AA_hl_mult)
); 

multiplication_gf4 #(.X_ID_WIDTH(4))
multiplication_gf4_AB (
    .a_in(shareA_h_in),
    .b_in(shareB_l_in),
    .multiplication_gf4_o(AB_hl_mult)
); 

multiplication_gf4 #(.X_ID_WIDTH(4))
multiplication_gf4_BB (
    .a_in(shareB_h_in),
    .b_in(shareB_l_in),
    .multiplication_gf4_o(BB_hl_mult)
);

multiplication_gf4 #(.X_ID_WIDTH(4))
multiplication_gf4_BA (
    .a_in(shareB_h_in),
    .b_in(shareA_l_in),
    .multiplication_gf4_o(BA_hl_mult)
);

always_comb 
begin : dom_multiplication_before_reg_gf4
    AB_hl_mult_r = AB_hl_mult ^ fresh_randomness;
    BA_hl_mult_r = BA_hl_mult ^ fresh_randomness;

    gf4_mult_o.AA = AA_hl_mult;
    gf4_mult_o.AB = AB_hl_mult_r;
    gf4_mult_o.BB = BB_hl_mult;
    gf4_mult_o.BA = BA_hl_mult_r;
    
end
    
endmodule