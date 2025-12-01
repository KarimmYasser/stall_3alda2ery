# Create work library if it doesn't exist
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Compile the design files
vcom -93 -work work control_unit.vhd
vcom -93 -work work control_unit_tb.vhd

# Start simulation
vsim -t 1ns work.control_unit_tb

# Add waves for all signals
add wave -position insertpoint sim:/control_unit_tb/*

# Add divider for inputs
add wave -divider "Inputs"
add wave -position insertpoint sim:/control_unit_tb/clk
add wave -position insertpoint sim:/control_unit_tb/inturrupt
add wave -position insertpoint -radix binary sim:/control_unit_tb/op_code
add wave -position insertpoint sim:/control_unit_tb/data_ready

# Add divider for control outputs
add wave -divider "Control Outputs"
add wave -position insertpoint sim:/control_unit_tb/FD_enable
add wave -position insertpoint sim:/control_unit_tb/DE_enable
add wave -position insertpoint sim:/control_unit_tb/EM_enable
add wave -position insertpoint sim:/control_unit_tb/MW_enable
add wave -position insertpoint sim:/control_unit_tb/Stall
add wave -position insertpoint sim:/control_unit_tb/Branch_Decode
add wave -position insertpoint sim:/control_unit_tb/ID_flush
add wave -position insertpoint sim:/control_unit_tb/CSwap

# Add divider for flag outputs
add wave -divider "Flag Outputs"
add wave -position insertpoint -radix binary sim:/control_unit_tb/Micro_inst
add wave -position insertpoint -radix binary sim:/control_unit_tb/WB_flages
add wave -position insertpoint -radix binary sim:/control_unit_tb/EXE_flages
add wave -position insertpoint -radix binary sim:/control_unit_tb/MEM_flages
add wave -position insertpoint -radix binary sim:/control_unit_tb/IO_flages

# Add divider for internal state
add wave -divider "Internal State"
add wave -position insertpoint sim:/control_unit_tb/UUT/micro_state
add wave -position insertpoint sim:/control_unit_tb/UUT/micro_active

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
run 2000 ns

# Zoom to fit
wave zoom full

# Print completion message
echo "Simulation completed. Check the wave window and transcript for results."
