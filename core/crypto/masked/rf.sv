module rf (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic [4:0]  addr_i,      // Address for read/write
    input  logic [63:0] input0_i,    // Input data 1
    input  logic [63:0] input1_i,    // Input data 2
    input  logic [63:0] input2_i,
    input  logic [63:0] input3_i,
    input  logic        random_i,
    input  logic        add_round_key_i,
    input  logic        unmasking_i, 
    input  logic        aes_round_i,
    input  logic        aes_key_exp_ks1_i,
    input  logic        aes_key_exp_ks2_i,
    input  logic        write_en_i,  // Enable signal for writing
    input  logic        read_en_i,   // Enable signal for reading
    output logic [63:0] aes_comb_out0_o,
    output logic [63:0] aes_comb_out1_o,
    output logic [63:0] aes_comb_out2_o,
    output logic [63:0] aes_comb_out3_o,
    output logic [63:0] output_o     // Output data
);

    parameter NUM_REGS = 14;  // 14 registers
    
    logic [63:0] register_array [0:NUM_REGS-1];
    logic [3:0] addr_1a, addr_2a, addr_3a, addr_4a;
    logic [3:0] addr_1b, addr_2b, addr_3b, addr_4b;

    logic [63:0] temp1, temp2, temp3, temp4;
    logic aes64ks2_first;

    always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)
        aes64ks2_first <= 1'b0; // Initialize to 0 on reset
    else if (aes_key_exp_ks2_i)
        aes64ks2_first <= ~aes64ks2_first; // Toggle when aes_key_exp_ks2_i is 1
    end

    //Synchronous read - combinatorial 
    always_comb begin
      begin
        addr_1a = 0;
        addr_2a = 0;
        addr_3a = 0;
        addr_4a = 0;

        addr_1b = 0;
        addr_2b = 0;
        addr_3b = 0;
        addr_4b = 0;

        if (write_en_i && random_i) begin
            addr_1a = addr_i;
            addr_2a = addr_i + 1;
            addr_3a = addr_i + 2;
            addr_4a = addr_i + 3;

        end else if (write_en_i && (add_round_key_i || unmasking_i)) begin
            addr_1a = input0_i[3:0];
            addr_2a = input0_i[3:0] + 1;
            addr_3a = input0_i[3:0] + 2;
            addr_4a = input0_i[3:0] + 3;
            
            addr_1b = input1_i[3:0];
            addr_2b = input1_i[3:0] + 1;
            addr_3b = input1_i[3:0] + 2;
            addr_4b = input1_i[3:0] + 3;
        

        end else if (read_en_i && aes_round_i) begin
            addr_1a = input1_i[3:0];
            addr_2a = input1_i[3:0] + 1;
            addr_3a = input0_i[3:0];

            addr_1b = input1_i[3:0] + 2;
            addr_2b = input1_i[3:0] + 3;
            
        end else if (read_en_i && aes_key_exp_ks1_i) begin
            addr_1a = input0_i[3:0];
            addr_2a = input0_i[3:0] + 2;

        end else if (read_en_i && aes_key_exp_ks2_i) begin
            addr_1a = input0_i[3:0];
            addr_2a = input1_i[3:0];

            if (aes64ks2_first) begin
                addr_1b = input0_i[3:0] + 2;
            end else begin
                addr_1b = input0_i[3:0] + 1;
            end 
            addr_2b = input1_i[3:0] + 2;

        end
      end
    end

    // Synchronous write - next clock cycles, of 6-clock cycle after
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (write_en_i && ~random_i &&  ~add_round_key_i && ~unmasking_i && ~aes_round_i && ~aes_key_exp_ks1_i && ~aes_key_exp_ks2_i) begin
            register_array[addr_i]      <= input0_i;
            register_array[addr_i + 1]  <= input1_i;

        end else if (write_en_i && random_i) begin
            register_array[addr_1a] <= register_array[addr_1a] ^ input1_i; 
            register_array[addr_2a] <= register_array[addr_2a] ^ input2_i;
            register_array[addr_3a] <= input1_i;
            register_array[addr_4a] <= input2_i;

        end else if (write_en_i && add_round_key_i) begin
            register_array[addr_1b] <= register_array[addr_1a] ^ register_array[6]; 
            register_array[addr_2b] <= register_array[addr_2a] ^ register_array[7]; 
            register_array[addr_3b] <= register_array[addr_3a] ^ register_array[8]; 
            register_array[addr_4b] <= register_array[addr_4a] ^ register_array[9]; 

        end else if (write_en_i && unmasking_i) begin
            register_array[addr_1a] <= register_array[addr_1a] ^ register_array[addr_1b]; 
            register_array[addr_2a] <= register_array[addr_2a] ^ register_array[addr_2b]; 

        end else if (write_en_i && aes_round_i) begin     
            register_array[addr_2a] <= register_array[addr_1a];
            register_array[addr_1a] <= register_array[addr_2a];
            register_array[addr_2b] <= register_array[addr_1b];
            register_array[addr_1b] <= register_array[addr_2b];

        end else if (write_en_q5 && aes_round_q5) begin    
            register_array[input0_q5]      <= input2_i; 
            register_array[input0_q5 + 2 ] <= input3_i; 

        end else if (write_en_q5 && aes_key_exp_ks1_q5) begin
            register_array[input1_q5]     <= input2_i;
            register_array[input1_q5 + 1] <= input3_i;
        
        end else if (write_en_i && aes_key_exp_ks2_i) begin
            register_array[addr_2a] <= input2_i;
            register_array[addr_2b] <= input3_i;
        end 
    end


    logic [3:0] input0_q1, input0_q2, input0_q3, input0_q4, input0_q5;
    logic [3:0] input1_q1, input1_q2, input1_q3, input1_q4, input1_q5;
    logic write_en_q1, write_en_q2, write_en_q3, write_en_q4, write_en_q5;
    logic aes_key_exp_ks1_q1, aes_key_exp_ks1_q2, aes_key_exp_ks1_q3, aes_key_exp_ks1_q4, aes_key_exp_ks1_q5;
    logic aes_round_q1, aes_round_q2, aes_round_q3, aes_round_q4, aes_round_q5;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            // Reset all pipeline stages
            input0_q1 <= '0;  input1_q1 <= '0; 
            write_en_q1 <= '0;  aes_key_exp_ks1_q1 <= '0;  aes_round_q1 <= '0;

            input0_q2 <= '0;  input1_q2 <= '0;  
            write_en_q2 <= '0;  aes_key_exp_ks1_q2 <= '0;  aes_round_q2 <= '0;

            input0_q3 <= '0;  input1_q3 <= '0;
            write_en_q3 <= '0; aes_key_exp_ks1_q3 <= '0;  aes_round_q3 <= '0;

            input0_q4 <= '0;  input1_q4 <= '0;  
            write_en_q4 <= '0;  aes_key_exp_ks1_q4 <= '0;  aes_round_q4 <= '0;

            input0_q5 <= '0;  input1_q5 <= '0; 
            write_en_q5 <= '0; aes_key_exp_ks1_q5 <= '0;  aes_round_q5 <= '0;

        end
        else begin
            // Pipeline stage 1
            input0_q1           <= input0_i[3:0];
            input1_q1           <= input1_i[3:0];
            write_en_q1         <= write_en_i;
            aes_key_exp_ks1_q1  <= aes_key_exp_ks1_i;
            aes_round_q1        <= aes_round_i;

            // Pipeline stage 2
            input0_q2          <= input0_q1;
            input1_q2          <= input1_q1;
            write_en_q2        <= write_en_q1;
            aes_key_exp_ks1_q2 <= aes_key_exp_ks1_q1;
            aes_round_q2       <= aes_round_q1;

            // Pipeline stage 3
            input0_q3          <= input0_q2;
            input1_q3          <= input1_q2;
            write_en_q3        <= write_en_q2;
            aes_key_exp_ks1_q3 <= aes_key_exp_ks1_q2;
            aes_round_q3       <= aes_round_q2;

            // Pipeline stage 4
            input0_q4          <= input0_q3;
            input1_q4          <= input1_q3;
            write_en_q4        <= write_en_q3;
            aes_key_exp_ks1_q4 <= aes_key_exp_ks1_q3;
            aes_round_q4       <= aes_round_q3;

            // Pipeline stage 5
            input0_q5          <= input0_q4;
            input1_q5          <= input1_q4;
            write_en_q5        <= write_en_q4;
            aes_key_exp_ks1_q5 <= aes_key_exp_ks1_q4;
            aes_round_q5       <= aes_round_q4;
        end
    end


    // Read logic
    always_comb begin
        if (read_en_i) begin
            output_o        = register_array[addr_i];
            aes_comb_out0_o = register_array[addr_1a];
            aes_comb_out1_o = register_array[addr_2a];
            aes_comb_out2_o = register_array[addr_1b];
            aes_comb_out3_o = register_array[addr_2b];
        end else begin
            output_o        = 64'b0;
            aes_comb_out0_o = 64'b0;
            aes_comb_out1_o = 64'b0;
            aes_comb_out2_o = 64'b0;
            aes_comb_out3_o = 64'b0;
        end
    end

endmodule
