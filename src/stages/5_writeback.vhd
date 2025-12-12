library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity writeback is
    port(
        mem_read_data  : in  std_logic_vector(31 downto 0);
        alu_result     : in  std_logic_vector(31 downto 0);
        wb_select      : in  std_logic;
        wb_data        : out std_logic_vector(31 downto 0)
    );
end entity writeback;


architecture behavior of writeback is
begin
    process(mem_read_data, alu_result, wb_select)
    begin
        if wb_select = '0' then
            wb_data <= alu_result;
        else
            wb_data <= mem_read_data;
        end if;
    end process;
end architecture behavior;

