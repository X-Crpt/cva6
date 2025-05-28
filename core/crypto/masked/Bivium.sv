module Bivium #(
    parameter int OUTPUT_BITS = 64
) (
    input  logic                   clk,
    input  logic                   rst,    // synchronous reset
    input  logic                   en,     // enable shifting
    input  logic                   init,   // load key/iv
    input  logic [79:0]            key,
    input  logic [79:0]            iv,
    output logic [OUTPUT_BITS-1:0] stream_out
);

    // full state width = 177 bits
    localparam int STATE_W = 177;

    // state[0] is the stored register; state[1..OUTPUT_BITS] are
    // the unrolled, combinational stages
    logic [STATE_W-1:0] state [0:OUTPUT_BITS];
    logic [OUTPUT_BITS-1:0] t1, t2;

    //-------------------------------------------------------------------------------
    // Sequential: update state[0] on clock
    //-------------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            state[0] <= '0;
        end
        else if (init) begin
            // {zero, iv, 12'h000, zero, key}
            state[0] <= {1'b0,
                         iv,
                         12'h000,
                         1'b0,
                         key};
        end
        else if (en) begin
            // feedback from the last unrolled stage
            state[0] <= state[OUTPUT_BITS];
        end
    end

    //-------------------------------------------------------------------------------
    // Combinational unrolled “cycles” 1..OUTPUT_BITS
    //-------------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 1; i <= OUTPUT_BITS; i++) begin : MULTIPLE_CYCLES
            always_comb begin
                // taps for the two LFSR registers
                t1[i-1] = state[i-1][65]  ^ state[i-1][92];
                t2[i-1] = state[i-1][161] ^ state[i-1][176];

                // next state of the two registers
                state[i] = {
                    state[i-1][175:93],
                    // new bit for LFSR1: t1 ⊕ (bit90 & bit91) ⊕ bit170
                    t1[i-1] ^ (state[i-1][90] & state[i-1][91]) ^ state[i-1][170],
                    state[i-1][91:0],
                    // new bit for LFSR2: t2 ⊕ (bit174 & bit175) ⊕ bit68
                    t2[i-1] ^ (state[i-1][174] & state[i-1][175]) ^ state[i-1][68]
                };

                // output bit (note reverse indexing to match VHDL)
                stream_out[i-1] = t1[OUTPUT_BITS-i] ^ t2[OUTPUT_BITS-i];
            end
        end
    endgenerate

endmodule
