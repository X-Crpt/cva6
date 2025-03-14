module rf (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic [3:0]  addr_i,      // Address for read/write
    input  logic [63:0] input0_i,    // Input data 1
    input  logic [63:0] input1_i,    // Input data 2
    input  logic [63:0] input2_i,
    input  logic        random_i,
    input  logic        add_round_key_i,
    input  logic        aes_round_i,
    input  logic        aes_key_exp_i,
    input  logic        write_en_i,  // Enable signal for writing
    input  logic        read_en_i,   // Enable signal for reading
    output logic [63:0] aes_comb_out0_o,
    output logic [63:0] aes_comb_out1_o,
    output logic [63:0] output_o     // Output data
);

    parameter NUM_REGS = 16;  // 16 registers
    
    logic [63:0] register_array [0:NUM_REGS-1];
    logic [4:0] addr_1a, addr_2a, addr_3a, addr_4a;
    logic [4:0] addr_1b, addr_2b, addr_3b, addr_4b;

    logic [63:0] temp1, temp2, temp3, temp4;


    always_comb begin
      begin
        if (write_en_i && random_i) begin
            addr_1a <= addr_i;
            addr_2a <= addr_i + 1;
            addr_3a <= addr_i + 2;
            addr_4a <= addr_i + 3;

        end else if (write_en_i && add_round_key_i) begin
            addr_1a <= input0_i[4:0];
            addr_2a <= input0_i[4:0] + 1;
            addr_3a <= input0_i[4:0] + 2;
            addr_4a <= input0_i[4:0] + 3;
            addr_1b <= input1_i[4:0];
            addr_2b <= input1_i[4:0] + 1;
            addr_3b <= input1_i[4:0] + 2;
            addr_4b <= input1_i[4:0] + 3;

        end else if (read_en_i && aes_round_i) begin
            addr_1a <= input1_i[4:0];
            addr_2a <= input1_i[4:0] + 1;
            addr_3a <= input0_i[4:0];

        end else if (read_en_i && aes_key_exp_i) begin
            addr_1a <= input0_i[4:0];
            addr_2a <= input1_i[4:0];

        end else begin
            addr_1a <= 0;
            addr_2a <= 0;
        end
      end
    end

    // Synchronous write
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            register_array <= '{default: '0}; // Reset all registers to 0
        end else if (write_en_i && ~random_i &&  ~add_round_key_i && ~aes_round_i && ~aes_key_exp_i) begin
            register_array[addr_i]     <= {input0_i[7:0], input0_i[15:8], input0_i[23:16], input0_i[31:24], 
                                            input0_i[39:32], input0_i[47:40], input0_i[55:48], input0_i[63:56]};
            register_array[addr_i + 1] <= {input1_i[7:0], input1_i[15:8], input1_i[23:16], input1_i[31:24], 
                                            input1_i[39:32], input1_i[47:40], input1_i[55:48], input1_i[63:56]};

        end else if (write_en_i && random_i) begin
            register_array[addr_1a] <= register_array[addr_1a] ^ input1_i; 
            register_array[addr_2a] <= register_array[addr_2a] ^ input2_i;
            register_array[addr_3a] <= input1_i;
            register_array[addr_4a] <= input2_i;

        end else if (write_en_i && add_round_key_i) begin
            register_array[addr_1a] <= register_array[addr_1a] ^ register_array[addr_1b]; 
            register_array[addr_2a] <= register_array[addr_2a] ^ register_array[addr_2b]; 
            register_array[addr_3a] <= register_array[addr_3a] ^ register_array[addr_3b]; 
            register_array[addr_4a] <= register_array[addr_4a] ^ register_array[addr_4b]; 

        end else if (write_en_i && aes_round_i) begin    
            register_array[addr_3a] <= input2_i; 
            
            register_array[addr_2a] <= register_array[addr_1a];
            register_array[addr_1a] <= register_array[addr_2a];

        end else if (write_en_i && aes_key_exp_i) begin
            register_array[addr_2a] <= input2_i;

        end 
    end

    // Read logic
    always_comb begin
        if (read_en_i) begin
            output_o        = register_array[addr_i];
            aes_comb_out0_o = register_array[addr_1a];
            aes_comb_out1_o = register_array[addr_2a];
        end else begin
            output_o        = 64'b0;
            aes_comb_out0_o = 64'b0;
            aes_comb_out1_o = 64'b0;
        end
    end

endmodule