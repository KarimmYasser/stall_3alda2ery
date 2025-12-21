import sys

# ============================================================
# ISA DESCRIPTION (UNCHANGED)
# ============================================================

formats = {
    "A": ["opcode"],
    "B": ["opcode", "rdst"],
    "C": ["opcode", "rdst", "rsrc"],
    "D": ["opcode", "rdst", "rsrc1", "rsrc2"],
    "E": ["opcode", "rdst", "immediate"],
    "F": ["opcode", "rdst", "rsrc", "immediate"],
    "G": ["opcode", "rdst", "offset", "rsrc"],
    "H": ["opcode", "rsrc2", "offset", "rsrc1"],
    "I": ["opcode", "address"],
    "J": ["opcode", "index"],
    "M": ["opcode", "rsrc2"],
}

instruction_map = {
    "NOP":  {"opcode": "00000", "num_words": 1, "format": "A"},
    "HLT":  {"opcode": "00001", "num_words": 1, "format": "A"},
    "SETC": {"opcode": "00010", "num_words": 1, "format": "A"},
    "INC":  {"opcode": "00011", "num_words": 1, "format": "B"},
    "NOT":  {"opcode": "00100", "num_words": 1, "format": "B"},
    "LDM":  {"opcode": "00101", "num_words": 2, "format": "E"},
    "MOV":  {"opcode": "00110", "num_words": 1, "format": "C"},
    "SWAP": {"opcode": "00111", "num_words": 1, "format": "C"},
    "IADD": {"opcode": "01000", "num_words": 2, "format": "F"},
    "ADD":  {"opcode": "01001", "num_words": 1, "format": "D"},
    "SUB":  {"opcode": "01010", "num_words": 1, "format": "D"},
    "AND":  {"opcode": "01011", "num_words": 1, "format": "D"},
    "JZ":   {"opcode": "01100", "num_words": 2, "format": "I"},
    "JN":   {"opcode": "01101", "num_words": 2, "format": "I"},
    "JC":   {"opcode": "01110", "num_words": 2, "format": "I"},
    "JMP":  {"opcode": "01111", "num_words": 2, "format": "I"},
    "OUT":  {"opcode": "10000", "num_words": 1, "format": "M"},
    "IN":   {"opcode": "10001", "num_words": 1, "format": "B"},
    "PUSH": {"opcode": "10010", "num_words": 1, "format": "M"},
    "POP":  {"opcode": "10011", "num_words": 1, "format": "B"},
    "LDD":  {"opcode": "10100", "num_words": 2, "format": "G"},
    "STD":  {"opcode": "10101", "num_words": 2, "format": "H"},
    "CALL": {"opcode": "10110", "num_words": 2, "format": "I"},
    "RET":  {"opcode": "10111", "num_words": 1, "format": "A"},
    "INT":  {"opcode": "11000", "num_words": 1, "format": "J"},
    "RTI":  {"opcode": "11001", "num_words": 1, "format": "A"},
}

register_map = {
    "R0": "000", "R1": "001", "R2": "010", "R3": "011",
    "R4": "100", "R5": "101", "R6": "110", "R7": "111",
}

# ============================================================
# PARSER (MINIMALLY FIXED)
# ============================================================

def parse_line(line):
    # remove comments (# and ;)
    line = line.split('#')[0].split(';')[0].strip()
    if not line:
        return None, None, []

    # handle .ORG
    if line.upper().startswith(".ORG"):
        parts = line.split()
        return None, ".ORG", [parts[1]]

    # label
    label = None
    if ':' in line:
        label, line = line.split(':', 1)
        label = label.strip().upper()
        line = line.strip()
        if not line:
            return label, None, []

    # 🔧 FIX: allow no spaces between registers
    line = line.replace(',', ' ')
    parts = line.split()

    instruction = parts[0].upper()
    operands = [op.upper() for op in parts[1:]]

    return label, instruction, operands

# ============================================================
# IMMEDIATE HANDLING (UNCHANGED)
# ============================================================

def parse_immediate(val, symbols=None):
    if symbols and val in symbols:
        return symbols[val]
    if val.startswith("0X"):
        return int(val, 16)
    return int(val)

def sign_extend_32(val):
    return format(val & 0xFFFFFFFF, "032b")

# ============================================================
# ENCODER (UNCHANGED)
# ============================================================

def encode_instruction(instr, ops, symbols):
    info = instruction_map[instr]
    opcode = info["opcode"]
    fmt = info["format"]

    index = "00"
    rdst = rs1 = rs2 = "000"
    dont = "0" * 16

    if fmt == "B":
        rdst = rs1 = register_map[ops[0]]

    elif fmt == "C":
        rs1 = register_map[ops[0]]
        rdst = register_map[ops[1]]

    elif fmt == "D":
        rdst = register_map[ops[0]]
        rs1 = register_map[ops[1]]
        rs2 = register_map[ops[2]]

    elif fmt == "E":
        rdst = register_map[ops[0]]

    elif fmt == "F":
        rdst = register_map[ops[0]]
        rs1 = register_map[ops[1]]

    elif fmt == "G":
        rdst = register_map[ops[0]]
        rs1 = register_map[ops[2]]

    elif fmt == "H":
        rs2 = register_map[ops[0]]
        rs1 = register_map[ops[2]]

    elif fmt == "J":
        index = format(int(ops[0]) + 2, "02b")

    elif fmt == "M":
        rs2 = register_map[ops[0]]

    word1 = opcode + index + dont + rdst + rs1 + rs2
    words = [word1]

    if info["num_words"] == 2:
        imm = parse_immediate(ops[-1], symbols)
        words.append(sign_extend_32(imm))

    return words

# ============================================================
# TWO-PASS ASSEMBLER WITH ABSOLUTE MEMORY
# ============================================================

def assemble_file(input_file, output_file):
    with open(input_file) as f:
        lines = f.readlines()

    # PASS 1 — SYMBOLS
    symbols = {}
    pc = 0
    for line in lines:
        label, instr, ops = parse_line(line)
        if instr == ".ORG":
            pc = int(ops[0], 16)
            continue
        if label:
            symbols[label] = pc
        if instr in instruction_map:
            pc += instruction_map[instr]["num_words"]

    # PASS 2 — CODE
    memory = {}
    pc = 0
    max_addr = 0

    for line in lines:
        label, instr, ops = parse_line(line)

        if instr == ".ORG":
            pc = int(ops[0], 16)
            continue

        if instr in instruction_map:
            words = encode_instruction(instr, ops, symbols)
            for w in words:
                memory[pc] = w
                pc += 1
                max_addr = max(max_addr, pc)

    # WRITE MEMORY IMAGE
    with open(output_file, "w") as f:
        for addr in range(max_addr):
            f.write(memory.get(addr, "0" * 32) + "\n")

    print(f"✔ Assembled correctly ({max_addr} memory words)")

# ============================================================
# ENTRY
# ============================================================

if __name__ == "__main__":
    assemble_file(sys.argv[1], sys.argv[2])
