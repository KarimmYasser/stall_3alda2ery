library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;

entity tb_top_level_aggressive is
end entity tb_top_level_aggressive;

architecture testbench of tb_top_level_aggressive is
    -- Component declaration
    component top_level_processor is
        port(
            clk : in std_logic;
            reset : in std_logic;
            interrupt : in std_logic;
            tb_instruction_mem : in std_logic_vector(31 downto 0);
            tb_mem_read_data : in std_logic_vector(31 downto 0)
        );
    end component top_level_processor;

    -- Test signals
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal interrupt : std_logic := '0';
    signal instruction : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_read_data : std_logic_vector(31 downto 0) := (others => '0');
    
    -- Clock period
    constant clk_period : time := 10 ns;
    
    -- Helper function to create instruction
    function make_instruction(
        opcode : std_logic_vector(4 downto 0);
        index  : std_logic_vector(1 downto 0);
        rd     : std_logic_vector(2 downto 0);
        rs1    : std_logic_vector(2 downto 0);
        rs2    : std_logic_vector(2 downto 0)
    ) return std_logic_vector is
        variable inst : std_logic_vector(31 downto 0);
    begin
        inst := (others => '0');
        inst(31 downto 27) := opcode;
        inst(26 downto 25) := index;
        inst(8 downto 6)   := rd;
        inst(5 downto 3)   := rs1;
        inst(2 downto 0)   := rs2;
        return inst;
    end function;
    
    -- Procedure to log cycle-by-cycle state
    procedure log_cycle_state(
        constant cycle_num : in integer;
        constant test_name : in string;
        signal instruction : in std_logic_vector(31 downto 0)
    ) is
        variable l : line;
    begin
        write(l, string'("Cycle "));
        write(l, cycle_num);
        write(l, string'(" [") & test_name & string'("]"));
        writeline(output, l);
        write(l, string'("  Instruction: "));
        hwrite(l, instruction);
        write(l, string'(" | Opcode: "));
        write(l, instruction(31 downto 27));
        writeline(output, l);
        write(l, string'("  Check waveforms for detailed signal analysis"));
        writeline(output, l);
        write(l, string'(""));
        writeline(output, l);
    end procedure;

begin
    -- Instantiate DUT
    DUT: top_level_processor port map(
        clk => clk,
        reset => reset,
        interrupt => interrupt,
        tb_instruction_mem => instruction,
        tb_mem_read_data => mem_read_data
    );

    -- Clock generation
    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
        variable l : line;
        variable cycle_count : integer := 0;
    begin
        write(l, string'(""));
        writeline(output, l);
        write(l, string'("================================================================================"));
        writeline(output, l);
        write(l, string'("   TOP-LEVEL PROCESSOR AGGRESSIVE TESTBENCH"));
        writeline(output, l);
        write(l, string'("   Testing Complete System with Same Tests as Decode Stage"));
        writeline(output, l);
        write(l, string'("================================================================================"));
        writeline(output, l);
        write(l, string'(""));
        writeline(output, l);
        
        -- Reset
        reset <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        reset <= '0';
        wait until rising_edge(clk);
        
        -- TEST 1: Multi-cycle SWAP instruction
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 1: SWAP Instruction (Multi-Cycle - 2 cycles)"));
        writeline(output, l);
        write(l, string'("Expected: Stall asserted, CSwap toggles, no forwarding during SWAP"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("00111", "00", "001", "010", "011"); -- SWAP
        cycle_count := 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "SWAP-C1", instruction);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "SWAP-C2", instruction);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "SWAP-C3", instruction);
        
        -- TEST 2: ADD after SWAP
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 2: ADD after SWAP"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("01001", "00", "100", "001", "010"); -- ADD
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "ADD", instruction);
        
        -- TEST 3: Interrupt during SWAP
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 3: Interrupt during SWAP execution"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("00111", "00", "011", "100", "101"); -- SWAP
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "SWAP-INT-C1", instruction);
        
        interrupt <= '1';
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "SWAP-INT-C2", instruction);
        
        interrupt <= '0';
        for i in 1 to 4 loop
            cycle_count := cycle_count + 1;
            wait until rising_edge(clk);
            log_cycle_state(cycle_count, "INT-HANDLING", instruction);
        end loop;
        
        -- TEST 4: INT instruction
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 4: INT Instruction (Software Interrupt - 3 cycles)"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("11000", "00", "000", "001", "010"); -- INT
        for i in 1 to 4 loop
            cycle_count := cycle_count + 1;
            wait until rising_edge(clk);
            log_cycle_state(cycle_count, "INT-INST", instruction);
        end loop;
        
        -- TEST 5: RTI instruction
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 5: RTI Instruction"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("11001", "00", "000", "001", "010"); -- RTI
        for i in 1 to 3 loop
            cycle_count := cycle_count + 1;
            wait until rising_edge(clk);
            log_cycle_state(cycle_count, "RTI", instruction);
        end loop;
        
        -- TEST 6-12: Copy remaining tests from decode_aggressive
        -- TEST 6: LDD
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 6: LDD (Memory Read)"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("10100", "01", "010", "011", "000"); -- LDD
        for i in 1 to 3 loop
            cycle_count := cycle_count + 1;
            wait until rising_edge(clk);
            log_cycle_state(cycle_count, "LDD", instruction);
        end loop;
        
        -- TEST 7: PUSH-POP
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 7: PUSH and POP"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("10010", "00", "000", "001", "010"); -- PUSH
        for i in 1 to 3 loop
            cycle_count := cycle_count + 1;
            wait until rising_edge(clk);
            log_cycle_state(cycle_count, "PUSH", instruction);
        end loop;
        
        instruction <= make_instruction("10011", "00", "001", "010", "011"); -- POP
        for i in 1 to 3 loop
            cycle_count := cycle_count + 1;
            wait until rising_edge(clk);
            log_cycle_state(cycle_count, "POP", instruction);
        end loop;
        
        -- TEST 8: Rapid fire instructions
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 8: Rapid Fire Instructions"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("01001", "00", "001", "010", "011"); -- ADD
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "ADD", instruction);
        
        instruction <= make_instruction("01010", "00", "010", "011", "100"); -- SUB
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "SUB", instruction);
        
        instruction <= make_instruction("01011", "00", "011", "100", "101"); -- AND
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "AND", instruction);
        
        -- TEST 9: STD instruction (memory write with immediate)
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 9: STD (Store Direct - Memory Write)"));
        writeline(output, l);
        write(l, string'("Expected: Uses immediate addressing, memory write flag set"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("10101", "10", "011", "100", "101"); -- STD
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "STD", instruction);
        
        -- TEST 10: IADD instruction (immediate add)
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 10: IADD (Immediate Add)"));
        writeline(output, l);
        write(l, string'("Expected: Uses immediate value, ALU add operation, register write"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("01000", "00", "001", "010", "011"); -- IADD
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "IADD", instruction);
        
        -- Add ADD instruction before HLT
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST: ADD (before HLT)"));
        writeline(output, l);
        write(l, string'("Expected: Normal ADD execution"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("01001", "00", "010", "011", "100"); -- ADD
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "ADD-BEFORE-HLT", instruction);
        
        -- Wait 2 cycles before HLT
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "WAIT-1", instruction);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "WAIT-2", instruction);
        
        -- TEST 11: HLT instruction
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 11: HLT (Halt)"));
        writeline(output, l);
        write(l, string'("Expected: Pipeline stops, FD_enable='0', DE_enable='0', Stall='1'"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("00001", "00", "000", "000", "000"); -- HLT
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "HLT-C1", instruction);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "HLT-C2", instruction);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "HLT-C3", instruction);
        
        -- Issue instructions after HLT to verify processor remains halted
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 12: Instructions after HLT (should be ignored)"));
        writeline(output, l);
        write(l, string'("Expected: Processor remains halted, instructions not executed"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("01001", "00", "001", "010", "011"); -- ADD
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "AFTER-HLT-ADD", instruction);
        
        instruction <= make_instruction("00110", "00", "010", "011", "100"); -- MOV
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "AFTER-HLT-MOV", instruction);
        
        instruction <= make_instruction("00011", "00", "011", "100", "101"); -- INC
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "AFTER-HLT-INC", instruction);
        
        instruction <= make_instruction("00100", "00", "100", "101", "110"); -- NOT
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "AFTER-HLT-NOT", instruction);
        
        -- TEST 13: Reset and Recovery
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 13: Reset and Recovery"));
        writeline(output, l);
        write(l, string'("Expected: System resets, then executes new instructions"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        reset <= '1';
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RESET-ASSERT", instruction);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RESET-HOLD", instruction);
        
        reset <= '0';
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RESET-RELEASE", instruction);
        
        -- ADD after reset
        instruction <= make_instruction("01001", "00", "001", "010", "011"); -- ADD
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "POST-RESET-ADD", instruction);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "POST-RESET-ADD-C2", instruction);
        
        -- MOV after reset
        instruction <= make_instruction("00110", "00", "010", "011", "100"); -- MOV
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "POST-RESET-MOV", instruction);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "POST-RESET-MOV-C2", instruction);
        
        -- IADD after reset
        instruction <= make_instruction("01000", "00", "011", "100", "101"); -- IADD
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "POST-RESET-IADD", instruction);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "POST-RESET-IADD-C2", instruction);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "POST-RESET-IADD-C3", instruction);
        
        -- Summary
        write(l, string'(""));
        writeline(output, l);
        write(l, string'("================================================================================"));
        writeline(output, l);
        write(l, string'("   TOP-LEVEL AGGRESSIVE TESTS COMPLETED"));
        writeline(output, l);
        write(l, string'("   Total Cycles: "));
        write(l, cycle_count);
        writeline(output, l);
        write(l, string'("================================================================================"));
        writeline(output, l);
        
        wait;
    end process;

end architecture testbench;
