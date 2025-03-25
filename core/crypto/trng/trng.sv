module trng #(
    parameter NUM_ROS      = 16,      // Number of ring oscillators
    parameter OUTPUT_WIDTH = 156      // Output bitwidth
)(
    input  logic                    clk_i,    // Sampling clock
    input  logic                    rst,      // Async reset (active high)
    input  logic                    init_i,   // Enable sampling from ring oscillators
    input  logic                    en_i,     // Enable conditioning / output update
    output logic [OUTPUT_WIDTH-1:0] out_data  // TRNG output
);

    // ---------------------------------------------------------
    // 1) Ring Oscillator Declaration
    //    Each ring oscillator is a small chain of inverters
    //    arranged in a loop. This minimal example uses 3 inverters.
    // ---------------------------------------------------------
    logic [NUM_ROS-1:0] ro_out;    // Outputs of each ring oscillator

    // Generate multiple ring oscillators
    generate
        genvar i;
        for (i = 0; i < NUM_ROS; i++) begin : ROSC
            ring_oscillator RO_INST (
                .RO_enable     (init_i),
                .random_bit    (ro_out[i])
            );
        end
    endgenerate

    // ---------------------------------------------------------
    // 2) Randomness Sampling Logic
    //    We sample the ring oscillators on each rising edge of clk
    //    if the TRNG is init_i. We store the sampled data in a
    //    shift register (here we just collect them in a register).
    // ---------------------------------------------------------
    logic [NUM_ROS-1:0] ro_sampled;
    always_ff @(posedge clk_i or posedge rst) begin
        if (rst) begin
            ro_sampled <= '0; // Clear on reset
        end else if (init_i) begin
            // Sample ring oscillator outputs
            ro_sampled <= ro_out;
        end
        // If not init_i, ro_sampled holds its value
    end

    // ---------------------------------------------------------
    // 3) Simple Barrel Shifter (Conditioning Circuit)
    //    Each time 'en_i' is 1, rotate/shift the previously
    //    collected bits and mix in the new ring oscillator samples.
    //    This helps "spread" the entropy. For demonstration, we
    //    show a simple rotate-by-N approach to produce new data.
    // ---------------------------------------------------------
    logic [OUTPUT_WIDTH-1:0] data_reg;
    always_ff @(posedge clk_i or posedge rst) begin
        if (rst) begin
            data_reg <= '0;
        end else if (en_i) begin
            // Insert new ring oscillator bits in the lower portion,
            // then shift/rotate the older bits for mixing
            // (Choice of shift amount is somewhat arbitrary here.)
            data_reg <= { data_reg[OUTPUT_WIDTH - NUM_ROS - 1 : 0],
                          ro_sampled };
        end
    end

    // ---------------------------------------------------------
    // 4) Assign final output
    //    The top-level 156-bit output is simply the content
    //    of data_reg. You could apply additional post-processing
    //    if desired.
    // ---------------------------------------------------------
    assign out_data = data_reg;

endmodule // trng

