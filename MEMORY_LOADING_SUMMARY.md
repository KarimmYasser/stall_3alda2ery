# Memory Loading Summary

## What Was Added

### 1. **Instruction Memory Component** ([components/instruction_memory.vhd](src/components/instruction_memory.vhd))
- RAM for storing program instructions
- Can be initialized from binary file at startup
- Supports runtime loading via load_mode
- 1024 words (32-bit each)

### 2. **Load Mode Interface** (Added to [top_level_processor.vhd](src/top_level_processor.vhd))
New ports:
```vhdl
load_mode   : in std_logic;                        -- '1' = loading, '0' = execution
load_addr   : in std_logic_vector(31 downto 0);   -- Address to write
load_data   : in std_logic_vector(31 downto 0);   -- Data to write  
load_enable : in std_logic;                        -- Write enable
```

### 3. **Memory Loading Procedure** (Added to [tb_top_level_aggressive.vhd](src/tb_top_level_aggressive.vhd))
```vhdl
load_memory_from_file(
    filename,      -- Path to .mem file
    clk,           -- Clock signal
    load_mode,     -- Load mode control
    load_addr,     -- Address output
    load_data,     -- Data output
    load_enable    -- Enable output
);
```

## How to Use

### Quick Start (3 Steps)

**Step 1: Assemble your program**
```powershell
cd assembler\src
python assembler.py ..\tests\test_all_instructions.asm ..\output\test_output.mem
```

**Step 2: Enable loading in testbench**

Edit `src/tb_top_level_aggressive.vhd` around line 240, uncomment:
```vhdl
load_memory_from_file(
    "../../assembler/output/test_output.mem",
    clk, load_mode, load_addr, load_data, load_enable
);
```

**Step 3: Run simulation**
```powershell
cd ..\..\src
vsim -do run_top_level_aggressive.do
```

## Key Features

✅ **No PC increment during loading** - PC stays at 0 while load_mode = '1'
✅ **No pipeline progression during loading** - Pipeline frozen during load
✅ **Loads before execution** - Memory populated before reset is released
✅ **Compatible with assembler output** - Reads binary .mem files directly
✅ **Visible in waveforms** - Load signals added to simulation view

## Three Ways to Load Memory

### Option 1: Runtime Loading (Most Flexible)
Load from testbench procedure during simulation:
```vhdl
load_memory_from_file("../../assembler/output/test_output.mem", ...);
```

### Option 2: Initialization File (Automatic)
Set INIT_FILE generic in top_level_processor.vhd:
```vhdl
INSTR_MEM: instruction_memory 
    generic map (
        MEM_SIZE => 1024,
        INIT_FILE => "../../assembler/output/test_output.mem"
    )
```

### Option 3: Manual Loading (For Testing)
Direct control from testbench:
```vhdl
load_mode <= '1';
load_addr <= X"00000000";
load_data <= "00101000000000000000000000000001";
load_enable <= '1';
wait until rising_edge(clk);
```

## File Format

Your assembler already generates the correct format! 

`test_output.mem`:
```
00101000000000000000000000000001
00000000000000000000000000000005
00101000000000000000000000000010
...
```
- One 32-bit binary instruction per line
- No comments, no spaces
- This is exactly what `assembler.py` outputs

## Waveform Signals Added

New signals in simulation:
- **Memory Loading Mode** section:
  - load_mode (Magenta)
  - load_addr (Cyan, hex)
  - load_data (Green, hex)
  - load_enable
  
- **Instruction Memory** section:
  - read_addr (PC from fetch)
  - instruction_out (to fetch stage)

## What Happens During Execution

1. **Simulation starts** → all signals at initial values
2. **load_memory_from_file called** → load_mode='1', PC frozen at 0
3. **Instructions written** → one per clock cycle to sequential addresses
4. **Loading complete** → load_mode='0', memory ready
5. **Reset asserted** → PC resets to 0
6. **Reset released** → Pipeline starts, PC increments normally
7. **Normal execution** → Fetch reads from loaded memory

## Complete Example

```powershell
# Assemble
cd assembler\src
python assembler.py ..\tests\test_all_instructions.asm ..\output\test_output.mem

# Edit testbench (uncomment load_memory_from_file call)
code ..\..\src\tb_top_level_aggressive.vhd

# Simulate
cd ..\..\src  
vsim -do run_top_level_aggressive.do

# Watch in ModelSim:
# 1. See instructions being loaded (waveform)
# 2. See transcript showing "Loaded X instructions"
# 3. See pipeline executing loaded program
```

## Files Modified

- ✅ `src/components/instruction_memory.vhd` - **NEW** RAM component
- ✅ `src/top_level_processor.vhd` - Added load_mode interface + instruction memory
- ✅ `src/tb_top_level_aggressive.vhd` - Added load signals + loading procedure
- ✅ `src/run_top_level_aggressive.do` - Added instruction_memory compilation + waveforms
- ✅ `MEMORY_LOADING_GUIDE.md` - **NEW** Detailed usage guide

## Next Steps

1. Assemble your program with the provided assembler
2. Uncomment the `load_memory_from_file` call in testbench
3. Run simulation and watch your program execute!

See [MEMORY_LOADING_GUIDE.md](MEMORY_LOADING_GUIDE.md) for detailed examples.
