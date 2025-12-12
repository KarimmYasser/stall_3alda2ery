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
            instruction : in std_logic_vector(26 downto 0);
            opcode : in std_logic_vector(4 downto 0);
            PC : in std_logic_vector(31 downto 0);
            mem_br: in std_logic;
            exe_br: in std_logic;
            WB_flages_in : in std_logic_vector(2 downto 0);
            EXE_flages_in : in std_logic_vector(5 downto 0);
            MEM_flages_in : in std_logic_vector(6 downto 0);
            IO_flages_in : in std_logic_vector(1 downto 0);
            FD_enable : out std_logic;
            Stall :out std_logic;
            DE_enable :out  std_logic;
            EM_enable : out std_logic;
            MW_enable :out std_logic;
            Branch_Decode: out std_logic;
            Micro_inst_out: out std_logic_vector(4 downto 0);
            WB_flages_out: out std_logic_vector(2 downto 0);
            EXE_flages_out: out std_logic_vector(5 downto 0);
            MEM_flages_out: out std_logic_vector(6 downto 0);
            IO_flages_out: out std_logic_vector(1 downto 0);
            Branch_Exec_out: out std_logic_vector(3 downto 0);
            CSwap_out: out std_logic; -- Added
            CCR_enable_out: out std_logic;
            Imm_hazard_out: out std_logic;
            FU_enable_out: out std_logic;
            Rrs1_out: out std_logic_vector(31 downto 0);
            Rrs2_out: out std_logic_vector(31 downto 0);
            index_out: out std_logic_vector(1 downto 0);
            pc_out: out std_logic_vector(31 downto 0);
            rs1_addr_out: out std_logic_vector(2 downto 0);
            rs2_addr_out: out std_logic_vector(2 downto 0);
            rd_addr_out: out std_logic_vector(2 downto 0)
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
    signal WB_flages_in : std_logic_vector(2 downto 0) := (others => '0');
    signal EXE_flages_in : std_logic_vector(5 downto 0) := (others => '0');
    signal MEM_flages_in : std_logic_vector(6 downto 0) := (others => '0');
    signal IO_flages_in : std_logic_vector(1 downto 0) := (others => '0');
    
    -- Output signals
    signal FD_enable : std_logic;
    signal Stall : std_logic;
    signal DE_enable : std_logic;
    signal EM_enable : std_logic;
    signal MW_enable : std_logic;
    signal Branch_Decode : std_logic;
    signal WB_flages : std_logic_vector(2 downto 0);
    signal EXE_flages : std_logic_vector(5 downto 0);
    signal MEM_flages : std_logic_vector(6 downto 0);
    signal IO_flages : std_logic_vector(1 downto 0);
    signal Branch_Exec : std_logic_vector(3 downto 0);
    signal Rrs1 : std_logic_vector(31 downto 0);
    signal Rrs2 : std_logic_vector(31 downto 0);
    signal index : std_logic_vector(1 downto 0);  -- 2 bits
    signal pc_out : std_logic_vector(31 downto 0);
    signal rs1_addr : std_logic_vector(2 downto 0);
    signal rs2_addr : std_logic_vector(2 downto 0);
    signal rd_addr : std_logic_vector(2 downto 0);
    signal Micro_inst : std_logic_vector(4 downto 0);
    signal mem_usage_predict : std_logic;
    signal imm_predict : std_logic;
    signal CCR_enable : std_logic;
    signal Imm_hazard : std_logic;
    signal FU_enable : std_logic;
    
    -- Clock period
    constant clk_period : time := 10 ns;
    
    -- Helper function to create instruction
    function make_instruction(
        opcode : std_logic_vector(4 downto 0);
        index  : std_logic_vector(1 downto 0);  -- Changed to 2 bits
        rd     : std_logic_vector(2 downto 0);
        rs1    : std_logic_vector(2 downto 0);
        rs2    : std_logic_vector(2 downto 0)
    ) return std_logic_vector is
        variable inst : std_logic_vector(31 downto 0);
    begin
        inst := (others => '0');
        inst(31 downto 27) := opcode;
        inst(26 downto 25) := index;  -- 2 bits [26:25]
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
        signal inturrupt : in std_logic;
        signal Micro_inst : in std_logic_vector(4 downto 0);
        signal WB_flages : in std_logic_vector(2 downto 0);
        signal Branch_Exec : in std_logic_vector(3 downto 0)
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
        write(l, string'(" | Micro: "));
        write(l, Micro_inst);
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
        write(l, string'(" INT="));
        write(l, inturrupt);
        writeline(output, l);
        write(l, string'("  WB: RegW="));
        write(l, WB_flages(2));
        write(l, string'(" MemToReg="));
        write(l, WB_flages(1));
        write(l, string'(" PC+="));
        write(l, WB_flages(0));
        writeline(output, l);
        write(l, string'("  MEM: WDsel="));
        write(l, MEM_flages(6));
        write(l, string'(" MemR="));
        write(l, MEM_flages(5));
        write(l, string'(" MemW="));
        write(l, MEM_flages(4));
        write(l, string'(" StkR="));
        write(l, MEM_flages(3));
        write(l, string'(" StkW="));
        write(l, MEM_flages(2));
        write(l, string'(" CCRSt="));
        write(l, MEM_flages(1));
        write(l, string'(" CCRLd="));
        write(l, MEM_flages(0));
        writeline(output, l);
        write(l, string'("  Branch: En="));
        write(l, Branch_Exec(0));
        write(l, string'(" Imm="));
        write(l, Branch_Exec(1));
        write(l, string'(" Sel="));
        write(l, Branch_Exec(3 downto 2));
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
        instruction => instruction(26 downto 0),
        opcode => instruction(31 downto 27),
        PC => PC,
        mem_br => mem_br,
        exe_br => exe_br,
        WB_flages_in => WB_flages_in,
        EXE_flages_in => EXE_flages_in,
        MEM_flages_in => MEM_flages_in,
        IO_flages_in => IO_flages_in,
        FD_enable => FD_enable,
        Stall => Stall,
        DE_enable => DE_enable,
        EM_enable => EM_enable,
        MW_enable => MW_enable,
        Branch_Decode => Branch_Decode,
        Micro_inst_out => Micro_inst,
        WB_flages_out => WB_flages,
        EXE_flages_out => EXE_flages,
        MEM_flages_out => MEM_flages,
        IO_flages_out => IO_flages,
        Branch_Exec_out => Branch_Exec,
        CSwap_out => open, -- Connected to open for now as it wasn't tracked in this TB
        CCR_enable_out => CCR_enable,
        Imm_hazard_out => Imm_hazard,
        FU_enable_out => FU_enable,
        Rrs1_out => Rrs1,
        Rrs2_out => Rrs2,
        index_out => index,
        pc_out => pc_out,
        rs1_addr_out => rs1_addr,
        rs2_addr_out => rs2_addr,
        rd_addr_out => rd_addr
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
        
        -- TEST 1: Multi-cycle SWAP instruction
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 1: SWAP Instruction (Multi-Cycle - 2 cycles)"));
        writeline(output, l);
        write(l, string'("Expected: Stall asserted, CSwap toggles, no forwarding during SWAP"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("00111", "00", "001", "010", "011"); -- SWAP with 2-bit index
        cycle_count := 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "SWAP-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "SWAP-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "SWAP-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        -- TEST 2: ADD after SWAP
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 2: ADD after SWAP (verify forwarding re-enabled)"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("01001", "00", "100", "001", "010"); -- ADD
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "ADD", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        -- TEST 3: Interrupt during SWAP
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 3: Interrupt during SWAP execution"));
        writeline(output, l);
        write(l, string'("Expected: SWAP completes, then 3-cycle interrupt sequence"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("00111", "00", "011", "100", "101"); -- SWAP
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "SWAP-INT-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        inturrupt <= '1';
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "SWAP-INT-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        inturrupt <= '0';
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "INT-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "INT-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "INT-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "POST-INT", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        -- TEST 4: INT instruction
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 4: INT Instruction (Software Interrupt - 3 cycles)"));
        writeline(output, l);
        write(l, string'("Expected: PC+1 saved, CCR stored, vector read, branch taken"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("11000", "00", "000", "001", "010"); -- INT
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "INT-INST-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "INT-INST-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "INT-INST-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "INT-INST-C4", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        -- TEST 5: RTI instruction
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 5: RTI Instruction (Return from Interrupt - 2 cycles)"));
        writeline(output, l);
        write(l, string'("Expected: CCR restored, PC popped from stack, branch taken"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("11001", "00", "000", "001", "010"); -- RTI
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RTI-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RTI-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RTI-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        -- TEST 6: Memory instruction sequence - test structural hazard (von Neumann)
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 6: Memory Structural Hazard - LDD followed by another instruction"));
        writeline(output, l);
        write(l, string'("Expected: LDD causes stall cycles, then next fetch should detect hazard"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("10100", "01", "010", "011", "000"); -- LDD (memory read)
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "LDD-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "LDD-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "LDD-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        -- Issue next instruction
        instruction <= make_instruction("01001", "00", "100", "010", "011"); -- ADD
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "POST-LDD-ADD", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        -- TEST 7: PUSH-POP sequence (stack operations)
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 7: PUSH followed immediately by POP"));
        writeline(output, l);
        write(l, string'("Expected: Each has stall cycles, back-to-back execution"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("10010", "00", "000", "001", "010"); -- PUSH
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "PUSH-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "PUSH-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "PUSH-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        instruction <= make_instruction("10011", "00", "001", "010", "011"); -- POP
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "POP-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "POP-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "POP-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        -- TEST 8: STD followed by LDD (memory write then read)
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 8: STD (write) followed by LDD (read) - Memory conflict"));
        writeline(output, l);
        write(l, string'("Expected: Each takes cycles, potential structural hazard"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("10101", "10", "011", "100", "101"); -- STD
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "STD-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "STD-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "STD-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        instruction <= make_instruction("10100", "11", "100", "101", "110"); -- LDD
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "LDD-AFTER-STD-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "LDD-AFTER-STD-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "LDD-AFTER-STD-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        -- TEST 9: CALL instruction (multi-cycle with branch)
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 9: CALL Instruction (subroutine call with stack write)"));
        writeline(output, l);
        write(l, string'("Expected: Multi-cycle with stack write and branch"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("10110", "00", "101", "110", "111"); -- CALL (changed from "100")
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "CALL-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "CALL-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "CALL-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "CALL-C4", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        -- TEST 10: RET instruction (return with stack read)
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 10: RET Instruction (return from subroutine)"));
        writeline(output, l);
        write(l, string'("Expected: Multi-cycle with stack read and branch"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("10111", "01", "110", "111", "000"); -- RET (changed from "101")
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RET-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RET-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RET-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        -- TEST 11: Rapid fire sequence - multiple single-cycle instructions
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 11: Rapid Fire - Multiple single-cycle instructions"));
        writeline(output, l);
        write(l, string'("Expected: All execute in consecutive cycles, no stalls"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("01001", "00", "001", "010", "011"); -- ADD
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RAPID-ADD", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        instruction <= make_instruction("01010", "00", "010", "011", "100"); -- SUB
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RAPID-SUB", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        instruction <= make_instruction("01011", "00", "011", "100", "101"); -- AND
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RAPID-AND", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        instruction <= make_instruction("00100", "00", "100", "101", "110"); -- NOT
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "RAPID-NOT", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        -- TEST 12: HLT instruction (should stall indefinitely)
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        write(l, string'("TEST 12: HLT Instruction (Halt - continuous stall)"));
        writeline(output, l);
        write(l, string'("Expected: FD_enable and DE_enable disabled, Stall asserted"));
        writeline(output, l);
        write(l, string'("--------------------------------------------------------------------------------"));
        writeline(output, l);
        
        instruction <= make_instruction("00001", "00", "000", "000", "000"); -- HLT
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "HLT-C1", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "HLT-C2", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
        cycle_count := cycle_count + 1;
        wait until rising_edge(clk);
        log_cycle_state(cycle_count, "HLT-C3", instruction, FD_enable, Stall, DE_enable, EM_enable, MW_enable, MEM_flages, inturrupt, Micro_inst, WB_flages, Branch_Exec);
        
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
        write(l, string'("1. SWAP: ForwardEnable disabled during execution"));
        writeline(output, l);
        write(l, string'("2. INT/RTI: Proper CCR and PC handling with branch signals"));
        writeline(output, l);
        write(l, string'("3. Memory ops: Correct mem_usage_predict and structural hazard detection"));
        writeline(output, l);
        write(l, string'("4. Interrupts: Asynchronous interrupt handling preserved"));
        writeline(output, l);
        write(l, string'("5. Branch_Exec: Proper branch signals for control flow changes"));
        writeline(output, l);
        write(l, string'("================================================================================"));
        writeline(output, l);
        
        wait;
    end process;

end architecture testbench;

