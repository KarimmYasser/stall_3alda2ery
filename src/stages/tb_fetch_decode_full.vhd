library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_fetch_decode_full is
end entity tb_fetch_decode_full;

architecture testbench of tb_fetch_decode_full is
    -- Component declarations
    component Fetch is 
        port(
            Stall : in std_logic;
            inturrupt : in std_logic;
            instruction_in : in std_logic_vector(31 downto 0);
            Micro_inst : in std_logic_vector(4 downto 0);
            instruction_out : out std_logic_vector(31 downto 0)
        );
    end component Fetch;
    
    component if_id_reg is
        port(
            clk : in std_logic;
            reset : in std_logic;
            write_enable : in std_logic;
            pc_in : in std_logic_vector(31 downto 0);
            instruction_in : in std_logic_vector(31 downto 0);
            pc_out : out std_logic_vector(31 downto 0);
            instruction_out : out std_logic_vector(31 downto 0)
        );
    end component if_id_reg;
    
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
            rd_addr_pipe_out: out std_logic_vector(2 downto 0);
            Micro_inst_out: out std_logic_vector(4 downto 0)
        );
    end component Decode;

    -- Test signals
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal inturrupt : std_logic := '0';
    
    -- Fetch stage signals
    signal instruction_from_memory : std_logic_vector(31 downto 0) := (others => '0');
    signal instruction_after_fetch : std_logic_vector(31 downto 0);
    
    -- IF/ID register signals
    signal pc_fetch : std_logic_vector(31 downto 0) := X"00000100";
    signal pc_decode : std_logic_vector(31 downto 0);
    signal instruction_decode : std_logic_vector(31 downto 0);
    
    -- Decode stage outputs
    signal FD_enable : std_logic;
    signal Stall : std_logic;
    signal DE_enable : std_logic;
    signal EM_enable : std_logic;
    signal MW_enable : std_logic;
    signal Branch_Decode : std_logic;
    signal Micro_inst : std_logic_vector(4 downto 0);
    
    -- Pipeline outputs (not used in this test but required)
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
    
    signal mem_br : std_logic := '0';
    signal exe_br : std_logic := '0';
    
    -- Clock period
    constant clk_period : time := 10 ns;
    
    -- Helper function to create instruction
    function make_instruction(
        opcode : std_logic_vector(4 downto 0);
        p_index  : std_logic_vector(2 downto 0);
        rd     : std_logic_vector(2 downto 0);
        rs1    : std_logic_vector(2 downto 0);
        rs2    : std_logic_vector(2 downto 0)
    ) return std_logic_vector is
        variable inst : std_logic_vector(31 downto 0);
    begin
        inst := (others => '0');
        inst(31 downto 27) := opcode;
        inst(26 downto 24) := p_index;
        inst(8 downto 6)   := rd;
        inst(5 downto 3)   := rs1;
        inst(2 downto 0)   := rs2;
        return inst;
    end function;

begin
    -- Instantiate Fetch stage
    FETCH_STAGE: Fetch port map(
        Stall => Stall,
        inturrupt => inturrupt,
        instruction_in => instruction_from_memory,
        Micro_inst => Micro_inst,
        instruction_out => instruction_after_fetch
    );
    
    -- Instantiate IF/ID pipeline register
    IF_ID_REG_INST: if_id_reg port map(
        clk => clk,
        reset => reset,
        write_enable => FD_enable,
        pc_in => pc_fetch,
        instruction_in => instruction_after_fetch,
        pc_out => pc_decode,
        instruction_out => instruction_decode
    );
    
    -- Instantiate Decode stage
    DECODE_STAGE: Decode port map(
        clk => clk,
        reset => reset,
        inturrupt => inturrupt,
        instruction => instruction_decode,
        PC => pc_decode,
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
    
    -- PC increment (simple for testing)
    pc_increment: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                pc_fetch <= X"00000100";
            elsif FD_enable = '1' and Stall = '0' then
                pc_fetch <= std_logic_vector(unsigned(pc_fetch) + 4);
            end if;
        end if;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        report "========================================";
        report "  FETCH-DECODE INTEGRATION TEST";
        report "  Testing Immediate Prediction Feedback";
        report "========================================";
        
        -- Reset
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait for clk_period;
        
        -- TEST 1: LDM instruction (needs immediate)
        report "TEST 1: LDM instruction (should trigger Imm_predict)";
        instruction_from_memory <= make_instruction("00101", "000", "001", "010", "011"); -- LDM
        wait for clk_period * 3;
        
        -- TEST 2: Normal ADD instruction
        report "TEST 2: ADD instruction (no immediate)";
        instruction_from_memory <= make_instruction("01001", "000", "010", "011", "100"); -- ADD
        wait for clk_period * 2;
        
        -- TEST 3: IADD instruction (needs immediate)
        report "TEST 3: IADD instruction (should trigger Imm_predict)";
        instruction_from_memory <= make_instruction("01000", "000", "011", "100", "101"); -- IADD
        wait for clk_period * 3;
        
        -- TEST 4: LDD instruction (needs immediate)
        report "TEST 4: LDD instruction (should trigger Imm_predict)";
        instruction_from_memory <= make_instruction("10100", "001", "100", "101", "110"); -- LDD
        wait for clk_period * 3;
        
        -- TEST 5: JZ instruction (needs immediate)
        report "TEST 5: JZ instruction (should trigger Imm_predict)";
        instruction_from_memory <= make_instruction("01100", "000", "101", "110", "111"); -- JZ
        wait for clk_period * 3;
        
        -- TEST 6: SWAP instruction (multi-cycle, no immediate)
        report "TEST 6: SWAP instruction (multi-cycle)";
        instruction_from_memory <= make_instruction("00111", "000", "001", "010", "011"); -- SWAP
        wait for clk_period * 4;
        
        -- TEST 7: STD instruction (needs immediate)
        report "TEST 7: STD instruction (should trigger Imm_predict)";
        instruction_from_memory <= make_instruction("10101", "010", "010", "011", "100"); -- STD
        wait for clk_period * 3;
        
        -- TEST 8: CALL instruction (needs immediate)
        report "TEST 8: CALL instruction (should trigger Imm_predict)";
        instruction_from_memory <= make_instruction("10110", "011", "011", "100", "101"); -- CALL
        wait for clk_period * 3;
        
        report "========================================";
        report "  ALL TESTS COMPLETED";
        report "  Check waveforms for:";
        report "  - Imm_predict assertion";
        report "  - Imm_in_use feedback";
        report "  - M_IMMEDIATE state activation";
        report "========================================";
        
        wait;
    end process;

end architecture testbench;
