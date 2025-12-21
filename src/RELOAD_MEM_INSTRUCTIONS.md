# How to Reload Memory After Assembling

## The Problem
ModelSim loads the `.mem` file only ONCE when the simulation resets (at initialization). If you generate a new `.mem` file while the simulation is running, ModelSim won't automatically reload it.

## The Solution

### Step 1: Assemble your code
```powershell
cd src
python ..\assembler\src\assembler.py ..\assembler\tests\mazen.asm ..\assembler\output\test_output.mem
```

### Step 2: Restart the simulation completely

**Option A: From ModelSim GUI**
1. In the ModelSim transcript window, type:
```tcl
quit -sim
do run_top_level_aggressive.do
```

**Option B: Close and reopen ModelSim**
1. Close ModelSim completely
2. Reopen and run: `do run_top_level_aggressive.do`

### Step 3: Run the simulation
```tcl
run 500 ns
```

## Why This Happens

The RAM component loads the memory file in this code (from [ram.vhd](c:\\Users\\ASUS\\Desktop\\SWE_Ass\\stall_3alda2ery\\memory\\ram.vhd#L40-L55)):

```vhdl
IF (reset = '1') THEN
    -- Safe File Loading
    file_open(file_status, memory_file, INIT_FILENAME, READ_MODE);
    
    IF file_status = OPEN_OK THEN
        FOR i IN memory'RANGE LOOP
            IF NOT ENDFILE(memory_file) THEN
                readline(memory_file, fileLineContent);
                read(fileLineContent, temp_data);
                memory(i) <= temp_data;
            ELSE
                EXIT;
            END IF;
        END LOOP;
        file_close(memory_file);
    END IF;
```

The file is only read **when reset = '1'**, which happens during simulation initialization. Changes to the `.mem` file after that won't be picked up until you restart the simulation.

## Verify Memory Was Loaded Correctly

After restarting, check the memory contents in ModelSim:
```tcl
examine -radix hex /tb_top_level_aggressive/DUT/MEMORY_UNIT_INST/RAM_INST/memory(19)
```

This should show `00000005` for your JMP instruction's target address.
