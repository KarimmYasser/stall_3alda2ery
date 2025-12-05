library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity IF_ID_register is
    port(
        -- Control signals
        clk : in std_logic;
        write_enable : in std_logic;  -- From Control Unit FD_enable
        flush : in std_logic;          -- From Control Unit ID_flush
        
        -- Inputs from Fetch stage
        pc_in : in std_logic_vector(31 downto 0);
        instruction_in : in std_logic_vector(26 downto 0);
        opcode_in : in std_logic_vector(4 downto 0);
        
        -- Outputs to Decode stage
        pc_out : out std_logic_vector(31 downto 0);
        instruction_out : out std_logic_vector(26 downto 0);
        opcode_out : out std_logic_vector(4 downto 0)
    );
end entity IF_ID_register;

architecture Behavioral of IF_ID_register is
    -- Component declaration for general_register
    component general_register is
        generic (
            REGISTER_SIZE : integer := 32;
            RESET_VALUE   : integer := 0
        );
        port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            write_enable : in  std_logic;
            data_in      : in  std_logic_vector(REGISTER_SIZE - 1 downto 0);
            data_out     : out std_logic_vector(REGISTER_SIZE - 1 downto 0)
        );
    end component general_register;
    
    -- Internal signals
    signal effective_write_enable : std_logic;
    signal pc_data_in : std_logic_vector(31 downto 0);
    signal instruction_data_in : std_logic_vector(26 downto 0);
    signal opcode_data_in : std_logic_vector(4 downto 0);
    
begin
    -- When flush is asserted, force write with zero data
    -- When flush is not asserted, use normal write_enable
    effective_write_enable <= write_enable or flush;
    
    -- Mux inputs: if flush, write zeros; otherwise, write normal inputs
    pc_data_in <= (others => '0') when flush = '1' else pc_in;
    instruction_data_in <= (others => '0') when flush = '1' else instruction_in;
    opcode_data_in <= (others => '0') when flush = '1' else opcode_in;
    
    -- PC register (32-bit)
    REG_PC: general_register
        generic map (
            REGISTER_SIZE => 32,
            RESET_VALUE   => 0
        )
        port map (
            clk          => clk,
            write_enable => effective_write_enable,
            data_in      => pc_data_in,
            data_out     => pc_out
        );
    
    -- Instruction register (27-bit)
    REG_INSTRUCTION: general_register
        generic map (
            REGISTER_SIZE => 27,
            RESET_VALUE   => 0
        )
        port map (
            clk          => clk,
            write_enable => effective_write_enable,
            data_in      => instruction_data_in,
            data_out     => instruction_out
        );
    
    -- Opcode register (5-bit)
    REG_OPCODE: general_register
        generic map (
            REGISTER_SIZE => 5,
            RESET_VALUE   => 0
        )
        port map (
            clk          => clk,
            write_enable => effective_write_enable,
            data_in      => opcode_data_in,
            data_out     => opcode_out
        );
    
end architecture Behavioral;
