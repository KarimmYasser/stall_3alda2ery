library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- ID/EX Pipeline Register with Memory Usage Feedback
-- Stores all control signals and data from Decode stage using general_register components
-- Implements feedback loop for von Neumann memory structural hazard detection
entity id_ex_reg_with_feedback is
    port (
        clk : in std_logic;
        reset : in std_logic;
        write_enable : in std_logic;

        -- Control signals from Decode
        WB_flages_in : in std_logic_vector(2 downto 0);
        EXE_flages_in : in std_logic_vector(5 downto 0);
        FU_enable_in : in std_logic;
        MEM_flages_in : in std_logic_vector(6 downto 0);
        IO_flages_in : in std_logic_vector(1 downto 0);
        Branch_Exec_in : in std_logic_vector(3 downto 0);

        -- Control signals to Execute
        WB_flages_out : out std_logic_vector(2 downto 0);
        EXE_flages_out : out std_logic_vector(5 downto 0);
        MEM_flages_out : out std_logic_vector(6 downto 0);
        IO_flages_out : out std_logic_vector(1 downto 0);
        Branch_Exec_out : out std_logic_vector(3 downto 0);
        FU_enable_out : out std_logic;

        -- Data signals from Decode
        Rrs1_in : in std_logic_vector(31 downto 0);
        Rrs2_in : in std_logic_vector(31 downto 0);
        index_in : in std_logic_vector(1 downto 0); -- Back to 2 bits
        pc_in : in std_logic_vector(31 downto 0);
        rs1_addr_in : in std_logic_vector(2 downto 0);
        rs2_addr_in : in std_logic_vector(2 downto 0);
        rd_addr_in : in std_logic_vector(2 downto 0);

        -- Data signals to Execute
        Rrs1_out : out std_logic_vector(31 downto 0);
        Rrs2_out : out std_logic_vector(31 downto 0);
        index_out : out std_logic_vector(1 downto 0); -- Back to 2 bits
        pc_out : out std_logic_vector(31 downto 0);
        rs1_addr_out : out std_logic_vector(2 downto 0);
        rs2_addr_out : out std_logic_vector(2 downto 0);
        rd_addr_out : out std_logic_vector(2 downto 0)
    );
end entity id_ex_reg_with_feedback;

architecture Behavioral of id_ex_reg_with_feedback is
    -- Component declaration for general_register
    component general_register is
        generic (
            REGISTER_SIZE : integer := 32;
            RESET_VALUE : integer := 0
        );
        port (
            clk : in std_logic;
            reset : in std_logic;
            write_enable : in std_logic;
            data_in : in std_logic_vector(REGISTER_SIZE - 1 downto 0);
            data_out : out std_logic_vector(REGISTER_SIZE - 1 downto 0)
        );
    end component;

    -- Concatenated input/output signals for vector registers
    signal control_flags_in : std_logic_vector(21 downto 0); -- 3+6+7+2+4
    signal control_flags_out : std_logic_vector(21 downto 0);
    signal addresses_in : std_logic_vector(10 downto 0); -- Changed from 10 DOWNTO 0 (was correct, comment was wrong: 3+2+3+3=11)
    signal addresses_out : std_logic_vector(10 downto 0);
    signal ForwardEnable_signal_in : std_logic_vector(0 downto 0);
    signal ForwardEnable_signal_out : std_logic_vector(0 downto 0);

begin
    -- Pack inputs
    control_flags_in <= WB_flages_in & EXE_flages_in & MEM_flages_in & IO_flages_in & Branch_Exec_in;
    addresses_in <= rd_addr_in & index_in & rs1_addr_in & rs2_addr_in;
    ForwardEnable_signal_in(0) <= FU_enable_in;

    -- Unpack outputs
    WB_flages_out <= control_flags_out(21 downto 19);
    EXE_flages_out <= control_flags_out(18 downto 13);
    MEM_flages_out <= control_flags_out(12 downto 6);
    IO_flages_out <= control_flags_out(5 downto 4);
    Branch_Exec_out <= control_flags_out(3 downto 0);
    FU_enable_out <= ForwardEnable_signal_out(0);

    rd_addr_out <= addresses_out(10 downto 8);
    index_out <= addresses_out(7 downto 6);
    rs1_addr_out <= addresses_out(5 downto 3);
    rs2_addr_out <= addresses_out(2 downto 0);

    -- ForwardEnable register (1 bit)
    REG_FU_enable : general_register
    generic map(REGISTER_SIZE => 1, RESET_VALUE => 0)
    port map(
        clk => clk,
        reset => reset,
        write_enable => write_enable,
        data_in => ForwardEnable_signal_in,
        data_out => ForwardEnable_signal_out
    );

    -- Control flags register (22 bits)
    REG_CONTROL_FLAGS : general_register
    generic map(REGISTER_SIZE => 22, RESET_VALUE => 0)
    port map(
        clk => clk,
        reset => reset,
        write_enable => write_enable,
        data_in => control_flags_in,
        data_out => control_flags_out
    );

    -- Rrs1 register (32 bits)
    REG_RRS1 : general_register
    generic map(REGISTER_SIZE => 32, RESET_VALUE => 0)
    port map(
        clk => clk,
        reset => reset,
        write_enable => write_enable,
        data_in => Rrs1_in,
        data_out => Rrs1_out
    );

    -- Rrs2 register (32 bits)
    REG_RRS2 : general_register
    generic map(REGISTER_SIZE => 32, RESET_VALUE => 0)
    port map(
        clk => clk,
        reset => reset,
        write_enable => write_enable,
        data_in => Rrs2_in,
        data_out => Rrs2_out
    );

    -- PC register (32 bits)
    REG_PC : general_register
    generic map(REGISTER_SIZE => 32, RESET_VALUE => 0)
    port map(
        clk => clk,
        reset => reset,
        write_enable => write_enable,
        data_in => pc_in,
        data_out => pc_out
    );

    -- Addresses register (11 bits: rd_addr(3) + index(2) + rs1_addr(3) + rs2_addr(3))
    REG_ADDRESSES : general_register
    generic map(REGISTER_SIZE => 11, RESET_VALUE => 0)
    port map(
        clk => clk,
        reset => reset,
        write_enable => write_enable,
        data_in => addresses_in,
        data_out => addresses_out
    );

end architecture Behavioral;