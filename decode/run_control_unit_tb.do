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
echo "Compiling general register..."
vcom -93 -work work ../src/components/register.vhd

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
add wave {sim:/control_unit_tb/data_ready}

add wave -divider "Feedback Input Signals"
add wave -color "Cyan" {sim:/control_unit_tb/mem_will_be_used_in}
add wave -color "Cyan" {sim:/control_unit_tb/Imm_in_use_in}

add wave -divider "Registered Feedback (Inside CU)"
add wave -color "Magenta" {sim:/control_unit_tb/UUT/mem_will_be_used}
add wave -color "Magenta" {sim:/control_unit_tb/UUT/Imm_in_use}

add wave -divider "Pipeline Control Outputs"
add wave {sim:/control_unit_tb/FD_enable}
add wave {sim:/control_unit_tb/DE_enable}
add wave {sim:/control_unit_tb/EM_enable}
add wave {sim:/control_unit_tb/MW_enable}
add wave -color "Orange" {sim:/control_unit_tb/Stall}

add wave -divider "Branch and Flush Control"
add wave {sim:/control_unit_tb/Branch_Decode}
add wave {sim:/control_unit_tb/ID_flush}
add wave {sim:/control_unit_tb/CSwap}
add wave -radix binary {sim:/control_unit_tb/Branch_Exec}

add wave -divider "WB Flags (RegWrite, MemtoReg, PC-sel)"
add wave -radix binary {sim:/control_unit_tb/WB_flages}
add wave {sim:/control_unit_tb/WB_flages(2)}
add wave {sim:/control_unit_tb/WB_flages(1)}
add wave {sim:/control_unit_tb/WB_flages(0)}

add wave -divider "EXE Flags (ALU_OP[4:2], ALUSrc, Index)"
add wave -radix binary {sim:/control_unit_tb/EXE_flages}
add wave -radix binary {sim:/control_unit_tb/EXE_flages(4)}
add wave -radix binary {sim:/control_unit_tb/EXE_flages(3)}
add wave -radix binary {sim:/control_unit_tb/EXE_flages(2)}
add wave {sim:/control_unit_tb/EXE_flages(1)}
add wave {sim:/control_unit_tb/EXE_flages(0)}

add wave -divider "MEM Flags (WDsel, MemR/W, StkR/W, CCR)"
add wave -radix binary {sim:/control_unit_tb/MEM_flages}
add wave {sim:/control_unit_tb/MEM_flages(6)}
add wave {sim:/control_unit_tb/MEM_flages(5)}
add wave {sim:/control_unit_tb/MEM_flages(4)}
add wave {sim:/control_unit_tb/MEM_flages(3)}
add wave {sim:/control_unit_tb/MEM_flages(2)}
add wave {sim:/control_unit_tb/MEM_flages(1)}
add wave {sim:/control_unit_tb/MEM_flages(0)}

add wave -divider "IO Flags (Out, In)"
add wave -radix binary {sim:/control_unit_tb/IO_flages}
add wave {sim:/control_unit_tb/IO_flages(1)}
add wave {sim:/control_unit_tb/IO_flages(0)}

add wave -divider "Other Control Signals"
add wave -color "Magenta" {sim:/control_unit_tb/CCR_enable}
add wave {sim:/control_unit_tb/ForwardEnable}
add wave {sim:/control_unit_tb/Write_in_Src2}
add wave {sim:/control_unit_tb/mem_usage_predict}
add wave {sim:/control_unit_tb/Imm_predict}

add wave -divider "Microcode State Machine"
add wave -radix binary {sim:/control_unit_tb/Micro_inst}
add wave -color "Yellow" {sim:/control_unit_tb/UUT/micro_state}
add wave -color "Cyan" {sim:/control_unit_tb/UUT/micro_next}
add wave {sim:/control_unit_tb/UUT/micro_active}
add wave {sim:/control_unit_tb/UUT/start_swap_req}
add wave {sim:/control_unit_tb/UUT/start_int_req}
add wave {sim:/control_unit_tb/UUT/start_rti_req}
add wave {sim:/control_unit_tb/UUT/start_int_signal_req}
add wave {sim:/control_unit_tb/UUT/start_immediate_req}

add wave -divider "Main Decoder Signals"
add wave {sim:/control_unit_tb/UUT/main_Stall}
add wave {sim:/control_unit_tb/UUT/main_Branch_Decode}
add wave {sim:/control_unit_tb/UUT/main_ID_flush}
add wave {sim:/control_unit_tb/UUT/main_CSwap}
add wave {sim:/control_unit_tb/UUT/main_CCR_enable}
add wave {sim:/control_unit_tb/UUT/main_ForwardEnable}
add wave {sim:/control_unit_tb/UUT/main_write_in_src2}

add wave -divider "Micro Decoder Signals"
add wave {sim:/control_unit_tb/UUT/micro_Stall}
add wave {sim:/control_unit_tb/UUT/micro_Branch_Decode}
add wave {sim:/control_unit_tb/UUT/micro_ID_flush}
add wave {sim:/control_unit_tb/UUT/micro_CSwap}
add wave {sim:/control_unit_tb/UUT/micro_CCR_enable}
add wave {sim:/control_unit_tb/UUT/micro_ForwardEnable}
add wave {sim:/control_unit_tb/UUT/micro_write_in_src2}

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
