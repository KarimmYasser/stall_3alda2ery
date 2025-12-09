# Create work library if it doesn't exist
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Compile the design files
vcom -93 -work work control_unit.vhd
vcom -93 -work work testbench/control_unit_tb.vhd

# Start simulation
vsim -t 1ns work.control_unit_tb

# Add waves for all signals
add wave -divider "Clock and Reset"
add wave -color "Yellow" sim:/control_unit_tb/clk

# Add divider for inputs
add wave -divider "Inputs"
add wave -position insertpoint sim:/control_unit_tb/inturrupt
add wave -position insertpoint -radix binary sim:/control_unit_tb/op_code
add wave -position insertpoint sim:/control_unit_tb/data_ready
add wave -position insertpoint sim:/control_unit_tb/mem_will_be_used
add wave -position insertpoint sim:/control_unit_tb/Imm_in_use

# Add divider for pipeline control outputs
add wave -divider "Pipeline Control Outputs"
add wave -color "Green" sim:/control_unit_tb/FD_enable
add wave -color "Green" sim:/control_unit_tb/DE_enable
add wave -color "Green" sim:/control_unit_tb/EM_enable
add wave -color "Green" sim:/control_unit_tb/MW_enable
add wave -color "Red" sim:/control_unit_tb/Stall
add wave -color "Cyan" sim:/control_unit_tb/Branch_Decode
add wave -color "Orange" sim:/control_unit_tb/ID_flush
add wave -color "Magenta" sim:/control_unit_tb/CSwap

# Add divider for new control signals
add wave -divider "Additional Control Signals"
add wave -position insertpoint sim:/control_unit_tb/CCR_enable
add wave -position insertpoint sim:/control_unit_tb/ForwardEnable
add wave -position insertpoint sim:/control_unit_tb/mem_usage_predict
add wave -position insertpoint sim:/control_unit_tb/Imm_predict

# Add divider for flag outputs
add wave -divider "Write-Back Flags"
add wave -position insertpoint -radix binary sim:/control_unit_tb/WB_flages
add wave -label "WB_RegWrite" sim:/control_unit_tb/WB_flages(2)
add wave -label "WB_MemtoReg" sim:/control_unit_tb/WB_flages(1)
add wave -label "WB_PC_select" sim:/control_unit_tb/WB_flages(0)

add wave -divider "Execute Flags"
add wave -position insertpoint -radix binary sim:/control_unit_tb/EXE_flages
add wave -label "EXE_ALUOp_2" sim:/control_unit_tb/EXE_flages(4)
add wave -label "EXE_ALUOp_1" sim:/control_unit_tb/EXE_flages(3)
add wave -label "EXE_ALUOp_0" sim:/control_unit_tb/EXE_flages(2)
add wave -label "EXE_ALUSrc" sim:/control_unit_tb/EXE_flages(1)
add wave -label "EXE_Index" sim:/control_unit_tb/EXE_flages(0)

add wave -divider "Memory Flags"
add wave -position insertpoint -radix binary sim:/control_unit_tb/MEM_flages
add wave -label "MEM_WDselect" sim:/control_unit_tb/MEM_flages(6)
add wave -label "MEM_MEMRead" sim:/control_unit_tb/MEM_flages(5)
add wave -label "MEM_MEMWrite" sim:/control_unit_tb/MEM_flages(4)
add wave -label "MEM_StackRead" sim:/control_unit_tb/MEM_flages(3)
add wave -label "MEM_StackWrite" sim:/control_unit_tb/MEM_flages(2)
add wave -label "MEM_CCRStore" sim:/control_unit_tb/MEM_flages(1)
add wave -label "MEM_CCRLoad" sim:/control_unit_tb/MEM_flages(0)

add wave -divider "I/O and Branch Flags"
add wave -position insertpoint -radix binary sim:/control_unit_tb/IO_flages
add wave -label "IO_output" sim:/control_unit_tb/IO_flages(1)
add wave -label "IO_input" sim:/control_unit_tb/IO_flages(0)

add wave -position insertpoint -radix binary sim:/control_unit_tb/Branch_Exec
add wave -label "Branch_sel1" sim:/control_unit_tb/Branch_Exec(3)
add wave -label "Branch_sel0" sim:/control_unit_tb/Branch_Exec(2)
add wave -label "Branch_imm" sim:/control_unit_tb/Branch_Exec(1)
add wave -label "Branch_enable" sim:/control_unit_tb/Branch_Exec(0)

# Add divider for microcode
add wave -divider "Microcode State"
add wave -position insertpoint -radix binary sim:/control_unit_tb/Micro_inst
add wave -color "Magenta" sim:/control_unit_tb/UUT/micro_state
add wave -position insertpoint sim:/control_unit_tb/UUT/micro_active
add wave -position insertpoint sim:/control_unit_tb/UUT/start_swap_req
add wave -position insertpoint sim:/control_unit_tb/UUT/start_int_req
add wave -position insertpoint sim:/control_unit_tb/UUT/start_rti_req
add wave -position insertpoint sim:/control_unit_tb/UUT/start_int_signal_req
add wave -position insertpoint sim:/control_unit_tb/UUT/start_immediate_req

# Configure wave window
configure wave -namecolwidth 300
configure wave -valuecolwidth 120
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns

# Run simulation
run 2000 ns

# Zoom to fit
wave zoom full

# Print completion message
echo ""
echo "=========================================="
echo "Control Unit testbench simulation completed"
echo "=========================================="
echo "Check waveforms for:"
echo "  - ForwardEnable disabled during SWAP"
echo "  - Branch_Exec signals for control flow"
echo "  - Memory usage prediction feedback"
echo "  - CCR_enable for flag operations"
echo "=========================================="
