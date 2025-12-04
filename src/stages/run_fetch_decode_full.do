# DO file to compile and simulate Fetch-Decode integration testbench
# Usage: vsim -do run_fetch_decode_full.do

# Create work library
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Compile source files in order

# 1. Compile general register component
vcom -2008 -work work ../components/register.vhd

# 2. Compile register file component
vcom -2008 -work work ../components/reg_file.vhd

# 3. Compile IF/ID pipeline register
vcom -2008 -work work ../pipeline/if_id_reg.vhd

# 4. Compile ID/EX pipeline register with feedback
vcom -2008 -work work ../pipeline/id_ex_reg_with_feedback.vhd

# 5. Compile control unit
vcom -2008 -work work ../../decode/control_unit.vhd

# 6. Compile fetch stage
vcom -2008 -work work 1_fetch.vhd

# 7. Compile decode stage
vcom -2008 -work work 2_decode.vhd

# 8. Compile testbench
vcom -2008 -work work tb_fetch_decode_full.vhd

# Start simulation
vsim -voptargs=+acc work.tb_fetch_decode_full

# Add waves for comprehensive monitoring

add wave -divider "Clock and Control"
add wave -color "Yellow" sim:/tb_fetch_decode_full/clk
add wave -color "Orange" sim:/tb_fetch_decode_full/reset
add wave -color "Red" sim:/tb_fetch_decode_full/inturrupt

add wave -divider "PC Tracking"
add wave -radix hexadecimal -label "PC_Fetch" sim:/tb_fetch_decode_full/pc_fetch
add wave -radix hexadecimal -label "PC_Decode" sim:/tb_fetch_decode_full/pc_decode

add wave -divider "Instruction Flow"
add wave -radix hexadecimal -label "Inst_From_Memory" sim:/tb_fetch_decode_full/instruction_from_memory
add wave -radix hexadecimal -label "Inst_After_Fetch" sim:/tb_fetch_decode_full/instruction_after_fetch
add wave -radix hexadecimal -label "Inst_To_Decode" sim:/tb_fetch_decode_full/instruction_decode

add wave -divider "Microcode and Fetch MUX"
add wave -radix binary -label "Micro_inst (from Decode)" sim:/tb_fetch_decode_full/Micro_inst
add wave -label "Fetch_MUX_Select (Stall|Int)" sim:/tb_fetch_decode_full/Stall

add wave -divider "Pipeline Control"
add wave -color "Green" -label "FD_enable" sim:/tb_fetch_decode_full/FD_enable
add wave -color "Red" -label "Stall" sim:/tb_fetch_decode_full/Stall
add wave -color "Green" -label "DE_enable" sim:/tb_fetch_decode_full/DE_enable
add wave -color "Green" -label "EM_enable" sim:/tb_fetch_decode_full/EM_enable
add wave -color "Green" -label "MW_enable" sim:/tb_fetch_decode_full/MW_enable

add wave -divider "*** IMMEDIATE PREDICTION FEEDBACK LOOP ***"
add wave -color "Cyan" -label "Imm_predict (CU Output)" sim:/tb_fetch_decode_full/DECODE_STAGE/CU/Imm_predict
add wave -color "Magenta" -label "Imm_in_use (CU Input - Feedback)" sim:/tb_fetch_decode_full/DECODE_STAGE/CU/Imm_in_use
add wave -color "Yellow" -label "start_immediate_req (Internal)" sim:/tb_fetch_decode_full/DECODE_STAGE/CU/start_immediate_req
add wave -color "Orange" -label "Imm_predict_signal (to ID/EX reg)" sim:/tb_fetch_decode_full/DECODE_STAGE/imm_predict_signal
add wave -color "Pink" -label "Imm_in_use_feedback (from ID/EX reg)" sim:/tb_fetch_decode_full/DECODE_STAGE/imm_in_use_feedback

add wave -divider "Control Unit Microcode State"
add wave -color "Magenta" -label "micro_state" sim:/tb_fetch_decode_full/DECODE_STAGE/CU/micro_state
add wave -color "Magenta" -label "micro_next" sim:/tb_fetch_decode_full/DECODE_STAGE/CU/micro_next
add wave -label "micro_active" sim:/tb_fetch_decode_full/DECODE_STAGE/CU/micro_active

add wave -divider "Control Flags"
add wave -label "WB_flags" -radix binary sim:/tb_fetch_decode_full/WB_flages
add wave -label "EXE_flags" -radix binary sim:/tb_fetch_decode_full/EXE_flages
add wave -label "MEM_flags" -radix binary sim:/tb_fetch_decode_full/MEM_flages
add wave -label "Branch_Exec" -radix binary sim:/tb_fetch_decode_full/Branch_Exec

add wave -divider "Memory Feedback Loop"
add wave -color "Yellow" sim:/tb_fetch_decode_full/DECODE_STAGE/mem_will_be_used_feedback
add wave -color "Yellow" sim:/tb_fetch_decode_full/DECODE_STAGE/mem_usage_predict_signal

# Run simulation
run 400 ns

# Zoom to see details
wave zoom full
