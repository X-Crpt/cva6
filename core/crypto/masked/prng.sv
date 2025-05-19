// Author: Alessandra Dolmeta {alessandra.dolmeta@polito.it}, Davide Bellizia
// {davide.bellizia@telsy.it}:w
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


    Bivium #(
	.output_bits(144)	    
    ) stream_i (
	.clk(clk),
	.rst(rst),
	.init(init_i),
	.en(en_i),
	.key(seed_i[79:0]),
	.iv({{32{1'b1}},seed_i[127:80]}),
	.stream_out(prng_o)
    );

endmodule
