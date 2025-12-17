# Instruction Memory Loading Guide

## Overview
The processor now supports loading instructions from your assembled binary files before starting execution. This ensures the PC doesn't increment and the pipeline doesn't run during memory loading.

## How It Works

### 1. **Assemble Your Code**
```powershell
cd assembler\src
python assembler.py ..\tests\test_all_instructions.asm ..\output\test_output.mem
```

This generates:
- `assembler/output/test_output.mem` - Binary format (32-bit binary strings, one per line)
- `assembler/output/test_output_hex.mem` - Hex with comments

### 2. **Load Memory in Simulation**

The testbench has a `load_memory_from_file` procedure. In `tb_top_level_aggressive.vhd`:

```vhdl
-- Uncomment these lines to load from file:
load_memory_from_file(
    "../../assembler/output/test_output.mem",  -- Path to your .mem file
    clk,
    load_mode,
    load_addr,
    load_data,
    load_enable
);
```

### 3. **What Happens During Loading**

1. **load_mode = '1'**: Memory enters write mode
2. **PC is NOT incrementing**: Fetch stage is reading but processor is in reset
3. **Each instruction is written**: One per clock cycle
4. **load_mode = '0'**: Memory returns to normal read mode
5. **Pipeline starts**: Normal execution begins with loaded instructions

## Memory Loading Modes

### Option A: Load from File (Recommended)
```vhdl
-- In testbench stimulus process, before reset:
load_memory_from_file(
    "../../assembler/output/test_output.mem",
    clk, load_mode, load_addr, load_data, load_enable
);
```

### Option B: Manual Loading
```vhdl
-- Load mode active
load_mode <= '1';

-- Write to address 0
load_addr <= X"00000000";
load_data <= "00101000000000000000000000000001"; -- LDM R0, 1
load_enable <= '1';
wait until rising_edge(clk);

-- Write to address 1  
load_addr <= X"00000001";
load_data <= X"00000001"; -- Immediate value
load_enable <= '1';
wait until rising_edge(clk);

-- Exit load mode
load_enable <= '0';
load_mode <= '0';
```

### Option C: Pre-initialization from File
Set the generic when instantiating instruction_memory in top_level_processor:

```vhdl
INSTR_MEM: instruction_memory 
    generic map (
        MEM_SIZE => 1024,
        INIT_FILE => "../../assembler/output/test_output.mem"  -- Load at startup
    )
    port map ( ... );
```

## Control Signals

- **load_mode**: `'1'` = loading mode, `'0'` = normal execution
- **load_addr**: 32-bit address to write to
- **load_data**: 32-bit instruction word to write
- **load_enable**: `'1'` = write on next clock edge

## Important Notes

1. **Loading happens BEFORE reset is released** or while processor is in reset
2. **PC does NOT increment** during load_mode = '1'
3. **Pipeline does NOT advance** during load_mode = '1'
4. **After loading**, reset the processor and start normal execution
5. **File format**: Plain text, one 32-bit binary string per line (no comments)

## Complete Example Workflow

```powershell
# 1. Write your assembly
# Edit: assembler/tests/my_program.asm

# 2. Assemble it
cd assembler\src
python assembler.py ..\tests\my_program.asm ..\output\my_program.mem

# 3. Update testbench to load the file
# Edit: src/tb_top_level_aggressive.vhd
# Uncomment and update the load_memory_from_file call

# 4. Run simulation
cd ..\..\src
vsim -do run_top_level_aggressive.do

# 5. Watch waveforms - your loaded program executes!
```

## Simulation Output Example

```
========================================
Loading instruction memory from: ../../assembler/output/test_output.mem
========================================
  Addr 0: 00101000000000000000000000000001
  Addr 1: 00000000000000000000000000000005
  Addr 2: 00101000000000000000000000000010
  Addr 3: 00000000000000000000000000000000
  ...
Loaded 42 instructions into memory
========================================

[Then normal simulation output continues...]
```

## File Format Details

Your `.mem` file from the assembler should look like:
```
00101000000000000000000000000001
00000000000000000000000000000005
00101000000000000000000000000010
00000000000000000000000000000000
01001000000000000000001001010011
...
```

Each line = 1 instruction word (32 bits binary)
No comments, no spaces, just pure binary strings.
