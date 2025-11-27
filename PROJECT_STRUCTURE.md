# CMP 3010: Computer Architecture Project Repository

> **5-Stage Pipelined Processor with Hazard Detection & Forwarding**

---

## 📂 Project Structure

```
.
├── docs/                          # 📚 Documentation & Reports
│   ├── phase1/                    # Phase 1 Requirements
│   │   ├── schematics/            # Diagrams (ALU, Dataflow, Pipeline stages)
│   │   ├── instruction_format/    # Opcode and instruction bit details
│   │   └── hazards_report.pdf     # Data, Structural, Control hazard solutions
│   └── phase2/                    # Phase 2 Requirements
│       ├── design_changes.pdf     # Changes made after Phase 1
│       └── final_report.pdf       # Final pipeline hazard analysis
│
├── src/                           # 💻 VHDL Source Code
│   ├── common/                    # Shared packages (Types, Constants, Port maps)
│   ├── components/                # Basic reusable components
│   │   ├── alu.vhd
│   │   ├── reg_file.vhd
│   │   ├── mux.vhd
│   │   ├── adder.vhd
│   │   └── sign_extender.vhd
│   ├── stages/                    # 5 Pipeline Stages
│   │   ├── 1_fetch.vhd            # IF:  PC logic, Instruction Fetch
│   │   ├── 2_decode.vhd           # ID:  Control Unit, Register Read
│   │   ├── 3_execute.vhd          # EX:  ALU operations, Flag (CCR) updates
│   │   ├── 4_memory.vhd           # MEM: Memory Access logic
│   │   └── 5_writeback.vhd        # WB:  Write back to Register File
│   ├── pipeline/                  # Pipeline Registers & Hazard Logic
│   │   ├── if_id_reg.vhd          # IF/ID Pipeline Register
│   │   ├── id_ex_reg.vhd          # ID/EX Pipeline Register
│   │   ├── ex_mem_reg.vhd         # EX/MEM Pipeline Register
│   │   ├── mem_wb_reg.vhd         # MEM/WB Pipeline Register
│   │   ├── forwarding_unit.vhd    # Data Forwarding logic
│   │   └── hazard_detection.vhd   # Stalling & Flush logic
│   └── top_level_processor.vhd    # Top-level integration
│
├── memory/                        # 🧠 Memory Modules
│   ├── ram.vhd                    # Von Neumann (Instruction & Data)
│   └── stack_pointer.vhd          # SP Logic (Initial: 2^20-1)
│
├── assembler/                     # 🔧 Assembly to Machine Code
│   ├── src/                       # Python/C++ assembler source
│   ├── tests/                     # Test assembly files (.asm)
│   └── output/                    # Generated memory files (.mem, .hex)
│
├── simulation/                    # 🔬 Modelsim/QuestaSim
│   ├── do_files/                  # Automation scripts
│   │   ├── compile.do             # Compiles all VHDL files
│   │   └── wave.do                # Signal setup (R0-R7, PC, SP, Flags)
│   ├── test_cases/                # TA-provided test files
│   └── waveforms/                 # Saved simulation results
│
└── README.md                      # Project overview and setup
```

---

## 🛠 Component Breakdown

### 1️⃣ Pipeline Stages (`src/stages/`)

| Stage   | File              | Responsibility                             |
| ------- | ----------------- | ------------------------------------------ |
| **IF**  | `1_fetch.vhd`     | PC increment, Branch/Call/Interrupt muxing |
| **ID**  | `2_decode.vhd`    | Control Unit, Register File reads          |
| **EX**  | `3_execute.vhd`   | ALU operations, CCR flag updates (Z, N, C) |
| **MEM** | `4_memory.vhd`    | Memory access (LDD, STD, PUSH, POP)        |
| **WB**  | `5_writeback.vhd` | Write-back muxing to destination register  |

> **💡 Tip:** Modular stage separation enables easier debugging and unit testing.

---

### 2️⃣ Pipeline Control (`src/pipeline/`)

**Critical for Phase 1 & 2 evaluation**

| Component              | Purpose                                                                      |
| ---------------------- | ---------------------------------------------------------------------------- |
| **Pipeline Registers** | Store control signals and data between stages (IF/ID, ID/EX, EX/MEM, MEM/WB) |
| **Forwarding Unit**    | Implements data forwarding to resolve data hazards                           |
| **Hazard Detection**   | Handles stalls, flushes, and branch prediction                               |

**Requirements:**

- ✅ Static branch prediction (always taken/not taken)
- 🎯 **Bonus:** 2-bit dynamic branch predictor

---

### 3️⃣ Assembler (`assembler/`)

**Purpose:** Convert assembly programs to machine code

**Workflow:**

```
Input  → program.asm (e.g., ADD R1, R2, R3)
Output → instruction_memory.mem (Binary/Hex)
```

**Implementation:** Python or C++ based assembler

---

### 4️⃣ Simulation Setup (`simulation/do_files/`)

**Required deliverables:**

- **`compile.do`**: Compiles all VHDL files
- **`wave.do`**: Configures waveform signals (R0-R7, PC, SP, Flags)
- **`run_test.do`**: Loads memory, resets processor, runs simulation

**Example workflow:**

```tcl
# Reset sequence
force RESET.IN = 1
run 10 ns
force RESET.IN = 0
run 1000 ns
```

---

## 📋 Key Design Constraints

| Parameter          | Value       | Description                       |
| ------------------ | ----------- | --------------------------------- |
| **Memory Model**   | Von Neumann | Unified instruction & data memory |
| **Address Space**  | 2^20        | 1 MB total addressable memory     |
| **Stack Pointer**  | 2^20 - 1    | Initial SP value (grows downward) |
| **Registers**      | R0-R7       | 8 general-purpose registers       |
| **Pipeline Depth** | 5 stages    | IF → ID → EX → MEM → WB           |

---

## 🧹 .gitignore Configuration

Add to `.gitignore` to keep the repository clean:

```gitignore
# Modelsim/QuestaSim generated files
work/
transcript
vsim.wlf
*.mpf
*.mti

# Python (Assembler)
__pycache__/
*.pyc
*.pyo

# Assembler output (optional - comment if needed for submission)
# assembler/output/*.mem
# assembler/output/*.hex

# OS artifacts
.DS_Store
Thumbs.db
desktop.ini

# Editor files
*.swp
*.swo
*~
.vscode/
.idea/
```

---

## 🚀 Quick Start

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd stall_3alda2ery
   ```

2. **Compile VHDL files** (Modelsim)

   ```bash
   vsim -do simulation/do_files/compile.do
   ```

3. **Run assembler**

   ```bash
   python assembler/src/assembler.py assembler/tests/program.asm
   ```

4. **Simulate**
   ```bash
   vsim -do simulation/do_files/run_test.do
   ```

---

## 📌 Phase Checklist

### Phase 1

- [ ] Pipeline stage implementations (IF, ID, EX, MEM, WB)
- [ ] Basic hazard detection
- [ ] Static branch prediction
- [ ] Assembler implementation
- [ ] Test case documentation

### Phase 2

- [ ] Enhanced hazard handling
- [ ] Data forwarding optimization
- [ ] Performance analysis report
- [ ] Design change documentation
- [ ] Final simulation demonstrations

---

**Last Updated:** 2025-11-27
