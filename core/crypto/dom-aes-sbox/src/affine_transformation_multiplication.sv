module affine_transformation_multiplication
#(
    parameter int          X_ID_WIDTH      =  4  // Width of ID field.
) (
    input  logic [7:0]  byte_in,
    output logic [7:0]  byte_out    
);

logic [7:0] affine_transformation_multiplication;

always_comb 
begin : affine_transformation_multiplication_process
    affine_transformation_multiplication[7] = byte_in[7] ^ byte_in[6] ^ byte_in[5] ^ byte_in[4] ^ byte_in[3];
    affine_transformation_multiplication[6] = byte_in[6] ^ byte_in[5] ^ byte_in[4] ^ byte_in[3] ^ byte_in[2];
    affine_transformation_multiplication[5] = byte_in[5] ^ byte_in[4] ^ byte_in[3] ^ byte_in[2] ^ byte_in[1];
    affine_transformation_multiplication[4] = byte_in[4] ^ byte_in[3] ^ byte_in[2] ^ byte_in[1] ^ byte_in[0];
    affine_transformation_multiplication[3] = byte_in[7] ^ byte_in[3] ^ byte_in[2] ^ byte_in[1] ^ byte_in[0];
    affine_transformation_multiplication[2] = byte_in[7] ^ byte_in[6] ^ byte_in[2] ^ byte_in[1] ^ byte_in[0];
    affine_transformation_multiplication[1] = byte_in[7] ^ byte_in[6] ^ byte_in[5] ^ byte_in[1] ^ byte_in[0];
    affine_transformation_multiplication[0] = byte_in[7] ^ byte_in[6] ^ byte_in[5] ^ byte_in[4] ^ byte_in[0];
    
end

assign byte_out = affine_transformation_multiplication;

endmodule