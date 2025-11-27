# CMP 3010: Project Structure Documentation

> **Comprehensive guide to the 32-bit pipelined RISC processor project structure**

---

## 📂 Directory Structure Overview

```
stall_3alda2ery/
│
├── 📚 docs/                              # All documentation and reports
│   ├── phase1/                           # Phase 1 deliverables (Week 10)
│   │   ├── schematics/                   # Block diagrams, dataflow, pipeline visuals
│   │   ├── instruction_format/           # Opcode tables, instruction encoding
│   │   └── hazards_report.pdf            # Data/Structural/Control hazard analysis
│   ├── phase2/                           # Phase 2 deliverables (Week 13)
│   │   ├── design_changes.pdf            # Modifications after Phase 1 feedback
│   │   └── final_report.pdf              # Complete project documentation
│   └── Architecture_Project.pdf          # Official project specification
│
├── 💻 src/                               # VHDL source code
│   ├── common/                           # Shared packages, types, constants
│   ├── components/                       # Reusable hardware units
│   │   ├── alu.vhd                       # 32-bit ALU with Z/N/C flags
│   │   ├── reg_file.vhd                  # 8×32-bit register file (R0-R7)
│   │   ├── mux.vhd                       # Generic N-to-1 multiplexer
│   │   ├── adder.vhd                     # 32-bit adder with carry/overflow
│   │   └── sign_extender.vhd             # 16-bit to 32-bit sign extension
│   ├── stages/                           # 5 pipeline stage implementations
│   │   ├── 1_fetch.vhd                   # IF:  Instruction Fetch
│   │   ├── 2_decode.vhd                  # ID:  Instruction Decode
│   │   ├── 3_execute.vhd                 # EX:  Execute/ALU operations
│   │   ├── 4_memory.vhd                  # MEM: Memory Access
│   │   └── 5_writeback.vhd               # WB:  Register Write-back
│   ├── pipeline/                         # Pipeline control and hazard units
│   │   ├── if_id_reg.vhd                 # IF/ID pipeline register
│   │   ├── id_ex_reg.vhd                 # ID/EX pipeline register
│   │   ├── ex_mem_reg.vhd                # EX/MEM pipeline register
│   │   ├── mem_wb_reg.vhd                # MEM/WB pipeline register
│   │   ├── forwarding_unit.vhd           # Data forwarding logic
│   │   └── hazard_detection.vhd          # Stall/flush control
│   └── top_level_processor.vhd           # Top-level entity (DUT)
│
├── 🧠 memory/                            # Memory subsystem
│   ├── ram.vhd                           # 1 MB unified memory (2^20 × 32-bit)
│   └── stack_pointer.vhd                 # SP control logic
│
├── 🔧 assembler/                         # Custom assembler tool
│   ├── src/                              # Assembler implementation
│   ├── tests/                            # Test assembly programs
│   └── output/                           # Generated machine code (.mem/.hex)
│
├── 🔬 simulation/                        # Testbench and simulation files
│   ├── do_files/                         # Modelsim automation scripts
│   │   ├── compile.do                    # Compilation script
│   │   └── wave.do                       # Waveform configuration
│   ├── test_cases/                       # TA-provided test programs
│   └── waveforms/                        # Saved simulation results
│
├── PROJECT_STRUCTURE.md                  # This file
├── README.md                             # Project overview and documentation
└── .gitignore                            # Git ignore patterns
```

---

## 🏗 Component Details

### 1️⃣ **src/common/** - Shared Definitions

**Purpose**: Centralize type definitions, constants, and utility packages used across the entire design.

**Recommended Files**:

#### `processor_pkg.vhd`

```vhdl
-- Constants and type definitions
package processor_pkg is
    -- Architecture parameters
    constant WORD_WIDTH     : positive := 32;
    constant ADDR_WIDTH     : positive := 20;  -- 2^20 = 1 MB
    constant REG_COUNT      : positive := 8;   -- R0-R7
    constant REG_ADDR_WIDTH : positive := 3;   -- log2(8)
    constant IMM_WIDTH      : positive := 16;  -- Immediate value width

    -- Type definitions
    subtype word_t is std_logic_vector(WORD_WIDTH-1 downto 0);
    subtype addr_t is std_logic_vector(ADDR_WIDTH-1 downto 0);
    subtype reg_addr_t is std_logic_vector(REG_ADDR_WIDTH-1 downto 0);

    -- CCR flags
    constant CCR_Z : natural := 0;  -- Zero flag
    constant CCR_N : natural := 1;  -- Negative flag
    constant CCR_C : natural := 2;  -- Carry flag

    -- Opcode definitions (to be filled based on your encoding)
    constant OP_NOP  : std_logic_vector(4 downto 0) := "00000";
    constant OP_ADD  : std_logic_vector(4 downto 0) := "00001";
    -- ... more opcodes
end package;
```

**Files to Create**:

- `processor_pkg.vhd` - Main package with constants and types
- `control_signals_pkg.vhd` - Control signal definitions
- `alu_ops_pkg.vhd` - ALU operation codes

---

### 2️⃣ **src/components/** - Reusable Hardware Blocks

#### **alu.vhd** - Arithmetic Logic Unit

**Specifications**:

- **Width**: 32-bit
- **Operations**: ADD, SUB, AND, NOT, INC (from ISA)
- **Flags**: Zero (Z), Negative (N), Carry (C)
- **Inputs**:
  - `A`, `B` (32-bit operands)
  - `ALU_OP` (operation select)
  - `Cin` (carry in for chained operations)
- **Outputs**:
  - `Result` (32-bit)
  - `Z`, `N`, `C` (flags)

**Operations to Implement**:

```vhdl
-- ALU Operations (based on ISA)
case alu_op is
    when ALU_ADD  => result := A + B;          -- ADD, IADD
    when ALU_SUB  => result := A - B;          -- SUB
    when ALU_AND  => result := A AND B;        -- AND
    when ALU_NOT  => result := NOT A;          -- NOT
    when ALU_INC  => result := A + 1;          -- INC
    when ALU_PASS => result := A;              -- MOV, SWAP
    when others   => result := (others => '0');
end case;
```

---

#### **reg_file.vhd** - Register File

**Specifications**:

- **Registers**: 8 × 32-bit (R0-R7)
- **Read Ports**: 2 (for Rsrc1, Rsrc2)
- **Write Port**: 1 (for Rdst)
- **Addressing**: 3-bit register address

**Interface**:

```vhdl
entity reg_file is
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        -- Read ports
        rd_addr1    : in  std_logic_vector(2 downto 0);  -- Rsrc1
        rd_addr2    : in  std_logic_vector(2 downto 0);  -- Rsrc2
        rd_data1    : out std_logic_vector(31 downto 0); -- Rsrc1 value
        rd_data2    : out std_logic_vector(31 downto 0); -- Rsrc2 value
        -- Write port
        wr_enable   : in  std_logic;
        wr_addr     : in  std_logic_vector(2 downto 0);  -- Rdst
        wr_data     : in  std_logic_vector(31 downto 0)  -- Data to write
    );
end entity;
```

**Special Behavior**:

- Write on rising edge when `wr_enable='1'`
- Reads are combinational (asynchronous)
- R0 might be hardwired to 0 (design choice)

---

#### **mux.vhd** - Generic Multiplexer

**Current Implementation**:

- Generic width (M=32 for word size)
- Generic input count (N=8 for registers)
- Generic select width (K=3 for 8-way select)

**Use Cases**:

1. **Register File Output Selection**: Select between R0-R7
2. **ALU Input Selection**: Choose between register/immediate
3. **Write-back Mux**: Select between ALU result/Memory data/PC+1

---

#### **adder.vhd** - 32-bit Adder

**Current Implementation**: ✅ Already updated to 32-bit

**Use Cases**:

1. **PC Increment**: PC = PC + 1 or PC + 2 (multi-word instructions)
2. **Branch Target**: PC = PC + offset
3. **SP Operations**: SP = SP ± 1
4. **Address Calculation**: EA = Rsrc + offset (for LDD/STD)

---

#### **sign_extender.vhd** - Sign Extension Unit

**Purpose**: Extend 16-bit immediate values to 32-bit

**Implementation**:

```vhdl
entity sign_extender is
    port (
        input_16  : in  std_logic_vector(15 downto 0);
        output_32 : out std_logic_vector(31 downto 0)
    );
end entity;

architecture behavioral of sign_extender is
begin
    output_32 <= (31 downto 16 => input_16(15)) & input_16;
end architecture;
```

**Used For**: IADD, LDM, LDD, STD, JZ, JN, JC, JMP, CALL

---

### 3️⃣ **src/stages/** - Pipeline Stage Implementations

#### **1_fetch.vhd** - Instruction Fetch (IF)

**Responsibilities**:

- Fetch instruction from memory at address PC
- Calculate PC_next (PC+1, branch target, interrupt vector)
- Handle RESET (PC ← M[0]) and INTERRUPT (PC ← M[1])

**Inputs**:

- Clock, Reset, Interrupt
- Branch signals (from EX stage)
- Branch target address
- Memory data (instruction)

**Outputs**:

- Instruction
- PC+1 (for next stage)

**Control Flow**:

```vhdl
if reset = '1' then
    PC <= M[0];  -- Load starting address from memory[0]
elsif interrupt = '1' then
    PC <= M[1];  -- Jump to interrupt vector
elsif branch_taken = '1' then
    PC <= branch_target;
else
    PC <= PC + 1;  -- Normal increment
end if;
```

---

#### **2_decode.vhd** - Instruction Decode (ID)

**Responsibilities**:

- Decode instruction format
- Generate all control signals
- Read from register file
- Sign-extend immediate values

**Control Signals Generated**:

```vhdl
-- ALU control
alu_op       : ALU operation code
alu_src      : Select immediate or register for ALU input

-- Memory control
mem_read     : Enable memory read
mem_write    : Enable memory write

-- Write-back control
reg_write    : Enable register write
wb_src       : Select ALU/Memory/PC for write-back

-- Branch control
branch       : Branch instruction indicator
jump         : Unconditional jump
call_ret     : CALL or RET instruction
```

**Instruction Format Decoding**:

```
 31...26  25...23  22...20  19...16       15...0
 Opcode   Rdst     Rsrc1    Rsrc2/Func   Immediate/Offset
```

_(Adjust based on your actual encoding)_

---

#### **3_execute.vhd** - Execute (EX)

**Responsibilities**:

- Perform ALU operations
- Calculate branch targets
- Update CCR flags (Z, N, C)
- Determine if branch is taken

**Components Used**:

- ALU
- Adder (for branch target = PC + offset)
- Comparators (for branch conditions)

**Flag Updates**:

```vhdl
-- Zero flag
if alu_result = x"00000000" then
    Z <= '1';
else
    Z <= '0';
end if;

-- Negative flag (MSB)
N <= alu_result(31);

-- Carry flag (from ALU)
C <= alu_carry_out;
```

**Branch Decision**:

```vhdl
branch_taken <= (instr_JZ and Z) or
                (instr_JN and N) or
                (instr_JC and C) or
                (instr_JMP);
```

---

#### **4_memory.vhd** - Memory Access (MEM)

**Responsibilities**:

- Execute load/store operations (LDD, STD)
- Handle stack operations (PUSH, POP)
- Interface with unified memory

**Operations**:

```vhdl
PUSH: mem_addr <= SP;
      mem_data_in <= reg_data;
      mem_write <= '1';
      SP <= SP - 1;

POP:  SP <= SP + 1;
      mem_addr <= SP;
      mem_read <= '1';
      -- Data available in next cycle

LDD:  mem_addr <= reg_src + offset;
      mem_read <= '1';

STD:  mem_addr <= reg_src2 + offset;
      mem_data_in <= reg_src1;
      mem_write <= '1';
```

---

#### **5_writeback.vhd** - Write-Back (WB)

**Responsibilities**:

- Select data to write back to register file
- Enable register write

**Data Sources**:

```vhdl
case wb_src is
    when WB_ALU => wr_data <= alu_result;
    when WB_MEM => wr_data <= mem_read_data;
    when WB_PC  => wr_data <= PC + 1;  -- For CALL
    when others => wr_data <= (others => '0');
end case;
```

---

### 4️⃣ **src/pipeline/** - Pipeline Control

#### **Pipeline Registers**

Each pipeline register stores:

1. **Data signals** (instruction, addresses, values)
2. **Control signals** (ALU op, mem read/write, etc.)

#### **if_id_reg.vhd** - IF/ID Register

```vhdl
-- Stored values
instruction : std_logic_vector(31 downto 0);
PC_plus_1   : std_logic_vector(31 downto 0);
```

#### **id_ex_reg.vhd** - ID/EX Register

```vhdl
-- Control signals
alu_op, mem_read, mem_write, reg_write, branch, ...

-- Data
reg_data1, reg_data2 : std_logic_vector(31 downto 0);
immediate : std_logic_vector(31 downto 0);
PC : std_logic_vector(31 downto 0);
rd_addr : std_logic_vector(2 downto 0);
```

#### **ex_mem_reg.vhd** - EX/MEM Register

```vhdl
-- Control signals
mem_read, mem_write, reg_write, ...

-- Data
alu_result : std_logic_vector(31 downto 0);
mem_write_data : std_logic_vector(31 downto 0);
rd_addr : std_logic_vector(2 downto 0);
```

#### **mem_wb_reg.vhd** - MEM/WB Register

```vhdl
-- Control signals
reg_write, wb_src, ...

-- Data
alu_result : std_logic_vector(31 downto 0);
mem_read_data : std_logic_vector(31 downto 0);
rd_addr : std_logic_vector(2 downto 0);
```

---

#### **forwarding_unit.vhd** - Data Forwarding Logic

**Purpose**: Resolve data hazards by forwarding results from later stages

**Forwarding Scenarios**:

```vhdl
-- EX Hazard (forward from MEM stage)
if (EX_MEM.RegWrite = '1' and EX_MEM.Rd /= 0 and
    EX_MEM.Rd = ID_EX.Rs) then
    forward_A <= "10";  -- Forward from EX/MEM

-- MEM Hazard (forward from WB stage)
elsif (MEM_WB.RegWrite = '1' and MEM_WB.Rd /= 0 and
       MEM_WB.Rd = ID_EX.Rs) then
    forward_A <= "01";  -- Forward from MEM/WB

else
    forward_A <= "00";  -- No forwarding
end if;
```

**Forwarding Paths**:

- `00`: Use value from register file
- `01`: Forward from MEM/WB (previous instruction)
- `10`: Forward from EX/MEM (previous-previous instruction)

---

#### **hazard_detection.vhd** - Stall/Flush Control

**Load-Use Hazard** (requires stall):

```vhdl
-- Detect: instruction in EX is LOAD and next instruction uses result
if (ID_EX.MemRead = '1' and
    (ID_EX.Rd = IF_ID.Rs or ID_EX.Rd = IF_ID.Rt)) then
    stall <= '1';
    -- Insert bubble (NOP) in ID/EX register
end if;
```

**Branch Flush** (on misprediction):

```vhdl
if branch_taken = '1' then
    flush_IF_ID <= '1';
    flush_ID_EX <= '1';
    -- Clear instructions in pipeline
end if;
```

---

### 5️⃣ **memory/** - Memory Subsystem

#### **ram.vhd** - Unified Memory

**Specifications**:

- **Size**: 1 MB (2^20 locations)
- **Width**: 32-bit per location
- **Type**: Synchronous SRAM
- **Ports**: Single read/write port (Von Neumann)

**Interface**:

```vhdl
entity ram is
    port (
        clk       : in  std_logic;
        addr      : in  std_logic_vector(19 downto 0);  -- 2^20 addresses
        data_in   : in  std_logic_vector(31 downto 0);
        data_out  : out std_logic_vector(31 downto 0);
        mem_read  : in  std_logic;
        mem_write : in  std_logic
    );
end entity;
```

**Memory Initialization**:

```vhdl
-- Load program from file
type mem_array is array(0 to 2**20-1) of std_logic_vector(31 downto 0);
signal memory : mem_array := (others => (others => '0'));

-- Read from file in testbench
procedure load_memory(filename : string) is
    -- Implementation
end procedure;
```

---

#### **stack_pointer.vhd** - Stack Pointer Logic

**Purpose**: Central SP management for PUSH, POP, CALL, RET, INT, RTI

**Behavior**:

```vhdl
-- PUSH, CALL, INT
if sp_decrement = '1' then
    SP <= SP - 1;

-- POP, RET, RTI
elsif sp_increment = '1' then
    SP <= SP + 1;

-- RESET
elsif reset = '1' then
    SP <= (19 downto 0 => '1');  -- 2^20 - 1
end if;
```

---

### 6️⃣ **assembler/** - Custom Assembler Tool

#### **assembler/src/** - Implementation

**Recommended Structure** (Python):

```python
assembler/
├── src/
│   ├── assembler.py        # Main entry point
│   ├── parser.py           # Parse assembly instructions
│   ├── encoder.py          # Encode to machine code
│   ├── opcodes.py          # Opcode definitions
│   └── symbol_table.py     # Label/symbol resolution
```

**Features to Implement**:

1. **Instruction Parsing**: Convert assembly mnemonics to binary
2. **Label Resolution**: Handle branch targets and data labels
3. **Two-Pass Assembly**:
   - Pass 1: Build symbol table
   - Pass 2: Generate machine code
4. **Error Handling**: Syntax errors, undefined labels
5. **Output Formats**: `.mem` (binary), `.hex` (hexadecimal)

**Sample Output** (.mem file):

```
00000000000000000000000000000001    // NOP
00010001001010000000000000000101    // LDM R1, 5
00010001010000000000000000000011    // LDM R2, 3
00100001011001010000000000000000    // ADD R3, R1, R2
01000001011000000000000000000000    // OUT R3
11111111111111111111111111111111    // HLT
```

---

#### **assembler/tests/** - Test Programs

**Example Test Programs**:

```assembly
# test_arithmetic.asm
LDM R1, 10       # Load 10 into R1
LDM R2, 5        # Load 5 into R2
ADD R3, R1, R2   # R3 = R1 + R2 = 15
SUB R4, R1, R2   # R4 = R1 - R2 = 5
AND R5, R1, R2   # R5 = R1 AND R2
OUT R3           # Output R3
HLT

# test_memory.asm
LDM R1, 100      # Load immediate
STD R1, 0(R0)    # Store to memory[0]
LDD R2, 0(R0)    # Load from memory[0]
OUT R2           # Should output 100
HLT

# test_branch.asm
LDM R1, 0
INC R1           # R1 = 1
JZ skip          # Should not jump (Z=0)
INC R1           # R1 = 2
skip:
OUT R1           # Output R1
HLT
```

---

### 7️⃣ **simulation/** - Testing Environment

#### **simulation/do_files/compile.do**

```tcl
# Create library
vlib work

# Compile in dependency order
echo "Compiling common packages..."
vcom -2008 src/common/*.vhd

echo "Compiling components..."
vcom -2008 src/components/mux.vhd
vcom -2008 src/components/adder.vhd
vcom -2008 src/components/sign_extender.vhd
vcom -2008 src/components/alu.vhd
vcom -2008 src/components/reg_file.vhd

echo "Compiling memory..."
vcom -2008 memory/ram.vhd
vcom -2008 memory/stack_pointer.vhd

echo "Compiling pipeline registers..."
vcom -2008 src/pipeline/if_id_reg.vhd
vcom -2008 src/pipeline/id_ex_reg.vhd
vcom -2008 src/pipeline/ex_mem_reg.vhd
vcom -2008 src/pipeline/mem_wb_reg.vhd
vcom -2008 src/pipeline/forwarding_unit.vhd
vcom -2008 src/pipeline/hazard_detection.vhd

echo "Compiling pipeline stages..."
vcom -2008 src/stages/1_fetch.vhd
vcom -2008 src/stages/2_decode.vhd
vcom -2008 src/stages/3_execute.vhd
vcom -2008 src/stages/4_memory.vhd
vcom -2008 src/stages/5_writeback.vhd

echo "Compiling top level..."
vcom -2008 src/top_level_processor.vhd

echo "Compilation complete!"
```

#### **simulation/do_files/wave.do**

```tcl
onerror {resume}
quietly WaveActivateNextPane {} 0

# Clock and Control
add wave -noupdate -divider {Clock & Control}
add wave -noupdate /top_level_processor/clk
add wave -noupdate /top_level_processor/RESET.IN
add wave -noupdate /top_level_processor/INTR.IN

# Program Counter & Stack Pointer
add wave -noupdate -divider {PC & SP}
add wave -noupdate -radix hexadecimal /top_level_processor/PC
add wave -noupdate -radix hexadecimal /top_level_processor/SP

# Register File (R0-R7)
add wave -noupdate -divider {Register File}
add wave -noupdate -radix hexadecimal /top_level_processor/R0
add wave -noupdate -radix hexadecimal /top_level_processor/R1
add wave -noupdate -radix hexadecimal /top_level_processor/R2
add wave -noupdate -radix hexadecimal /top_level_processor/R3
add wave -noupdate -radix hexadecimal /top_level_processor/R4
add wave -noupdate -radix hexadecimal /top_level_processor/R5
add wave -noupdate -radix hexadecimal /top_level_processor/R6
add wave -noupdate -radix hexadecimal /top_level_processor/R7

# Condition Code Register
add wave -noupdate -divider {CCR Flags}
add wave -noupdate /top_level_processor/CCR_Z
add wave -noupdate /top_level_processor/CCR_N
add wave -noupdate /top_level_processor/CCR_C

# I/O Ports
add wave -noupdate -divider {I/O Ports}
add wave -noupdate -radix hexadecimal /top_level_processor/IN.PORT
add wave -noupdate -radix hexadecimal /top_level_processor/OUT.PORT

TreeUpdate [SetDefaultTree]
WaveRestoreCursors
configure wave -namecolwidth 200
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
```

---

## 🎯 Implementation Roadmap

### Phase 1: Core Components ✅

1. **Week 1-2**: Basic components

   - [x] Adder (32-bit) ✅
   - [x] MUX (generic) ✅
   - [ ] ALU (32-bit with flags)
   - [ ] Register File (8×32-bit)
   - [ ] Sign Extender (16→32)

2. **Week 3-4**: Memory subsystem

   - [ ] RAM (1 MB, 32-bit wide)
   - [ ] Stack Pointer logic

3. **Week 5-6**: Pipeline stages

   - [ ] Fetch stage
   - [ ] Decode stage (with control unit)
   - [ ] Execute stage (with ALU)
   - [ ] Memory stage
   - [ ] Write-back stage

4. **Week 7**: Pipeline registers
   - [ ] All 4 pipeline registers
   - [ ] Basic integration

### Phase 2: Advanced Features

5. **Week 8-9**: Hazard handling

   - [ ] Forwarding unit
   - [ ] Hazard detection unit
   - [ ] Static branch prediction

6. **Week 10**: Assembler development

   - [ ] Parser and encoder
   - [ ] Test programs
   - [ ] Memory file generation

7. **Week 11-12**: Testing & debugging

   - [ ] Comprehensive test suite
   - [ ] Waveform analysis
   - [ ] Bug fixes

8. **Week 13**: Final integration
   - [ ] Bonus: 2-bit branch predictor
   - [ ] Documentation
   - [ ] Demo preparation

---

## 📊 File Size Estimates

| Component               | Estimated Lines of Code         |
| ----------------------- | ------------------------------- |
| Common packages         | 100-150                         |
| ALU                     | 150-200                         |
| Register File           | 80-120                          |
| Memory (RAM)            | 100-150                         |
| Fetch Stage             | 200-250                         |
| Decode Stage            | 300-400 (includes control unit) |
| Execute Stage           | 250-300                         |
| Memory Stage            | 150-200                         |
| Write-back Stage        | 100-150                         |
| Pipeline Registers (×4) | 400-500 total                   |
| Forwarding Unit         | 150-200                         |
| Hazard Detection        | 200-250                         |
| Top Level               | 300-400                         |
| **Total VHDL**          | **~2500-3500 lines**            |
| Assembler (Python)      | 500-800                         |

---

## 🔍 Quality Checklist

### Before Phase 1 Submission

- [ ] All schematics clearly labeled
- [ ] Instruction encoding documented
- [ ] Opcode table complete
- [ ] Control signal table defined
- [ ] Hazard scenarios documented
- [ ] Forwarding paths identified
- [ ] Pipeline register contents specified

### Before Phase 2 Submission

- [ ] All components compile without errors
- [ ] No latches (all signals assigned in all branches)
- [ ] Test programs execute correctly
- [ ] Waveforms show correct operation
- [ ] Hazard handling verified
- [ ] Assembler generates valid machine code
- [ ] Documentation complete

---

## 🚨 Common Pitfalls to Avoid

1. **Incomplete Signal Assignments** → Creates latches
2. **Incorrect Clock Domains** → Timing violations
3. **Missing Reset Logic** → Unpredictable startup
4. **Hardcoded Widths** → Use generics/constants
5. **Improper Sensitivity Lists** → Simulation ≠ Synthesis
6. **Branch Delay Slots** → Must flush pipeline
7. **Forwarding Edge Cases** → Test all combinations
8. **Stack Overflow/Underflow** → Add bounds checking

---

## 📌 Quick Reference

### Key Constants

```vhdl
WORD_WIDTH      = 32 bits
ADDR_WIDTH      = 20 bits (2^20 = 1 MB)
REG_COUNT       = 8 (R0-R7)
IMM_WIDTH       = 16 bits
INITIAL_SP      = 2^20 - 1
RESET_VECTOR    = M[0]
INTERRUPT_VECTOR = M[1]
```

### Important Addresses

```
M[0] : Initial PC value (on RESET)
M[1] : Interrupt handler address
M[2] : INT 0 handler (optional)
M[3] : INT 1 handler (optional)
```

---

**Last Updated**: November 27, 2025  
**Document Version**: 2.0  
**Project Phase**: Phase 1 - Design & Planning
