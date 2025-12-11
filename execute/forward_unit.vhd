

-- Forwarding unit for data hazard resolution
-- Detects register dependencies and generates forwarding control signals

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity forward_unit is
  port (
    rs1_addr : in std_logic_vector(2 downto 0);        -- Rs1 address in execute stage
    rs2_addr : in std_logic_vector(2 downto 0);        -- Rs2 address in execute stage
    rdst_mem : in std_logic_vector(2 downto 0);            -- Rd address in memory stage
    rdst_wb : in std_logic_vector(2 downto 0);             -- Rd address in writeback stage
    reg_write_mem : in std_logic;                    -- Register write enable (MEM)
    reg_write_wb : in std_logic;                     -- Register write enable (WB)
    swap_signal : in std_logic;                             -- SWAP instruction indicator
    forward1_signal : out std_logic_vector(1 downto 0);     -- Forward control for operand 1
    forward2_signal : out std_logic_vector(1 downto 0)      -- Forward control for operand 2
  );
end entity forward_unit;

architecture behavioral of forward_unit is
begin
  process(rs1_addr, rs2_addr, rdst_mem, rdst_wb, reg_write_mem, reg_write_wb, swap_signal)
  begin

        forward1_signal <= "00";
        forward2_signal <= "00";

        if (reg_write_mem = '1') then
            if (rdst_mem = rs1_addr) then
                forward1_signal <= "01";
            end if;
            if (rdst_mem = rs2_addr) then
                forward2_signal <= "01";
            end if;
        elsif (reg_write_wb = '1') then
            if (rdst_wb = rs1_addr) then
                forward1_signal <= "10";
            end if;
            if (rdst_wb = rs2_addr) then
                forward2_signal <= "10";
            end if;
        elsif (swap_signal = '1') then
            forward1_signal <= "11";
            forward2_signal <= "00";
        end if;
    end process;

end behavioral;