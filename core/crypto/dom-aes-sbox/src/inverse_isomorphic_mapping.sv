module inverse_isomorphic_mapping
#(
    parameter int          X_ID_WIDTH      =  4  // Width of ID field.
) (
    input  logic [7:0]  byte_in,
    output logic [7:0]  byte_out    
);

logic [7:0] im;

always_comb 
begin : INVERSE_ISOMORPHIC_MAPPING
    im[7] = byte_in[4] ^ byte_in[1];
    im[6] = byte_in[7] ^ byte_in[6] ^ byte_in[5] ^ byte_in[3] ^ byte_in[1] ^ byte_in[0];
    im[5] = byte_in[7] ^ byte_in[6] ^ byte_in[5] ^ byte_in[3] ^ byte_in[2] ^ byte_in[0];
    im[4] = byte_in[6] ^ byte_in[1];
    im[3] = byte_in[6] ^ byte_in[5] ^ byte_in[4] ^ byte_in[3] ^ byte_in[2] ^ byte_in[1];
    im[2] = byte_in[7] ^ byte_in[5] ^ byte_in[4] ^ byte_in[1];
    im[1] = byte_in[5] ^ byte_in[1];
    im[0] = byte_in[2];

    byte_out = im;
    
end
    
endmodule