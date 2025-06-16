#-----------------------------------------------------------------------------
# This script employs core to verify AES encryption and decryption functions. 
# It conducts tests for a single AES-128 block encryption and decryption, with 
# and without a cryptographic accelerator. The results will be used for 
# subsequent analysis and comparison
#-----------------------------------------------------------------------------
# Author: Behnam Farnaghinejad
#-----------------------------------------------------------------------------

# Make sure to source this script from the root directory 
# to correctly set the environment variables related to the tools
source ./verif/sim/setup-env.sh
DV_TARGET=cv64a6_imac_crypto

# Set the NUM_JOBS variable to increase the number of parallel make jobs
# export NUM_JOBS=

export DV_SIMULATORS=veri-testharness
#export DV_SIMULATORS=spike
export TRACE_FAST=1

cd ./verif/sim



# sv39 is structure of the virtual memory
# core/include i can change the configuration
python3 -c "
from cva6 import generate_fpga_files
# Define parameters
c_test = '../../additional_files/masked_single_block/aes64-fpga-test/aes_asm_FPGA_masked_single_encryption.c'
linker = '../tests/custom/common/test.ld'
gcc_opts = '-static -mcmodel=medany -fvisibility=hidden -O0 -nostartfiles -g ../tests/custom/common/syscalls.c ../tests/custom/common/crt.S -lgcc -I../tests/custom/env -I../tests/custom/common'
output_dir = './FPGA_output'
isa = 'rv64imafdc'
mabi = 'lp64'
# Call the function
generate_fpga_files(c_test=c_test, linker=linker, gcc_opts=gcc_opts, isa=isa, mabi=mabi, output_dir=output_dir)
"

cd ..
cd ..