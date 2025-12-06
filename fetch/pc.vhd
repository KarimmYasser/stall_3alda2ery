library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity PC is
    port(
        clk       : in std_logic;
        reset     : in std_logic;
        pc_in     : in std_logic_vector(31 downto 0);
        pc_out    : out std_logic_vector(31 downto 0);
        pc_enable : in std_logic
    );
end entity PC;

architecture Behavior of PC is
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
begin
    REG_PC: general_register
        generic map (
            REGISTER_SIZE => 32,
            RESET_VALUE   => 0
        )
        port map (
            clk          => clk,
            reset        => reset,
            write_enable => pc_enable,
            data_in      => pc_in,
            data_out     => pc_out
        );
end architecture Behavior;