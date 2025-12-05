# Create work library
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Compile common components
vcom -93 -work work common/general_register.vhd
vcom -93 -work work common/PC.vhd

# Compile control unit
vcom -93 -work work ../decode/control_unit.vhd

# Compile IF/ID register
vcom -93 -work work ../decode/IF_ID_register.vhd

# Compile stages
vcom -93 -work work stages/1_fetch.vhd

# Compile integrated fetch-decode
vcom -93 -work work stages/fetch_decode_integrated.vhd

# Compile top level
vcom -93 -work work top_level_processor.vhd

# Compile testbench
vcom -93 -work work testbench/top_level_processor_tb.vhd

# Start simulation
vsim -t 1ns work.top_level_processor_tb

# Add waves - Top level signals
add wave -divider "Clock and Reset"
add wave -position insertpoint sim:/top_level_processor_tb/clk
add wave -position insertpoint sim:/top_level_processor_tb/reset
add wave -position insertpoint sim:/top_level_processor_tb/external_interrupt

# Memory interface
add wave -divider "Memory Interface"
add wave -position insertpoint -radix hexadecimal sim:/top_level_processor_tb/mem_address
add wave -position insertpoint -radix hexadecimal sim:/top_level_processor_tb/mem_data_in
add wave -position insertpoint -radix hexadecimal sim:/top_level_processor_tb/mem_data_out
add wave -position insertpoint sim:/top_level_processor_tb/mem_read
add wave -position insertpoint sim:/top_level_processor_tb/mem_write

# I/O interface
add wave -divider "I/O Interface"
add wave -position insertpoint -radix hexadecimal sim:/top_level_processor_tb/io_data_in
add wave -position insertpoint -radix hexadecimal sim:/top_level_processor_tb/io_data_out
add wave -position insertpoint sim:/top_level_processor_tb/io_read
add wave -position insertpoint sim:/top_level_processor_tb/io_write

# Internal processor signals
add wave -divider "Internal Control Signals"
add wave -position insertpoint sim:/top_level_processor_tb/UUT/FD_enable_sig
add wave -position insertpoint sim:/top_level_processor_tb/UUT/DE_enable_sig
add wave -position insertpoint sim:/top_level_processor_tb/UUT/Stall_sig
add wave -position insertpoint sim:/top_level_processor_tb/UUT/ID_flush_sig
add wave -position insertpoint sim:/top_level_processor_tb/UUT/Branch_Decode_sig

# Pipeline registers
add wave -divider "Pipeline Data"
add wave -position insertpoint -radix hexadecimal sim:/top_level_processor_tb/UUT/pc_to_decode
add wave -position insertpoint -radix binary sim:/top_level_processor_tb/UUT/opcode_to_decode
add wave -position insertpoint -radix hexadecimal sim:/top_level_processor_tb/UUT/instruction_to_decode

# Control signals
add wave -divider "Control Unit Outputs"
add wave -position insertpoint -radix binary sim:/top_level_processor_tb/UUT/WB_flages_sig
add wave -position insertpoint -radix binary sim:/top_level_processor_tb/UUT/EXE_flages_sig
add wave -position insertpoint -radix binary sim:/top_level_processor_tb/UUT/MEM_flages_sig
add wave -position insertpoint -radix binary sim:/top_level_processor_tb/UUT/IO_flages_sig

# Microcode state
add wave -divider "Microcode"
add wave -position insertpoint -radix binary sim:/top_level_processor_tb/UUT/Micro_inst_sig
add wave -position insertpoint sim:/top_level_processor_tb/UUT/CONTROL/micro_state
add wave -position insertpoint sim:/top_level_processor_tb/UUT/CONTROL/micro_active

# Configure wave window
configure wave -namecolwidth 300
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

# Run simulation
run 1000 ns

# Zoom to fit
wave zoom full

echo "=========================================="
echo "Top-level processor testbench completed"
echo "Check the transcript and waveform for results"
echo "=========================================="
