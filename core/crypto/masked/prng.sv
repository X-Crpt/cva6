// Author: Alessandra Dolmeta {alessandra.dolmeta@polito.it}
// Company: PoliTO - Telsy S.p.A.
// Date: 03-Febraury-2025
// Project: SERICS-SANDSTORM


module prng (
    input  logic        clk,      // Clock input
    input  logic        rst,      // Reset input (active high)
    input  logic        init_i, 
    input  logic        en_i,       // Enable input
    input  logic [127:0] seed_i,    // 128-bit seed
    output logic [127:0]  prng_o // 64-bit pseudo-random output
);

    logic [127:0] lfsr;
    logic [127:0] feedback_q, feedback_d;
    logic [127:0] result_ghash;
    logic enable_ghash;

    always_comb begin
      if (rst) begin
            lfsr       = 0;  
        end else if (init_i) begin
            lfsr       = seed_i;
        end else if (en_i) begin
            lfsr       = seed_i;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            feedback_q   <= 128'b0;
            enable_ghash <= 1'b0;
        end else if (init_i) begin
            feedback_q   <= seed_i;
            enable_ghash <= 1'b1;
        end else if (en_i) begin
            feedback_q   <= result_ghash;
            enable_ghash <= 1'b1;
        end else begin
            // No init, no enable => keep the old feedback, or do something else
            feedback_q   <= feedback_q; 
            enable_ghash <= 1'b0;
        end
    end


    ghash ghash_i (
        .x(lfsr),
        .y(feedback_q),
        .enable_i(enable_ghash),
        .res(result_ghash)
    );

    assign prng_o = result_ghash;

endmodule