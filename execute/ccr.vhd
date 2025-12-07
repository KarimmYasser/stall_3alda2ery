-- Condition Code Register (CCR)
-- Flags: [2]=Carry, [1]=Negative, [0]=Zero

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ccr is
  port (
    rst : in std_logic;                              -- Reset signal
    clk : in std_logic;                              -- Clock signal
    enable : in std_logic;                           -- Enable signal
    set_carry : in std_logic;                        -- Set carry flag to '1'
    ccr_load : in std_logic;                       -- Return from interrupt signal
    ccr_from_stack : in std_logic_vector(2 downto 0);  -- Flags to restore on RTI
    alu_flags_enable : in std_logic_vector(2 downto 0); -- ALU flag update enables
    alu_flags : in std_logic_vector(2 downto 0);        -- ALU flag values
    flags_out : out std_logic_vector(2 downto 0)     -- Current flag values
  );
end entity ccr;

architecture behavioral of ccr is
  signal flags : std_logic_vector(2 downto 0); -- Internal flag register
begin
  process(clk, rst)
  begin
    if rst = '1' then
      flags <= (others => '0');
    elsif rising_edge(clk) then
      if enable = '1' then
        if (ccr_load = '1') then
          flags <= ccr_from_stack;
        end if;
        if (alu_flags_enable(0) = '1') then
          flags(0) <= alu_flags(0);
        end if;
        if (alu_flags_enable(1) = '1') then
          flags(1) <= alu_flags(1);
        end if;
        if (alu_flags_enable(2) = '1') then
          flags(2) <= alu_flags(2);
        end if;
        if (set_carry = '1') then
          flags(2) <= '1';
        end if;
      end if;
    end if;
  end process;
  
  flags_out <= flags;
end architecture behavioral;