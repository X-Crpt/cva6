module inverse_affine_transformation_addition
#(
    parameter int          X_ID_WIDTH      =  4  // Width of ID field.
) (
    input  logic [7:0]  byte_in,
    output logic [7:0]  byte_out    
);

logic [7:0] im;

always_comb 
begin : inverse_affine_transformation_addition
    im[7] = byte_in[7] ^ 0;
    im[6] = byte_in[6] ^ 0;
    im[5] = byte_in[5] ^ 0;
    im[4] = byte_in[4] ^ 0;
    im[3] = byte_in[3] ^ 0;
    im[2] = byte_in[2] ^ 1;
    im[1] = byte_in[1] ^ 0;
    im[0] = byte_in[0] ^ 1;

    byte_out = im;
    
end
    
endmodule