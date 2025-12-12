# ModelSim Simulation Script for Execute Stage Testbench
# Usage: vsim -do run_execute_stage_tb.do

# Create work library if it doesn't exist
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Compile all required files
puts "Compiling Execute Stage Components..."

# Compile ALU and related components
vcom -2008 -work work ../execute/alu.vhd
vcom -2008 -work work ../execute/alu_controller.vhd
vcom -2008 -work work ../execute/ccr.vhd
vcom -2008 -work work ../execute/branch_detection.vhd
vcom -2008 -work work ../execute/forward_unit.vhd

# Compile the execute stage
vcom -2008 -work work ../execute/execute_stage.vhd

# Compile the testbench
puts "Compiling Testbench..."
vcom -2008 -work work ../execute/tb_execute_stage.vhd

# Start simulation
puts "Starting Simulation..."
vsim -voptargs=+acc work.tb_execute_stage

# Configure wave window
view wave

# Add signals to wave window
add wave -divider "Clock and Control"
add wave -color Yellow /tb_execute_stage/clk
add wave -color Orange /tb_execute_stage/rst
add wave -color Orange /tb_execute_stage/flush

add wave -divider "Control Signals"
add wave -radix binary /tb_execute_stage/exe_signals
add wave -radix binary /tb_execute_stage/mem_signals
add wave -radix binary /tb_execute_stage/wb_signals
add wave /tb_execute_stage/output_signal
add wave /tb_execute_stage/input_signal
add wave /tb_execute_stage/ccr_enable

add wave -divider "Data Inputs"
add wave -radix hexadecimal /tb_execute_stage/rs1_data
add wave -radix hexadecimal /tb_execute_stage/rs2_data
add wave -radix hexadecimal /tb_execute_stage/immediate
add wave -radix hexadecimal /tb_execute_stage/in_port
add wave -radix hexadecimal /tb_execute_stage/pc

add wave -divider "Register Addresses"
add wave -radix unsigned /tb_execute_stage/rs1_addr
add wave -radix unsigned /tb_execute_stage/rs2_addr
add wave -radix unsigned /tb_execute_stage/rd_addr

add wave -divider "Forwarding Control"
add wave -radix unsigned /tb_execute_stage/rdst_mem
add wave -radix unsigned /tb_execute_stage/rdst_wb
add wave /tb_execute_stage/reg_write_mem
add wave /tb_execute_stage/reg_write_wb
add wave -radix hexadecimal /tb_execute_stage/mem_forwarded_data
add wave -radix hexadecimal /tb_execute_stage/wb_forwarded_data

add wave -divider "Internal Signals"
add wave -radix hexadecimal /tb_execute_stage/DUT/alu_operand_1
add wave -radix hexadecimal /tb_execute_stage/DUT/alu_operand_2
add wave -radix hexadecimal /tb_execute_stage/DUT/variant_operand
add wave -radix binary /tb_execute_stage/DUT/forward1_signal
add wave -radix binary /tb_execute_stage/DUT/forward2_signal

add wave -divider "ALU Signals"
add wave -radix hexadecimal /tb_execute_stage/DUT/alu_result
add wave -radix binary /tb_execute_stage/DUT/alu_flags
add wave -radix binary /tb_execute_stage/DUT/alu_flags_enable

add wave -divider "CCR"
add wave -radix binary /tb_execute_stage/DUT/ccr_out_sig
add wave -radix binary /tb_execute_stage/ccr_from_stack
add wave /tb_execute_stage/ccr_load

add wave -divider "EX/MEM Outputs"
add wave -radix binary /tb_execute_stage/ex_mem_wb_signals
add wave -radix binary /tb_execute_stage/ex_mem_mem_signals
add wave /tb_execute_stage/ex_mem_output_signal
add wave -radix hexadecimal /tb_execute_stage/ex_mem_alu_result
add wave -radix hexadecimal /tb_execute_stage/ex_mem_rs2_data
add wave -radix binary /tb_execute_stage/ex_mem_ccr
add wave -radix unsigned /tb_execute_stage/ex_mem_rd_addr

add wave -divider "Branch Signals"
add wave /tb_execute_stage/ex_mem_branch_taken
add wave /tb_execute_stage/branch_enable

# Configure wave window appearance
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

# Run simulation
puts "Running Testbench..."
run -all

# Zoom to fit all signals
wave zoom full

puts "Simulation Complete!"
puts "Check transcript for detailed test results."
