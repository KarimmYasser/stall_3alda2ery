# DO file to compile and simulate the TOP-LEVEL processor testbench
# Run from: c:\Users\ASUS\Desktop\SWE_Ass\stall_3alda2ery\src

# Create work library
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

echo "========================================="
echo "Compiling Top-Level Processor Testbench"
echo "========================================="

# Compile basic register component FIRST
echo "Compiling general register..."
vcom -93 -work work components/register.vhd

# Compile register file component
echo "Compiling register file..."
vcom -93 -work work components/reg_file.vhd

# Compile control unit
echo "Compiling control unit..."
vcom -93 -work work ../decode/control_unit.vhd

# Compile IF/ID pipeline register
echo "Compiling IF/ID pipeline register..."
vcom -93 -work work pipeline/if_id_register.vhd

# Compile ID/EX pipeline register with feedback
echo "Compiling ID/EX pipeline register..."
vcom -93 -work work pipeline/id_ex_reg_with_feedback.vhd

# Compile fetch stage
echo "Compiling fetch stage..."
vcom -93 -work work stages/1_fetch.vhd

# Compile decode stage
echo "Compiling decode stage..."
vcom -93 -work work stages/2_decode.vhd

# Compile top-level processor
echo "Compiling top-level processor..."
vcom -93 -work work top_level_processor.vhd

# Compile testbench
echo "Compiling testbench..."
vcom -93 -work work tb_top_level_aggressive.vhd

echo "========================================="
echo "Starting Simulation"
echo "========================================="

# Start simulation
vsim -t 1ns work.tb_top_level_aggressive

# Add waves - Top level signals
add wave -divider "Top-Level Signals"
add wave -color "Yellow" {sim:/tb_top_level_aggressive/clk}
add wave -color "Orange" {sim:/tb_top_level_aggressive/reset}
add wave -color "Red" {sim:/tb_top_level_aggressive/interrupt}

# Add waves - Fetch Stage
add wave -divider "Fetch Stage"
add wave -radix hexadecimal {sim:/tb_top_level_aggressive/instruction}
add wave -radix hexadecimal {sim:/tb_top_level_aggressive/DUT/FETCH_STAGE/pc_current}
add wave -radix hexadecimal {sim:/tb_top_level_aggressive/DUT/FETCH_STAGE/pc_next}
add wave {sim:/tb_top_level_aggressive/DUT/FETCH_STAGE/pc_enable_signal}
add wave {sim:/tb_top_level_aggressive/DUT/stall_signal}

# Add waves - IF/ID Pipeline Register
add wave -divider "IF/ID Pipeline Register"
add wave {sim:/tb_top_level_aggressive/DUT/FD_enable_signal}
add wave -radix hexadecimal {sim:/tb_top_level_aggressive/DUT/fetch_instruction_out}
add wave -radix hexadecimal {sim:/tb_top_level_aggressive/DUT/ifid_instruction_out}
add wave -radix binary {sim:/tb_top_level_aggressive/DUT/ifid_opcode_out}
add wave -radix hexadecimal {sim:/tb_top_level_aggressive/DUT/ifid_pc_out}

# Add waves - Decode Stage Outputs
add wave -divider "Decode Stage Outputs"
add wave {sim:/tb_top_level_aggressive/DUT/decode_DE_enable}
add wave -radix binary {sim:/tb_top_level_aggressive/DUT/decode_WB_flages}
add wave -radix binary {sim:/tb_top_level_aggressive/DUT/decode_EXE_flages}
add wave -radix binary {sim:/tb_top_level_aggressive/DUT/decode_MEM_flages}

# Add waves - ID/EX Pipeline Register Signals
add wave -divider "ID/EX Pipeline Register"
add wave {sim:/tb_top_level_aggressive/DUT/ID_EX_REGISTER/write_enable}
add wave {sim:/tb_top_level_aggressive/DUT/mem_will_be_used_feedback}
add wave {sim:/tb_top_level_aggressive/DUT/imm_in_use_feedback}
add wave {sim:/tb_top_level_aggressive/DUT/decode_mem_predict}
add wave {sim:/tb_top_level_aggressive/DUT/decode_imm_predict}

# Add waves - Execute Stage Inputs (from ID/EX register)
add wave -divider "Execute Stage Inputs"
add wave -radix binary {sim:/tb_top_level_aggressive/DUT/exe_WB_flages}
add wave -radix binary {sim:/tb_top_level_aggressive/DUT/exe_EXE_flages}
add wave -radix binary {sim:/tb_top_level_aggressive/DUT/exe_MEM_flages}
add wave -radix hexadecimal {sim:/tb_top_level_aggressive/DUT/exe_Rrs1}
add wave -radix hexadecimal {sim:/tb_top_level_aggressive/DUT/exe_Rrs2}
add wave -radix unsigned {sim:/tb_top_level_aggressive/DUT/exe_rd_addr}

# Add waves - Control Unit State
add wave -divider "Control Unit State"
add wave -color "Magenta" {sim:/tb_top_level_aggressive/DUT/DECODE_STAGE/CU/micro_state}
add wave {sim:/tb_top_level_aggressive/DUT/DECODE_STAGE/CU/micro_active}
add wave {sim:/tb_top_level_aggressive/DUT/DECODE_STAGE/CU/start_swap_req}
add wave {sim:/tb_top_level_aggressive/DUT/DECODE_STAGE/CU/start_int_req}
add wave {sim:/tb_top_level_aggressive/DUT/DECODE_STAGE/CU/start_rti_req}

# Add waves - Register File
add wave -divider "Register File"
add wave -radix unsigned {sim:/tb_top_level_aggressive/DUT/DECODE_STAGE/GRF/read_address1}
add wave -radix unsigned {sim:/tb_top_level_aggressive/DUT/DECODE_STAGE/GRF/read_address2}
add wave -radix hexadecimal {sim:/tb_top_level_aggressive/DUT/DECODE_STAGE/GRF/read_data1}
add wave -radix hexadecimal {sim:/tb_top_level_aggressive/DUT/DECODE_STAGE/GRF/read_data2}

# Configure wave window
configure wave -namecolwidth 400
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
run 1000 ns

# Zoom to fit
wave zoom full

# Print message
echo ""
echo "=========================================="
echo "Top-Level Aggressive Testbench Complete"
echo "=========================================="
echo "Check transcript for cycle-by-cycle logs"
echo "Check waveforms for:"
echo "  - Decode to ID/EX register interface"
echo "  - Feedback signal propagation"
echo "  - Pipeline register timing"
echo "  - Control unit state transitions"
echo "  - Interrupt handling at system level"
echo "=========================================="
