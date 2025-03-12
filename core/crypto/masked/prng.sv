// Author: Alessandra Dolmeta {alessandra.dolmeta@polito.it}
// Company: PoliTO - Telsy S.p.A.
// Date: 03-Febraury-2025
// Project: SERICS-SANDSTORM


module simple_prng (
    input  logic        clk,      // Clock input
    input  logic        rst,      // Reset input (active high)
    input  logic        init_i, 
    input  logic        en_i,       // Enable input
    input  logic [127:0] seed_i,    // 128-bit seed
    output logic [127:0]  prng_o // 64-bit pseudo-random output
);

    logic [127:0] lfsr;

    always_comb begin
      if (rst) begin
            lfsr <= 0;  
        end else if (init_i) begin
            lfsr <= seed_i;
        end else if (en_i) begin
            lfsr <= {lfsr[126:0], lfsr[127] ^ lfsr[63] ^ lfsr[31] ^ lfsr[0]};
        end
    end

    //always_ff @(posedge clk or posedge rst) begin
    //    if (rst) begin
    //        lfsr <= 0;  
    //    end else if (init_i) begin
    //        lfsr <= seed_i;
    //    end else if (en_i) begin
    //        lfsr <= {lfsr[126:0], lfsr[127] ^ lfsr[63] ^ lfsr[31] ^ lfsr[0]};
    //    end
    //end

    assign prng_o = lfsr;

endmodule