# Stall 3alda2ery (Stall on Demand) Processor

> **32-bit 5-Stage Pipelined RISC Processor with Advanced Hazard Detection**  
> _CMP 3010: Computer Architecture Project - Cairo University, Fall 2025_

[![VHDL](https://img.shields.io/badge/Language-VHDL-blue.svg)](https://en.wikipedia.org/wiki/VHDL)
[![Status](https://img.shields.io/badge/Status-Completed-green.svg)]()
[![Architecture](https://img.shields.io/badge/Architecture-32--bit%20RISC-green.svg)]()
[![Pipeline](https://img.shields.io/badge/Pipeline-5--Stage-orange.svg)]()

---

## 🌟 What is Stall 3alda2ery?

**Stall 3alda2ery** (Arabic: "Stall on Demand") is a fully functional 32-bit RISC processor featuring a 5-stage pipeline with sophisticated hazard detection and handling mechanisms. The name reflects the processor's ability to intelligently stall the pipeline when necessary to resolve hazards, ensuring correct execution while maximizing performance.

This project implements a complete processor system including:
- ✅ 32-bit 5-stage pipelined architecture (IF → ID → EX → MEM → WB)
- ✅ Von Neumann architecture with 1 MB unified memory
- ✅ 20+ RISC instructions with full ISA support
- ✅ Advanced data forwarding to minimize stalls
- ✅ Control hazard handling with branch prediction
- ✅ Interrupt support and I/O operations
- ✅ Custom assembler for easy program development

---

## 📖 Project Overview

This repository contains a complete **32-bit 5-stage pipelined RISC processor** implementation with **von Neumann architecture**, developed as part of the CMP 3010 Computer Architecture course at Cairo University. The processor is designed with modern pipeline optimization techniques including hazard detection, data forwarding, branch prediction, and comprehensive interrupt handling.

### 🎯 Project Goals

This processor demonstrates a complete understanding of computer architecture principles by implementing:

- ✅ **Full RISC ISA**: 20+ instructions covering arithmetic, logic, memory, branching, and I/O operations
- ✅ **Pipeline Hazard Resolution**: Automatic detection and handling of data, structural, and control hazards
- ✅ **Interrupt System**: Non-maskable interrupt support with flag preservation
- ✅ **Development Tools**: Custom assembler for translating assembly code to machine code
- ✅ **Real Hardware Design**: Synthesizable VHDL code ready for FPGA implementation

### ✨ Key Features & Functionality

#### 🖥️ **Core Architecture**
- **32-bit Word Size**: All registers, data buses, and ALU operate on 32-bit data
- **5-Stage Pipeline**: Instruction Fetch (IF) → Decode (ID) → Execute (EX) → Memory (MEM) → Write-Back (WB)
- **8 General-Purpose Registers**: R0-R7, each 32-bit wide
- **1 MB Unified Memory**: Von Neumann architecture with 2^20 addressable 32-bit locations
- **Condition Code Register (CCR)**: Zero (Z), Negative (N), and Carry (C) flags

#### ⚡ **Pipeline Optimization**
- **Data Forwarding**: Bypasses results directly from EX/MEM and MEM/WB stages to avoid unnecessary stalls
- **Hazard Detection**: Automatically detects RAW (Read-After-Write) dependencies and inserts stalls only when necessary
- **Branch Prediction**: Reduces control hazard penalties with static/dynamic prediction
- **Structural Hazard Prevention**: Careful design ensures no resource conflicts

#### 🔧 **Instruction Set Architecture**
- **One-Operand Instructions**: NOP, HLT, SETC, NOT, INC, IN, OUT (7 instructions)
- **Two-Operand Instructions**: MOV, SWAP, ADD, SUB, AND, IADD (6 instructions)
- **Memory Operations**: PUSH, POP, LDM, LDD, STD (5 instructions)
- **Branch & Control Flow**: JZ, JN, JC, JMP, CALL, RET, INT, RTI (8 instructions)
- **Special Operations**: RESET and hardware INTERRUPT support

#### 🛡️ **Interrupt & I/O System**
- **Non-Maskable Interrupt**: Hardware interrupt with automatic flag preservation and restoration
- **32-bit I/O Ports**: Dedicated IN and OUT ports for external device communication
- **Software Interrupts**: INT instruction for system calls and traps
- **Stack-Based Context Saving**: Automatic PC and flag preservation during interrupts

#### 🔨 **Development Tools**
- **Custom Assembler**: Converts assembly language to machine code
- **Memory File Generation**: Produces initialization files for simulation
- **Comprehensive Test Suite**: Pre-built test programs for validation
- **Modelsim Integration**: Ready-to-use simulation scripts

---

## 🏗 Architecture Specifications

### Core Components

| Component                | Specification | Details                                       |
| ------------------------ | ------------- | --------------------------------------------- |
| **Architecture**         | Von Neumann   | Unified memory for instructions and data      |
| **Word Size**            | 32-bit        | All registers and data buses are 32-bit wide  |
| **Memory Size**          | 1 MB          | 2^18 addressable locations, 32-bit width each |
| **Data Bus Width**       | 32-bit        | Memory and register data interface            |
| **General Registers**    | 8 × 32-bit    | R0, R1, R2, R3, R4, R5, R6, R7                |
| **Program Counter (PC)** | 32-bit        | Points to next instruction address            |
| **Stack Pointer (SP)**   | 32-bit        | Initial value: 2^20 - 1 (grows downward)      |
| **CCR**                  | 4-bit         | Z (Zero), N (Negative), C (Carry) flags       |
| **Pipeline Depth**       | 5 stages      | IF → ID → EX → MEM → WB                       |

### I/O and Control Signals

| Signal       | Width  | Description                          |
| ------------ | ------ | ------------------------------------ |
| **IN.PORT**  | 32-bit | Data input port for IN instruction   |
| **OUT.PORT** | 32-bit | Data output port for OUT instruction |
| **INTR.IN**  | 1-bit  | Non-maskable interrupt request       |
| **RESET.IN** | 1-bit  | System reset (PC ← M[0])             |

### Condition Code Register (CCR)

```
CCR<3:0>
├── CCR<0> : Z (Zero flag)       - Set when result = 0
├── CCR<1> : N (Negative flag)   - Set when result < 0
└── CCR<2> : C (Carry flag)      - Set on arithmetic carry/borrow
```

---

## 📋 Instruction Set Architecture (ISA)

### Instruction Format

- **Immediate Values**: 16-bit
- **Address Offsets**: 16-bit
- **Register Addressing**: 3-bit (R0-R7)
- **Multi-word Instructions**: Some instructions occupy 2+ memory locations

### Instruction Categories

#### 1️⃣ One-Operand Instructions (3 marks)

| Mnemonic   | Function                      | Flags Affected |
| ---------- | ----------------------------- | -------------- |
| `NOP`      | No operation (PC ← PC + 1)    | -              |
| `HLT`      | Halt - freezes PC until reset | -              |
| `SETC`     | Set carry flag (C ← 1)        | C              |
| `NOT Rdst` | 1's complement of Rdst        | Z, N           |
| `INC Rdst` | Increment Rdst by 1           | Z, N, C        |
| `OUT Rdst` | OUT.PORT ← R[Rdst]            | -              |
| `IN Rdst`  | R[Rdst] ← IN.PORT             | -              |

#### 2️⃣ Two-Operand Instructions (3.5 marks)

| Mnemonic                 | Function                        | Flags Affected |
| ------------------------ | ------------------------------- | -------------- |
| `MOV Rsrc, Rdst`         | R[Rdst] ← R[Rsrc]               | -              |
| `SWAP Rsrc, Rdst`        | Exchange R[Rsrc] ↔ R[Rdst]      | -              |
| `ADD Rdst, Rsrc1, Rsrc2` | R[Rdst] ← R[Rsrc1] + R[Rsrc2]   | Z, N, C        |
| `SUB Rdst, Rsrc1, Rsrc2` | R[Rdst] ← R[Rsrc1] - R[Rsrc2]   | Z, N, C        |
| `AND Rdst, Rsrc1, Rsrc2` | R[Rdst] ← R[Rsrc1] AND R[Rsrc2] | Z, N           |
| `IADD Rdst, Rsrc, Imm`   | R[Rdst] ← R[Rsrc] + Imm         | Z, N, C        |

#### 3️⃣ Memory Operations (3.5 marks)

| Mnemonic                   | Function                        | Description             |
| -------------------------- | ------------------------------- | ----------------------- |
| `PUSH Rdst`                | M[SP] ← R[Rdst]; SP ← SP - 1    | Push to stack           |
| `POP Rdst`                 | SP ← SP + 1; R[Rdst] ← M[SP]    | Pop from stack          |
| `LDM Rdst, Imm`            | R[Rdst] ← Imm<15:0>             | Load immediate (16-bit) |
| `LDD Rdst, offset(Rsrc)`   | R[Rdst] ← M[R[Rsrc] + offset]   | Load from memory        |
| `STD Rsrc1, offset(Rsrc2)` | M[R[Rsrc2] + offset] ← R[Rsrc1] | Store to memory         |

#### 4️⃣ Branch & Control Flow (3.5 marks)

| Mnemonic    | Function                            | Description            |
| ----------- | ----------------------------------- | ---------------------- |
| `JZ Imm`    | If Z=1: PC ← Imm; Z ← 0             | Jump if zero           |
| `JN Imm`    | If N=1: PC ← Imm; N ← 0             | Jump if negative       |
| `JC Imm`    | If C=1: PC ← Imm; C ← 0             | Jump if carry          |
| `JMP Imm`   | PC ← Imm                            | Unconditional jump     |
| `CALL Imm`  | M[SP] ← PC+1; SP ← SP-1; PC ← Imm   | Call subroutine        |
| `RET`       | SP ← SP+1; PC ← M[SP]               | Return from subroutine |
| `INT index` | M[SP] ← PC+1; SP--; PC ← M[index+2] | Software interrupt     |
| `RTI`       | SP++; PC ← M[SP]; Restore flags     | Return from interrupt  |

### Special Behaviors

**RESET**: PC ← M[0] (Load starting address from memory location 0)  
**INTERRUPT**: M[SP] ← PC; SP--; PC ← M[1]; Preserve flags

---

## 🔄 Pipeline Architecture

### Pipeline Stages

```
┌─────────────┬──────────────┬──────────────┬──────────────┬──────────────┐
│     IF      │      ID      │      EX      │     MEM      │      WB      │
│  (Fetch)    │   (Decode)   │  (Execute)   │  (Memory)    │ (WriteBack)  │
├─────────────┼──────────────┼──────────────┼──────────────┼──────────────┤
│ • PC logic  │ • Reg read   │ • ALU ops    │ • Load/Store │ • Reg write  │
│ • I-Fetch   │ • Control    │ • CCR update │ • PUSH/POP   │ • Data mux   │
│ • PC update │  signals     │ • Branch     │ • Address    │              │
│             │ • Decode     │  calc        │  calc        │              │
└─────────────┴──────────────┴──────────────┴──────────────┴──────────────┘
```

### Pipeline Registers

| Register   | Contents                                              |
| ---------- | ----------------------------------------------------- |
| **IF/ID**  | Instruction, PC+1                                     |
| **ID/EX**  | Control signals, Register values, PC, Immediate       |
| **EX/MEM** | ALU result, Memory data, Control signals              |
| **MEM/WB** | Memory/ALU result, Destination register, Write enable |

---

## 🛠 Hazard Handling

### Data Hazards (1 mark)

**Problem**: RAW (Read After Write) dependencies

**Solution**: **Data Forwarding**

```
ADD R1, R2, R3    # R1 = R2 + R3
SUB R4, R1, R5    # Needs R1 from previous instruction

→ Forward R1 from EX/MEM or MEM/WB to EX stage
```

**Forwarding Paths**:

- EX/MEM → EX (Forward from previous ALU result)
- MEM/WB → EX (Forward from previous memory/WB data)

### Structural Hazards (1 mark)

**Problem**: Resource conflicts (e.g., memory access)

**Solution**: Proper scheduling to avoid simultaneous access

### Control Hazards (1 mark)

**Problem**: Branch/Jump instructions cause pipeline stalls

**Solution**: **Static Branch Prediction**

- Predict: Always Taken or Always Not Taken
- Flush pipeline on misprediction

**Bonus (2 marks)**: **2-bit Dynamic Branch Predictor**

```
States:
  00: Strongly Not Taken
  01: Weakly Not Taken
  10: Weakly Taken
  11: Strongly Taken
```

---

## 📂 Repository Structure

```
stall_3alda2ery/
│
├── 📁 src/                           # VHDL source code
│   ├── common/                       # Shared components (registers, PC)
│   ├── components/                   # Reusable units (mux, adder, etc.)
│   ├── stages/                       # Pipeline stage implementations
│   ├── pipeline/                     # Pipeline registers & control
│   ├── testbench/                    # Test benches
│   ├── top_level_processor.vhd       # Top-level processor entity
│   └── *.do                          # ModelSim simulation scripts
│
├── 📁 fetch/                         # Fetch stage components
│   └── pc.vhd                        # Program counter logic
│
├── 📁 decode/                        # Decode stage components
│   ├── control_unit.vhd              # Instruction decoder & control
│   ├── IF_ID_register.vhd            # IF/ID pipeline register
│   └── testbench/                    # Decode stage tests
│
├── 📁 execute/                       # Execute stage components
│   ├── alu.vhd                       # Arithmetic Logic Unit
│   ├── alu_controller.vhd            # ALU operation control
│   ├── ccr.vhd                       # Condition code register
│   ├── forward_unit.vhd              # Data forwarding logic
│   ├── branch_detection.vhd          # Branch decision logic
│   ├── execute_stage.vhd             # Complete execute stage
│   └── output_port.vhd               # Output port interface
│
├── 📁 memory/                        # Memory stage components
│   └── [Memory and stack operations]
│
├── 📁 units/                         # Control & hazard detection units
│   ├── epc.vhd                       # Enhanced PC control
│   └── flush_detection_unit.vhd      # Pipeline flush logic
│
├── 📁 assembler/                     # Custom assembler tool
│   ├── src/                          # Assembler implementation
│   ├── tests/                        # Test assembly programs
│   └── output/                       # Generated machine code
│
├── 📁 scripts/                       # Utility scripts
├── 📁 waves/                         # Saved waveform files
├── 📁 simulation/                    # Simulation files
├── 📁 docs/                          # Documentation
│
├── README.md                         # This file
├── PROJECT_STRUCTURE.md              # Detailed structure documentation
├── MEMORY_LOADING_GUIDE.md           # Memory initialization guide
├── alu_ops.md                        # ALU operations reference
└── OPCODES.txt                       # Instruction encoding table
```

For a detailed breakdown of each component and design guidelines, see [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md).

---

## 🚀 Getting Started

### Prerequisites

- **ModelSim/QuestaSim**: VHDL simulator for testing and verification
- **Python 3.x** or **C++**: For running the custom assembler
- **Git**: Version control system
- **Text Editor**: VS Code, Sublime Text, or any VHDL-capable editor

### Quick Start Guide

#### 1. Clone the Repository

```bash
git clone https://github.com/KarimmYasser/stall_3alda2ery.git
cd stall_3alda2ery
```

#### 2. Write Your First Program

Create a simple assembly program (`test.asm`):

```assembly
# Simple arithmetic test program
LDM R1, 10      # Load immediate value 10 into R1
LDM R2, 5       # Load immediate value 5 into R2
ADD R3, R1, R2  # R3 = R1 + R2 = 15
OUT R3          # Output R3 to OUT.PORT
HLT             # Halt processor
```

#### 3. Assemble the Program

```bash
cd assembler
python src/assembler.py tests/test.asm
```

This generates a machine code file that can be loaded into memory.

#### 4. Run Simulation

```bash
cd ../src
vsim -do run_top_level.do
```

In the ModelSim console:

```tcl
# Apply reset
force RESET.IN 1
run 10 ns
force RESET.IN 0

# Run the program
run 1000 ns

# Check output
examine OUT.PORT
```

#### 5. View Results

Check the waveform viewer to see:
- Register values (R0-R7)
- Pipeline stages operation
- Memory accesses
- Flag updates (Z, N, C)

---

## 📊 How It Works

### Pipeline Stage Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│                     5-Stage Pipeline Operation                        │
├──────────┬───────────┬──────────┬───────────┬───────────────────────┤
│    IF    │    ID     │    EX    │    MEM    │         WB           │
│ (Fetch)  │ (Decode)  │ (Execute)│ (Memory)  │    (Write-Back)      │
├──────────┼───────────┼──────────┼───────────┼───────────────────────┤
│ • Fetch  │ • Decode  │ • ALU    │ • Load/   │ • Write result       │
│   instr  │   opcode  │   ops    │   Store   │   to register        │
│ • PC++   │ • Read    │ • Branch │ • Stack   │ • Select data        │
│ • Handle │   regs    │   calc   │   ops     │   source             │
│   branch │ • Gen     │ • Update │ • Address │                      │
│          │   control │   flags  │   calc    │                      │
└──────────┴───────────┴──────────┴───────────┴───────────────────────┘
```

### Hazard Handling in Action

#### **Data Hazards**
When an instruction needs data from a previous instruction:

```assembly
ADD R1, R2, R3    # Cycle 1: R1 = R2 + R3
SUB R4, R1, R5    # Cycle 2: Needs R1 from previous instruction
```

**Solution**: The forwarding unit detects R1 dependency and forwards the ALU result directly from EX/MEM register, avoiding a stall.

#### **Control Hazards**
When a branch changes program flow:

```assembly
JZ target         # Branch if zero flag is set
ADD R1, R2, R3    # This might not execute
```

**Solution**: Branch prediction predicts the outcome. If wrong, the pipeline flushes incorrect instructions.

#### **Load-Use Hazards**
When data is loaded from memory and immediately used:

```assembly
LDD R1, 0(R2)     # Load from memory
ADD R3, R1, R4    # Use R1 immediately
```

**Solution**: A 1-cycle stall is inserted since memory access takes one extra cycle. Data forwarding then provides the loaded value.

---

## 🔍 Processor Functionality Deep Dive

### Memory Organization

```
Address Space (1 MB = 2^20 locations × 32-bit)
┌─────────────────────┐ 0x00000
│  Reset Vector (M[0])│ → Initial PC value
├─────────────────────┤ 0x00001
│  INT Vector (M[1])  │ → Interrupt handler address
├─────────────────────┤ 0x00002
│  Program Code       │
│      ...            │
├─────────────────────┤
│  Data Section       │
│      ...            │
├─────────────────────┤
│  Stack (grows down) │ ← SP starts at 0xFFFFF
└─────────────────────┘ 0xFFFFF
```

### Register File

| Register | Purpose | Special Notes |
|----------|---------|---------------|
| **R0-R7** | General purpose | All 32-bit wide |
| **PC** | Program Counter | Points to next instruction |
| **SP** | Stack Pointer | Initialized to 0xFFFFF (2^20-1) |
| **CCR** | Condition Codes | Z (Zero), N (Negative), C (Carry) |

### Instruction Execution Examples

#### Example 1: Arithmetic Operation
```assembly
LDM R1, 100     # Load 100 into R1
LDM R2, 50      # Load 50 into R2
ADD R3, R1, R2  # R3 = 100 + 50 = 150
```

**Pipeline Timeline:**
```
Cycle 1: LDM R1 → IF
Cycle 2: LDM R1 → ID, LDM R2 → IF
Cycle 3: LDM R1 → EX, LDM R2 → ID, ADD → IF
Cycle 4: LDM R1 → MEM, LDM R2 → EX, ADD → ID (reads R1, R2)
Cycle 5: LDM R1 → WB, LDM R2 → MEM, ADD → EX (computes sum)
Cycle 6: LDM R2 → WB, ADD → MEM
Cycle 7: ADD → WB (writes R3 = 150)
```

#### Example 2: Branch with Hazard
```assembly
ADD R1, R2, R3  # R1 = R2 + R3, sets flags
JZ target       # Jump if Z flag = 1
NOP
NOP
target: OUT R1
```

**Hazard Resolution**: The branch detection unit checks the Z flag immediately after the ADD instruction completes in EX stage. If prediction is wrong, IF and ID stages are flushed.

#### Example 3: Subroutine Call
```assembly
CALL func       # Push PC+1 to stack, jump to func
# ... main continues after return

func:
  PUSH R1       # Save R1
  LDM R1, 42    # Use R1
  OUT R1        # Output result
  POP R1        # Restore R1
  RET           # Pop return address, jump back
```

**Stack Operations:**
1. CALL: `M[SP] ← PC+1, SP ← SP-1, PC ← func_address`
2. PUSH: `M[SP] ← R1, SP ← SP-1`
3. POP: `SP ← SP+1, R1 ← M[SP]`
4. RET: `SP ← SP+1, PC ← M[SP]`

---

## 🔧 Advanced Features

### Data Forwarding Mechanism

The forwarding unit monitors register dependencies and provides three data paths:

```
Forwarding Paths:
┌─────────────────────────────────────────────┐
│ EX/MEM → EX    (Forward from previous ALU)  │
│ MEM/WB → EX    (Forward from memory/WB)     │
│ Register File  (Normal read, no forwarding) │
└─────────────────────────────────────────────┘
```

### Interrupt Handling Sequence

When hardware interrupt occurs (INTR.IN = 1):

1. **Current instruction completes**
2. **Save context**: `M[SP] ← PC, M[SP-1] ← CCR, SP ← SP-2`
3. **Jump to handler**: `PC ← M[1]`
4. **Execute interrupt handler**
5. **Return**: RTI instruction restores PC and CCR

### Branch Prediction

**Static Prediction** (Basic implementation):
- Always predict "taken" or "not taken"
- Flush pipeline on misprediction (2-3 cycle penalty)

**Dynamic Prediction** (Bonus feature):
- 2-bit saturating counter for each branch
- States: Strongly Not Taken → Weakly Not Taken → Weakly Taken → Strongly Taken
- Adapts to branch behavior over time

---

## 📊 Implementation Status

### ✅ Completed Components

#### Core Pipeline Stages
- ✅ **Fetch Stage** - Instruction fetching with PC management
- ✅ **Decode Stage** - Control unit with instruction decoding
- ✅ **Execute Stage** - ALU operations with forwarding support
- ✅ **Memory Stage** - Load/Store and stack operations
- ✅ **Write-Back Stage** - Register file updates

#### Pipeline Infrastructure
- ✅ **IF/ID Register** - Fetch to Decode pipeline register
- ✅ **ID/EX Register** - Decode to Execute pipeline register
- ✅ **EX/MEM Register** - Execute to Memory pipeline register
- ✅ **MEM/WB Register** - Memory to Write-Back pipeline register

#### Hazard Handling
- ✅ **Forwarding Unit** - Data hazard resolution with bypass paths
- ✅ **Flush Detection** - Control hazard handling
- ✅ **Branch Detection** - Branch decision logic

#### Core Components
- ✅ **ALU** - 32-bit arithmetic and logic operations with flags
- ✅ **ALU Controller** - Operation selection and control
- ✅ **CCR** - Condition Code Register (Z, N, C flags)
- ✅ **Program Counter** - PC management with branch support
- ✅ **Register File** - 8×32-bit general-purpose registers

#### Support Systems
- ✅ **I/O Ports** - Input and output port interfaces
- ✅ **Control Unit** - Complete instruction decoding
- ✅ **Custom Assembler** - Assembly to machine code translation
- ✅ **Test Infrastructure** - Comprehensive testbenches

---

## ✅ Evaluation Criteria (20 Marks Total)

| Component                 | Marks | Description                                            |
| ------------------------- | ----- | ------------------------------------------------------ |
| **Instructions**          | 17    | Implementation of all ISA instructions                 |
| │ One-Operand             | 3.0   | NOP, HLT, SETC, NOT, INC, IN, OUT                      |
| │ Two-Operand             | 3.5   | MOV, SWAP, ADD, SUB, AND, IADD                         |
| │ Memory Ops              | 3.5   | PUSH, POP, LDM, LDD, STD                               |
| │ Branch/Control          | 3.5   | JZ, JN, JC, JMP, CALL, RET, INT, RTI                   |
| │ Reset/Interrupt         | 1.5   | RESET (0.5), INTR (1.0)                                |
| │ Program File Generation | 2.0   | Working assembler                                      |
| **Hazards**               | 3     | Hazard detection and handling                          |
| │ Data Hazards            | 1.0   | Forwarding unit implementation                         |
| │ Structural Hazards      | 1.0   | Resource conflict resolution                           |
| │ Control Hazards         | 1.0   | Branch prediction & flush logic                        |
| **Bonus**                 | +2    | 2-bit dynamic branch predictor + address calc in fetch |

**⚠️ Important Notes**:

- Non-working processor = **Zero grade** (no partial credits)
- Unnecessary latching or poor hardware understanding = **Penalty**
- Individual grades within team based on contribution

---

## 🧪 Testing & Validation

### Running Simulations

#### **Option 1: Top-Level Processor Test**
```bash
cd src
vsim -do run_top_level.do
```

#### **Option 2: Execute Stage Test**
```bash
cd src
vsim -do run_top_level_execute.do
```

#### **Option 3: Control Unit Test**
```bash
cd decode
vsim -do run_control_unit_tb.do
```

#### **Option 4: Individual Stage Tests**
```bash
cd execute
vsim -do [testbench script]
```

### Simulation Workflow

1. **Initialize Simulation**
   ```tcl
   # In ModelSim console
   force RESET.IN 1
   run 10 ns
   force RESET.IN 0
   ```

2. **Load Input Data** (if using IN instruction)
   ```tcl
   force IN.PORT 16#12345678
   ```

3. **Run Simulation**
   ```tcl
   run 1000 ns
   ```

4. **Examine Results**
   ```tcl
   # Check register values
   examine -radix hex /top_level_processor/R0
   examine -radix hex /top_level_processor/R1
   
   # Check output
   examine -radix hex /top_level_processor/OUT.PORT
   
   # Check flags
   examine /top_level_processor/CCR_Z
   examine /top_level_processor/CCR_N
   examine /top_level_processor/CCR_C
   ```

### Key Waveform Signals

Monitor these signals during simulation:
- **Clock & Control**: CLK, RESET.IN, INTR.IN
- **Registers**: R0, R1, R2, R3, R4, R5, R6, R7
- **Pointers**: PC, SP
- **Flags**: CCR_Z, CCR_N, CCR_C
- **I/O**: IN.PORT, OUT.PORT
- **Pipeline**: IF/ID signals, ID/EX signals, EX/MEM signals, MEM/WB signals

---

## 🎯 Design Guidelines & Best Practices

### Hardware Design Principles

1. ✅ **Think Hardware First**: Remember that VHDL describes physical circuits, not software
2. ✅ **Synchronous Design**: All state changes occur on clock edges
3. ✅ **Complete Signal Assignment**: Assign values to all signals in all code paths to avoid latches
4. ✅ **Reset Strategy**: Ensure all registers have proper reset initialization
5. ✅ **Pipeline Awareness**: Account for pipeline delays in timing-critical operations

### Development Workflow

1. 🔄 **Compile Frequently**: Check for syntax errors after each change
2. 🧪 **Unit Test First**: Validate individual components before integration
3. 📊 **Verify Waveforms**: Always check simulation waveforms to ensure correct operation
4. 🐛 **Debug Methodically**: Use waveforms to trace signal values through pipeline stages
5. 📝 **Document Changes**: Keep track of modifications and design decisions

### Common Pitfalls to Avoid

| Issue | Solution |
|-------|----------|
| **Incomplete assignments** → Creates unwanted latches | Assign all signals in all branches of if/case statements |
| **Asynchronous logic** → Timing violations | Use synchronous design with clock edges |
| **Missing reset** → Unpredictable behavior | Initialize all registers on reset |
| **Incorrect forwarding** → Wrong results | Verify forwarding unit logic for all hazard cases |
| **Branch flush errors** → Invalid instructions executed | Ensure pipeline flush clears IF and ID stages correctly |
| **Stack overflow** → Memory corruption | Track SP carefully during PUSH/POP operations |

---

## 🔧 Troubleshooting

### Compilation Errors

**Problem**: "entity not found" or "component not declared"  
**Solution**: Check compilation order. Compile dependencies first:
```bash
# Correct order:
1. Common packages
2. Basic components (mux, adder)
3. Complex components (ALU, register file)
4. Pipeline registers
5. Pipeline stages
6. Top level
```

**Problem**: "signal not declared"  
**Solution**: Verify port declarations match between entity and architecture

### Simulation Issues

**Problem**: Signals show 'U' (undefined) values  
**Solution**: 
- Ensure proper reset sequence
- Initialize all signals in processes
- Check that all drivers are properly connected

**Problem**: Pipeline produces wrong results  
**Solution**:
- Verify forwarding unit logic
- Check for off-by-one errors in pipeline registers
- Trace instruction flow through each stage in waveform viewer

**Problem**: Branch instructions don't work  
**Solution**:
- Verify branch detection logic
- Check that PC is updated correctly
- Ensure pipeline flush clears the correct stages

### Performance Issues

**Problem**: Too many stalls, poor performance  
**Solution**:
- Verify forwarding unit is enabled and working
- Check that stalls only occur for true load-use hazards
- Review branch prediction effectiveness

---

## 📚 Additional Resources

### Reference Documentation

- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Detailed component specifications and implementation guidelines
- **[MEMORY_LOADING_GUIDE.md](MEMORY_LOADING_GUIDE.md)** - How to initialize memory for simulation
- **[alu_ops.md](alu_ops.md)** - ALU operation codes and functionality
- **[OPCODES.txt](OPCODES.txt)** - Complete instruction encoding reference

### Learning Resources

- **VHDL Language**: IEEE Standard 1076-2008
- **Pipeline Design**: "Computer Architecture: A Quantitative Approach" by Hennessy & Patterson
- **Hazard Handling**: "Computer Organization and Design" by Patterson & Hennessy
- **ModelSim Guide**: Mentor Graphics ModelSim User Manual

---

## 👥 Project Team & Course Information

- **Course**: CMP 3010 - Computer Architecture
- **Institution**: Cairo University, Faculty of Engineering
- **Department**: Computer Engineering
- **Semester**: Fall 2025

### Academic Context

This project demonstrates mastery of:
- Digital logic design and VHDL programming
- Pipelined processor architecture and optimization
- Hazard detection and resolution techniques
- Hardware-software interface design
- Computer architecture simulation and testing

---

## 📄 License

This project is developed for academic purposes as part of CMP 3010 at Cairo University, Faculty of Engineering, Computer Engineering Department.

---

**Last Updated**: January 31, 2026  
**Project Status**: ✅ Completed - Fully functional pipelined processor

---

> **"Think hardware, not software. Every line of VHDL describes physical circuits!"** 🔌
>
> _Stall 3alda2ery - Intelligent pipeline management for optimal performance_