// Copyright 2024 Thales DIS France SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Guillaume Chauvon

module instr_decoder #(
    parameter type               copro_issue_resp_t          = logic,
    parameter type               opcode_t                    = logic,
    parameter int                NbInstr                     = 1,
    parameter copro_issue_resp_t CoproInstr        [NbInstr] = {0},
    parameter int unsigned       NrRgprPorts                 = 2,
    parameter type               hartid_t                    = logic,
    parameter type               id_t                        = logic,
    parameter type               x_issue_req_t               = logic,
    parameter type               x_issue_resp_t              = logic,
    parameter type               x_register_t                = logic,
    parameter type               registers_t                 = logic
) (
    input  logic                clk_i,
    input  logic                rst_ni,
    input  logic                issue_valid_i,
    input  x_issue_req_t        issue_req_i,
    output logic                issue_ready_o,
    output x_issue_resp_t       issue_resp_o,
    input  logic                register_valid_i,
    input  x_register_t         register_i,
    output registers_t          registers_o,
    output opcode_t             opcode_o,
    output hartid_t             hartid_o,
    output id_t                 id_o,
    output logic          [4:0] rd_o
);

  logic [NbInstr-1:0] sel;
  logic rs1_ready;
  logic rs2_ready;
  logic rs3_ready;

  for (genvar i = 0; i < NbInstr; i++) begin : gen_predecoder_selector
    assign sel[i] = ((CoproInstr[i].mask & issue_req_i.instr) == CoproInstr[i].instr);
  end

  always_comb begin
    rs1_ready                  = '0;
    rs2_ready                  = '0;
    rs3_ready                  = '0;
    issue_ready_o              = '0;
    issue_resp_o.accept        = '0;
    issue_resp_o.writeback     = '0;
    issue_resp_o.register_read = '0;
    registers_o                = '0;
    opcode_o                   = opcode_t'(0);  // == ILLEGAL see cvxif_instr_pkg.sv
    hartid_o                   = '0;
    id_o                       = '0;
    rd_o                       = '0;
    for (int unsigned i = 0; i < NbInstr; i++) begin
      if (sel[i] && issue_valid_i) begin
        issue_resp_o.accept = CoproInstr[i].resp.accept;
        issue_resp_o.writeback = CoproInstr[i].resp.writeback;
        issue_resp_o.register_read = CoproInstr[i].resp.register_read; // Warning :  potential 3 bits vector into 2 bits one
        if (issue_resp_o.accept) begin
          rs1_ready = (~CoproInstr[i].resp.register_read[0] || register_i.rs_valid[0]);
          rs2_ready = (~CoproInstr[i].resp.register_read[1] || register_i.rs_valid[1]);
          rs3_ready = NrRgprPorts == 3 ? (~CoproInstr[i].resp.register_read[2] || register_i.rs_valid[2]) : 1'b1;
          issue_ready_o = rs1_ready && rs2_ready && rs3_ready;
        end
        opcode_o = CoproInstr[i].opcode;
        id_o     = issue_req_i.id;
        hartid_o = issue_req_i.hartid;
        rd_o     = issue_req_i.instr[11:7];
        for (int unsigned j = 0; j < NrRgprPorts; j++) begin
          registers_o[j] = issue_resp_o.register_read[j] ? register_i.rs[j] : '0;
        end
      end
    end
    // Coprocessor could not decode offloaded instruction -> instruction is not accepted
    if (issue_valid_i && ~(|sel)) begin
      issue_ready_o = 1'b1;
    end
  end

  //  logic temp_issue_ready;
  //  logic temp_accept;
  //  logic temp_writeback;
  //  logic [2:0] temp_register_read;
  //  registers_t temp_registers;
  //  opcode_t temp_opcode;
  //  hartid_t temp_hartid;
  //  id_t temp_id;
  //  logic [4:0] temp_rd;
//
  //  always_comb begin
  //    rs1_ready                  = '0;
  //    rs2_ready                  = '0;
  //    rs3_ready                  = '0;
  //    // Default values for temporary signals
  //    temp_issue_ready = '0;
  //    temp_accept = '0;
  //    temp_writeback = '0;
  //    temp_register_read = '0;
  //    temp_registers = '0;
  //    temp_opcode = opcode_t'(0);  // ILLEGAL
  //    temp_hartid = '0;
  //    temp_id = '0;
  //    temp_rd = '0;
//
  //    // Process logic
  //    for (int unsigned i = 0; i < NbInstr; i++) begin
  //      if (sel[i] && issue_valid_i) begin
  //        temp_accept = CoproInstr[i].resp.accept;
  //        temp_writeback = CoproInstr[i].resp.writeback;
  //        temp_register_read = CoproInstr[i].resp.register_read;
//
  //        if (temp_accept) begin
  //          rs1_ready = (~CoproInstr[i].resp.register_read[0] || register_i.rs_valid[0]);
  //          rs2_ready = (~CoproInstr[i].resp.register_read[1] || register_i.rs_valid[1]);
  //          rs3_ready = NrRgprPorts == 3 ? (~CoproInstr[i].resp.register_read[2] || register_i.rs_valid[2]) : 1'b1;
  //          temp_issue_ready = rs1_ready && rs2_ready && rs3_ready;
  //        end
//
  //        temp_opcode = CoproInstr[i].opcode;
  //        temp_id = issue_req_i.id;
  //        temp_hartid = issue_req_i.hartid;
  //        temp_rd = issue_req_i.instr[11:7];
//
  //        for (int unsigned j = 0; j < NrRgprPorts; j++) begin
  //          temp_registers[j] = temp_register_read[j] ? register_i.rs[j] : '0;
  //        end
  //      end
  //    end
//
  //    // Instruction not accepted
  //    if (issue_valid_i && ~(|sel)) begin
  //      temp_issue_ready = 1'b1;
  //    end
//
  //    // Pass temporary values to pipeline input
  //    issue_ready_n = temp_issue_ready;
  //    issue_resp_n.accept = temp_accept;
  //    issue_resp_n.writeback = temp_writeback;
  //    issue_resp_n.register_read = temp_register_read;
  //    registers_n = temp_registers;
  //    opcode_n = temp_opcode;
  //    hartid_n = temp_hartid;
  //    id_n = temp_id;
  //    rd_n = temp_rd;
  //  end
//
  //// Pipeline registers
  //logic issue_ready_n, issue_ready_q1, issue_ready_q2, issue_ready_q3;
  //x_issue_resp_t issue_resp_n, issue_resp_q1, issue_resp_q2, issue_resp_q3;
  //registers_t registers_n, registers_q1, registers_q2, registers_q3;
  //opcode_t opcode_n, opcode_q1, opcode_q2, opcode_q3;
  //hartid_t hartid_n, hartid_q1, hartid_q2, hartid_q3;
  //id_t id_n, id_q1, id_q2, id_q3;
  //logic [4:0] rd_n, rd_q1, rd_q2, rd_q3;
//
  //always_ff @(posedge clk_i, negedge rst_ni) begin
  //  if (~rst_ni) begin
  //    // Reset pipeline stages
  //    issue_ready_q1 <= '0; issue_ready_q2 <= '0; issue_ready_q3 <= '0;
  //    issue_resp_q1.accept <= '0; issue_resp_q2.accept <= '0; issue_resp_q3.accept <= '0;
  //    issue_resp_q1.writeback <= '0; issue_resp_q2.writeback <= '0; issue_resp_q3.writeback <= '0;
  //    issue_resp_q1.register_read <= '0; issue_resp_q2.register_read <= '0; issue_resp_q3.register_read <= '0;
  //    registers_q1 <= '0; registers_q2 <= '0; registers_q3 <= '0;
  //    opcode_q1 <= opcode_t'(0); opcode_q2 <= opcode_t'(0); opcode_q3 <= opcode_t'(0);
  //    hartid_q1 <= '0; hartid_q2 <= '0; hartid_q3 <= '0;
  //    id_q1 <= '0; id_q2 <= '0; id_q3 <= '0;
  //    rd_q1 <= '0; rd_q2 <= '0; rd_q3 <= '0;
  //  end else begin
  //    // Pipeline stage 1
  //    issue_ready_q1 <= issue_ready_n;
  //    issue_resp_q1 <= issue_resp_n;
  //    registers_q1 <= registers_n;
  //    opcode_q1 <= opcode_n;
  //    hartid_q1 <= hartid_n;
  //    id_q1 <= id_n;
  //    rd_q1 <= rd_n;
//
  //    // Pipeline stage 2
  //    issue_ready_q2 <= issue_ready_q1;
  //    issue_resp_q2 <= issue_resp_q1;
  //    registers_q2 <= registers_q1;
  //    opcode_q2 <= opcode_q1;
  //    hartid_q2 <= hartid_q1;
  //    id_q2 <= id_q1;
  //    rd_q2 <= rd_q1;
//
  //    // Pipeline stage 3
  //    issue_ready_q3 <= issue_ready_q2;
  //    issue_resp_q3 <= issue_resp_q2;
  //    registers_q3 <= registers_q2;
  //    opcode_q3 <= opcode_q2;
  //    hartid_q3 <= hartid_q2;
  //    id_q3 <= id_q2;
  //    rd_q3 <= rd_q2;
  //  end
  //end
//
  //// Assign outputs to the last stage of the pipeline
  //assign issue_ready_o = issue_ready_q3;
  //assign issue_resp_o = issue_resp_q3;
  //assign registers_o = registers_q3;
  //assign opcode_o = opcode_q3;
  //assign hartid_o = hartid_q3;
  //assign id_o = id_q3;
  //assign rd_o = rd_q3;


  assert property (@(posedge clk_i) $onehot0(sel))
  else $warning("This offloaded instruction is valid for multiple coprocessor instructions !");

endmodule
