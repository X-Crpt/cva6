module multiplication_gf16
#(
    parameter int          X_ID_WIDTH      =  4  // Width of ID field.
) (
    input logic  [3:0] a_in,
    input logic  [3:0] b_in,   
    output logic [3:0] multiplication_gf16_o
);

logic [1:0] a_sum;
logic [1:0] b_sum;
logic [1:0] a_high_b_high_mult; 
logic [1:0] a_low_b_low_mult;   
logic [1:0] ab_sum_mult;        
logic [1:0] ab_sum_scale_N; 
logic [1:0] result_h; 
logic [1:0] result_l; 

//function logic [1:0] scale_N_gf4;
//    input [1:0] bits_in;
//    scale_N_gf4 = {bits_in[0], bits_in[1] ^ bits_in[0]};
//endfunction

multiplication_gf4 #(.X_ID_WIDTH(4))
multiplication_gf4_A_high_b_high (
    .a_in(a_in[3:2]),
    .b_in(b_in[3:2]),
    .multiplication_gf4_o(a_high_b_high_mult)
); 

multiplication_gf4 #(.X_ID_WIDTH(4))
multiplication_gf4_A_low_b_low (
    .a_in(a_in[1:0]),
    .b_in(b_in[1:0]),
    .multiplication_gf4_o(a_low_b_low_mult)
); 

multiplication_gf4 #(.X_ID_WIDTH(4))
multiplication_gf4_AB_sum (
    .a_in(a_sum),
    .b_in(b_sum),
    .multiplication_gf4_o(ab_sum_mult)
); 

always_comb 
begin : multiplication_gf16
    a_sum = a_in[3:2] ^ a_in[1:0];
    b_sum = b_in[3:2] ^ b_in[1:0];
    //ab_sum_scale_N = scale_N_gf4(ab_sum_mult);
    ab_sum_scale_N = {ab_sum_mult[0], ab_sum_mult[1] ^ ab_sum_mult[0]};
    
    result_h = ab_sum_scale_N ^ a_high_b_high_mult;
    result_l = ab_sum_scale_N ^ a_low_b_low_mult;

    multiplication_gf16_o = {result_h, result_l};
    
end
    
endmodule