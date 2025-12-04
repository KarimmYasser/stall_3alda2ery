# DO file to compile and simulate the AGGRESSIVE Decode stage testbench
# Usage: vsim -do run_decode_aggressive.do

# Create work library if it doesn't exist
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Compile source files in order

# 1. Compile general register component (used by pipeline register)
vcom -2008 -work work ../components/register.vhd

# 2. Compile register file component
vcom -2008 -work work ../components/reg_file.vhd

# 3. Compile ID/EX pipeline register with feedback
vcom -2008 -work work ../pipeline/id_ex_reg_with_feedback.vhd

# 4. Compile control unit
vcom -2008 -work work ../../decode/control_unit.vhd

# 5. Compile decode stage
vcom -2008 -work work 2_decode.vhd

# 6. Compile aggressive testbench
vcom -2008 -work work tb_decode_aggressive.vhd

# Start simulation
vsim -voptargs=+acc work.tb_decode_aggressive

# Add waves for comprehensive monitoring

add wave -divider "Clock and Control"
add wave -color "Yellow" sim:/tb_decode_aggressive/clk
add wave -color "Orange" sim:/tb_decode_aggressive/reset
add wave -color "Red" sim:/tb_decode_aggressive/inturrupt

add wave -divider "Instruction & PC"
add wave -radix hexadecimal sim:/tb_decode_aggressive/instruction
add wave -radix hexadecimal sim:/tb_decode_aggressive/PC
add wave -radix binary sim:/tb_decode_aggressive/DUT/opcode
add wave -label "Opcode" -radix binary sim:/tb_decode_aggressive/DUT/opcode

add wave -divider "Pipeline Enable/Stall Signals"
add wave -color "Green" sim:/tb_decode_aggressive/FD_enable
add wave -color "Green" sim:/tb_decode_aggressive/DE_enable
add wave -color "Green" sim:/tb_decode_aggressive/EM_enable
add wave -color "Green" sim:/tb_decode_aggressive/MW_enable
add wave -color "Red" sim:/tb_decode_aggressive/Stall
add wave -color "Cyan" sim:/tb_decode_aggressive/Branch_Decode

add wave -divider "Memory Flags (Structural Hazard Detection)"
add wave -label "MEM_StackWrite" sim:/tb_decode_aggressive/MEM_flages(2)
add wave -label "MEM_StackRead" sim:/tb_decode_aggressive/MEM_flages(3)
add wave -label "MEM_MemWrite" sim:/tb_decode_aggressive/MEM_flages(4)
add wave -label "MEM_MemRead" sim:/tb_decode_aggressive/MEM_flages(5)
add wave -label "MEM_WDselect" sim:/tb_decode_aggressive/MEM_flages(6)
add wave -label "MEM_CCRLoad" sim:/tb_decode_aggressive/MEM_flages(0)
add wave -label "MEM_CCRStore" sim:/tb_decode_aggressive/MEM_flages(1)

add wave -divider "Control Unit Internal State"
add wave -color "Magenta" sim:/tb_decode_aggressive/DUT/CU/micro_state
add wave sim:/tb_decode_aggressive/DUT/CU/micro_active
add wave -radix binary -label "Micro_inst (CU)" sim:/tb_decode_aggressive/DUT/Micro_inst
add wave -radix binary -label "Micro_inst_out" sim:/tb_decode_aggressive/Micro_inst
add wave sim:/tb_decode_aggressive/DUT/CU/start_swap_req
add wave sim:/tb_decode_aggressive/DUT/CU/start_int_req
add wave sim:/tb_decode_aggressive/DUT/CU/start_rti_req
add wave sim:/tb_decode_aggressive/DUT/CU/start_immediate_req
add wave sim:/tb_decode_aggressive/DUT/CU/start_int_signal_req

add wave -divider "Memory Feedback Loop"
add wave -color "Yellow" sim:/tb_decode_aggressive/DUT/mem_will_be_used_feedback
add wave -color "Yellow" sim:/tb_decode_aggressive/DUT/mem_usage_predict_signal

add wave -divider "Write-Back Flags"
add wave -label "WB_PC+1" sim:/tb_decode_aggressive/WB_flages(0)
add wave -label "WB_MemtoReg" sim:/tb_decode_aggressive/WB_flages(1)
add wave -label "WB_RegWrite" sim:/tb_decode_aggressive/WB_flages(2)

add wave -divider "Execute Flags"
add wave -radix binary sim:/tb_decode_aggressive/EXE_flages
add wave -label "EXE_Index" sim:/tb_decode_aggressive/EXE_flages(0)
add wave -label "EXE_ALUSrc" sim:/tb_decode_aggressive/EXE_flages(1)

add wave -divider "Branch & I/O"
add wave -radix binary sim:/tb_decode_aggressive/Branch_Exec
add wave -radix binary sim:/tb_decode_aggressive/IO_flages

add wave -divider "Register File"
add wave -radix unsigned sim:/tb_decode_aggressive/rd_addr
add wave -radix unsigned sim:/tb_decode_aggressive/rs1_addr
add wave -radix unsigned sim:/tb_decode_aggressive/rs2_addr
add wave -radix hexadecimal sim:/tb_decode_aggressive/Rrs1
add wave -radix hexadecimal sim:/tb_decode_aggressive/Rrs2

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

# Run simulation for adequate time
run 1500ns

# Zoom to fit
wave zoom full

# Add cursor at interesting points
# You can manually add cursors to mark multi-cycle instruction boundaries

# Print message
echo ""
echo "=========================================="
echo "AGGRESSIVE Decode Testbench Complete"
echo "=========================================="
echo "Check transcript for cycle-by-cycle logs"
echo "Check waveforms for:"
echo "  - Multi-cycle instructions (SWAP, INT, RTI)"
echo "  - Memory structural hazards"
echo "  - Interrupt handling during execution"
echo "  - Pipeline stall behavior"
echo "=========================================="
