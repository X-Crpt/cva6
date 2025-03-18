`timescale 1ns/1ps

module tb_dom_sbox;

  // Parameter from the DUT
  parameter X_ID_WIDTH = 4;

  // Testbench signals
  logic                 clk_i;
  logic                 rst_n;
  logic                 valid_i;
  logic [7:0]           shareA_in;
  logic [7:0]           shareB_in;
  logic [17:0]          randombits_i;

  // DUT outputs
  logic                 ready_for_sbox_i;
  logic                 valid_o;
  logic [7:0]           shareA_out;
  logic [7:0]           shareB_out;

  // Instantiate the DUT
  dom_sbox #(
    .X_ID_WIDTH(X_ID_WIDTH)
  ) dut (
    .clk_i            (clk_i),
    .rst_n            (rst_n),
    .valid_i          (valid_i),
    .ready_for_sbox_i (ready_for_sbox_i),

    .shareA_in        (shareA_in),
    .shareB_in        (shareB_in),
    .randombits_i     (randombits_i),

    .valid_o          (valid_o),
    .ready_for_sbox_o (ready_for_sbox_o),
    .shareA_out       (shareA_out),
    .shareB_out       (shareB_out)
  );

  // Clock generation
  initial clk_i = 1'b0;
  always #5 clk_i = ~clk_i;

  // Test sequence
  initial begin
    // Initial values
    rst_n         = 1'b0;
    valid_i       = 1'b0;
    shareA_in     = 8'hFB;  // as requested
    shareB_in     = 8'h34;  // as requested
    randombits_i  = 18'h0;  // all zeros as requested

    // Release reset after a few clock cycles
    repeat (2) @(posedge clk_i);
    rst_n = 1'b1;

    // Wait 1 cycle, then start toggling inputs for 6 cycles
    @(posedge clk_i);

    // Cycle 1
    valid_i       <= 1'b1;

    @(posedge clk_i);

    // Cycle 2
    valid_i       <= 1'b0;

    @(posedge clk_i);

    // Cycle 3
    valid_i       <= 1'b0;

    @(posedge clk_i);

    // Cycle 4

    @(posedge clk_i);

    // Cycle 5


    @(posedge clk_i);

    // Cycle 6

    @(posedge clk_i);

    // Wrap up

    // Wait a few cycles to observe outputs
    repeat (3) @(posedge clk_i);

    // End simulation
    $finish;
  end

endmodule
