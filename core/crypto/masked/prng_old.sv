// Author: Alessandra Dolmeta {alessandra.dolmeta@polito.it}
// Company: PoliTO - Telsy S.p.A.
// Date: 03-Febraury-2025
// Project: SERICS-SANDSTORM


module prng (
    input  logic        clk,      // Clock input
    input  logic        rst,      // Reset input (active high)
    input  logic        init_i, 
    input  logic        en_i,       // Enable input
    input  logic [127:0]  seed_i,    // 128-bit seed
    output logic [143:0]  prng_o // 64-bit pseudo-random output
);

    logic [127:0] seed1, seed2;
    logic [127:0] feedback_q1, feedback_q2;
    logic [127:0] result_ghash1, result_ghash2;
    logic enable_ghash;

    always_comb begin
      if (rst) begin
            seed1       = 0;  
        end else if (init_i) begin
            seed1       = seed_i;
        end else if (en_i) begin
            seed1       = seed_i;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            seed1         <= 128'b0;
            seed2         <= 128'b0;
            feedback_q1   <= 128'b0;
            feedback_q2   <= 128'b0;
            enable_ghash  <= 1'b0;
        end else if (init_i) begin
            seed1         <= seed_i;
            seed2         <= seed1;
            feedback_q1   <= seed_i;
            feedback_q2   <= feedback_q1;
            enable_ghash <= 1'b1;
        end else if (en_i) begin
            seed1         <= seed1;
            seed2         <= seed2;
            feedback_q1   <= result_ghash1;
            feedback_q2   <= result_ghash2;
            enable_ghash <= 1'b1;
        end else begin
            // No init, no enable => keep the old feedback, or do something else
            seed1         <= seed1;
            seed2         <= seed2;
            feedback_q1   <= feedback_q1; 
            feedback_q2   <= feedback_q2; 
            enable_ghash <= 1'b0;
        end
    end


    ghash ghash_i1 (
        .x(seed1),
        .y(feedback_q1),
        .enable_i(enable_ghash),
        .res(result_ghash1)
    );

    ghash ghash_i2 (
        .x(seed2),
        .y(feedback_q2),
        .enable_i(enable_ghash),
        .res(result_ghash2)
    );

    assign prng_o = {result_ghash1, result_ghash2[15:0]};

endmodule