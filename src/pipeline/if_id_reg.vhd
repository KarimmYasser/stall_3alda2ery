library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity if_id_reg is
    port(
        clk : in std_logic;
        reset : in std_logic;
        write_enable : in std_logic;
        -- Inputs from Fetch stage
        pc_in : in std_logic_vector(31 downto 0);
        instruction_in : in std_logic_vector(31 downto 0);
        -- Outputs to Decode stage
        pc_out : out std_logic_vector(31 downto 0);
        instruction_out : out std_logic_vector(31 downto 0)
    );
end entity if_id_reg;

architecture Behavioral of if_id_reg is
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

begin
    -- PC register (32-bit)
    REG_PC: general_register
        generic map (
            REGISTER_SIZE => 32,
            RESET_VALUE   => 0
        )
        port map (
            clk          => clk,
            reset        => reset,
            write_enable => write_enable,
            data_in      => pc_in,
            data_out     => pc_out
        );

    -- Instruction register (32-bit)
    REG_INSTRUCTION: general_register
        generic map (
            REGISTER_SIZE => 32,
            RESET_VALUE   => 0
        )
        port map (
            clk          => clk,
            reset        => reset,
            write_enable => write_enable,
            data_in      => instruction_in,
            data_out     => instruction_out
        );

end architecture Behavioral;
