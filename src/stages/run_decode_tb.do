# DO file to compile and simulate the Decode stage testbench
# Usage: vsim -do run_decode_tb.do

# Create work library if it doesn't exist
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Compile source files in order

# 1. Compile register file component
vcom -2008 -work work ../components/reg_file.vhd

# 2. Compile control unit
vcom -2008 -work work ../../decode/control_unit.vhd

# 3. Compile decode stage
vcom -2008 -work work 2_decode.vhd

# 4. Compile testbench
vcom -2008 -work work tb_decode.vhd

# Start simulation
vsim -voptargs=+acc work.tb_decode

# Add waves for key signals
add wave -divider "Clock and Reset"
add wave -color "Yellow" sim:/tb_decode/clk
add wave -color "Orange" sim:/tb_decode/reset
add wave -color "Red" sim:/tb_decode/inturrupt

add wave -divider "Instruction Input"
add wave -radix hexadecimal sim:/tb_decode/instruction
add wave -radix hexadecimal sim:/tb_decode/PC
add wave -radix binary sim:/tb_decode/DUT/opcode

add wave -divider "Register Addresses"
add wave -radix unsigned sim:/tb_decode/rd_addr
add wave -radix unsigned sim:/tb_decode/rs1_addr
add wave -radix unsigned sim:/tb_decode/rs2_addr
add wave -radix unsigned sim:/tb_decode/index

add wave -divider "Pipeline Control"
add wave sim:/tb_decode/FD_enable
add wave sim:/tb_decode/DE_enable
add wave sim:/tb_decode/EM_enable
add wave sim:/tb_decode/MW_enable
add wave -color "Red" sim:/tb_decode/Stall
add wave sim:/tb_decode/Branch_Decode

add wave -divider "Control Flags"
add wave -radix binary sim:/tb_decode/WB_flages
add wave -radix binary sim:/tb_decode/EXE_flages
add wave -radix binary sim:/tb_decode/MEM_flages
add wave -radix binary sim:/tb_decode/IO_flages
add wave -radix binary sim:/tb_decode/Branch_Exec

add wave -divider "Register File Outputs"
add wave -radix hexadecimal sim:/tb_decode/Rrs1
add wave -radix hexadecimal sim:/tb_decode/Rrs2

add wave -divider "Internal Signals (DUT)"
add wave -radix binary sim:/tb_decode/DUT/opcode
add wave sim:/tb_decode/DUT/CSwap
add wave -radix binary sim:/tb_decode/DUT/Micro_inst
add wave sim:/tb_decode/DUT/CU/micro_state
add wave sim:/tb_decode/DUT/CU/micro_active

# Configure wave window
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

# Run simulation
run 2000ns

# Zoom to fit
wave zoom full

# Print message
echo ""
echo "=========================================="
echo "Decode Stage Testbench Simulation Complete"
echo "=========================================="
echo "Check transcript window for detailed logs"
echo "Check wave window for signal waveforms"
echo "=========================================="
