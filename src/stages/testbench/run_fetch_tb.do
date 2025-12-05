# Create work library if it doesn't exist
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Compile common components
vcom -93 -work work ../../common/general_register.vhd

# Compile stage components
vcom -93 -work work ../1_fetch.vhd

# Compile testbench
vcom -93 -work work fetch_tb.vhd

# Start simulation
vsim -t 1ns work.fetch_tb

# Add waves
add wave -position insertpoint sim:/fetch_tb/*

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

echo "Fetch testbench simulation completed."
