# ============================================================================
# ModelSim DO File: run_tb_top_level.do
# ============================================================================
# Compiles and simulates tb_top_level with unified Von Neumann memory
# Instructions are loaded from assembler output: test_output.mem
# ============================================================================

# Clean up
if {[file exists work]} {
    vdel -all
}
vlib work

echo "========================================="
echo "Compiling Components"
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

# Compile execute stage components
echo "Compiling input port..."
vcom -93 -work work ../memory/input_port.vhd

echo "Compiling output port..."
vcom -93 -work work ../execute/output_port.vhd

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

# Compile EX/MEM pipeline register
echo "Compiling EX/MEM pipeline register..."
vcom -93 -work work pipeline/ex_mem_reg.vhd

# Compile memory interface package
echo "Compiling memory interface package..."
vcom -93 -work work common/memory_interface_pkg.vhd

# Compile top-level processor
echo "Compiling top-level processor..."
vcom -93 -work work top_level_processor.vhd


# 9. Compile testbench
echo "Compiling testbench..."
vcom -93 -work work tb_top_level.vhd

echo "========================================="
echo "Starting Simulation"
echo "========================================="

# Start simulation
vsim -t 1ns work.tb_top_level

# Configure waveform window
echo "Setting up waveforms..."

# Add waves - Top level signals
add wave -divider "=== CLOCK & CONTROL ==="
add wave -color "Yellow" {sim:/tb_top_level/clk}
add wave -color "Orange" {sim:/tb_top_level/reset}
add wave -color "Red" {sim:/tb_top_level/interrupt}
add wave -color "Cyan" -radix hexadecimal {sim:/tb_top_level/inputport_data}

# Memory interface
add wave -divider "=== MEMORY INTERFACE ==="
add wave -radix hexadecimal {sim:/tb_top_level/instruction_from_mem}
add wave -radix hexadecimal {sim:/tb_top_level/mem_read_data}
add wave -radix hexadecimal {sim:/tb_top_level/mem_req_from_proc}
add wave -radix hexadecimal {sim:/tb_top_level/mem_resp_to_proc}

# Memory unit internals
add wave -divider "=== MEMORY UNIT (RAM) ==="
add wave -radix hexadecimal {sim:/tb_top_level/MEMORY/RAM_INST/addr}
add wave {sim:/tb_top_level/MEMORY/RAM_INST/mem_read}
add wave {sim:/tb_top_level/MEMORY/RAM_INST/mem_write}
add wave -radix hexadecimal {sim:/tb_top_level/MEMORY/RAM_INST/data_in}
add wave -radix hexadecimal {sim:/tb_top_level/MEMORY/RAM_INST/data_out}

# Fetch stage
add wave -divider "=== FETCH STAGE ==="
add wave -radix hexadecimal {sim:/tb_top_level/DUT/FETCH_STAGE/pc_current}
add wave -radix hexadecimal {sim:/tb_top_level/DUT/FETCH_STAGE/pc_next}
add wave {sim:/tb_top_level/DUT/FETCH_STAGE/pc_enable_signal}
add wave {sim:/tb_top_level/DUT/stall_signal}

# IF/ID Pipeline Register
add wave -divider "=== IF/ID REGISTER ==="
add wave -radix hexadecimal {sim:/tb_top_level/DUT/ifid_instruction_out}
add wave -radix binary {sim:/tb_top_level/DUT/ifid_opcode_out}
add wave -radix hexadecimal {sim:/tb_top_level/DUT/ifid_pc_out}

# Decode stage
add wave -divider "=== DECODE STAGE ==="
add wave -radix binary {sim:/tb_top_level/DUT/DECODE_STAGE/opcode}
add wave -radix unsigned {sim:/tb_top_level/DUT/DECODE_STAGE/rs1_addr}
add wave -radix unsigned {sim:/tb_top_level/DUT/DECODE_STAGE/rs2_addr}
add wave -radix unsigned {sim:/tb_top_level/DUT/DECODE_STAGE/rd_addr}

# ID/EX Pipeline Register
add wave -divider "=== ID/EX REGISTER ==="
add wave -radix hexadecimal {sim:/tb_top_level/DUT/ID_EX_REGISTER/Rrs1_out}
add wave -radix hexadecimal {sim:/tb_top_level/DUT/ID_EX_REGISTER/Rrs2_out}
add wave -radix unsigned {sim:/tb_top_level/DUT/ID_EX_REGISTER/rs1_addr_out}
add wave -radix unsigned {sim:/tb_top_level/DUT/ID_EX_REGISTER/rs2_addr_out}
add wave -radix unsigned {sim:/tb_top_level/DUT/ID_EX_REGISTER/rd_addr_out}

# Execute stage
add wave -divider "=== EXECUTE STAGE ==="
add wave -radix hexadecimal {sim:/tb_top_level/exe_alu_result}
add wave -radix binary {sim:/tb_top_level/exe_ccr}
add wave {sim:/tb_top_level/exe_branch_taken}
add wave -radix unsigned {sim:/tb_top_level/exe_rd_addr}

# EX/MEM Pipeline Register
add wave -divider "=== EX/MEM REGISTER ==="
add wave -radix hexadecimal {sim:/tb_top_level/DUT/EX_MEM/alu_result_out}
add wave -radix unsigned {sim:/tb_top_level/DUT/EX_MEM/rd_addr_out}
add wave -radix binary {sim:/tb_top_level/DUT/EX_MEM/wb_signals_out}

# Memory stage
add wave -divider "=== MEMORY STAGE ==="
add wave -radix hexadecimal {sim:/tb_top_level/mem_stage_read_data_out}
add wave -radix hexadecimal {sim:/tb_top_level/mem_alu_result}
add wave -radix unsigned {sim:/tb_top_level/mem_rd_addr}

# MEM/WB Pipeline Register
add wave -divider "=== MEM/WB REGISTER ==="
add wave -radix hexadecimal {sim:/tb_top_level/DUT/MEM_WB/read_data_out}
add wave -radix hexadecimal {sim:/tb_top_level/DUT/MEM_WB/alu_result_out}
add wave -radix unsigned {sim:/tb_top_level/DUT/MEM_WB/rd_addr_out}
add wave -radix binary {sim:/tb_top_level/DUT/MEM_WB/wb_signals_out}

# Writeback stage
add wave -divider "=== WRITEBACK STAGE ==="
add wave -radix hexadecimal {sim:/tb_top_level/DUT/WRITEBACK_STAGE/write_data}
add wave -radix unsigned {sim:/tb_top_level/DUT/WRITEBACK_STAGE/rd_addr}
add wave {sim:/tb_top_level/DUT/WRITEBACK_STAGE/reg_write}

# Register file
add wave -divider "=== REGISTER FILE ==="
add wave -radix hexadecimal {sim:/tb_top_level/DUT/DECODE_STAGE/REGISTER_FILE/general_register(0)}
add wave -radix hexadecimal {sim:/tb_top_level/DUT/DECODE_STAGE/REGISTER_FILE/general_register(1)}
add wave -radix hexadecimal {sim:/tb_top_level/DUT/DECODE_STAGE/REGISTER_FILE/general_register(2)}
add wave -radix hexadecimal {sim:/tb_top_level/DUT/DECODE_STAGE/REGISTER_FILE/general_register(3)}
add wave -radix hexadecimal {sim:/tb_top_level/DUT/DECODE_STAGE/REGISTER_FILE/general_register(4)}
add wave -radix hexadecimal {sim:/tb_top_level/DUT/DECODE_STAGE/REGISTER_FILE/general_register(5)}
add wave -radix hexadecimal {sim:/tb_top_level/DUT/DECODE_STAGE/REGISTER_FILE/general_register(6)}
add wave -radix hexadecimal {sim:/tb_top_level/DUT/DECODE_STAGE/REGISTER_FILE/general_register(7)}

# Set radix and format
config wave -signalnamewidth 1

# Run simulation
echo "========================================="
echo "Running Simulation"
echo "========================================="
echo "Instructions loaded from: ../assembler/output/test_output.mem"
echo ""

run 3000 ns

echo ""
echo "========================================="
echo "Simulation Complete"
echo "========================================="
echo "Use 'run <time>' to continue simulation"
echo "Use 'wave zoom full' to see all waveforms"

# Zoom to fit
wave zoom full
