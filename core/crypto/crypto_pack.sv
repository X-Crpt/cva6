///////////////////////////////////////////////////////////////////////
// File: crypto_pack.sv
// Date: 2024-04-02
// Author: Behnam Farnaghinejad <behnam.farnaghinejad@polito.it>
// 
///////////////////////////////////////////////////////////////////////


//------------------------------- Sail model -------------------------------------------
/*
--- PACK:
let lo_half : bits(xlen/2) = X(rs1)[xlen/2-1..0];
let hi_half : bits(xlen/2) = X(rs2)[xlen/2-1..0];
X(rd) = EXTZ(hi_half @ lo_half);

---PACKH:
let lo_half : bits(8) = X(rs1)[7..0];
let hi_half : bits(8) = X(rs2)[7..0];
X(rd) = EXTZ(hi_half @ lo_half);

---PACKW:
let lo_half : bits(16) = X(rs1)[15..0];
let hi_half : bits(16) = X(rs2)[15..0];
X(rd) = EXTS(hi_half @ lo_half);
*/
//-------------------------------------------------------------------------------------
module crypto_pack
  import crypto_instr_pkg::*;
(
    input  logic [1:0]              pack_op_i,
    input  logic [XLEN-1:0]  pack_rs1_i,
    input  logic [XLEN-1:0]  pack_rs2_i,
    output logic [XLEN-1:0]  pack_result_o
);

logic [31:0] lo_half ;
logic [31:0] hi_half ;
assign lo_half = pack_rs1_i[31:0];
assign hi_half = pack_rs2_i[31:0];

logic [7:0] lo_half_h ;
logic [7:0] hi_half_h ;
assign lo_half_h = pack_rs1_i[7:0];
assign hi_half_h = pack_rs2_i[7:0];

logic [15:0] lo_half_w ;
logic [15:0] hi_half_w ;
assign lo_half_w = pack_rs1_i[15:0];
assign hi_half_w = pack_rs2_i[15:0];

always_comb begin
  //pack
  if (pack_op_i==2'b00) begin                                           
    pack_result_o = XLEN==64? {hi_half,lo_half}: {hi_half_w,lo_half_w};
  end 
  //packh
  else if (pack_op_i==2'b10) begin                                      
    pack_result_o = {hi_half_h,lo_half_h};
  end 
  //packw
  else if (pack_op_i==2'b01) begin                                      
    pack_result_o = XLEN==64 ? {{32{hi_half_w[15]}},hi_half_w,lo_half_w} : 0;
  end 
end

endmodule