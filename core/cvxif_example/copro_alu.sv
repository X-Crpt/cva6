// Copyright 2024 Thales DIS France SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Guillaume Chauvon

// Modified by: Alessandra Dolmeta

module copro_alu
  import cvxif_instr_pkg::*;
#(
    parameter int unsigned NrRgprPorts = 2,
    parameter int unsigned XLEN = 32,
    parameter type hartid_t = logic,
    parameter type id_t = logic,
    parameter type registers_t = logic

) (
    input  logic                  clk_i,
    input  logic                  rst_ni,
    input  registers_t            registers_i,
    input  opcode_t               opcode_i,
    input  hartid_t               hartid_i,
    input  id_t                   id_i,
    input  logic       [     4:0] rd_i,
    output logic       [XLEN-1:0] result_o,
    output hartid_t               hartid_o,
    output id_t                   id_o,
    output logic       [     4:0] rd_o,
    output logic                  valid_o,
    output logic                  we_o
);

  logic [XLEN-1:0] result_n, result_q;
  hartid_t hartid_n, hartid_q;
  id_t id_n, id_q;
  logic valid_n, valid_q;
  logic [4:0] rd_n, rd_q;
  logic we_n, we_q;


  always_comb begin
    case (opcode_i)
      cvxif_instr_pkg::NOP: begin
        result_n = '0;
        hartid_n = hartid_i;
        id_n     = id_i;
        valid_n  = 1'b1;
        rd_n     = '0;
        we_n     = '0;
      end
      cvxif_instr_pkg::ADD: begin
        result_n = registers_i[1] + registers_i[0];
        hartid_n = hartid_i;
        id_n     = id_i;
        valid_n  = 1'b1;
        rd_n     = rd_i;
        we_n     = 1'b1;
      end

      //------AD: new custom instruction---------------------
      cvxif_instr_pkg::XOR: begin
        result_n = registers_i[1] ^ registers_i[0];
        hartid_n = hartid_i;
        id_n     = id_i;
        valid_n  = 1'b1;
        rd_n     = rd_i;
        we_n     = 1'b1;
      end
      cvxif_instr_pkg::AND: begin
        result_n = registers_i[1] & registers_i[0];
        hartid_n = hartid_i;
        id_n     = id_i;
        valid_n  = 1'b1;
        rd_n     = rd_i;
        we_n     = 1'b1;
      end
      cvxif_instr_pkg::OR: begin
        result_n = registers_i[1] | registers_i[0];
        hartid_n = hartid_i;
        id_n     = id_i;
        valid_n  = 1'b1;
        rd_n     = rd_i;
        we_n     = 1'b1;
      end
      //-----------------------------------------------------

      cvxif_instr_pkg::DOUBLE_RS1: begin
        result_n = registers_i[0] + registers_i[0];
        hartid_n = hartid_i;
        id_n     = id_i;
        valid_n  = 1'b1;
        rd_n     = rd_i;
        we_n     = 1'b1;
      end
      cvxif_instr_pkg::DOUBLE_RS2: begin
        result_n = registers_i[1] + registers_i[1];
        hartid_n = hartid_i;
        id_n     = id_i;
        valid_n  = 1'b1;
        rd_n     = rd_i;
        we_n     = 1'b1;
      end
      cvxif_instr_pkg::ADD_MULTI: begin
        result_n = registers_i[1] + registers_i[0];
        hartid_n = hartid_i;
        id_n     = id_i;
        valid_n  = 1'b1;
        rd_n     = rd_i;
        we_n     = 1'b1;
      end
      cvxif_instr_pkg::ADD_RS3_R4: begin
        result_n = NrRgprPorts == 3 ? registers_i[2] + registers_i[1] + registers_i[0] : registers_i[1] + registers_i[0];
        hartid_n = hartid_i;
        id_n = id_i;
        valid_n = 1'b1;
        rd_n = rd_i;
        we_n = 1'b1;
      end
      cvxif_instr_pkg::ADD_RS3_R: begin
        result_n = NrRgprPorts == 3 ? registers_i[2] + registers_i[1] + registers_i[0] : registers_i[1] + registers_i[0];
        hartid_n = hartid_i;
        id_n = id_i;
        valid_n = 1'b1;
        rd_n = 5'b01010;
        we_n = 1'b1;
      end
      default: begin
        result_n = '0;
        hartid_n = '0;
        id_n     = '0;
        valid_n  = '0;
        rd_n     = '0;
        we_n     = '0;
      end
    endcase
  end

  //always_ff @(posedge clk_i, negedge rst_ni) begin
  //  if (~rst_ni) begin
  //    result_q <= '0;
  //    hartid_q <= '0;
  //    id_q     <= '0;
  //    valid_q  <= '0;
  //    rd_q     <= '0;
  //    we_q     <= '0;
  //  end else begin
  //    result_q <= result_n;
  //    hartid_q <= hartid_n;
  //    id_q     <= id_n;
  //    valid_q  <= valid_n;
  //    rd_q     <= rd_n;
  //    we_q     <= we_n;
  //  end
  //end
  //assign result_o = result_q;
  //assign hartid_o = hartid_q;
  //assign id_o     = id_q;
  //assign valid_o  = valid_q;
  //assign rd_o     = rd_q;
  //assign we_o     = we_q;

  
  logic [XLEN-1:0] result_q1, result_q2, result_q3;
  hartid_t hartid_q1, hartid_q2, hartid_q3;
  id_t id_q1, id_q2, id_q3;
  logic valid_q1, valid_q2, valid_q3;
  logic [4:0] rd_q1, rd_q2, rd_q3;
  logic we_q1, we_q2, we_q3;
  always_ff @(posedge clk_i, negedge rst_ni) begin
  if (~rst_ni) begin
    // Reset all pipeline stages
    result_q1 <= '0; result_q2 <= '0; result_q3 <= '0;
    hartid_q1 <= '0; hartid_q2 <= '0; hartid_q3 <= '0;
    id_q1     <= '0; id_q2     <= '0; id_q3     <= '0;
    valid_q1  <= '0; valid_q2  <= '0; valid_q3  <= '0;
    rd_q1     <= '0; rd_q2     <= '0; rd_q3     <= '0;
    we_q1     <= '0; we_q2     <= '0; we_q3     <= '0;
  end else begin
    // Pipeline stage 1
    result_q1 <= result_n;
    hartid_q1 <= hartid_n;
    id_q1     <= id_n;
    valid_q1  <= valid_n;
    rd_q1     <= rd_n;
    we_q1     <= we_n;
    // Pipeline stage 2
    result_q2 <= result_q1;
    hartid_q2 <= hartid_q1;
    id_q2     <= id_q1;
    valid_q2  <= valid_q1;
    rd_q2     <= rd_q1;
    we_q2     <= we_q1;
    // Pipeline stage 3
    result_q3 <= result_q2;
    hartid_q3 <= hartid_q2;
    id_q3     <= id_q2;
    valid_q3  <= valid_q2;
    rd_q3     <= rd_q2;
    we_q3     <= we_q2;
  end
end


// Outputs assigned to the last stage of the pipeline
assign result_o = result_q1;
assign hartid_o = hartid_q1;
assign id_o     = id_q1;
assign valid_o  = valid_q1;
assign rd_o     = rd_q1;
assign we_o     = we_q1;

  


endmodule