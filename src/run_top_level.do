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

# Compile testbench (if exists)
# vcom -93 -work work testbench/top_level_processor_tb.vhd

# Start simulation
# vsim -t 1ns work.top_level_processor_tb

echo "Top-level processor compiled successfully."
echo "Create a testbench and uncomment the simulation lines to run."
