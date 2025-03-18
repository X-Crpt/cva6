module square_scale_gf16
#(
    parameter int          X_ID_WIDTH      =  4  // Width of ID field.
) (
    input  logic [3:0]  nibble_in,
    output logic [3:0]  square_scale_gf16_o    
);

logic [1:0] sum_bits;       
logic [1:0] square_sum;     
logic [1:0] scale_h;        
logic [1:0] square_scale_h;

//function logic [1:0] square_gf4;
//    input [1:0] bits_in;
//    square_gf4 = {bits_in[0], bits_in[1]};
//endfunction
//function logic [1:0] scale_N_gf4;
//    input [1:0] bits_in;
//    scale_N_gf4 = {bits_in[0], bits_in[1] ^ bits_in[0]};
//endfunction

always_comb 
begin : square_scale_gf16
    sum_bits       = nibble_in[3:2] ^ nibble_in[1:0];

    //square_sum     = square_gf4(sum_bits);
    square_sum     = {sum_bits[0], sum_bits[1]};

    //scale_h        = scale_N_gf4(nibble_in[1:0]);
    scale_h        = {nibble_in[0], nibble_in[1] ^ nibble_in[0]};

    //square_scale_h = square_gf4(scale_h);
    square_scale_h = {scale_h[0], scale_h[1]};

    square_scale_gf16_o = {square_sum, square_scale_h};
    
end
    
endmodule