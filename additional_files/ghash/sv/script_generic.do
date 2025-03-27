if {[file exists work]} { vdel -all -lib work }
vlib work

######### SRC FILES COMPILE #########
vlog -work ./work ./ghash.sv

####### TESTBENCH COMPILE #########
vlog -work ./work ./ghash.sv


vsim work.ghash_tb -t ps -vopt -voptargs=+acc
add wave -r /*

run 10 us
