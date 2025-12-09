# DO file to compile and simulate the Control Unit testbench
# Run from: c:\Users\ASUS\Desktop\SWE_Ass\stall_3alda2ery\decode

# Create work library
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

echo "========================================="
echo "Compiling Control Unit Testbench"
echo "========================================="

# Compile control unit
echo "Compiling control unit..."
vcom -93 -work work control_unit.vhd

# Compile testbench (from decode folder, not testbench subfolder)
echo "Compiling testbench..."
vcom -93 -work work control_unit_tb.vhd

echo "========================================="
echo "Starting Simulation"
echo "========================================="

# Start simulation
vsim -t 1ns work.control_unit_tb

# Add waves
add wave -divider "Clock and Control"
add wave -color "Yellow" {sim:/control_unit_tb/clk}
add wave -color "Red" {sim:/control_unit_tb/inturrupt}
add wave -radix binary {sim:/control_unit_tb/op_code}

add wave -divider "Pipeline Control"
add wave {sim:/control_unit_tb/FD_enable}
add wave {sim:/control_unit_tb/DE_enable}
add wave {sim:/control_unit_tb/EM_enable}
add wave {sim:/control_unit_tb/MW_enable}
add wave -color "Orange" {sim:/control_unit_tb/Stall}

add wave -divider "Branch and Flush"
add wave {sim:/control_unit_tb/Branch_Decode}
add wave {sim:/control_unit_tb/ID_flush}
add wave {sim:/control_unit_tb/CSwap}

add wave -divider "Flags"
add wave -radix binary {sim:/control_unit_tb/WB_flages}
add wave -radix binary {sim:/control_unit_tb/EXE_flages}
add wave -radix binary {sim:/control_unit_tb/MEM_flages}
add wave -radix binary {sim:/control_unit_tb/IO_flages}

add wave -divider "Microcode"
add wave -radix binary {sim:/control_unit_tb/Micro_inst}
add wave {sim:/control_unit_tb/UUT/micro_state}
add wave {sim:/control_unit_tb/UUT/micro_active}

# Configure wave window
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
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
run 2000 ns

# Zoom to fit
wave zoom full

echo ""
echo "=========================================="
echo "Control Unit Testbench Complete"
echo "=========================================="
echo "Check transcript for test results"
echo "Check waveforms for signal analysis"
echo "=========================================="
