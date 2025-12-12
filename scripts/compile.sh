#!/bin/bash
# ============================================================================
# GHDL Compile Script for VHDL Files
# ============================================================================
# Compiles all .vhd files in a specified directory with GHDL
# Usage: ./scripts/compile.sh [directory] [options]
#   directory       : Directory to compile (default: current directory)
#   -s, --synopsys  : Enable synopsys packages (-fsynopsys)
#   -c, --clean     : Clean work library before compiling
#   -r, --recursive : Compile recursively in subdirectories
#   -h, --help      : Show this help
# ============================================================================

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
NC=$'\033[0m' # No Color

# Default options
SYNOPSYS=""
CLEAN=true
RECURSIVE=true
STD="--std=08"
TARGET_DIR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--synopsys)
            SYNOPSYS="-fsynopsys"
            shift
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -r|--recursive)
            RECURSIVE=true
            shift
            ;;
        -h|--help)
            echo "GHDL Compile Script"
            echo "Usage: $0 [directory] [options]"
            echo "  directory       : Directory to compile (default: project root)"
            echo "  -s, --synopsys  : Enable synopsys packages (-fsynopsys)"
            echo "  -c, --clean     : Clean work library before compiling"
            echo "  -r, --recursive : Compile recursively in subdirectories"
            echo "  -h, --help      : Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 memory -s         # Compile memory/ with synopsys"
            echo "  $0 src/pipeline      # Compile src/pipeline/"
            echo "  $0 . -r              # Compile all recursively"
            exit 0
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
        *)
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

# Set target directory
if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="$PROJECT_ROOT"
else
    # Handle relative paths
    if [[ ! "$TARGET_DIR" = /* ]]; then
        TARGET_DIR="$PROJECT_ROOT/$TARGET_DIR"
    fi
fi

# Verify directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}Error: Directory '$TARGET_DIR' does not exist${NC}"
    exit 1
fi

cd "$TARGET_DIR"
printf "%sCompiling in: %s%s\n" "$GREEN" "$TARGET_DIR" "$NC"

# Clean work library if requested
if [ "$CLEAN" = true ]; then
    printf "%sCleaning work library...%s\n" "$YELLOW" "$NC"
    rm -rf work-obj08.cf *.cf
fi

# Find VHDL files - packages first, then others (for correct dependency order)
if [ "$RECURSIVE" = true ]; then
    PKG_FILES=$(find . -name "*_pkg.vhd" -type f 2>/dev/null | sort)
    OTHER_FILES=$(find . -name "*.vhd" ! -name "*_pkg.vhd" -type f 2>/dev/null | sort)
else
    PKG_FILES=$(find . -maxdepth 1 -name "*_pkg.vhd" -type f 2>/dev/null | sort)
    OTHER_FILES=$(find . -maxdepth 1 -name "*.vhd" ! -name "*_pkg.vhd" -type f 2>/dev/null | sort)
fi

# Combine: packages first, then other files
VHD_FILES="$PKG_FILES $OTHER_FILES"
VHD_FILES=$(echo "$VHD_FILES" | tr ' ' '\n' | grep -v '^$')

if [ -z "$VHD_FILES" ]; then
    printf "%sNo .vhd files found in %s%s\n" "$YELLOW" "$TARGET_DIR" "$NC"
    if [ "$RECURSIVE" = false ]; then
        printf "%sHint: Use -r or --recursive to search in subdirectories.%s\n" "$YELLOW" "$NC"
    fi
     exit 0
fi

# Count files
FILE_COUNT=$(echo "$VHD_FILES" | wc -l)
printf "%sFound %s VHDL file(s) to compile%s\n" "$GREEN" "$FILE_COUNT" "$NC"
if [ -n "$PKG_FILES" ]; then
    PKG_COUNT=$(echo "$PKG_FILES" | wc -w)
    printf "%s(Compiling %s package(s) first)%s\n" "$YELLOW" "$PKG_COUNT" "$NC"
fi
echo ""

# Compile each file
SUCCESS=0
FAILED=0
SKIPPED=0

for file in $VHD_FILES; do
    # Skip empty files
    if [ ! -s "$file" ]; then
        printf "Skipping %s... %sEMPTY%s\n" "$file" "$YELLOW" "$NC"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi
    
    printf "Compiling %s... " "$file"
    
    if ghdl -a $STD -fsynopsys $SYNOPSYS "$file" 2>&1; then
        printf "%sOK%s\n" "$GREEN" "$NC"
        SUCCESS=$((SUCCESS + 1))
    else
        printf "%sFAILED%s\n" "$RED" "$NC"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "======================================"
printf "Results: %s%s passed%s, %s%s failed%s, %s%s skipped%s\n" "$GREEN" "$SUCCESS" "$NC" "$RED" "$FAILED" "$NC" "$YELLOW" "$SKIPPED" "$NC"
echo "======================================"

if [ $FAILED -gt 0 ]; then
    exit 1
fi
