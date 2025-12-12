"""
Validation script for the assembler output.
Compares generated machine code with expected values.
"""

def load_expected(filename):
    """Load expected hex values from file (ignores comments)."""
    expected = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.split(';')[0].split('#')[0].strip()
            if line and len(line) == 8:  # Valid 8-char hex
                try:
                    int(line, 16)  # Validate it's hex
                    expected.append(line.upper())
                except ValueError:
                    pass
    return expected


def load_generated(filename):
    """Load generated hex values from .mem file."""
    generated = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            # Skip comment lines
            if line.startswith('//'):
                continue
            if line and len(line) == 8:
                try:
                    int(line, 16)  # Validate it's hex
                    generated.append(line.upper())
                except ValueError:
                    pass
    return generated


def validate(expected_file, generated_file):
    """Compare expected vs generated and report differences."""
    expected = load_expected(expected_file)
    generated = load_generated(generated_file)
    
    print("=" * 70)
    print("ASSEMBLER VALIDATION REPORT")
    print("=" * 70)
    print(f"Expected file:  {expected_file}")
    print(f"Generated file: {generated_file}")
    print(f"Expected count: {len(expected)}")
    print(f"Generated count: {len(generated)}")
    print("-" * 70)
    
    errors = []
    max_len = max(len(expected), len(generated))
    
    for i in range(max_len):
        exp = expected[i] if i < len(expected) else "--------"
        gen = generated[i] if i < len(generated) else "--------"
        
        if exp != gen:
            errors.append((i, exp, gen))
    
    if not errors:
        print("\n✅ SUCCESS! All {} instructions match!\n".format(len(generated)))
    else:
        print(f"\n❌ FAILED! {len(errors)} mismatches found:\n")
        print(f"{'Addr':<6} {'Expected':<12} {'Generated':<12} {'Status'}")
        print("-" * 45)
        for addr, exp, gen in errors:
            print(f"{addr:<6} {exp:<12} {gen:<12} MISMATCH")
    
    # Show summary
    print("-" * 70)
    print(f"Total instructions: {len(generated)}")
    print(f"Matching: {len(generated) - len(errors)}")
    print(f"Mismatches: {len(errors)}")
    print("=" * 70)
    
    # Detailed comparison (first 20 and last 10)
    print("\n" + "=" * 70)
    print("DETAILED COMPARISON (first 30 + last 10 instructions)")
    print("=" * 70)
    print(f"{'Addr':<6} {'Expected':<12} {'Generated':<12} {'Match'}")
    print("-" * 45)
    
    # First 30
    for i in range(min(30, max_len)):
        exp = expected[i] if i < len(expected) else "--------"
        gen = generated[i] if i < len(generated) else "--------"
        match = "✓" if exp == gen else "✗"
        print(f"{i:<6} {exp:<12} {gen:<12} {match}")
    
    if max_len > 40:
        print("...")
        # Last 10
        for i in range(max(30, max_len - 10), max_len):
            exp = expected[i] if i < len(expected) else "--------"
            gen = generated[i] if i < len(generated) else "--------"
            match = "✓" if exp == gen else "✗"
            print(f"{i:<6} {exp:<12} {gen:<12} {match}")
    
    print("=" * 70)
    
    return len(errors) == 0


if __name__ == "__main__":
    import sys
    import os
    
    # Get script directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    tests_dir = os.path.join(os.path.dirname(script_dir), "tests")
    output_dir = os.path.join(os.path.dirname(script_dir), "output")
    
    expected_file = os.path.join(tests_dir, "expected_output.txt")
    generated_file = os.path.join(output_dir, "test_output.mem")
    
    # Allow command line override
    if len(sys.argv) >= 3:
        expected_file = sys.argv[1]
        generated_file = sys.argv[2]
    
    success = validate(expected_file, generated_file)
    sys.exit(0 if success else 1)
