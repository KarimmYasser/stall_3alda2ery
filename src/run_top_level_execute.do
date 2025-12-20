# DO file to compile and simulate the Execute Stage Integration Testbench
# Tests the execute stage through the top-level processor
# Run from: c:\Users\ASUS\Desktop\SWE_Ass\stall_3alda2ery\src

# Create work library
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

echo "========================================="
echo "Execute Stage Integration Test"
echo "========================================="

# Compile basic components
echo "Compiling general register..."
vcom -93 -work work components/register.vhd

echo "Compiling register file..."
vcom -93 -work work components/reg_file.vhd

echo "Compiling memory interface package..."
vcom -93 -work work common/memory_interface_pkg.vhd

# Compile control unit
echo "Compiling control unit..."
vcom -93 -work work ../decode/control_unit.vhd

# Compile IF/ID pipeline register
echo "Compiling IF/ID pipeline register..."
vcom -93 -work work pipeline/if_id_register.vhd

# Compile ID/EX pipeline register
echo "Compiling ID/EX pipeline register..."
vcom -93 -work work pipeline/id_ex_reg_with_feedback.vhd

# Compile fetch stage
echo "Compiling fetch stage..."
vcom -93 -work work stages/1_fetch.vhd

# Compile decode stage
echo "Compiling decode stage..."
vcom -93 -work work stages/2_decode.vhd

# Compile execute stage components
echo "Compiling ALU..."
vcom -93 -work work ../execute/alu.vhd

echo "Compiling forward unit..."
vcom -93 -work work ../execute/forward_unit.vhd

echo "Compiling CCR..."
vcom -93 -work work ../execute/ccr.vhd

echo "Compiling branch detection..."
vcom -93 -work work ../execute/branch_detection.vhd

echo "Compiling execute stage..."
vcom -93 -work work ../execute/execute_stage.vhd
echo "Compiling input port..."
vcom -93 -work work ../memory/input_port.vhd

# Compile EX/MEM pipeline register
echo "Compiling EX/MEM pipeline register..."
vcom -93 -work work pipeline/ex_mem_reg.vhd

echo "Compiling fetch memory interface..."
vcom -93 -work work pipeline/fetch_mem_interface.vhd

echo "Compiling memory stage support (stack pointer/output port)..."
vcom -93 -work work ../memory/stack_pointer.vhd
vcom -93 -work work ../execute/output_port.vhd

echo "Compiling memory stage..."
vcom -93 -work work stages/4_memory.vhd

echo "Compiling data memory interface..."
vcom -93 -work work pipeline/data_mem_interface.vhd

echo "Compiling memory arbiter..."
vcom -93 -work work pipeline/memory_arbiter.vhd

echo "Compiling external RAM/memory unit..."
vcom -93 -work work ../memory/ram.vhd
vcom -93 -work work ../memory/memory_unit.vhd

echo "Compiling MEM/WB pipeline register..."
vcom -93 -work work pipeline/mem_wb_reg.vhd

echo "Compiling writeback stage..."
vcom -93 -work work stages/5_writeback.vhd

# Compile top-level processor
echo "Compiling top-level processor..."
vcom -93 -work work top_level_processor.vhd

# Compile execute integration testbench
echo "Compiling execute integration testbench..."
vcom -2008 -work work tb_top_level_execute.vhd

echo "========================================="
echo "Starting Simulation"
echo "========================================="

# Start simulation
vsim -t 1ns work.tb_top_level_execute

# Add waves - Top level signals
add wave -divider "Clock and Control"
add wave -color "Yellow" {sim:/tb_top_level_execute/clk}
add wave -color "Orange" {sim:/tb_top_level_execute/reset}
add wave -color "Red" {sim:/tb_top_level_execute/interrupt}
add wave -color "Cyan" -radix hexadecimal {sim:/tb_top_level_execute/inputport_data}

# Add waves - Instruction Input
add wave -divider "Instruction Input"
add wave -radix hexadecimal {sim:/tb_top_level_execute/instruction}
add wave -radix binary {sim:/tb_top_level_execute/instruction(31 downto 27)}

# Add waves - Execute Stage Outputs (TB Observation)
add wave -divider "Execute Stage Outputs (TB)"
add wave -color "Yellow" -radix hexadecimal {sim:/tb_top_level_execute/exe_alu_result}
add wave -color "Cyan" -radix decimal {sim:/tb_top_level_execute/exe_alu_result}
add wave -color "Green" {sim:/tb_top_level_execute/exe_ccr}
add wave {sim:/tb_top_level_execute/exe_ccr(2)}
add wave {sim:/tb_top_level_execute/exe_ccr(1)}
add wave {sim:/tb_top_level_execute/exe_ccr(0)}
add wave -color "Red" {sim:/tb_top_level_execute/exe_branch_taken}
add wave -color "Magenta" -radix unsigned {sim:/tb_top_level_execute/exe_rd_addr}

# Add waves - Pipeline Stages
add wave -divider "Fetch Stage"
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/FETCH_STAGE/pc_current}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/FETCH_STAGE/pc_next}
add wave {sim:/tb_top_level_execute/DUT/stall_signal}

# Add waves - Decode Stage
add wave -divider "Decode Stage"
add wave -radix binary {sim:/tb_top_level_execute/DUT/DECODE_STAGE/opcode}
add wave {sim:/tb_top_level_execute/DUT/DECODE_STAGE/FD_enable}
add wave {sim:/tb_top_level_execute/DUT/DECODE_STAGE/DE_enable}

# Add waves - ID/EX Register
add wave -divider "ID/EX Register (to Execute)"
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/ID_EX_REGISTER/Rrs1_out}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/ID_EX_REGISTER/Rrs2_out}
add wave -radix unsigned {sim:/tb_top_level_execute/DUT/ID_EX_REGISTER/rs1_addr_out}
add wave -radix unsigned {sim:/tb_top_level_execute/DUT/ID_EX_REGISTER/rs2_addr_out}
add wave -radix unsigned {sim:/tb_top_level_execute/DUT/ID_EX_REGISTER/rd_addr_out}
add wave -radix binary {sim:/tb_top_level_execute/DUT/ID_EX_REGISTER/EXE_flages_out}
add wave -radix binary {sim:/tb_top_level_execute/DUT/ID_EX_REGISTER/WB_flages_out}
add wave -radix binary {sim:/tb_top_level_execute/DUT/ID_EX_REGISTER/MEM_flages_out}

# Add waves - Execute Stage Internal
add wave -divider "Execute Stage Internal"
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/EXECUTE_STAGE_INST/alu_operand_1}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/EXECUTE_STAGE_INST/alu_operand_2}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/EXECUTE_STAGE_INST/alu_result}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/EXECUTE_STAGE_INST/variant_operand}
add wave -radix binary {sim:/tb_top_level_execute/DUT/EXECUTE_STAGE_INST/alu_flags}
add wave {sim:/tb_top_level_execute/DUT/EXECUTE_STAGE_INST/ccr_out_sig}
add wave {sim:/tb_top_level_execute/DUT/EXECUTE_STAGE_INST/forward1_signal}
add wave {sim:/tb_top_level_execute/DUT/EXECUTE_STAGE_INST/forward2_signal}

# Add waves - Execute Stage Control Signals
add wave -divider "Execute Stage Control Flags"
add wave -radix binary {sim:/tb_top_level_execute/DUT/EXECUTE_STAGE_INST/wb_signals}
add wave -radix binary {sim:/tb_top_level_execute/DUT/EXECUTE_STAGE_INST/mem_signals}
add wave -radix binary {sim:/tb_top_level_execute/DUT/EXECUTE_STAGE_INST/exe_signals}
add wave {sim:/tb_top_level_execute/DUT/EXECUTE_STAGE_INST/output_signal}
add wave {sim:/tb_top_level_execute/DUT/EXECUTE_STAGE_INST/input_signal}
add wave -radix binary {sim:/tb_top_level_execute/DUT/ID_EX_REGISTER/IO_flages_out}

# Add waves - EX/MEM Register
add wave -divider "EX/MEM Register (Execute Output)"
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/exe_mem_alu_result_out}
add wave {sim:/tb_top_level_execute/DUT/exe_mem_ccr_out}
add wave {sim:/tb_top_level_execute/DUT/exe_mem_branch_taken_out}
add wave -radix unsigned {sim:/tb_top_level_execute/DUT/exe_mem_rd_addr_out}
add wave -radix binary {sim:/tb_top_level_execute/DUT/exe_mem_wb_signals_out}
add wave -radix binary {sim:/tb_top_level_execute/DUT/exe_mem_mem_signals_out}
add wave {sim:/tb_top_level_execute/DUT/exe_mem_output_signal_out}

# Add waves - Memory Stage + MEM/WB + Writeback
add wave -divider "Memory + Arbiter (DUT)"
add wave -radix binary {sim:/tb_top_level_execute/DUT/mem_wb_signals}
add wave -radix binary {sim:/tb_top_level_execute/DUT/mem_mem_signals}
add wave {sim:/tb_top_level_execute/DUT/mem_output_signal}
add wave {sim:/tb_top_level_execute/DUT/mem_branch_taken}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/mem_alu_result}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/mem_rs2_data}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/mem_pc}
add wave -radix unsigned {sim:/tb_top_level_execute/DUT/mem_rd_addr}
add wave -radix unsigned {sim:/tb_top_level_execute/DUT/data_mem_interface_addr}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/data_mem_interface_read_data}
add wave {sim:/tb_top_level_execute/DUT/data_mem_interface_stall}

add wave -divider "Memory Stage (Instance)"
add wave -radix binary {sim:/tb_top_level_execute/DUT/MEMORY_STAGE_INST/wb_signals_in}
add wave -radix binary {sim:/tb_top_level_execute/DUT/MEMORY_STAGE_INST/mem_signals_in}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/MEMORY_STAGE_INST/alu_result_in}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/MEMORY_STAGE_INST/rs2_data_in}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/MEMORY_STAGE_INST/read_data_out}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/MEMORY_STAGE_INST/alu_result_out}
add wave -radix unsigned {sim:/tb_top_level_execute/DUT/MEMORY_STAGE_INST/rd_addr_out}
add wave -radix unsigned {sim:/tb_top_level_execute/DUT/MEMORY_STAGE_INST/sp_out_debug}
add wave -radix unsigned {sim:/tb_top_level_execute/DUT/MEMORY_STAGE_INST/mem_addr_out}

add wave -divider "MEM/WB + Writeback"
add wave -radix binary {sim:/tb_top_level_execute/DUT/MEM_WB_REGISTER/wb_signals_in}
add wave -radix binary {sim:/tb_top_level_execute/DUT/MEM_WB_REGISTER/wb_signals_out}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/MEM_WB_REGISTER/read_data_in}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/MEM_WB_REGISTER/read_data_out}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/MEM_WB_REGISTER/alu_result_in}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/MEM_WB_REGISTER/alu_result_out}
add wave -radix unsigned {sim:/tb_top_level_execute/DUT/MEM_WB_REGISTER/rd_addr_in}
add wave -radix unsigned {sim:/tb_top_level_execute/DUT/MEM_WB_REGISTER/rd_addr_out}
add wave -radix binary {sim:/tb_top_level_execute/DUT/WRITEBACK_STAGE_INST/wb_select}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/WRITEBACK_STAGE_INST/mem_read_data}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/WRITEBACK_STAGE_INST/alu_result}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/WRITEBACK_STAGE_INST/wb_data}
add wave -radix hexadecimal {sim:/tb_top_level_execute/DUT/wb_data_out}

add wave -divider "RAM Bus (dbg_*)"
add wave -radix hexadecimal {sim:/tb_top_level_execute/dbg_pc}
add wave -radix hexadecimal {sim:/tb_top_level_execute/dbg_fetched_instruction}
add wave -radix unsigned {sim:/tb_top_level_execute/dbg_sp}
add wave {sim:/tb_top_level_execute/dbg_stall}
add wave -radix unsigned {sim:/tb_top_level_execute/dbg_ram_addr}
add wave {sim:/tb_top_level_execute/dbg_ram_read_en}
add wave {sim:/tb_top_level_execute/dbg_ram_write_en}
add wave -radix hexadecimal {sim:/tb_top_level_execute/dbg_ram_data_in}
add wave -radix hexadecimal {sim:/tb_top_level_execute/dbg_ram_data_out}

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
echo "Running simulation for 6000 ns..."
run 6000 ns

# Zoom to fit
wave zoom full

echo ""
echo "=========================================="
echo "Execute Stage Integration Test Complete"
echo "=========================================="
echo "Check transcript for test results"
echo "Check waveforms for:"
echo "  - Execute stage ALU operations"
echo "  - CCR flag updates"
echo "  - Branch decisions"
echo "  - Forwarding unit behavior"
echo "  - Pipeline progression"
echo "=========================================="
