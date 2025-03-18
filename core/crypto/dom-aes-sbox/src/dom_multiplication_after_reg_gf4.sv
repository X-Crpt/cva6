module dom_multiplication_after_reg_gf4 import aes_pkg::*;
#(
    parameter int          X_ID_WIDTH      =  4  // Width of ID field.
) (
    input gf4_mult_t shares_i, 
    output gf4_mult_res_t dom_multiplication_after_reg_gf4_o
);

logic [1:0] shareA_result;
logic [1:0] shareB_result;

always_comb 
begin : dom_multiplication_after_reg_gf4
    shareA_result = shares_i.AA ^ shares_i.AB;
    shareB_result = shares_i.BB ^ shares_i.BA;

    dom_multiplication_after_reg_gf4_o.shareA = shareA_result;
    dom_multiplication_after_reg_gf4_o.shareB = shareB_result;
    
end
    
endmodule