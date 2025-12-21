# first the instruction map 

formats = {
    "A": ["opcode"],                                    # NOP, HLT, SETC, RET, RTI
    "B": ["opcode", "rdst"],                            # INC, NOT, IN , POP
    "C": ["opcode", "rdst", "rsrc"],                    # MOV, SWAP
    "D": ["opcode", "rdst", "rsrc1", "rsrc2"],          # ADD, SUB, AND
    "E": ["opcode", "rdst", "immediate"],               # LDM
    "F": ["opcode", "rdst", "rsrc", "immediate"],       # IADD
    "G": ["opcode", "rdst", "offset", "rsrc"],          # LDD  -> LDD Rdst, offset(Rsrc)
    "H": ["opcode", "rsrc2", "offset", "rsrc1"],        # STD  -> STD Rsrc2, offset(Rsrc1)
    "I": ["opcode", "address"],                         # JZ, JN, JC, JMP, CALL
    "J": ["opcode", "index"],                           # INT
    "M": ["opcode","rsrc2"],                            # OUT , PUSH
}

instruction_map = {
    # Group 0: Format Type Instructions (Bit 4 = 0)
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
    
    # Group 1: Format Type Instructions (Bit 4 = 1)
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

# Register encoding map
register_map = {
    "R0": "000",
    "R1": "001",
    "R2": "010",
    "R3": "011",
    "R4": "100",
    "R5": "101",
    "R6": "110",
    "R7": "111",
}


def parse_line(line):
    """
    Parse a line of assembly code.
    Returns: (label, instruction, operands)
    """
    # Remove comments (both ; and # style)
    comment_pos = len(line)
    for comment_char in [';', '#']:
        pos = line.find(comment_char)
        if pos != -1 and pos < comment_pos:
            comment_pos = pos
    line = line[:comment_pos].strip()

    if not line:
        return None, None, []
    
    label = None
    
    # Check for label (ends with :)
    if ':' in line:
        parts = line.split(':')
        label = parts[0].strip().upper()
        line = parts[1].strip()
        
        # If line is empty after label, return just the label
        if not line:
            return label, None, []
    
    parts = line.split()
    if not parts:
        return label, None, []
    
    instruction = parts[0].upper()
    
    # Check if instruction has a digit at the end (like INT0, INT1)
    # This handles cases where instruction and operand are merged
    if instruction.startswith('INT') and len(instruction) > 3:
        # Extract the digit and make it an operand
        operand_part = instruction[3:]
        instruction = 'INT'
        parts = [instruction, operand_part] + parts[1:]
    
    # Handle operands: split by commas first, then by spaces
    # This handles both \"add r1, r2, r3\" and \"add r1,r2,r3\"
    operands_str = ' '.join(parts[1:])
    
    # Split by comma and clean up
    operands = []
    if operands_str:
        # Split by comma and strip whitespace
        operands_raw = [op.strip() for op in operands_str.split(',')]
        # Filter out operands that contain '=' or other invalid characters (likely comments)
        for op in operands_raw:
            # Remove any trailing/leading spaces and check for comment patterns
            op = op.strip()
            # If operand contains space followed by non-parenthesis, it's likely a comment
            if ' ' in op and '(' not in op:
                # Take only the first part before space
                op = op.split()[0]
            # Stop at first operand containing '='
            if '=' in op:
                break
            if op:  # Only add non-empty operands
                operands.append(op)
    
    parsed_operands = []
    for operand in operands:
        if '(' in operand and ')' in operand:
            # Extract offset and register from format: offset(Rsrc)
            offset = operand.split('(')[0].strip()
            register = operand.split('(')[1].replace(')', '').strip().upper()
            parsed_operands.append(offset)
            parsed_operands.append(register)
        else:
            parsed_operands.append(operand.upper())
    
    return label, instruction, parsed_operands


def parse_immediate(value_str, symbol_table=None):
    """
    Parse immediate value from string.
    Handles decimal, hex (0x or bare), negative numbers, and labels.
    Returns integer value.
    """
    value_str = value_str.strip()
    
    # Check if it's a label
    if symbol_table and value_str in symbol_table:
        return symbol_table[value_str]
    
    if value_str.startswith("0X") or value_str.startswith("0x"):
        return int(value_str, 16)
    else:
        # Try to parse as decimal first
        try:
            return int(value_str, 10)
        except ValueError:
            # If that fails, try as hex (for bare hex like 200, 0A00)
            try:
                return int(value_str, 16)
            except ValueError:
                raise ValueError(f"Invalid immediate value: {value_str}")


def sign_extend_to_32bit(value):
    """
    Sign extend a 16-bit value to 32-bit.
    Returns 32-bit binary string.
    """
    # Handle negative numbers (two's complement for 16-bit)
    if value < 0:
        # Convert to 16-bit two's complement
        value = value & 0xFFFF
    
    # Check if sign bit (bit 15) is set
    if value & 0x8000:
        # Negative: extend with 1s
        extended = value | 0xFFFF0000
    else:
        # Positive: extend with 0s
        extended = value & 0x0000FFFF
    
    # Convert to 32-bit binary string (handle as unsigned for formatting)
    return format(extended & 0xFFFFFFFF, '032b')


def encode_instruction(instruction, operands, symbol_table=None):
    """
    Encode instruction and operands into binary words.
    Returns list of 32-bit binary strings.
    """
    if instruction not in instruction_map:
        raise ValueError(f"Unknown instruction: {instruction}")
    
    info = instruction_map[instruction]
    opcode = info["opcode"]
    num_words = info["num_words"]
    fmt = info["format"]
    
    # Word 1 format: opcode(5) | index(2) | dont_care(16) | rdst(3) | rs1(3) | rs2(3)
    # Initialize all fields to zeros
    index_bits = "00"
    rdst = "000"
    rs1 = "000"
    rs2 = "000"
    dont_care = "0" * 16
    
    # Encode based on format
    if fmt == "A":
        # No operands: NOP, HLT, SETC, RET, RTI
        pass
    
    elif fmt == "B":
        # Single register: INC, NOT, IN, PUSH
        rdst = register_map[operands[0]]
        if instruction == "INC":
            rs1 = register_map[operands[0]]  # INC uses rs2 as the register to increment
        if instruction == "NOT":
            rs1 = register_map[operands[0]]  # NOT uses rs2 as the register to negate
    
    elif fmt == "C":
        # Two registers: MOV Rsrc, Rdst | SWAP Rsrc, Rdst
        rs1 = register_map[operands[0]]   # Rsrc
        rdst = register_map[operands[1]]  # Rdst
        if instruction == "SWAP":
            rs2=register_map[operands[1]]  # Rdst
    
    elif fmt == "D":
        # Three registers: ADD Rdst, Rsrc1, Rsrc2
        rdst = register_map[operands[0]]
        rs1 = register_map[operands[1]]
        rs2 = register_map[operands[2]]
    
    elif fmt == "E":
        # Register + Immediate: LDM Rdst, Imm
        rdst = register_map[operands[0]]
        # Immediate goes in word 2
    
    elif fmt == "F":
        # Two registers + Immediate: IADD Rdst, Rsrc, Imm
        rdst = register_map[operands[0]]
        rs1 = register_map[operands[1]]
        # Immediate goes in word 2
    
    elif fmt == "G":
        # LDD Rdst, offset(Rsrc) -> operands = [Rdst, offset, Rsrc]
        rdst = register_map[operands[0]]
        rs1 = register_map[operands[2]]  # Rsrc
        # Offset goes in word 2
    
    elif fmt == "H":
        # STD Rsrc1, offset(Rsrc2) -> operands = [Rsrc2, offset, Rsrc1]
        rs2 = register_map[operands[0]]  # Rsrc1 (source data)
        rs1 = register_map[operands[2]]   # Rsrc2 (base address)
        # Offset goes in word 2
    
    elif fmt == "I":
        # Jump/Call with address: JZ, JN, JC, JMP, CALL
        # Address goes in word 2
        pass
    
    elif fmt == "J":
        # INT index
        int_index = int(operands[0])
        # index = user_value + 2, stored in bits 26-25
        index_value = int_index + 2
        index_bits = format(index_value, '02b')

    elif fmt == "M":
        # OUT , PUSH : single register operand
        rs2 = register_map[operands[0]]
    
    # Build Word 1
    word1 = opcode + index_bits + dont_care + rdst + rs1 + rs2
    
    result = [word1]
    
    # Build Word 2 if needed (immediate/offset/address)
    if num_words == 2:
        if fmt == "E":
            # LDM: immediate is operands[1]
            imm_value = parse_immediate(operands[1], symbol_table)
        elif fmt == "F":
            # IADD: immediate is operands[2]
            imm_value = parse_immediate(operands[2], symbol_table)
        elif fmt == "G":
            # LDD: offset is operands[1]
            imm_value = parse_immediate(operands[1], symbol_table)
        elif fmt == "H":
            # STD: offset is operands[1]
            imm_value = parse_immediate(operands[1], symbol_table)
        elif fmt == "I":
            # Jump/Call: address is operands[0]
            imm_value = parse_immediate(operands[0], symbol_table)
        else:
            imm_value = 0
        
        word2 = sign_extend_to_32bit(imm_value)
        result.append(word2)
    
    return result


def binary_to_hex(binary_str):
    """Convert 32-bit binary string to 8-character hex string."""
    return format(int(binary_str, 2), '08X')


def pass1_build_symbol_table(lines):
    """
    First pass: Build symbol table with label addresses.
    Returns: symbol_table dict {label: address}
    """
    symbol_table = {}
    current_address = 0
    
    for line_num, line in enumerate(lines, 1):
        label, instruction, operands = parse_line(line)
        
        # If there's a label, record its address
        if label:
            if label in symbol_table:
                raise ValueError(f"Line {line_num}: Duplicate label '{label}'")
            symbol_table[label] = current_address
        
        # Handle .ORG directive
        if instruction and instruction == ".ORG":
            if not operands or len(operands) < 1:
                raise ValueError(f"Line {line_num}: .ORG requires an address")
            try:
                new_address = parse_immediate(operands[0], symbol_table)
                current_address = new_address
            except Exception as e:
                raise ValueError(f"Line {line_num}: Invalid .ORG address: {e}")
            continue
        
        # If there's an instruction, advance address
        if instruction:
            # Check if it's a raw data value (hex number)
            if instruction not in instruction_map:
                # Try to parse as data value
                try:
                    # If it parses as a number, it's data (takes 1 word)
                    parse_immediate(instruction, symbol_table)
                    current_address += 1
                    continue
                except:
                    raise ValueError(f"Line {line_num}: Unknown instruction '{instruction}'")
            else:
                num_words = instruction_map[instruction]["num_words"]
                current_address += num_words
    
    return symbol_table


def pass2_generate_code(lines, symbol_table):
    """
    Second pass: Generate machine code.
    Returns: list of (address, binary_word, hex_word, original_line) tuples
    """
    output = []
    current_address = 0
    
    for line_num, line in enumerate(lines, 1):
        label, instruction, operands = parse_line(line)
        
        # Handle .ORG directive
        if instruction and instruction == ".ORG":
            if not operands or len(operands) < 1:
                raise ValueError(f"Line {line_num}: .ORG requires an address")
            try:
                new_address = parse_immediate(operands[0], symbol_table)
                current_address = new_address
            except Exception as e:
                raise ValueError(f"Line {line_num}: Invalid .ORG address: {e}")
            continue
        
        if instruction:
            # Check if it's a raw data value (hex number)
            if instruction not in instruction_map:
                try:
                    # Parse as data value and encode directly
                    data_value = parse_immediate(instruction, symbol_table)
                    binary_word = sign_extend_to_32bit(data_value)
                    hex_word = binary_to_hex(binary_word)
                    output.append((current_address, binary_word, hex_word, line.strip()))
                    current_address += 1
                    continue
                except:
                    raise ValueError(f"Line {line_num}: Unknown instruction '{instruction}'")
            
            try:
                words = encode_instruction(instruction, operands, symbol_table)
                for i, word in enumerate(words):
                    binary_word = word  # Already 32-bit binary string
                    hex_word = binary_to_hex(word)
                    if i == 0:
                        output.append((current_address, binary_word, hex_word, line.strip()))
                    else:
                        output.append((current_address, binary_word, hex_word, "  ; immediate/offset"))
                    current_address += 1
            except Exception as e:
                raise ValueError(f"Line {line_num}: {e}")
    
    return output


def assemble_file(input_file, output_file):
    """
    Assemble an input file and write to output files.
    Creates two files:
    - output_file.mem: Binary only (for VHDL/machine)
    - output_file_hex.mem: Hex with comments (for manual inspection)
    """
    # Read input file
    with open(input_file, 'r') as f:
        lines = f.readlines()
    
    print(f"Assembling: {input_file}")
    print("=" * 60)
    
    # Pass 1: Build symbol table
    print("Pass 1: Building symbol table...")
    symbol_table = pass1_build_symbol_table(lines)
    
    if symbol_table:
        print("\nSymbol Table:")
        print("-" * 30)
        for label, addr in symbol_table.items():
            print(f"  {label}: {addr} (0x{addr:04X})")
        print()
    
    # Pass 2: Generate code
    print("Pass 2: Generating machine code...")
    output = pass2_generate_code(lines, symbol_table)
    
    # Generate output file names
    base_name = output_file.rsplit('.', 1)[0]
    binary_file = base_name + ".mem"
    hex_file = base_name + "_hex.mem"
    
    # Write binary file - ONLY binary, no comments (for VHDL/machine)
    with open(binary_file, 'w') as f:
        for addr, binary_word, hex_word, original in output:
            f.write(f"{binary_word}\n")
    
    # Write hex file - with comments (for manual inspection)
    with open(hex_file, 'w') as f:
        f.write(f"// Machine code generated from: {input_file}\n")
        f.write(f"// Total words: {len(output)}\n")
        f.write(f"// Format: ADDR | HEX | Source\n")
        f.write("//\n")
        for addr, binary_word, hex_word, original in output:
            f.write(f"{addr:04d}  {hex_word}  ; {original}\n")
    
    print(f"\nOutput files:")
    print(f"  Binary (for machine): {binary_file}")
    print(f"  Hex (for inspection): {hex_file}")
    print(f"Total instructions: {len(output)} words")
    
    # Print output for verification (console still shows full details)
    print("\n" + "=" * 100)
    print("GENERATED MACHINE CODE")
    print("=" * 100)
    print(f"{'Addr':<6} {'Binary (32-bit)':<34} {'Hex':<10} {'Source'}")
    print("-" * 100)
    for addr, binary_word, hex_word, original in output:
        print(f"{addr:<6} {binary_word} {hex_word:<10} {original}")
    print("=" * 100)


def main():
    import sys
    
    if len(sys.argv) >= 3:
        # Command line usage: python assembler.py input.asm output.mem
        input_file = sys.argv[1]
        output_file = sys.argv[2]
        assemble_file(input_file, output_file)
    
    elif len(sys.argv) == 2:
        # Single argument: input file, output defaults to input.mem
        input_file = sys.argv[1]
        output_file = input_file.rsplit('.', 1)[0] + ".mem"
        assemble_file(input_file, output_file)
    
    else:
        # No arguments: run test
        print("Usage: python assembler.py <input.asm> [output.mem]")
        print("\nRunning built-in test...\n")
        
        # Test with inline assembly
        test_code = """
# Test program with labels
        LDM R0, 5       ; Load 5 into R0
        LDM R1, 0       ; Load 0 into R1 (counter)
        
LOOP:   ADD R1, R1, R0  ; R1 = R1 + R0
        INC R0          ; R0++
        JZ END          ; If zero, jump to END
        JMP LOOP        ; Jump back to LOOP
        
END:    OUT R1          ; Output result
        HLT             ; Halt
"""
        
        lines = test_code.strip().split('\n')
        
        # Pass 1
        symbol_table = pass1_build_symbol_table(lines)
        print("Symbol Table:")
        for label, addr in symbol_table.items():
            print(f"  {label}: {addr}")
        print()
        
        # Pass 2
        output = pass2_generate_code(lines, symbol_table)
        
        print("Generated Code:")
        print(f"{'Addr':<6} {'Binary (32-bit)':<34} {'Hex':<10} {'Source'}")
        print("-" * 90)
        for addr, binary_word, hex_word, original in output:
            print(f"{addr:<6} {binary_word} {hex_word:<10} {original}")


if __name__ == "__main__":
    main()