///////////////////////////////////////////////////////////////////////
// File: crypto_zip.sv
// Date: 2024-04-02
// Author: Behnam Farnaghinejad <behnam.farnaghinejad@polito.it>
// 
///////////////////////////////////////////////////////////////////////


//------------------------------- Sail model -------------------------------------------
/*
---Unzip:
foreach (i from 0 to xlen/2-1) {
  X(rd)[i ] = X(rs1)[2*i ]
  X(rd)[i+xlen/2] = X(rs1)[2*i+1]
}

---Zip:
foreach (i from 0 to xlen/2-1) {
  X(rd)[2*i ] = X(rs1)[i ]
  X(rd)[2*i+1] = X(rs1)[i+xlen/2]
}
*/
//-------------------------------------------------------------------------------------
module crypto_zip
  import crypto_instr_pkg::*;
(
    input  logic         zip_op_i,
    input  logic [31:0]  zip_rs1_i,
    output logic [31:0]  zip_result_o
);
    always_comb
    begin 
        if (zip_op_i==0) begin  //Zip
            for (int i=0; i<16; i++) begin
                zip_result_o [2*i]   = zip_rs1_i [i];
                zip_result_o [2*i+1] = zip_rs1_i [i+16];
            end
        end
        else begin              //Unzip
            for (int i=0; i<16; i++) begin
                zip_result_o [i]    = zip_rs1_i [2*i];
                zip_result_o [i+16] = zip_rs1_i [2*i+1];
            end
        end
    end
endmodule