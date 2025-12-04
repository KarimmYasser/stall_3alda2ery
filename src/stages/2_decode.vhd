library IEEE;
use IEEE.std_logic_1164.all;
entity Decode is 
    port(
        inturrupt : in std_logic;
        reset: in std_logic;
        clk: in std_logic;
        instruction : in std_logic_vector(31 downto 0); --opcode[31-27],
        PC : in std_logic_vector(31 downto 0);
        mem_br: in std_logic;
        exe_br: in std_logic;
        FD_enable : out std_logic;
        Stall :out std_logic;
        DE_enable :out  std_logic; --############
        EM_enable : out std_logic;
        MW_enable :out std_logic;
        Branch_Decode: out std_logic;
        -- Pipeline register outputs (to Execute stage)
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
end entity Decode;

architecture Behavior of Decode is
    component Control_Unit is
      Port(
        clk: IN Std_logic;
        inturrupt : in std_logic;
        op_code : in std_logic_vector(4 downto 0);
        data_ready : in std_logic;
        mem_will_be_used : in std_logic;
        FD_enable : out std_logic;
        Micro_inst: out std_logic_vector(4 downto 0);
        Stall :out std_logic;
        DE_enable :out  std_logic;
        EM_enable : out std_logic;
        MW_enable :out std_logic;
        Branch_Decode: out std_logic;
        ID_flush :out std_logic;
        mem_usage_predict : out std_logic;
        WB_flages: out std_logic_vector(2 downto 0);
        EXE_flages: out std_logic_vector(4 downto 0);
        MEM_flages: out std_logic_vector(6 downto 0);
        IO_flages: out std_logic_vector(1 downto 0);
        CSwap : out std_logic;
        Branch_Exec: out std_logic_vector(3 downto 0);
        CCR_enable : out std_logic;
        Imm_predict : out std_logic;
        Imm_in_use: in std_logic
    );
    end component Control_Unit;
    
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
        MEM_flages_in   : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
        IO_flages_in    : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        Branch_Exec_in  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        WB_flages_out   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        EXE_flages_out  : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        MEM_flages_out  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        IO_flages_out   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        Branch_Exec_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        Rrs1_in         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        Rrs2_in         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        index_in        : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        pc_in           : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        rs1_addr_in     : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        rs2_addr_in     : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        rd_addr_in      : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        Rrs1_out        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        Rrs2_out        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        index_out       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        pc_out          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rs1_addr_out    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        rs2_addr_out    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        rd_addr_out     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
    end component id_ex_reg_with_feedback;
    
    component general_register_file is
   PORT (
        clk           : IN  STD_LOGIC;
        reset         : IN  STD_LOGIC;    -- Synchronous reset (active high)
        write_enable  : IN  STD_LOGIC;    -- Write enable (active high)
        
        -- Read ports (3-bit addresses for R0-R7)
        read_address1 : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);  -- Source register 1
        read_address2 : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);  -- Source register 2
        read_data1    : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0);
        read_data2    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        
        -- Write port
        write_address : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);  -- Destination register
        write_data    : IN  STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
    end component general_register_file;

    signal opcode : std_logic_vector(4 downto 0);
    signal rAddr1, rAddr2, wAddr : std_logic_vector (2 DOWNTO 0);
    signal dataIn : std_logic_vector (31 DOWNTO 0);
    signal dataOut1, dataOut2 : std_logic_vector (31 DOWNTO 0);
    signal we : std_logic;
    signal Rs1, Rs2 : std_logic_vector (31 DOWNTO 0);
    signal main_wb_flages : std_logic_vector(2 downto 0);
    signal main_exe_flages : std_logic_vector(4 downto 0);
    signal main_mem_flages : std_logic_vector(6 downto 0);
    signal main_io_flages : std_logic_vector(1 downto 0);
    signal main_branch_exec : std_logic_vector(3 downto 0);
    signal Micro_inst : std_logic_vector(4 downto 0);
    signal CSwap : std_logic;
    signal main_stall : std_logic;
    signal ID_flush_main :std_logic;
    signal main_DE_enable : std_logic;
    
    -- Feedback loop signals
    signal mem_will_be_used_feedback : std_logic;
    signal mem_usage_predict_signal : std_logic;
    signal imm_in_use_feedback : std_logic;
    signal imm_predict_signal : std_logic;
    
    -- Signals before pipeline register (after flush logic)
    signal wb_flages_to_pipe : std_logic_vector(2 downto 0);
    signal exe_flages_to_pipe : std_logic_vector(4 downto 0);
    signal mem_flages_to_pipe : std_logic_vector(6 downto 0);
    signal io_flages_to_pipe : std_logic_vector(1 downto 0);
    signal branch_exec_to_pipe : std_logic_vector(3 downto 0);
    signal rrs1_to_pipe : std_logic_vector(31 downto 0);
    signal rrs2_to_pipe : std_logic_vector(31 downto 0);
    signal pipe_write_enable : std_logic;

begin
    CU: Control_Unit port map(
        clk => clk,
        inturrupt => inturrupt,
        op_code => opcode,
        data_ready => '1',
        mem_will_be_used => mem_will_be_used_feedback,
        FD_enable => FD_enable,
        Micro_inst => Micro_inst,
        Stall => main_stall,
        DE_enable => main_DE_enable,
        EM_enable => EM_enable,
        MW_enable => MW_enable,
        Branch_Decode => Branch_Decode,
        ID_flush => ID_flush_main,
        mem_usage_predict => mem_usage_predict_signal,
        WB_flages => main_wb_flages,
        EXE_flages => main_exe_flages,
        MEM_flages => main_mem_flages,
        IO_flages => main_io_flages,
        CSwap => CSwap,
        Branch_Exec => main_branch_exec,
        CCR_enable => open,
        Imm_predict => imm_predict_signal,
        Imm_in_use => imm_in_use_feedback
    );

    GRF: general_register_file port map(
        clk => clk,
        reset => reset,
        write_enable => we,
        read_address1 => rAddr1,
        read_address2 => rAddr2,
        read_data1 => dataOut1,
        read_data2 => dataOut2,
        write_address => wAddr,
        write_data => dataIn
    );
    
    -- ID/EX Pipeline Register with Memory Usage Feedback
    ID_EX_REG: id_ex_reg_with_feedback port map(
        clk => clk,
        reset => reset,
        write_enable => pipe_write_enable,
        mem_usage_predict_in => mem_usage_predict_signal,
        mem_will_be_used_out => mem_will_be_used_feedback,
        Imm_predict_in => imm_predict_signal,
        Imm_in_use_out => imm_in_use_feedback,
        WB_flages_in => wb_flages_to_pipe,
        EXE_flages_in => exe_flages_to_pipe,
        MEM_flages_in => mem_flages_to_pipe,
        IO_flages_in => io_flages_to_pipe,
        Branch_Exec_in => branch_exec_to_pipe,
        WB_flages_out => WB_flages_pipe_out,
        EXE_flages_out => EXE_flages_pipe_out,
        MEM_flages_out => MEM_flages_pipe_out,
        IO_flages_out => IO_flages_pipe_out,
        Branch_Exec_out => Branch_Exec_pipe_out,
        Rrs1_in => rrs1_to_pipe,
        Rrs2_in => rrs2_to_pipe,
        index_in => instruction(26 downto 24),
        pc_in => PC,
        rs1_addr_in => instruction(5 downto 3),
        rs2_addr_in => instruction(2 downto 0),
        rd_addr_in => instruction(8 downto 6),
        Rrs1_out => Rrs1_pipe_out,
        Rrs2_out => Rrs2_pipe_out,
        index_out => index_pipe_out,
        pc_out => pc_pipe_out,
        rs1_addr_out => rs1_addr_pipe_out,
        rs2_addr_out => rs2_addr_pipe_out,
        rd_addr_out => rd_addr_pipe_out
    );
    --Forwarding Unit--
    rAddr1 <= instruction(5 downto 3); --rs1
    rAddr2 <= instruction(2 downto 0); --rs2
    wAddr <= instruction(8 downto 6);  --rd
    --write back data--
    dataIn <= (others => '0'); -- placeholder
    we <= '0'; -- palceholder

    -- swap logic (before pipeline register)
    rrs1_to_pipe <= dataOut1 when CSwap='0' else dataOut2;
    rrs2_to_pipe <= dataOut2 when CSwap='0' else dataOut1;
    
    -- opcode selection: always use instruction opcode, control unit handles microcode internally
    opcode <= instruction(31 downto 27);
    
    -- Stall signal
    Stall <= main_stall;
    
    -- Flush logic: zero out control signals on branch or flush
    wb_flages_to_pipe <= main_wb_flages when exe_br='0' and mem_br='0' and ID_flush_main='0' else (others => '0');
    exe_flages_to_pipe <= main_exe_flages when mem_br='0' and ID_flush_main='0' else (others => '0');
    mem_flages_to_pipe <= main_mem_flages when ID_flush_main='0' and mem_br='0' and exe_br='0' else (others => '0');
    io_flages_to_pipe <= main_io_flages when ID_flush_main='0' and mem_br='0' and exe_br='0' else (others => '0');
    branch_exec_to_pipe <= main_branch_exec when ID_flush_main='0' and mem_br='0' and exe_br='0' else (others => '0');
    
    -- Pipeline register write enable (always enabled, uses flush logic above)
    pipe_write_enable <= main_DE_enable;
    DE_enable <= main_DE_enable;
    
    -- Output microcode instruction for fetch stage
    Micro_inst_out <= Micro_inst;

end architecture Behavior;