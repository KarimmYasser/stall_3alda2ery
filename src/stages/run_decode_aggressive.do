# DO file to compile and simulate the AGGRESSIVE Decode stage testbench
# Run from: c:\Users\ASUS\Desktop\SWE_Ass\stall_3alda2ery\src\stages

# Create work library if it doesn't exist
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

echo "========================================="
echo "Compiling Decode Stage Testbench"
echo "========================================="

# Compile basic register component FIRST (needed by pipeline register)
echo "Compiling general register..."
vcom -93 -work work ../components/register.vhd

# Compile register file component
echo "Compiling register file..."
vcom -93 -work work ../components/reg_file.vhd

# Compile control unit
echo "Compiling control unit..."
vcom -93 -work work ../../decode/control_unit.vhd

# Compile ID/EX pipeline register with feedback
echo "Compiling ID/EX pipeline register..."
vcom -93 -work work ../pipeline/id_ex_reg_with_feedback.vhd

# Compile decode stage
echo "Compiling decode stage..."
vcom -93 -work work 2_decode.vhd

# Compile testbench
echo "Compiling testbench..."
vcom -93 -work work tb_decode_aggressive.vhd

echo "========================================="
echo "Starting Simulation"
echo "========================================="

# Start simulation
vsim -t 1ns work.tb_decode_aggressive

# Add waves - Top level signals
add wave -divider "Clock and Control"
add wave -color "Yellow" sim:/tb_decode_aggressive/clk
add wave -color "Orange" sim:/tb_decode_aggressive/reset
add wave -color "Red" sim:/tb_decode_aggressive/inturrupt

add wave -divider "Instruction & PC"
add wave -radix hexadecimal sim:/tb_decode_aggressive/instruction
add wave -radix hexadecimal sim:/tb_decode_aggressive/PC

# Concatenated instruction fields for easier viewing - use curly braces for ranges
add wave -radix binary -label "Opcode[4:0]" {sim:/tb_decode_aggressive/instruction[31:27]}
add wave -radix binary -label "Index[1:0]" {sim:/tb_decode_aggressive/instruction[26:25]}
add wave -radix unsigned -label "rd[2:0]" {sim:/tb_decode_aggressive/instruction[8:6]}
add wave -radix unsigned -label "rs1[2:0]" {sim:/tb_decode_aggressive/instruction[5:3]}
add wave -radix unsigned -label "rs2[2:0]" {sim:/tb_decode_aggressive/instruction[2:0]}

add wave -divider "Pipeline Enable/Stall Signals"
add wave -color "Green" sim:/tb_decode_aggressive/FD_enable
add wave -color "Green" sim:/tb_decode_aggressive/DE_enable
add wave -color "Green" sim:/tb_decode_aggressive/EM_enable
add wave -color "Green" sim:/tb_decode_aggressive/MW_enable
add wave -color "Red" sim:/tb_decode_aggressive/Stall
add wave -color "Cyan" sim:/tb_decode_aggressive/Branch_Decode

add wave -divider "Memory Flags (Structural Hazard Detection)"
add wave -radix binary sim:/tb_decode_aggressive/MEM_flages
add wave -label "MEM_WDselect" sim:/tb_decode_aggressive/MEM_flages(6)
add wave -label "MEM_MemRead" sim:/tb_decode_aggressive/MEM_flages(5)
add wave -label "MEM_MemWrite" sim:/tb_decode_aggressive/MEM_flages(4)
add wave -label "MEM_StackRead" sim:/tb_decode_aggressive/MEM_flages(3)
add wave -label "MEM_StackWrite" sim:/tb_decode_aggressive/MEM_flages(2)
add wave -label "MEM_CCRStore" sim:/tb_decode_aggressive/MEM_flages(1)
add wave -label "MEM_CCRLoad" sim:/tb_decode_aggressive/MEM_flages(0)

add wave -divider "Control Unit Internal State"
add wave -color "Magenta" sim:/tb_decode_aggressive/DUT/CU/micro_state
add wave sim:/tb_decode_aggressive/DUT/CU/micro_active
add wave -radix binary -label "Micro_inst" sim:/tb_decode_aggressive/Micro_inst
add wave sim:/tb_decode_aggressive/DUT/CU/start_swap_req
add wave sim:/tb_decode_aggressive/DUT/CU/start_int_req
add wave sim:/tb_decode_aggressive/DUT/CU/start_rti_req
add wave sim:/tb_decode_aggressive/DUT/CU/start_immediate_req
add wave sim:/tb_decode_aggressive/DUT/CU/start_int_signal_req

add wave -divider "Memory and Immediate Feedback Loop"
add wave -color "Yellow" sim:/tb_decode_aggressive/DUT/mem_will_be_used_feedback
add wave -color "Yellow" sim:/tb_decode_aggressive/DUT/mem_usage_predict_signal
add wave -color "Cyan" sim:/tb_decode_aggressive/DUT/imm_in_use_feedback
add wave -color "Cyan" sim:/tb_decode_aggressive/DUT/imm_predict_signal

add wave -divider "Write-Back Flags"
add wave -radix binary sim:/tb_decode_aggressive/WB_flages
add wave -label "WB_RegWrite" sim:/tb_decode_aggressive/WB_flages(2)
add wave -label "WB_MemtoReg" sim:/tb_decode_aggressive/WB_flages(1)
add wave -label "WB_PC+1" sim:/tb_decode_aggressive/WB_flages(0)

add wave -divider "Execute Flags"
add wave -radix binary sim:/tb_decode_aggressive/EXE_flages
add wave -label "EXE_ALUOp_2" sim:/tb_decode_aggressive/EXE_flages(4)
add wave -label "EXE_ALUOp_1" sim:/tb_decode_aggressive/EXE_flages(3)
add wave -label "EXE_ALUOp_0" sim:/tb_decode_aggressive/EXE_flages(2)
add wave -label "EXE_ALUSrc" sim:/tb_decode_aggressive/EXE_flages(1)
add wave -label "EXE_Index" sim:/tb_decode_aggressive/EXE_flages(0)

add wave -divider "Branch Execution Flags"
add wave -radix binary sim:/tb_decode_aggressive/Branch_Exec
add wave -label "Branch_sel1" sim:/tb_decode_aggressive/Branch_Exec(3)
add wave -label "Branch_sel0" sim:/tb_decode_aggressive/Branch_Exec(2)
add wave -label "Branch_imm" sim:/tb_decode_aggressive/Branch_Exec(1)
add wave -label "Branch_enable" sim:/tb_decode_aggressive/Branch_Exec(0)

add wave -divider "I/O Flags"
add wave -radix binary sim:/tb_decode_aggressive/IO_flages
add wave -label "IO_output" sim:/tb_decode_aggressive/IO_flages(1)
add wave -label "IO_input" sim:/tb_decode_aggressive/IO_flages(0)

add wave -divider "Register File Data"
add wave -radix unsigned sim:/tb_decode_aggressive/rd_addr
add wave -radix unsigned sim:/tb_decode_aggressive/rs1_addr
add wave -radix unsigned sim:/tb_decode_aggressive/rs2_addr
add wave -radix hexadecimal sim:/tb_decode_aggressive/Rrs1
add wave -radix hexadecimal sim:/tb_decode_aggressive/Rrs2

add wave -divider "SWAP and Forwarding Control"
add wave -label "CSwap" sim:/tb_decode_aggressive/DUT/CSwap
add wave -label "ForwardEnable" sim:/tb_decode_aggressive/DUT/CU/main_ForwardEnable

add wave -divider "Decode Internal Signals"
add wave sim:/tb_decode_aggressive/DUT/ID_flush_main
add wave sim:/tb_decode_aggressive/DUT/main_stall
add wave sim:/tb_decode_aggressive/DUT/pipe_write_enable

# Configure wave window
configure wave -namecolwidth 350
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
run 1500 ns

# Zoom to fit
wave zoom full

# Print message
echo ""
echo "=========================================="
echo "AGGRESSIVE Decode Testbench Complete"
echo "=========================================="
echo "Check transcript for cycle-by-cycle logs"
echo "Check waveforms for:"
echo "  - Multi-cycle instructions (SWAP, INT, RTI)"
echo "  - ForwardEnable disabled during SWAP"
echo "  - Memory structural hazards and feedback"
echo "  - Interrupt handling during execution"
echo "  - Branch_Exec signals for control flow"
echo "  - Pipeline stall behavior"
echo "  - Immediate value prediction"
echo "=========================================="
