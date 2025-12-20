-- ============================================================================
-- Top-Level Execute Stage Testbench
-- ============================================================================
-- Tests the execute stage behavior when integrated in the top-level processor
-- Similar to tb_execute_stage.vhd but tests through the full pipeline
-- ============================================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.memory_interface_pkg.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;

entity tb_top_level_execute is
end entity tb_top_level_execute;

architecture testbench of tb_top_level_execute is
    -- Component declaration
    component top_level_processor is
        generic (
            INIT_FILENAME : string := "../assembler/output/test_output.mem"
        );
        port(
            clk : in std_logic;
            reset : in std_logic;
            interrupt : in std_logic;
            inputport_data : in std_logic_vector(31 downto 0);
            tb_instruction_mem : in std_logic_vector(31 downto 0);
            tb_mem_read_data : in std_logic_vector(31 downto 0);
            tb_exe_alu_result : out std_logic_vector(31 downto 0);
            tb_exe_ccr : out std_logic_vector(2 downto 0);
            tb_exe_branch_taken : out std_logic;
            tb_exe_rd_addr : out std_logic_vector(2 downto 0);
            tb_mem_wb_signals : out std_logic_vector(2 downto 0);
            tb_mem_stage_read_data_out  : out std_logic_vector(31 downto 0);
            tb_mem_alu_result : out std_logic_vector(31 downto 0);
            tb_mem_rd_addr    : out std_logic_vector(2 downto 0);

            dbg_pc : out std_logic_vector(31 downto 0);
            dbg_fetched_instruction : out std_logic_vector(31 downto 0);
            dbg_sp : out std_logic_vector(17 downto 0);
            dbg_stall : out std_logic;
            dbg_ram_addr : out std_logic_vector(17 downto 0);
            dbg_ram_read_en : out std_logic;
            dbg_ram_write_en : out std_logic;
            dbg_ram_data_in : out std_logic_vector(31 downto 0);
            dbg_ram_data_out : out std_logic_vector(31 downto 0)
        );
    end component top_level_processor;

    -- Test signals
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal interrupt : std_logic := '0';
    signal inputport_data : std_logic_vector(31 downto 0) := X"000000FF"; -- Default input port value
    signal instruction : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_read_data : std_logic_vector(31 downto 0) := (others => '0');
    
    -- Execute stage observation signals
    signal exe_alu_result : std_logic_vector(31 downto 0);
    signal exe_ccr : std_logic_vector(2 downto 0);
    signal exe_branch_taken : std_logic;
    signal exe_rd_addr : std_logic_vector(2 downto 0);

    -- Memory stage observation signals
    signal mem_wb_signals : std_logic_vector(2 downto 0);
    signal mem_stage_read_data_out : std_logic_vector(31 downto 0);
    signal mem_alu_result : std_logic_vector(31 downto 0);
    signal mem_rd_addr : std_logic_vector(2 downto 0);

    signal dbg_pc : std_logic_vector(31 downto 0);
    signal dbg_fetched_instruction : std_logic_vector(31 downto 0);
    signal dbg_sp : std_logic_vector(17 downto 0);
    signal dbg_stall : std_logic;
    signal dbg_ram_addr : std_logic_vector(17 downto 0);
    signal dbg_ram_read_en : std_logic;
    signal dbg_ram_write_en : std_logic;
    signal dbg_ram_data_in : std_logic_vector(31 downto 0);
    signal dbg_ram_data_out : std_logic_vector(31 downto 0);
    
    -- Clock period
    constant clk_period : time := 10 ns;
    
    -- Test counters
    signal test_count : integer := 0;
    shared variable passed_tests : integer := 0;
    shared variable failed_tests : integer := 0;

    constant MAX_CYCLES : integer := 500;
    
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
    
    -- Procedure to print test header
    procedure print_header(test_name : string) is
        variable l : line;
    begin
        write(l, string'(""));
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);
        write(l, string'("TEST "));
        write(l, test_count);
        write(l, string'(": ") & test_name);
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);
    end procedure;
    
    -- Procedure to check ALU result
    procedure check_alu_result(
        expected : std_logic_vector(31 downto 0);
        test_name : string;
        signal actual : in std_logic_vector(31 downto 0)
    ) is
        variable l : line;
        variable passed : boolean;
    begin
        passed := (actual = expected);
        
        write(l, string'("  ALU Result: Expected="));
        hwrite(l, expected);
        write(l, string'(" Got="));
        hwrite(l, actual);
        
        if passed then
            write(l, string'(" [PASS]"));
            passed_tests := passed_tests + 1;
        else
            write(l, string'(" [FAIL]"));
            failed_tests := failed_tests + 1;
        end if;
        writeline(output, l);
    end procedure;
    
    -- Procedure to check CCR flags
    procedure check_ccr(
        expected_z : std_logic;
        expected_n : std_logic;
        expected_c : std_logic;
        test_name : string;
        signal actual : in std_logic_vector(2 downto 0)
    ) is
        variable l : line;
        variable passed : boolean;
        variable expected : std_logic_vector(2 downto 0);
    begin
        expected := expected_z & expected_n & expected_c;
        passed := (actual = expected);
        
        write(l, string'("  CCR Flags: Expected=[Z="));
        write(l, expected_z);
        write(l, string'(",N="));
        write(l, expected_n);
        write(l, string'(",C="));
        write(l, expected_c);
        write(l, string'("] Got=[Z="));
        write(l, actual(2));
        write(l, string'(",N="));
        write(l, actual(1));
        write(l, string'(",C="));
        write(l, actual(0));
        write(l, string'("]"));
        
        if passed then
            write(l, string'(" [PASS]"));
        else
            write(l, string'(" [FAIL]"));
        end if;
        writeline(output, l);
    end procedure;
    
    -- Procedure to wait for execute stage (pipeline delay)
    procedure wait_for_execute is
    begin
        -- Wait for instruction to propagate through pipeline:
        -- Cycle 1: Fetch -> IF/ID
        wait until rising_edge(clk);
        -- Cycle 2: Decode -> ID/EX
        wait until rising_edge(clk);
        -- Cycle 3: Execute -> EX/MEM (result available)
        wait until rising_edge(clk);
    end procedure;

begin
    -- Instantiate DUT
    DUT: top_level_processor port map(
        clk => clk,
        reset => reset,
        interrupt => interrupt,
        inputport_data => inputport_data,
        tb_instruction_mem => instruction,
        tb_mem_read_data => mem_read_data,
        tb_exe_alu_result => exe_alu_result,
        tb_exe_ccr => exe_ccr,
        tb_exe_branch_taken => exe_branch_taken,
        tb_exe_rd_addr => exe_rd_addr,
        tb_mem_wb_signals => mem_wb_signals,
        tb_mem_stage_read_data_out => mem_stage_read_data_out,
        tb_mem_alu_result => mem_alu_result,
        tb_mem_rd_addr => mem_rd_addr,

        dbg_pc => dbg_pc,
        dbg_fetched_instruction => dbg_fetched_instruction,
        dbg_sp => dbg_sp,
        dbg_stall => dbg_stall,
        dbg_ram_addr => dbg_ram_addr,
        dbg_ram_read_en => dbg_ram_read_en,
        dbg_ram_write_en => dbg_ram_write_en,
        dbg_ram_data_in => dbg_ram_data_in,
        dbg_ram_data_out => dbg_ram_data_out
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
        variable push_seen : boolean := false;
        variable pop_read_seen : boolean := false;
        variable push_addr : std_logic_vector(17 downto 0) := (others => '0');
        variable push_data : std_logic_vector(31 downto 0) := (others => '0');
        variable pop_data : std_logic_vector(31 downto 0) := (others => '0');
    begin
        write(l, string'(""));
        writeline(output, l);
        write(l, string'("================================================================================"));
        writeline(output, l);
        write(l, string'("   EXECUTE STAGE INTEGRATION TEST"));
        writeline(output, l);
        write(l, string'("   Testing Execute Stage through Top-Level Processor"));
        writeline(output, l);
        write(l, string'("================================================================================"));
        writeline(output, l);
        
        -- Reset
        reset <= '1';
        inputport_data <= X"000000FF"; -- Set input port data
        instruction <= (others => '0');
        mem_read_data <= (others => '0');
        wait for clk_period * 2;
        reset <= '0';
        wait for clk_period;

        for i in 0 to MAX_CYCLES-1 loop
            wait until rising_edge(clk);
            wait for 1 ns;

            write(l, string'("CYCLE="));
            write(l, i);
            write(l, string'(" PC="));
            hwrite(l, dbg_pc);
            write(l, string'(" INSTR="));
            hwrite(l, dbg_fetched_instruction);
            write(l, string'(" SP="));
            hwrite(l, (31 downto 18 => '0') & dbg_sp);
            write(l, string'(" STALL="));
            write(l, dbg_stall);
            writeline(output, l);

            if (dbg_ram_write_en = '1') then
                write(l, string'("  MEM_WR A="));
                hwrite(l, (31 downto 18 => '0') & dbg_ram_addr);
                write(l, string'(" D="));
                hwrite(l, dbg_ram_data_in);
                writeline(output, l);

                if (push_seen = false) and (dbg_ram_addr = std_logic_vector(to_unsigned(262143, 18))) then
                    push_seen := true;
                    push_addr := dbg_ram_addr;
                    push_data := dbg_ram_data_in;
                end if;
            end if;

            if (dbg_ram_read_en = '1') then
                write(l, string'("  MEM_RD A="));
                hwrite(l, (31 downto 18 => '0') & dbg_ram_addr);
                write(l, string'(" Q="));
                hwrite(l, dbg_ram_data_out);
                writeline(output, l);

                if (push_seen = true) and (pop_read_seen = false) and (dbg_ram_data_out = push_data) then
                    pop_read_seen := true;
                    pop_data := dbg_ram_data_out;
                end if;
            end if;
        end loop;

        assert push_seen
            report "FAIL: did not observe a stack write at address 0x0003FFFF (expected PUSH)"
            severity error;

        assert push_data = std_logic_vector(to_unsigned(4, 32))
            report "FAIL: PUSH did not write expected value (expected R4=4 on reset)"
            severity error;

        assert pop_read_seen
            report "FAIL: did not observe a stack read returning the pushed value (expected POP)"
            severity error;

        wait;
        
        -- ====================================================================
        -- TEST 1: NOP Instruction
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("NOP Instruction");
        
        instruction <= make_instruction("00000", "00", "000", "000", "000"); -- NOP
        wait_for_execute;
        
        -- NOP should not change anything
        write(l, string'("  NOP executed - no changes expected"));
        writeline(output, l);
        
        -- ====================================================================
        -- TEST 2: SETC Instruction
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("SETC Instruction");
        
        instruction <= make_instruction("00010", "00", "000", "000", "000"); -- SETC
        wait_for_execute;
        
        check_ccr('0', '0', '1', "SETC", exe_ccr);
        
        -- ====================================================================
        -- TEST 3: INC Instruction (Positive Value)
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("INC R1 (increment positive value)");
        
        -- First load a value into R1 using LDM (assuming register file is initialized)
        -- For testing, we'll just issue INC and check the ALU operation
        instruction <= make_instruction("00011", "00", "001", "000", "000"); -- INC R1
        wait_for_execute;
        
        write(l, string'("  INC R1 executed"));
        writeline(output, l);
        
        -- ====================================================================
        -- TEST 4: NOT Instruction
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("NOT R2 (bitwise complement)");
        
        instruction <= make_instruction("00100", "00", "010", "000", "000"); -- NOT R2
        wait_for_execute;
        
        write(l, string'("  NOT R2 executed"));
        writeline(output, l);
        
        -- ====================================================================
        -- TEST 5: ADD Instruction (R1 = R2 + R3)
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("ADD R1, R2, R3");
        
        instruction <= make_instruction("01001", "00", "001", "010", "011"); -- ADD R1, R2, R3
        wait_for_execute;
        
        write(l, string'("  ADD R1, R2, R3 executed"));
        writeline(output, l);
        write(l, string'("  Result available in exe_alu_result"));
        writeline(output, l);
        
        -- ====================================================================
        -- TEST 6: SUB Instruction (R4 = R5 - R6)
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("SUB R4, R5, R6");
        
        instruction <= make_instruction("01010", "00", "100", "101", "110"); -- SUB R4, R5, R6
        wait_for_execute;
        
        write(l, string'("  SUB R4, R5, R6 executed"));
        writeline(output, l);
        
        -- ====================================================================
        -- TEST 7: AND Instruction (R0 = R1 & R2)
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("AND R0, R1, R2");
        
        instruction <= make_instruction("01011", "00", "000", "001", "010"); -- AND R0, R1, R2
        wait_for_execute;
        
        write(l, string'("  AND R0, R1, R2 executed"));
        writeline(output, l);
        
        -- ====================================================================
        -- TEST 8: IADD Instruction (Immediate Add)
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("IADD R3, R4, #immediate");
        
        instruction <= make_instruction("01000", "00", "011", "100", "000"); -- IADD R3, R4, imm
        wait for clk_period; -- First word
        
        -- Second word: immediate value (this is multi-cycle)
        instruction <= X"00000005"; -- Immediate value = 5
        wait_for_execute;
        
        write(l, string'("  IADD R3, R4, #5 executed"));
        writeline(output, l);
        
        -- ====================================================================
        -- TEST 9: MOV Instruction
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("MOV R1, R2");
        
        instruction <= make_instruction("00110", "00", "001", "010", "000"); -- MOV R1, R2
        wait_for_execute;
        
        write(l, string'("  MOV R1, R2 executed"));
        writeline(output, l);
        
        -- ====================================================================
        -- TEST 10: SWAP Instruction (Multi-cycle)
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("SWAP R3, R4 (Multi-cycle)");
        
        instruction <= make_instruction("00111", "00", "011", "100", "000"); -- SWAP R3, R4
        
        -- SWAP is multi-cycle, need extra wait
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk); -- Extra cycle for SWAP
        
        write(l, string'("  SWAP R3, R4 executed (multi-cycle)"));
        writeline(output, l);
        
        -- ====================================================================
        -- TEST 11: Branch Instructions (JZ, JN, JC)
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("JZ (Jump if Zero)");
        
        instruction <= make_instruction("01100", "00", "000", "000", "000"); -- JZ
        wait_for_execute;
        
        write(l, string'("  JZ branch decision: "));
        write(l, exe_branch_taken);
        writeline(output, l);
        
        -- ====================================================================
        -- TEST 12: OUT Instruction
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("OUT R5");
        
        instruction <= make_instruction("10000", "00", "000", "000", "101"); -- OUT R5
        wait_for_execute;
        
        write(l, string'("  OUT R5 executed"));
        writeline(output, l);
        
        -- ====================================================================
        -- TEST 13: IN Instruction
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("IN R6");
        
        instruction <= make_instruction("10001", "00", "110", "000", "000"); -- IN R6
        wait_for_execute;
        
        write(l, string'("  IN R6 executed"));
        writeline(output, l);
        
        -- ====================================================================
        -- TEST 14: Rapid Fire - Multiple ALU Operations
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("Rapid Fire ALU Operations");
        
        -- ADD
        instruction <= make_instruction("01001", "00", "001", "010", "011"); -- ADD
        wait_for_execute;
        write(l, string'("  ADD executed, ALU Result: "));
        hwrite(l, exe_alu_result);
        writeline(output, l);
        
        -- SUB
        instruction <= make_instruction("01010", "00", "010", "011", "100"); -- SUB
        wait_for_execute;
        write(l, string'("  SUB executed, ALU Result: "));
        hwrite(l, exe_alu_result);
        writeline(output, l);
        
        -- AND
        instruction <= make_instruction("01011", "00", "011", "100", "101"); -- AND
        wait_for_execute;
        write(l, string'("  AND executed, ALU Result: "));
        hwrite(l, exe_alu_result);
        writeline(output, l);
        
        -- ====================================================================
        -- TEST 15: LDM Instruction (Load Immediate)
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("LDM R1, #100 (Load Immediate)");
        
        instruction <= make_instruction("00101", "00", "001", "000", "000"); -- LDM R1
        wait_for_execute;
        write(l, string'("  LDM executed - loads immediate value to R1"));
        writeline(output, l);
        
        -- ====================================================================
        -- TEST 16: LDD Instruction (Load Direct from Memory)
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("LDD R2, offset(R3) (Load Direct)");
        
        instruction <= make_instruction("10100", "01", "010", "011", "000"); -- LDD R2
        wait_for_execute;
        write(l, string'("  LDD executed - loads from memory address"));
        writeline(output, l);
        
        -- ====================================================================
        -- TEST 17: STD Instruction (Store Direct to Memory)
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("STD R3, offset(R4) (Store Direct)");
        
        instruction <= make_instruction("10101", "10", "011", "100", "000"); -- STD R3
        wait_for_execute;
        write(l, string'("  STD executed - stores to memory address"));
        writeline(output, l);
        
        -- ====================================================================
        -- TEST 18: CALL Instruction
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("CALL subroutine (Call Function)");
        
        instruction <= make_instruction("10110", "00", "000", "001", "000"); -- CALL
        wait_for_execute;
        write(l, string'("  CALL executed - branches and saves return address"));
        writeline(output, l);
        check_ccr('0', '0', '0', "CALL", exe_ccr);
        
        -- ====================================================================
        -- TEST 19: RET Instruction (Return from Subroutine)
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("RET (Return from Subroutine)");
        
        instruction <= make_instruction("10111", "00", "000", "000", "000"); -- RET
        wait_for_execute;
        write(l, string'("  RET executed - returns to caller"));
        writeline(output, l);
        
        -- ====================================================================
        -- TEST 20: RTI Instruction (Return from Interrupt)
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("RTI (Return from Interrupt)");
        
        instruction <= make_instruction("11001", "00", "000", "000", "000"); -- RTI
        wait_for_execute;
        wait_for_execute; -- RTI is multi-cycle
        write(l, string'("  RTI executed - returns from interrupt handler"));
        writeline(output, l);
        
        -- ====================================================================
        -- TEST 21: Interrupt Signal Test
        -- ====================================================================
        test_count <= test_count + 1;
        print_header("External Interrupt Signal");
        
        -- Issue a normal instruction
        instruction <= make_instruction("01001", "00", "001", "010", "011"); -- ADD
        wait until rising_edge(clk);
        
        -- Assert interrupt
        interrupt <= '1';
        wait until rising_edge(clk);
        interrupt <= '0';
        
        -- Wait for interrupt handling
        wait_for_execute;
        wait_for_execute; -- Extra cycles for interrupt
        wait_for_execute;
        
        write(l, string'("  Interrupt serviced - PC saved, CCR saved, jump to ISR"));
        writeline(output, l);
        
        -- ====================================================================
        -- End of Tests Summary
        -- ====================================================================
        write(l, string'(""));
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);
        write(l, string'("TEST SUMMARY"));
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);
        write(l, string'("Total Tests: "));
        write(l, test_count);
        writeline(output, l);
        write(l, string'("Passed: "));
        write(l, passed_tests);
        writeline(output, l);
        write(l, string'("Failed: "));
        write(l, failed_tests);
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);
        write(l, string'("  - Branch decisions"));
        writeline(output, l);
        write(l, string'("  - Forwarding unit behavior"));
        writeline(output, l);
        write(l, string'("================================================================================"));
        writeline(output, l);
        
        wait;
    end process;

end architecture testbench;
