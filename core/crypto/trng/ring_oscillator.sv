module ring_oscillator #(parameter int unsigned RO_LENGTH = 16)
   (
     input  logic                     RO_enable,
     output logic                     random_bit       
   );
    
    (* keep = "true" *) logic[RO_LENGTH - 1 : 0] out_inv;
        
    genvar i;
    generate
        for (i = 0; i < RO_LENGTH; i++) begin
             (* keep = "true" *) inv inv_i( 
                .in((i == 0)? (out_inv[RO_LENGTH - 1] | RO_enable) : out_inv[i-1]),   
                .out(out_inv[i])
                ); /* synthesis keep */  
        
        end
    endgenerate 

    assign random_bit = out_inv[RO_LENGTH - 1];


endmodule : ring_oscillator

