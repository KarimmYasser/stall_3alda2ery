library IEEE;
use IEEE.std_logic_1164.all;
entity Decode is 
    port(
        inturrupt : in std_logic;
        reset: in std_logic;
        clk: in std_logic;
        instruction : in std_logic_vector(26 downto 0);  -- Lower 27 bits from fetch
        opcode : in std_logic_vector(4 downto 0);        -- Opcode from fetch (may be micro-opcode)
        PC : in std_logic_vector(31 downto 0);
        mem_br: in std_logic;
        exe_br: in std_logic;
        
        -- Previous instruction flags from ID/EX register
        WB_flages_in : in std_logic_vector(2 downto 0);
        EXE_flages_in : in std_logic_vector(5 downto 0);
        MEM_flages_in : in std_logic_vector(6 downto 0);
        IO_flages_in : in std_logic_vector(1 downto 0);
        
        -- Pipeline control outputs
        FD_enable : out std_logic;
        Stall :out std_logic;
        DE_enable :out  std_logic;
        EM_enable : out std_logic;
        MW_enable :out std_logic;
        Branch_Decode: out std_logic;
        Micro_inst_out: out std_logic_vector(4 downto 0);
        
        -- Control signals outputs (to ID/EX register in top level)
        WB_flages_out: out std_logic_vector(2 downto 0);
        EXE_flages_out: out std_logic_vector(5 downto 0);
        MEM_flages_out: out std_logic_vector(6 downto 0);
        IO_flages_out: out std_logic_vector(1 downto 0);
        Branch_Exec_out: out std_logic_vector(3 downto 0);
        CCR_enable_out: out std_logic;
        Imm_hazard_out: out std_logic;
        FU_enable_out: out std_logic;
        
        -- Data outputs (to ID/EX register in top level)
        Rrs1_out: out std_logic_vector(31 downto 0);
        Rrs2_out: out std_logic_vector(31 downto 0);
        index_out: out std_logic_vector(1 downto 0);
        pc_out: out std_logic_vector(31 downto 0);
        rs1_addr_out: out std_logic_vector(2 downto 0);
        rs2_addr_out: out std_logic_vector(2 downto 0);
        rd_addr_out: out std_logic_vector(2 downto 0)
    );
end entity Decode;

architecture Behavior of Decode is
    component Control_Unit is
      Port(
        clk: IN Std_logic;
        reset : in std_logic;
        inturrupt : in std_logic;
        op_code : in std_logic_vector(4 downto 0);
        data_ready : in std_logic;
        FD_enable : out std_logic;
        Micro_inst: out std_logic_vector(4 downto 0);
        Stall :out std_logic;
        DE_enable :out  std_logic;
        EM_enable : out std_logic;
        MW_enable :out std_logic;
        Branch_Decode: out std_logic;
        ID_flush :out std_logic;
        WB_flages: out std_logic_vector(2 downto 0);
        EXE_flages: out std_logic_vector(5 downto 0);
        MEM_flages: out std_logic_vector(6 downto 0);
        IO_flages: out std_logic_vector(1 downto 0);
        CSwap : out std_logic;
        Branch_Exec: out std_logic_vector(3 downto 0);
        CCR_enable : out std_logic;
        Imm_hazard : out std_logic;
        ForwardEnable : out std_logic;
        Write_in_Src2: out std_logic
    );
    end component Control_Unit;
    
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

    signal opcode_signal : std_logic_vector(4 downto 0);
    signal rAddr1, rAddr2, wAddr : std_logic_vector (2 DOWNTO 0);
    signal dataIn : std_logic_vector (31 DOWNTO 0);
    signal dataOut1, dataOut2 : std_logic_vector (31 DOWNTO 0);
    signal we : std_logic;
    signal Rs1, Rs2 : std_logic_vector (31 DOWNTO 0);
    signal main_wb_flages : std_logic_vector(2 downto 0);
    signal main_exe_flages : std_logic_vector(5 downto 0);
    signal main_mem_flages : std_logic_vector(6 downto 0);
    signal main_io_flages : std_logic_vector(1 downto 0);
    signal main_branch_exec : std_logic_vector(3 downto 0);
    signal Micro_inst : std_logic_vector(4 downto 0);
    signal CSwap : std_logic;
    signal main_stall : std_logic;
    signal ID_flush_main :std_logic;
    signal main_DE_enable : std_logic;
    signal rd_addr_signal : std_logic_vector(2 downto 0);
    
    -- Signals after flush logic (these go directly to outputs)
    signal wb_flages_flushed : std_logic_vector(2 downto 0);
    signal exe_flages_flushed : std_logic_vector(5 downto 0);
    signal mem_flages_flushed : std_logic_vector(6 downto 0);
    signal io_flages_flushed : std_logic_vector(1 downto 0);
    signal branch_exec_flushed : std_logic_vector(3 downto 0);
    signal CCR_enable_signal : std_logic;
    signal Imm_hazard_signal : std_logic;
    signal ForwardEnable_signal : std_logic;
    signal Write_in_src2_signal : std_logic;
    signal mem_usage_predict_signal : std_logic;
    signal imm_predict_signal : std_logic;

begin
    CU: Control_Unit port map(
        clk => clk,
        reset => reset,
        inturrupt => inturrupt,
        op_code => opcode,  -- Use opcode input directly (may be micro-opcode from fetch)
        data_ready => '1',
        FD_enable => FD_enable,
        Micro_inst => Micro_inst_out,
        Stall => Stall,
        DE_enable => main_DE_enable,
        EM_enable => EM_enable,
        MW_enable => MW_enable,
        Branch_Decode => Branch_Decode,
        ID_flush => ID_flush_main,
        WB_flages => main_wb_flages,
        EXE_flages => main_exe_flages,
        MEM_flages => main_mem_flages,
        IO_flages => main_io_flages,
        CSwap => CSwap,
        Branch_Exec => main_branch_exec,
        CCR_enable => CCR_enable_signal,
        Imm_hazard => Imm_hazard_signal,
        ForwardEnable => ForwardEnable_signal,
        Write_in_Src2 => Write_in_src2_signal
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
    
    --Forwarding Unit--
    rAddr1 <= instruction(5 downto 3) when CSwap='0' else instruction(2 downto 0);
    rAddr2 <= instruction(2 downto 0) when CSwap='0' else instruction(5 downto 3);
    wAddr <= instruction(8 downto 6);
    dataIn <= (others => '0');
    we <= '0';

    -- Swap logic - register data outputs
    Rrs1_out <= dataOut1;
    Rrs2_out <= dataOut2;
    
    -- Address calculation and outputs
    rd_addr_signal <= instruction(8 downto 6) when Write_in_src2_signal='0' else rAddr2;
    rd_addr_out <= rd_addr_signal;
    rs1_addr_out <= instruction(5 downto 3);
    rs2_addr_out <= instruction(2 downto 0);
    index_out <= instruction(26 downto 25);  -- From instruction bits
    pc_out <= PC;
    
    
    -- DE enable output
    DE_enable <= main_DE_enable;
    
    -- Flush logic: zero out control signals on branch or flush
    wb_flages_flushed <= main_wb_flages when (exe_br='0' and mem_br='0' and ID_flush_main='0') else (others => '0');
    exe_flages_flushed <= main_exe_flages when (mem_br='0' and ID_flush_main='0') else (others => '0');
    mem_flages_flushed <= main_mem_flages when (ID_flush_main='0' and mem_br='0' and exe_br='0') else (others => '0');
    io_flages_flushed <= main_io_flages when (ID_flush_main='0' and mem_br='0' and exe_br='0') else (others => '0');
    branch_exec_flushed <= main_branch_exec when (ID_flush_main='0' and mem_br='0' and exe_br='0') else (others => '0');
    
    -- Control signal outputs (after flush logic)
    WB_flages_out <= wb_flages_flushed;
    EXE_flages_out <= exe_flages_flushed;
    MEM_flages_out <= mem_flages_flushed;
    IO_flages_out <= io_flages_flushed;
    Branch_Exec_out <= branch_exec_flushed;
    CCR_enable_out <= CCR_enable_signal;
    Imm_hazard_out <= Imm_hazard_signal;
    FU_enable_out <= ForwardEnable_signal;

end architecture Behavior;