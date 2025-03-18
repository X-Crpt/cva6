if {[file exists work]} { vdel -all -lib work }
vlib work

######### SRC FILES COMPILE #########
vlog -work ./work ./src/aes_pkg.sv
vlog -work ./work ./src/affine_transformation_addition.sv
vlog -work ./work ./src/affine_transformation_multiplication.sv
vlog -work ./work ./src/dom_multiplication_after_reg_gf4.sv
vlog -work ./work ./src/dom_multiplication_after_reg_gf16.sv
vlog -work ./work ./src/dom_multiplication_before_reg_gf4.sv
vlog -work ./work ./src/dom_multiplication_before_reg_gf16.sv
vlog -work ./work ./src/dom_multiplication_gf4.sv
vlog -work ./work ./src/dom_multiplication_gf16.sv
vlog -work ./work ./src/inverse_affine_transformation_addition.sv
vlog -work ./work ./src/inverse_affine_transformation_multiplication.sv
vlog -work ./work ./src/inverse_isomorphic_mapping.sv
vlog -work ./work ./src/isomorphic_mapping.sv
vlog -work ./work ./src/multiplication_gf4.sv
vlog -work ./work ./src/multiplication_gf16.sv
vlog -work ./work ./src/square_scale_gf16.sv
vlog -work ./work ./src/dom_sbox.sv

####### TESTBENCH COMPILE #########
vlog -work ./work ./tb/tb.sv


vsim work.tb_dom_sbox -t ps -vopt -voptargs=+acc
add wave -r /*

run 10 us
