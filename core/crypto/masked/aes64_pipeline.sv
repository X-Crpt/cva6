module aes64_pipeline 
    #(
    parameter int unsigned       NrRgprPorts                 = 2,
    parameter int unsigned       XLEN                        = 64,
    parameter type               hartid_t                    = logic,
    parameter type               id_t                        = logic,
    parameter type               registers_t                 = logic
  ) 
(
    input logic clk,
    input logic reset,
    input logic [XLEN-1:0] result_in,     
    input hartid_t hartid_in,             
    input id_t id_in,                     
    input logic valid_in,                 
    input logic [4:0] rd_in,              
    input logic we_in,                    
    
    output logic [XLEN-1:0] result_out,   
    output hartid_t hartid_out,    
    output id_t id_out,        
    output logic valid_out,               
    output logic [4:0] rd_out,                  
    output logic we_out                   
);

    // Define the pipeline registers
    logic [XLEN-1:0] result_reg [5:0];
    hartid_t hartid_reg [5:0];
    id_t id_reg [5:0];
    logic valid_reg [5:0];
    logic [4:0] rd_reg [5:0];
    logic we_reg [5:0];

    // Stage 0 is the input stage, and stages 1 to 5 are the pipeline stages
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all pipeline registers
            result_reg[0] <= 0;
            hartid_reg[0] <= 0;
            id_reg[0] <= 0;
            valid_reg[0] <= 0;
            rd_reg[0] <= 0;
            we_reg[0] <= 0;
        end else begin
            // Propagate the signals through the pipeline
            result_reg[0] <= result_in;
            hartid_reg[0] <= hartid_in;
            id_reg[0] <= id_in;
            valid_reg[0] <= valid_in;
            rd_reg[0] <= rd_in;
            we_reg[0] <= we_in;

            // Shift the registers
            for (int i = 1; i < 6; i = i + 1) begin
                result_reg[i] <= result_reg[i-1];
                hartid_reg[i] <= hartid_reg[i-1];
                id_reg[i] <= id_reg[i-1];
                valid_reg[i] <= valid_reg[i-1];
                rd_reg[i] <= rd_reg[i-1];
                we_reg[i] <= we_reg[i-1];
            end
        end
    end

    // Output the final pipeline value (stage 5)
    always @(*) begin
        result_out = result_reg[5];
        hartid_out = hartid_reg[5];
        id_out = id_reg[5];
        valid_out = valid_reg[5];
        rd_out = rd_reg[5];
        we_out = we_reg[5];
    end
endmodule
