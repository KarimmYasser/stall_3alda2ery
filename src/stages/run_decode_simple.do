# Simplified DO file for Decode stage testbench
# Run from: c:\Users\ASUS\Desktop\SWE_Ass\stall_3alda2ery\src\stages

# Create work library
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

echo "========================================="
echo "Compiling Decode Stage Components"
echo "========================================="

# First, let's check what files we have and compile them in correct order
echo "Step 1: Compiling Control Unit..."
if {[file exists ../../decode/control_unit.vhd]} {
    vcom -93 -work work ../../decode/control_unit.vhd
} else {
    echo "ERROR: control_unit.vhd not found!"
    quit -f
}

echo "Step 2: Compiling ID/EX Register..."
if {[file exists ../../decode/id_ex_reg_with_feedback.vhd]} {
    vcom -93 -work work ../../decode/id_ex_reg_with_feedback.vhd
} else {
    echo "WARNING: id_ex_reg_with_feedback.vhd not found, skipping..."
}

echo "Step 3: Compiling Decode Stage..."
if {[file exists 2_decode.vhd]} {
    vcom -93 -work work 2_decode.vhd
} else {
    echo "ERROR: 2_decode.vhd not found!"
    quit -f
}

echo "Step 4: Compiling Testbench..."
if {[file exists tb_decode_aggressive.vhd]} {
    vcom -93 -work work tb_decode_aggressive.vhd
} else {
    echo "ERROR: tb_decode_aggressive.vhd not found!"
    echo "Looking in testbench subfolder..."
    if {[file exists testbench/tb_decode_aggressive.vhd]} {
        vcom -93 -work work testbench/tb_decode_aggressive.vhd
    } else {
        echo "ERROR: Testbench not found in either location!"
        quit -f
    }
}

echo "========================================="
echo "Starting Simulation"
echo "========================================="

# Start simulation
vsim -t 1ns work.tb_decode_aggressive

# Add minimal waves for debugging
add wave -divider "Clock and Control"
add wave sim:/tb_decode_aggressive/clk
add wave sim:/tb_decode_aggressive/reset
add wave sim:/tb_decode_aggressive/inturrupt

add wave -divider "Main Signals"
add wave -radix hexadecimal sim:/tb_decode_aggressive/instruction
add wave -radix hexadecimal sim:/tb_decode_aggressive/PC
add wave sim:/tb_decode_aggressive/Stall
add wave sim:/tb_decode_aggressive/FD_enable
add wave sim:/tb_decode_aggressive/DE_enable

# Configure wave window
configure wave -namecolwidth 250
configure wave -valuecolwidth 100

# Run simulation
run 500 ns

# Zoom to fit
wave zoom full

echo "=========================================="
echo "Simulation Complete"
echo "Check transcript and waveforms"
echo "=========================================="
