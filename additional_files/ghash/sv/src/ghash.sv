module ghash (
    input  wire [127:0] x,
    input  wire [127:0] y,
    output reg  [127:0] res
);

    localparam [127:0] RED_POLY = 128'hE1000000000000000000000000000000;

    integer i;
    reg [127:0] x_reg;
    reg [127:0] result;

    always @(*) begin
        x_reg = x;
        result = 128'b0;

        for (i = 127; i >= 0; i = i - 1) begin
            if (y[i])
                result = result ^ x_reg;

            if (x_reg[0] == 1'b1)
                x_reg = (x_reg >> 1) ^ RED_POLY;
            else
                x_reg = x_reg >> 1;
        end

        res = result;
    end

endmodule
