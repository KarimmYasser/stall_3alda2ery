LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- ID/EX Pipeline Register with Memory Usage Feedback
-- Stores all control signals and data from Decode stage using general_register components
-- Implements feedback loop for von Neumann memory structural hazard detection
ENTITY id_ex_reg_with_feedback IS
    PORT (
        clk             : IN  STD_LOGIC;
        reset           : IN  STD_LOGIC;
        write_enable    : IN  STD_LOGIC;
        
        -- Control signals from Decode
        WB_flages_in    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        EXE_flages_in   : IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
        FU_enable_in   : IN  STD_LOGIC;
        MEM_flages_in   : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
        IO_flages_in    : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        Branch_Exec_in  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        
        -- Control signals to Execute
        WB_flages_out   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        EXE_flages_out  : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
        MEM_flages_out  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        IO_flages_out   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        Branch_Exec_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        FU_enable_out  : OUT STD_LOGIC;
        
        -- Data signals from Decode
        Rrs1_in         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        Rrs2_in         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        index_in        : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);  -- Back to 2 bits
        pc_in           : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        rs1_addr_in     : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        rs2_addr_in     : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        rd_addr_in      : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        
        -- Data signals to Execute
        Rrs1_out        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        Rrs2_out        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        index_out       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);  -- Back to 2 bits
        pc_out          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rs1_addr_out    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        rs2_addr_out    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        rd_addr_out     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
END ENTITY id_ex_reg_with_feedback;

ARCHITECTURE Behavioral OF id_ex_reg_with_feedback IS
    -- Component declaration for general_register
    COMPONENT general_register IS
        GENERIC (
            REGISTER_SIZE : INTEGER := 32;
            RESET_VALUE   : INTEGER := 0
        );
        PORT (
            clk          : IN  STD_LOGIC;
            reset        : IN  STD_LOGIC;
            write_enable : IN  STD_LOGIC;
            data_in      : IN  STD_LOGIC_VECTOR(REGISTER_SIZE - 1 DOWNTO 0);
            data_out     : OUT STD_LOGIC_VECTOR(REGISTER_SIZE - 1 DOWNTO 0)
        );
    END COMPONENT;
    
    -- Concatenated input/output signals for vector registers
    SIGNAL control_flags_in  : STD_LOGIC_VECTOR(21 DOWNTO 0); -- 3+6+7+2+4
    SIGNAL control_flags_out : STD_LOGIC_VECTOR(21 DOWNTO 0);
    SIGNAL addresses_in      : STD_LOGIC_VECTOR(10 DOWNTO 0);  -- Changed from 10 DOWNTO 0 (was correct, comment was wrong: 3+2+3+3=11)
    SIGNAL addresses_out     : STD_LOGIC_VECTOR(10 DOWNTO 0);
    signal ForwardEnable_signal_in : std_logic_vector(0 downto 0);
    signal ForwardEnable_signal_out : std_logic_vector(0 downto 0);
    
BEGIN
    -- Pack inputs
    control_flags_in <= WB_flages_in & EXE_flages_in & MEM_flages_in & IO_flages_in & Branch_Exec_in;
    addresses_in     <= rd_addr_in & index_in & rs1_addr_in & rs2_addr_in;
    ForwardEnable_signal_in(0) <= FU_enable_in;
    
    -- Unpack outputs
    WB_flages_out   <= control_flags_out(21 DOWNTO 19);
    EXE_flages_out  <= control_flags_out(18 DOWNTO 13);
    MEM_flages_out  <= control_flags_out(12 DOWNTO 6);
    IO_flages_out   <= control_flags_out(5 DOWNTO 4);
    Branch_Exec_out <= control_flags_out(3 DOWNTO 0);
    FU_enable_out   <= ForwardEnable_signal_out(0);

    
    rd_addr_out  <= addresses_out(10 DOWNTO 8);
    index_out    <= addresses_out(7 DOWNTO 6);
    rs1_addr_out <= addresses_out(5 DOWNTO 3);
    rs2_addr_out <= addresses_out(2 DOWNTO 0);
    
    -- ForwardEnable register (1 bit)
    REG_FU_enable: general_register
        GENERIC MAP (REGISTER_SIZE => 1, RESET_VALUE => 0)
        PORT MAP (
            clk => clk,
            reset => reset,
            write_enable => write_enable,
            data_in => ForwardEnable_signal_in,
            data_out => ForwardEnable_signal_out
        );
    
    -- Control flags register (22 bits)
    REG_CONTROL_FLAGS: general_register
        GENERIC MAP (REGISTER_SIZE => 22, RESET_VALUE => 0)
        PORT MAP (
            clk => clk,
            reset => reset,
            write_enable => write_enable,
            data_in => control_flags_in,
            data_out => control_flags_out
        );
    
    -- Rrs1 register (32 bits)
    REG_RRS1: general_register
        GENERIC MAP (REGISTER_SIZE => 32, RESET_VALUE => 0)
        PORT MAP (
            clk => clk,
            reset => reset,
            write_enable => write_enable,
            data_in => Rrs1_in,
            data_out => Rrs1_out
        );
    
    -- Rrs2 register (32 bits)
    REG_RRS2: general_register
        GENERIC MAP (REGISTER_SIZE => 32, RESET_VALUE => 0)
        PORT MAP (
            clk => clk,
            reset => reset,
            write_enable => write_enable,
            data_in => Rrs2_in,
            data_out => Rrs2_out
        );
    
    -- PC register (32 bits)
    REG_PC: general_register
        GENERIC MAP (REGISTER_SIZE => 32, RESET_VALUE => 0)
        PORT MAP (
            clk => clk,
            reset => reset,
            write_enable => write_enable,
            data_in => pc_in,
            data_out => pc_out
        );
    
    -- Addresses register (11 bits: rd_addr(3) + index(2) + rs1_addr(3) + rs2_addr(3))
    REG_ADDRESSES: general_register
        GENERIC MAP (REGISTER_SIZE => 11, RESET_VALUE => 0)
        PORT MAP (
            clk => clk,
            reset => reset,
            write_enable => write_enable,
            data_in => addresses_in,
            data_out => addresses_out
        );
    
END ARCHITECTURE Behavioral;
