module affine_transformation_addition
#(
    parameter int          X_ID_WIDTH      =  4  // Width of ID field.
) (
    input  logic [7:0]  byte_in,
    output logic [7:0]  byte_out    
);

logic [7:0] affine_transformation_addition;

always_comb 
begin : AFFINE_TRASFORMATION_ADDITION
    affine_transformation_addition[7] = byte_in[7] ^ 0;
    affine_transformation_addition[6] = byte_in[6] ^ 1;
    affine_transformation_addition[5] = byte_in[5] ^ 1;
    affine_transformation_addition[4] = byte_in[4] ^ 0;
    affine_transformation_addition[3] = byte_in[3] ^ 0;
    affine_transformation_addition[2] = byte_in[2] ^ 0;
    affine_transformation_addition[1] = byte_in[1] ^ 1;
    affine_transformation_addition[0] = byte_in[0] ^ 1;

end

assign byte_out = affine_transformation_addition;    

endmodule