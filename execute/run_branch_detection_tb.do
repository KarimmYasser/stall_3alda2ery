# Compile the branch detection unit
vcom -2008 branch_detection.vhd

# Compile the testbench
vcom -2008 tb_branch_detection.vhd

# Start simulation
vsim -voptargs=+acc work.tb_branch_detection

# Configure wave window
add wave -divider "Inputs"
add wave -color "Cyan" sim:/tb_branch_detection/opcode
add wave -color "Cyan" sim:/tb_branch_detection/ccr

add wave -divider "Output"
add wave -color "Yellow" sim:/tb_branch_detection/branch_taken

add wave -divider "Test Control"
add wave sim:/tb_branch_detection/test_done

# Run simulation
run -all

# Zoom to fit
wave zoom full
