# CMP 3010: Computer Architecture Project

> **5-Stage Pipelined RISC Processor - Cairo University**  
> _Fall 2025 - Computer Engineering Department_

[![VHDL](https://img.shields.io/badge/Language-VHDL-blue.svg)](https://en.wikipedia.org/wiki/VHDL)
[![Status](https://img.shields.io/badge/Status-Phase%202-orange.svg)]()
[![Architecture](https://img.shields.io/badge/Architecture-32--bit%20RISC-green.svg)]()

---

## 📖 Project Overview

This repository contains the implementation of a **32-bit 5-stage pipelined RISC processor** with **von Neumann architecture** as part of CMP 3010 Computer Architecture course at Cairo University. The processor features integrated hazard detection, data forwarding, branch prediction, and interrupt handling.

### 🎯 Objective

Design and implement a fully functional 5-stage pipelined processor that:

- Executes a RISC-like instruction set with 20+ instructions
- Handles pipeline hazards (data, structural, and control)
- Supports interrupts and I/O operations
- Includes a custom assembler for converting assembly to machine code

### ✨ Key Features

- ✅ **32-bit Architecture**: All registers, data bus, and ALU are 32-bit wide
- ✅ **5-Stage Pipeline**: IF → ID → EX → MEM → WB
- ✅ **8 General-Purpose Registers**: R0-R7 (each 32-bit)
- ✅ **1 MB Memory**: Von Neumann architecture (unified instruction/data memory)
- ✅ **Hazard Handling**: Data forwarding, stall insertion, branch prediction
- ✅ **Interrupt Support**: Non-maskable interrupt with flag preservation
- ✅ **I/O Capabilities**: 32-bit input and output ports
- ✅ **Custom Assembler**: Text-to-machine code converter

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
.
├── docs/                          # 📚 Documentation & Reports
│   ├── phase1/                    # Phase 1 deliverables
│   │   ├── schematics/            # Block diagrams, dataflow diagrams
│   │   ├── instruction_format/    # ISA encoding details
│   │   └── hazards_report.pdf     # Hazard analysis & solutions
│   ├── phase2/                    # Phase 2 deliverables
│   │   ├── design_changes.pdf     # Post-Phase1 design modifications
│   │   └── final_report.pdf       # Final project documentation
│   └── Architecture_Project.pdf   # Original project specification
│
├── src/                           # 💻 VHDL Source Code
│   ├── common/                    # Shared packages and constants
│   ├── components/                # Reusable hardware components
│   │   ├── alu.vhd                # 32-bit ALU with Z/N/C flags
│   │   ├── reg_file.vhd           # 8×32-bit register file
│   │   ├── mux.vhd                # Generic multiplexers
│   │   ├── adder.vhd              # 32-bit adder with carry
│   │   └── sign_extender.vhd      # 16→32 bit sign extension
│   ├── stages/                    # Pipeline stage implementations
│   │   ├── 1_fetch.vhd            # IF: Instruction fetch
│   │   ├── 2_decode.vhd           # ID: Decode & register read
│   │   ├── 3_execute.vhd          # EX: ALU operations
│   │   ├── 4_memory.vhd           # MEM: Memory access
│   │   └── 5_writeback.vhd        # WB: Register write-back
│   ├── pipeline/                  # Pipeline control & hazard units
│   │   ├── if_id_reg.vhd          # IF/ID pipeline register
│   │   ├── id_ex_reg.vhd          # ID/EX pipeline register
│   │   ├── ex_mem_reg.vhd         # EX/MEM pipeline register
│   │   ├── mem_wb_reg.vhd         # MEM/WB pipeline register
│   │   ├── forwarding_unit.vhd    # Data forwarding logic
│   │   └── hazard_detection.vhd   # Stall & flush control
│   └── top_level_processor.vhd    # Top-level entity integration
│
├── memory/                        # 🧠 Memory modules
│   ├── ram.vhd                    # 1 MB unified memory (32-bit wide)
│   └── stack_pointer.vhd          # SP control logic
│
├── assembler/                     # 🔧 Custom assembler
│   ├── src/                       # Assembler implementation (Python/C++)
│   ├── tests/                     # Test assembly programs
│   └── output/                    # Generated machine code files
│
├── simulation/                    # 🔬 Testbench & simulation
│   ├── do_files/                  # Modelsim automation scripts
│   │   ├── compile.do             # Compile all VHDL files
│   │   └── wave.do                # Configure waveform signals
│   ├── test_cases/                # TA-provided test programs
│   └── waveforms/                 # Saved simulation results
│
├── PROJECT_STRUCTURE.md           # Detailed project organization
├── README.md                      # This file
└── .gitignore                     # Git ignore patterns
```

---

## 🚀 Getting Started

### Prerequisites

- **Modelsim/QuestaSim**: VHDL simulator
- **Python 3.x** or **C++**: For assembler development
- **Git**: Version control
- **Text Editor**: VS Code, Sublime, or similar

### Setup Steps

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/stall_3alda2ery.git
   cd stall_3alda2ery
   ```

2. **Compile VHDL files** (Modelsim)

   ```bash
   vsim -do simulation/do_files/compile.do
   ```

3. **Create assembly program**

   ```assembly
   # example.asm
   LDM R1, 5
   LDM R2, 3
   ADD R3, R1, R2
   OUT R3
   HLT
   ```

4. **Assemble to machine code**

   ```bash
   python assembler/src/assembler.py assembler/tests/example.asm
   ```

5. **Run simulation**
   ```bash
   vsim -do simulation/do_files/wave.do
   # In Modelsim console:
   force RESET.IN 1
   run 10 ns
   force RESET.IN 0
   run 1000 ns
   ```

---

## 📊 Development Phases

### Phase 1 (Week 10) - Design & Planning

**Deliverables**:

- [x] Instruction format and opcode table
- [ ] Complete schematic diagram with dataflow
- [ ] ALU, Register File, Memory block designs
- [ ] Control unit detailed design
- [ ] Pipeline stage specifications
- [ ] Pipeline register details
- [ ] Hazard analysis and solutions report

### Phase 2 (Week 13) - Implementation & Testing

**Deliverables**:

- [ ] Complete VHDL implementation of all components
- [ ] Top-level processor integration
- [ ] Custom assembler implementation
- [ ] Test programs and simulation
- [ ] Waveform demonstrations (R0-R7, PC, SP, Flags)
- [ ] Design changes report
- [ ] Final pipeline hazards documentation

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

## 🧪 Testing Requirements

### Test Setup

1. **Memory Initialization**: Load program into RAM from memory file
2. **Reset Sequence**:

   ```
   RESET.IN = 1 (10ns)
   RESET.IN = 0
   PC ← M[0]  // Start address from memory location 0
   ```

3. **Waveform Signals** (Must show in do files):
   - Registers: R0, R1, R2, R3, R4, R5, R6, R7
   - Control: PC, SP, CCR (Z, N, C)
   - Clock: CLK
   - I/O: IN.PORT, OUT.PORT
   - Signals: RESET.IN, INTR.IN

### Sample Test Programs

Provided by TAs during demo session - notify if any instructions are not implemented.

---

## 🎯 Design Guidelines

1. ✅ **Compile frequently** after each modification
2. ✅ **Start simple**: Implement one-operand instructions first
3. ✅ **Integrate incrementally**: Add components one at a time
4. ✅ **Test thoroughly**: Validate each component before integration
5. ✅ **Use version control**: Git for tracking changes
6. ✅ **Document changes**: Justify any Phase 1 → Phase 2 modifications
7. ✅ **Clean waveforms**: Show only essential signals
8. ✅ **Initialize all signals**: No floating 'U' values in simulation
9. ✅ **Think hardware**: Remember VHDL describes physical circuits

---

## 👥 Team Structure

- **Team Size**: Maximum 4 members
- **Individual Grading**: Members can receive different grades based on contribution
- **Workload Balance**: Ensure fair distribution of tasks

---

## 📅 Important Dates

| Milestone              | Week    | Deliverable                       |
| ---------------------- | ------- | --------------------------------- |
| **Phase 1 Discussion** | Week 10 | Design reports + schematics       |
| **Phase 2 Demo**       | Week 13 | Working processor + documentation |

**Submission**: Google Classroom (soft copy)

---

## 📚 Documentation

- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)**: Detailed directory structure and component descriptions
- **[docs/Architecture_Project.pdf](docs/Architecture_Project.pdf)**: Official project specification
- **Phase Reports**: Located in `docs/phase1/` and `docs/phase2/`

---

## 🔧 Modelsim Configuration

### compile.do

```tcl
# Compile all VHDL files in dependency order
vlib work
vcom -2008 src/common/*.vhd
vcom -2008 src/components/*.vhd
vcom -2008 memory/*.vhd
vcom -2008 src/stages/*.vhd
vcom -2008 src/pipeline/*.vhd
vcom -2008 src/top_level_processor.vhd
```

### wave.do

```tcl
# Configure waveform display - MAIN SIGNALS ONLY
add wave -position end -radix hex sim:/top_level_processor/clk
add wave -position end sim:/top_level_processor/RESET.IN
add wave -position end sim:/top_level_processor/INTR.IN
add wave -position end -radix hex sim:/top_level_processor/PC
add wave -position end -radix hex sim:/top_level_processor/SP
add wave -position end -radix hex sim:/top_level_processor/R0
add wave -position end -radix hex sim:/top_level_processor/R1
add wave -position end -radix hex sim:/top_level_processor/R2
add wave -position end -radix hex sim:/top_level_processor/R3
add wave -position end -radix hex sim:/top_level_processor/R4
add wave -position end -radix hex sim:/top_level_processor/R5
add wave -position end -radix hex sim:/top_level_processor/R6
add wave -position end -radix hex sim:/top_level_processor/R7
add wave -position end sim:/top_level_processor/CCR
add wave -position end -radix hex sim:/top_level_processor/IN.PORT
add wave -position end -radix hex sim:/top_level_processor/OUT.PORT
```

---

## ⚠️ Common Pitfalls

| Issue                 | Solution                                              |
| --------------------- | ----------------------------------------------------- |
| Compilation errors    | Check dependency order, compile common packages first |
| Timing violations     | Verify all processes are synchronous to clock         |
| Hazard misses         | Thoroughly test all RAW, WAR, WAW scenarios           |
| Branch mispredictions | Ensure flush logic clears pipeline correctly          |
| Memory conflicts      | Check read/write timing and enable signals            |

---

## 📞 Support

- **Course Instructor**: [Instructor Name]
- **Teaching Assistants**: [TA Names]
- **Lab Sessions**: Regular weekly sessions

---

## 📄 License

This project is developed for academic purposes as part of CMP 3010 at Cairo University, Faculty of Engineering, Computer Engineering Department.

---

**Last Updated**: November 27, 2025  
**Project Status**: 🚧 Phase 1 - Planning & Design

---

> **Remember**: Think hardware, not software. Every line of VHDL describes physical circuits! 🔌

---

# Stall 3alda2ery Processor

## Folder Structure

```
stall_3alda2ery/
├── src/
│   ├── common/                     # Reusable components
│   │   ├── general_register.vhd    # Generic register
│   │   └── PC.vhd                  # Program Counter
│   │
│   ├── stages/                     # Pipeline stages
│   │   ├── 1_fetch.vhd            # Fetch stage
│   │   ├── fetch_decode_integrated.vhd  # Fetch + IF/ID + Decode integration
│   │   └── testbench/             # Stage testbenches
│   │       ├── fetch_tb.vhd
│   │       └── run_fetch_tb.do
│   │
│   ├── testbench/                  # Top-level testbenches
│   │   └── top_level_processor_tb.vhd
│   │
│   ├── top_level_processor.vhd    # Top-level processor entity
│   └── run_top_level_tb.do        # Top-level simulation script
│
└── decode/                         # Decode stage components
    ├── control_unit.vhd           # Control unit with microcode FSM
    ├── IF_ID_register.vhd         # IF/ID pipeline register
    ├── run_control_unit_tb.do     # Control unit simulation script
    └── testbench/                 # Decode stage testbenches
        └── control_unit_tb.vhd
```

## Running Simulations

### Control Unit Test
```bash
cd decode
vsim -do run_control_unit_tb.do
```

### Top-Level Processor Test
```bash
cd src
vsim -do run_top_level_tb.do
```

### Individual Stage Tests
```bash
cd src/stages/testbench
vsim -do run_fetch_tb.do
```

## Current Implementation Status

- [x] Fetch Stage
- [x] IF/ID Pipeline Register
- [x] Control Unit with Microcode
- [x] Fetch-Decode Integration
- [ ] Decode Stage (Register File)
- [ ] ID/EX Pipeline Register
- [ ] Execute Stage
- [ ] EX/MEM Pipeline Register
- [ ] Memory Stage
- [ ] MEM/WB Pipeline Register
- [ ] Writeback Stage

## Notes

- All testbenches have been moved to `testbench/` subdirectories
- DO files have been updated to reference new paths
- Top-level processor connects Fetch, IF/ID register, and Control Unit
- Ready for integration of remaining pipeline stages


