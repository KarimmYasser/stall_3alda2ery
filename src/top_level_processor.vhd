library IEEE;
use IEEE.std_logic_1164.all;

entity top_level_processor is
    port(
        clk : in std_logic;
        reset : in std_logic;
        interrupt : in std_logic;
        -- Testbench access for instruction injection (for fetch stage)
        tb_instruction_mem : in std_logic_vector(31 downto 0);
        -- Memory read data (for branches from memory stage)
        tb_mem_read_data : in std_logic_vector(31 downto 0) := (others => '0')
    );
end entity top_level_processor;

architecture structural of top_level_processor is
    
    -- Component: Fetch Stage (split instruction/opcode outputs)
    component Fetch is 
        port(
            clk : in std_logic;
            reset : in std_logic;
            Stall : in std_logic;
            inturrupt : in std_logic; 
            instruction_in : in std_logic_vector(31 downto 0);
            branch_exe : in std_logic;
            branch_decode: in std_logic;
            mem_branch : in std_logic;
            mem_read_data_in : in std_logic_vector(31 downto 0);
            Micro_inst : in std_logic_vector(4 downto 0);
            immediate_in : in std_logic_vector(31 downto 0);
            instruction_out : out std_logic_vector(26 downto 0);  -- Split output
            opcode_out : out std_logic_vector(4 downto 0);        -- Split output
            pc_out : out std_logic_vector(31 downto 0)
        );
    end component Fetch;
    
    -- Component: IF/ID Pipeline Register (now with split instruction/opcode)
    component if_id_register is
    PORT (
        clk             : IN  STD_LOGIC;
        reset           : IN  STD_LOGIC;
        write_enable    : IN  STD_LOGIC;
        instruction_in  : IN  STD_LOGIC_VECTOR(26 DOWNTO 0);
        opcode_in       : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
        pc_in           : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        instruction_out : OUT STD_LOGIC_VECTOR(26 DOWNTO 0);
        opcode_out      : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        pc_out          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
    end component if_id_register;
    
    -- Component: Decode Stage (now with split inputs)
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
            mem_will_be_used_feedback : in std_logic;
            imm_in_use_feedback : in std_logic;
            FD_enable : out std_logic;
            Stall :out std_logic;
            DE_enable :out  std_logic;
            EM_enable : out std_logic;
            MW_enable :out std_logic;
            Branch_Decode: out std_logic;
            Micro_inst_out: out std_logic_vector(4 downto 0);
            mem_usage_predict_out : out std_logic;
            imm_predict_out : out std_logic;
            WB_flages_out: out std_logic_vector(2 downto 0);
            EXE_flages_out: out std_logic_vector(4 downto 0);
            MEM_flages_out: out std_logic_vector(6 downto 0);
            IO_flages_out: out std_logic_vector(1 downto 0);
            Branch_Exec_out: out std_logic_vector(3 downto 0);
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
    
    -- Component: ID/EX Pipeline Register
    component id_ex_reg_with_feedback is
    PORT (
        clk             : IN  STD_LOGIC;
        reset           : IN  STD_LOGIC;
        write_enable    : IN  STD_LOGIC;
        mem_usage_predict_in : IN STD_LOGIC;
        mem_will_be_used_out : OUT STD_LOGIC;
        Imm_predict_in : IN STD_LOGIC;
        Imm_in_use_out : OUT STD_LOGIC;
        WB_flages_in    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        EXE_flages_in   : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
        FU_enable_in    : IN  STD_LOGIC;
        MEM_flages_in   : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
        IO_flages_in    : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        Branch_Exec_in  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        WB_flages_out   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        EXE_flages_out  : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        MEM_flages_out  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        IO_flages_out   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        Branch_Exec_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        FU_enable_out   : OUT STD_LOGIC;
        Rrs1_in         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        Rrs2_in         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        index_in        : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        pc_in           : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        rs1_addr_in     : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        rs2_addr_in     : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        rd_addr_in      : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        Rrs1_out        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        Rrs2_out        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        index_out       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        pc_out          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rs1_addr_out    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        rs2_addr_out    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        rd_addr_out     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
    end component id_ex_reg_with_feedback;
    
    -- ========== Fetch Stage Signals ==========
    signal fetch_instruction_out : std_logic_vector(26 downto 0);  -- Lower 27 bits
    signal fetch_opcode_out : std_logic_vector(4 downto 0);        -- Top 5 bits (may be micro)
    signal fetch_pc_out : std_logic_vector(31 downto 0);
    
    -- Feedback signals from Decode to Fetch
    signal stall_signal : std_logic;
    signal branch_decode_signal : std_logic;
    signal micro_inst_signal : std_logic_vector(4 downto 0);
    signal immediate_to_fetch : std_logic_vector(31 downto 0) := (others => '0');
    
    -- ========== IF/ID Register Signals ==========
    signal ifid_instruction_out : std_logic_vector(26 downto 0);  -- Lower 27 bits
    signal ifid_opcode_out : std_logic_vector(4 downto 0);        -- Top 5 bits
    signal ifid_pc_out : std_logic_vector(31 downto 0);
    signal FD_enable_signal : std_logic;
    
    -- ========== Decode Stage Signals ==========
    -- Signals between Decode and ID/EX register
    signal decode_instruction : std_logic_vector(31 downto 0);
    signal decode_PC : std_logic_vector(31 downto 0);
    signal decode_DE_enable : std_logic;
    signal decode_mem_predict : std_logic;
    signal decode_imm_predict : std_logic;
    signal decode_WB_flages : std_logic_vector(2 downto 0);
    signal decode_EXE_flages : std_logic_vector(4 downto 0);
    signal decode_MEM_flages : std_logic_vector(6 downto 0);
    signal decode_IO_flages : std_logic_vector(1 downto 0);
    signal decode_Branch_Exec : std_logic_vector(3 downto 0);
    signal decode_FU_enable : std_logic;
    signal decode_Rrs1 : std_logic_vector(31 downto 0);
    signal decode_Rrs2 : std_logic_vector(31 downto 0);
    signal decode_index : std_logic_vector(1 downto 0);
    signal decode_pc_out : std_logic_vector(31 downto 0);
    signal decode_rs1_addr : std_logic_vector(2 downto 0);
    signal decode_rs2_addr : std_logic_vector(2 downto 0);
    signal decode_rd_addr : std_logic_vector(2 downto 0);
    
    -- Feedback signals from ID/EX register to Decode
    signal mem_will_be_used_feedback : std_logic;
    signal imm_in_use_feedback : std_logic;
    
    -- Signals from ID/EX register to Execute stage
    signal exe_WB_flages : std_logic_vector(2 downto 0);
    signal exe_EXE_flages : std_logic_vector(4 downto 0);
    signal exe_MEM_flages : std_logic_vector(6 downto 0);
    signal exe_IO_flages : std_logic_vector(1 downto 0);
    signal exe_Branch_Exec : std_logic_vector(3 downto 0);
    signal exe_FU_enable : std_logic;
    signal exe_Rrs1 : std_logic_vector(31 downto 0);
    signal exe_Rrs2 : std_logic_vector(31 downto 0);
    signal exe_index : std_logic_vector(1 downto 0);
    signal exe_pc : std_logic_vector(31 downto 0);
    signal exe_rs1_addr : std_logic_vector(2 downto 0);
    signal exe_rs2_addr : std_logic_vector(2 downto 0);
    signal exe_rd_addr : std_logic_vector(2 downto 0);
    
    -- ========== Placeholder Signals ==========
    signal mem_br_signal : std_logic := '0';
    signal exe_br_signal : std_logic := '0';
    
begin
    
    -- ========== FETCH STAGE ==========
    FETCH_STAGE: Fetch port map(
        clk => clk,
        reset => reset,
        Stall => stall_signal,
        inturrupt => interrupt,
        instruction_in => tb_instruction_mem,
        branch_exe => exe_br_signal,
        branch_decode => branch_decode_signal,
        mem_branch => mem_br_signal,
        mem_read_data_in => tb_mem_read_data,
        Micro_inst => micro_inst_signal,
        immediate_in => immediate_to_fetch,
        instruction_out => fetch_instruction_out,  -- 27 bits
        opcode_out => fetch_opcode_out,            -- 5 bits (possibly micro-opcode)
        pc_out => fetch_pc_out
    );
    
    -- ========== IF/ID PIPELINE REGISTER ==========
    IF_ID_REG: if_id_register port map(
        clk => clk,
        reset => reset,
        write_enable => FD_enable_signal,
        instruction_in => fetch_instruction_out,   -- 27 bits from fetch
        opcode_in => fetch_opcode_out,             -- 5 bits from fetch (may be micro)
        pc_in => fetch_pc_out,
        instruction_out => ifid_instruction_out,
        opcode_out => ifid_opcode_out,
        pc_out => ifid_pc_out
    );
    
    -- ========== DECODE STAGE ==========
    DECODE_STAGE: Decode port map(
        clk => clk,
        reset => reset,
        inturrupt => interrupt,
        instruction => ifid_instruction_out,  -- 27 bits
        opcode => ifid_opcode_out,            -- 5 bits (may be micro-opcode)
        PC => ifid_pc_out,
        mem_br => mem_br_signal,
        exe_br => exe_br_signal,
        mem_will_be_used_feedback => mem_will_be_used_feedback,
        imm_in_use_feedback => imm_in_use_feedback,
        FD_enable => FD_enable_signal,
        Stall => stall_signal,
        DE_enable => decode_DE_enable,
        EM_enable => open,
        MW_enable => open,
        Branch_Decode => branch_decode_signal,
        Micro_inst_out => micro_inst_signal,
        mem_usage_predict_out => decode_mem_predict,
        imm_predict_out => decode_imm_predict,
        WB_flages_out => decode_WB_flages,
        EXE_flages_out => decode_EXE_flages,
        MEM_flages_out => decode_MEM_flages,
        IO_flages_out => decode_IO_flages,
        Branch_Exec_out => decode_Branch_Exec,
        FU_enable_out => decode_FU_enable,
        Rrs1_out => decode_Rrs1,
        Rrs2_out => decode_Rrs2,
        index_out => decode_index,
        pc_out => decode_pc_out,
        rs1_addr_out => decode_rs1_addr,
        rs2_addr_out => decode_rs2_addr,
        rd_addr_out => decode_rd_addr
    );
    
    -- ========== ID/EX PIPELINE REGISTER ==========
    ID_EX_REGISTER: id_ex_reg_with_feedback port map(
        clk => clk,
        reset => reset,
        write_enable => decode_DE_enable,
        mem_usage_predict_in => decode_mem_predict,
        mem_will_be_used_out => mem_will_be_used_feedback,
        Imm_predict_in => decode_imm_predict,
        Imm_in_use_out => imm_in_use_feedback,
        WB_flages_in => decode_WB_flages,
        EXE_flages_in => decode_EXE_flages,
        FU_enable_in => decode_FU_enable,
        MEM_flages_in => decode_MEM_flages,
        IO_flages_in => decode_IO_flages,
        Branch_Exec_in => decode_Branch_Exec,
        WB_flages_out => exe_WB_flages,
        EXE_flages_out => exe_EXE_flages,
        MEM_flages_out => exe_MEM_flages,
        IO_flages_out => exe_IO_flages,
        Branch_Exec_out => exe_Branch_Exec,
        FU_enable_out => exe_FU_enable,
        Rrs1_in => decode_Rrs1,
        Rrs2_in => decode_Rrs2,
        index_in => decode_index,
        pc_in => decode_pc_out,
        rs1_addr_in => decode_rs1_addr,
        rs2_addr_in => decode_rs2_addr,
        rd_addr_in => decode_rd_addr,
        Rrs1_out => exe_Rrs1,
        Rrs2_out => exe_Rrs2,
        index_out => exe_index,
        pc_out => exe_pc,
        rs1_addr_out => exe_rs1_addr,
        rs2_addr_out => exe_rs2_addr,
        rd_addr_out => exe_rd_addr
    );
    
    -- TODO: Add Execute stage component here
    -- EXECUTE_STAGE: Execute port map(...);
    
    -- TODO: Add other pipeline stages (Memory, Writeback)
    
    -- TODO: Extract immediate value from instruction for fetch stage
    -- This should come from decode stage when branch is taken
    -- For now, use placeholder
    immediate_to_fetch <= ifid_instruction_out(15 downto 0) & X"0000"; -- Sign-extend or use immediate field
    
end architecture structural;
