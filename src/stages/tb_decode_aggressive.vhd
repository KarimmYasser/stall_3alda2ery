library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;

entity tb_decode_aggressive is
end entity tb_decode_aggressive;

architecture testbench of tb_decode_aggressive is
    -- Component declaration
    component Decode is 
        port(
            inturrupt : in std_logic;
            reset: in std_logic;
            clk: in std_logic;
            instruction : in std_logic_vector(31 downto 0);
            PC : in std_logic_vector(31 downto 0);
            mem_br: in std_logic;
            exe_br: in std_logic;
            FD_enable : out std_logic;
            Stall :out std_logic;
            DE_enable :out  std_logic;
            EM_enable : out std_logic;
            MW_enable :out std_logic;
            Branch_Decode: out std_logic;
            Micro_inst_out: out std_logic_vector(4 downto 0);
            WB_flages_pipe_out: out std_logic_vector(2 downto 0);
            EXE_flages_pipe_out: out std_logic_vector(4 downto 0);
            MEM_flages_pipe_out: out std_logic_vector(6 downto 0);
            IO_flages_pipe_out: out std_logic_vector(1 downto 0);
            Branch_Exec_pipe_out: out std_logic_vector(3 downto 0);
            Rrs1_pipe_out: out std_logic_vector(31 downto 0);
            Rrs2_pipe_out: out std_logic_vector(31 downto 0);
            index_pipe_out: out std_logic_vector(2 downto 0);
            pc_pipe_out: out std_logic_vector(31 downto 0);
            rs1_addr_pipe_out: out std_logic_vector(2 downto 0);
            rs2_addr_pipe_out: out std_logic_vector(2 downto 0);
            rd_addr_pipe_out: out std_logic_vector(2 downto 0)
        );
    end component Decode;

    -- Test signals
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal inturrupt : std_logic := '0';
    signal instruction : std_logic_vector(31 downto 0) := (others => '0');
    signal PC : std_logic_vector(31 downto 0) := X"00000100";
    signal mem_br : std_logic := '0';
    signal exe_br : std_logic := '0';
    
    -- Output signals
    signal FD_enable : std_logic;
    signal Stall : std_logic;
    signal DE_enable : std_logic;
    signal EM_enable : std_logic;
    signal MW_enable : std_logic;
    signal Branch_Decode : std_logic;
    signal WB_flages : std_logic_vector(2 downto 0);
    signal EXE_flages : std_logic_vector(4 downto 0);
    signal MEM_flages : std_logic_vector(6 downto 0);
    signal IO_flages : std_logic_vector(1 downto 0);
    signal Branch_Exec : std_logic_vector(3 downto 0);
    signal Rrs1 : std_logic_vector(31 downto 0);
    signal Rrs2 : std_logic_vector(31 downto 0);
    signal index : std_logic_vector(2 downto 0);
    signal pc_out : std_logic_vector(31 downto 0);
    signal rs1_addr : std_logic_vector(2 downto 0);
    signal rs2_addr : std_logic_vector(2 downto 0);
    signal rd_addr : std_logic_vector(2 downto 0);
    signal Micro_inst : std_logic_vector(4 downto 0);
    
    -- Clock period
    constant clk_period : time := 10 ns;
    
    -- Helper function to create instruction
    function make_instruction(
        opcode : std_logic_vector(4 downto 0);
        index  : std_logic_vector(2 downto 0);
        rd     : std_logic_vector(2 downto 0);
        rs1    : std_logic_vector(2 downto 0);
        rs2    : std_logic_vector(2 downto 0)
    ) return std_logic_vector is
        variable inst : std_logic_vector(31 downto 0);
    begin
        inst := (others => '0');
        inst(31 downto 27) := opcode;
        inst(26 downto 24) := index;
        inst(8 downto 6)   := rd;
        inst(5 downto 3)   := rs1;
        inst(2 downto 0)   := rs2;
        return inst;
    end function;
    
    -- Procedure to log cycle-by-cycle state
    procedure log_cycle_state(
        constant cycle_num : in integer;
        constant test_name : in string;
        signal instruction : in std_logic_vector(31 downto 0);
        signal FD_enable : in std_logic;
        signal Stall : in std_logic;
        signal DE_enable : in std_logic;
        signal EM_enable : in std_logic;
        signal MW_enable : in std_logic;
        signal MEM_flages : in std_logic_vector(6 downto 0);
        signal inturrupt : in std_logic
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
        write(l, string'("  Pipeline: FD="));
        write(l, FD_enable);
        write(l, string'(" DE="));
        write(l, DE_enable);
        write(l, string'(" EM="));
        write(l, EM_enable);
        write(l, string'(" MW="));
        write(l, MW_enable);
        write(l, string'(" STALL="));
        write(l, Stall);
        writeline(output, l);
        write(l, string'("  MEM: StkW="));
        write(l, MEM_flages(2));
        write(l, string'(" StkR="));
        write(l, MEM_flages(3));
        write(l, string'(" MemW="));
        write(l, MEM_flages(4));
        write(l, string'(" MemR="));
        write(l, MEM_flages(5));
        write(l, string'(" | INT="));
        write(l, inturrupt);
        writeline(output, l);
        write(l, string'(""));
        writeline(output, l);
    end procedure;

begin
    -- Instantiate DUT
    DUT: Decode port map(
        clk => clk,
        reset => reset,
        inturrupt => inturrupt,
        instruction => instruction,
        PC => PC,
        mem_br => mem_br,
        exe_br => exe_br,
        FD_enable => FD_enable,
        Stall => Stall,
        DE_enable => DE_enable,
        EM_enable => EM_enable,
        MW_enable => MW_enable,
        Branch_Decode => Branch_Decode,
        Micro_inst_out => Micro_inst,
        WB_flages_pipe_out => WB_flages,
        EXE_flages_pipe_out => EXE_flages,
        MEM_flages_pipe_out => MEM_flages,
        IO_flages_pipe_out => IO_flages,
        Branch_Exec_pipe_out => Branch_Exec,
        Rrs1_pipe_out => Rrs1,
        Rrs2_pipe_out => Rrs2,
        index_pipe_out => index,
        pc_pipe_out => pc_out,
        rs1_addr_pipe_out => rs1_addr,
        rs2_addr_pipe_out => rs2_addr,
        rd_addr_pipe_out => rd_addr
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
        write(l, string'("   AGGRESSIVE DECODE STAGE TESTBENCH"));
        writeline(output, l);
        write(l, string'("   Testing Multi-Cycle Instructions, Interrupts, and Memory Hazards"));
        writeline(output, l);
        write(l, string'("   (Instructions applied on RISING EDGE of clock)"));
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
        
        -- TEST 1: Multi-cycle SWAP instruction - observe all cycles
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 1: SWAP Instruction (Multi-Cycle - 2 cycles)"));
        writeline(output, l);
        write(l, string'("Expected: Stall should be asserted for 2 cycles"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("00111", "000", "001", "010", "011"); -- SWAP
        cycle_count := 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "SWAP-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "SWAP-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "SWAP-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        -- TEST 2: Try to issue new instruction immediately after SWAP
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 2: Issue ADD immediately after SWAP completes"));
        writeline(output, l);
        write(l, string'("Expected: ADD should proceed normally, no stall"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("01001", "000", "100", "001", "010"); -- ADD
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "ADD", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        -- TEST 3: Interrupt during SWAP execution
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 3: Interrupt occurs DURING SWAP execution"));
        writeline(output, l);
        write(l, string'("Expected: SWAP continues, then interrupt serviced (3 cycles)"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("00111", "000", "011", "100", "101"); -- SWAP
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "SWAP-INT-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        -- Assert interrupt during SWAP
        inturrupt <= '1';
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "SWAP-INT-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        inturrupt <= '0';
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "INT-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "INT-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "INT-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "POST-INT", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        -- TEST 4: INT instruction (software interrupt - 3 cycles)
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 4: INT Instruction (Software Interrupt - 3 cycles)"));
        writeline(output, l);
        write(l, string'("Expected: 3 cycle execution with PC and CCR saved"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("11000", "000", "000", "001", "010"); -- INT
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "INT-INST-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "INT-INST-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "INT-INST-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "INT-INST-C4", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        -- TEST 5: RTI instruction (return from interrupt - 2 cycles)
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 5: RTI Instruction (Return from Interrupt - 2 cycles)"));
        writeline(output, l);
        write(l, string'("Expected: 2 cycle execution with CCR and PC restored"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("11001", "000", "000", "001", "010"); -- RTI
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RTI-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RTI-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RTI-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        -- TEST 6: Memory instruction sequence - test structural hazard (von Neumann)
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 6: Memory Structural Hazard - LDD followed by another instruction"));
        writeline(output, l);
        write(l, string'("Expected: LDD causes stall cycles, then next fetch should detect hazard"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("10100", "001", "010", "011", "000"); -- LDD (memory read)
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "LDD-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "LDD-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "LDD-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        -- Issue next instruction
        instruction <= make_instruction("01001", "000", "100", "010", "011"); -- ADD
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "POST-LDD-ADD", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        -- TEST 7: PUSH-POP sequence (stack operations)
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 7: PUSH followed immediately by POP"));
        writeline(output, l);
        write(l, string'("Expected: Each has stall cycles, back-to-back execution"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("10010", "000", "000", "001", "010"); -- PUSH
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "PUSH-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "PUSH-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "PUSH-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        instruction <= make_instruction("10011", "000", "001", "010", "011"); -- POP
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "POP-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "POP-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "POP-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        -- TEST 8: STD followed by LDD (memory write then read)
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 8: STD (write) followed by LDD (read) - Memory conflict"));
        writeline(output, l);
        write(l, string'("Expected: Each takes cycles, potential structural hazard"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("10101", "010", "011", "100", "101"); -- STD
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "STD-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "STD-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "STD-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        instruction <= make_instruction("10100", "011", "100", "101", "110"); -- LDD
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "LDD-AFTER-STD-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "LDD-AFTER-STD-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "LDD-AFTER-STD-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        -- TEST 9: CALL instruction (multi-cycle with branch)
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 9: CALL Instruction (subroutine call with stack write)"));
        writeline(output, l);
        write(l, string'("Expected: Multi-cycle with stack write and branch"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("10110", "100", "101", "110", "111"); -- CALL
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "CALL-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "CALL-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "CALL-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "CALL-C4", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        -- TEST 10: RET instruction (return with stack read)
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 10: RET Instruction (return from subroutine)"));
        writeline(output, l);
        write(l, string'("Expected: Multi-cycle with stack read and branch"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("10111", "101", "110", "111", "000"); -- RET
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RET-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RET-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RET-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RET-C4", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        -- TEST 11: Rapid fire sequence - multiple single-cycle instructions
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 11: Rapid Fire - Multiple single-cycle instructions"));
        writeline(output, l);
        write(l, string'("Expected: All execute in consecutive cycles, no stalls"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("01001", "000", "001", "010", "011"); -- ADD
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RAPID-ADD", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        instruction <= make_instruction("01010", "000", "010", "011", "100"); -- SUB
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RAPID-SUB", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        instruction <= make_instruction("01011", "000", "011", "100", "101"); -- AND
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RAPID-AND", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        instruction <= make_instruction("00100", "000", "100", "101", "110"); -- NOT
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RAPID-NOT", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        -- TEST 12: HLT instruction (should stall indefinitely)
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 12: HLT Instruction (Halt - continuous stall)"));
        writeline(output, l);
        write(l, string'("Expected: FD_enable and DE_enable disabled, Stall asserted"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("00001", "000", "000", "000", "000"); -- HLT
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "HLT-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "HLT-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "HLT-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt);
        
        -- Summary
        write(l, string'(""));
        writeline(output, l);
        write(l, string'("================================================================================"));
        writeline(output, l);
        write(l, string'("   ALL AGGRESSIVE TESTS COMPLETED"));
        writeline(output, l);
        write(l, string'("   Total Cycles: "));
        write(l, cycle_count);
        writeline(output, l);
        write(l, string'("================================================================================"));
        writeline(output, l);
        write(l, string'(""));
        writeline(output, l);
        write(l, string'("KEY OBSERVATIONS TO CHECK:"));
        writeline(output, l);
        write(l, string'("1. Multi-cycle instructions: SWAP(2), INT(3), RTI(2) complete correctly"));
        writeline(output, l);
        write(l, string'("2. Memory instructions: PUSH, POP, LDD, STD cause stalls"));
        writeline(output, l);
        write(l, string'("3. Interrupts: Can occur during instruction, handled properly"));
        writeline(output, l);
        write(l, string'("4. Structural hazards: FD_enable should disable when memory busy"));
        writeline(output, l);
        write(l, string'("5. HLT: Should keep pipeline stalled indefinitely"));
        writeline(output, l);
        write(l, string'("================================================================================"));
        writeline(output, l);
        
        wait;
    end process;

end architecture testbench;

