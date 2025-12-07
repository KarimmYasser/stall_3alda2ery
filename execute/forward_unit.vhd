

-- Forwarding unit for data hazard resolution
-- Detects register dependencies and generates forwarding control signals

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity forward_unit is
  port (
    rsrc1_execute : in std_logic_vector(2 downto 0);        -- Rs1 address in execute stage
    rsrc2_execute : in std_logic_vector(2 downto 0);        -- Rs2 address in execute stage
    rdest_mem : in std_logic_vector(2 downto 0);            -- Rd address in memory stage
    rdest_wb : in std_logic_vector(2 downto 0);             -- Rd address in writeback stage
    reg_write_signal_mem : in std_logic;                    -- Register write enable (MEM)
    reg_write_signal_wb : in std_logic;                     -- Register write enable (WB)
    swap_signal : in std_logic;                             -- SWAP instruction indicator
    forward1_signal : out std_logic_vector(1 downto 0);     -- Forward control for operand 1
    forward2_signal : out std_logic_vector(1 downto 0)      -- Forward control for operand 2
  );
end entity forward_unit;

architecture behavioral of forward_unit is
begin
  process(rsrc1_execute, rsrc2_execute, rdest_mem, rdest_wb, reg_write_signal_mem, reg_write_signal_wb, swap_signal)
  begin

        forward1_signal <= "00";
        forward2_signal <= "00";

        if (reg_write_signal_mem = '1') then
            if (rdest_mem = rsrc1_execute) then
                forward1_signal <= "01";
            end if;
            if (rdest_mem = rsrc2_execute) then
                forward2_signal <= "01";
            end if;
        elsif (reg_write_signal_wb = '1') then
            if (rdest_wb = rsrc1_execute) then
                forward1_signal <= "10";
            end if;
            if (rdest_wb = rsrc2_execute) then
                forward2_signal <= "10";
            end if;
        elsif (swap_signal = '1') then
            forward1_signal <= "11";
            forward2_signal <= "00";
        end if;
    end process;

end behavioral;