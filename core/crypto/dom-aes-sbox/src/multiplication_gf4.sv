module multiplication_gf4 import aes_pkg::*;
#(
    parameter int          X_ID_WIDTH      =  4  // Width of ID field.
) (
    input logic [1:0] a_in,
    input logic [1:0] b_in,
    output logic [1:0]  multiplication_gf4_o    
);

logic a_sum_bits;
logic b_sum_bits;
logic msb_ab_mult;
logic lsb_ab_mult;
logic a_sum_b_sum_mult;
logic result_h;
logic result_l;

always_comb 
begin : multiplication_gf4_process
    a_sum_bits = a_in[1] ^ a_in[0]; 
    b_sum_bits = b_in[1] ^ b_in[0]; 

    msb_ab_mult = a_in[1] & b_in[1]; 
    lsb_ab_mult = a_in[0] & b_in[0]; 
    a_sum_b_sum_mult = a_sum_bits & b_sum_bits; 

    result_h = msb_ab_mult ^ a_sum_b_sum_mult; 
    result_l = lsb_ab_mult ^ a_sum_b_sum_mult; 

    multiplication_gf4_o = {result_h, result_l};
    
end
    
endmodule