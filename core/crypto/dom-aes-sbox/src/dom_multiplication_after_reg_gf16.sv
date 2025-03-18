module dom_multiplication_after_reg_gf16 import aes_pkg::*;
#(
    parameter int          X_ID_WIDTH      =  4  // Width of ID field.
) (
    input gf16_mult_t shares_i,
    output gf16_mult_res_t dom_multiplication_after_reg_gf16_o
);

logic [3:0] AA_hl_mult; 
logic [3:0] AB_hl_mult; 
logic [3:0] BB_hl_mult; 
logic [3:0] BA_hl_mult; 
logic [3:0] shareA_result;
logic [3:0] shareB_result;

always_comb 
begin : dom_multiplication_after_reg_gf16
    AA_hl_mult = shares_i.AA;
    AB_hl_mult = shares_i.AB;
    BB_hl_mult = shares_i.BB;
    BA_hl_mult = shares_i.BA;

    shareA_result = AA_hl_mult ^ AB_hl_mult;
    shareB_result = BB_hl_mult ^ BA_hl_mult;

    dom_multiplication_after_reg_gf16_o.shareA = shareA_result;
    dom_multiplication_after_reg_gf16_o.shareB = shareB_result;
    
end
    
endmodule