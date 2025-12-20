# Create work library
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

echo "========================================="
echo "Golden Program Self-Checking Test"
echo "========================================="

echo "Compiling general register..."
vcom -93 -work work components/register.vhd

echo "Compiling register file..."
vcom -93 -work work components/reg_file.vhd

echo "Compiling memory interface package..."
vcom -93 -work work common/memory_interface_pkg.vhd

echo "Compiling control unit..."
vcom -93 -work work ../decode/control_unit.vhd

echo "Compiling IF/ID pipeline register..."
vcom -93 -work work pipeline/if_id_register.vhd

echo "Compiling ID/EX pipeline register..."
vcom -93 -work work pipeline/id_ex_reg_with_feedback.vhd

echo "Compiling fetch stage..."
vcom -93 -work work stages/1_fetch.vhd

echo "Compiling decode stage..."
vcom -93 -work work stages/2_decode.vhd

echo "Compiling ALU..."
vcom -93 -work work ../execute/alu.vhd

echo "Compiling input port..."
vcom -93 -work work ../memory/input_port.vhd

echo "Compiling forward unit..."
vcom -93 -work work ../execute/forward_unit.vhd

echo "Compiling CCR..."
vcom -93 -work work ../execute/ccr.vhd

echo "Compiling branch detection..."
vcom -93 -work work ../execute/branch_detection.vhd

echo "Compiling execute stage..."
vcom -93 -work work ../execute/execute_stage.vhd

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

echo "Compiling top-level processor..."
vcom -93 -work work top_level_processor.vhd

echo "Compiling golden testbench..."
vcom -2008 -work work tb_golden_inst.vhd

echo "========================================="
echo "Starting Simulation"
echo "========================================="

vsim -t 1ns work.tb_golden_inst

echo "Running simulation for 3000 ns..."
run 3000 ns
