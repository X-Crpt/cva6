///////////////////////////////////////////////////////////////////////
// File: crypto_brev8.sv
// Date: 2024-04-02
// Author: Behnam Farnaghinejad <behnam.farnaghinejad@polito.it>
// 
///////////////////////////////////////////////////////////////////////

//------------------------------- Sail model -------------------------------------------
/*
result : xlenbits = EXTZ(0b0);
foreach (i from 0 to sizeof(xlen) by 8) {
  result[i+7..i] = reverse_bits_in_byte(X(rs1)[i+7..i]);
};
X(rd) = result;
*/
//-------------------------------------------------------------------------------------
module crypto_brev8
  import crypto_instr_pkg::*;
(
    input  logic [XLEN-1:0]  brev8_rs1_i,
    output logic [XLEN-1:0]  brev8_result_o
);

always_comb begin
  for (int i=0; i<XLEN; i+=8) begin
    brev8_result_o [i+7] = brev8_rs1_i[i  ];
    brev8_result_o [i+6] = brev8_rs1_i[i+1];
    brev8_result_o [i+5] = brev8_rs1_i[i+2];
    brev8_result_o [i+4] = brev8_rs1_i[i+3];
    brev8_result_o [i+3] = brev8_rs1_i[i+4];
    brev8_result_o [i+2] = brev8_rs1_i[i+5];
    brev8_result_o [i+1] = brev8_rs1_i[i+6];
    brev8_result_o [i  ] = brev8_rs1_i[i+7];
  end
end
endmodule