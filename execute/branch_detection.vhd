-- Branch detection unit
-- Determines if a conditional branch should be taken based on CCR flags
-- OpCode encoding: [3:2]=branch type, [1]=condition invert, [0]=branch enable

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity branch_detection is
  port (
    opcode : in std_logic_vector(3 downto 0);     -- Branch operation code
    ccr : in std_logic_vector(2 downto 0);        -- Condition flags [0]=C,[1]=N,[2]=Z
    branch_taken : out std_logic                  -- '1' if branch taken
  );
end entity branch_detection;

architecture behavioral of branch_detection is
  signal flag_selected : std_logic;
  signal condition_met : std_logic;
begin
  process(opcode, ccr)
  begin
    -- Select the appropriate flag based on opcode(3 downto 2)
    -- 00: JZ (ccr(2) = Z)
    -- 01: JN (ccr(1) = N)
    -- 10: JC (ccr(0) = C)
    case opcode(3 downto 2) is
      when "00" => flag_selected <= ccr(2);  -- JZ
      when "01" => flag_selected <= ccr(1);  -- JN
      when "10" => flag_selected <= ccr(0);  -- JC
      when others => flag_selected <= '0';
    end case;
    
    -- Compute: (flag_selected AND opcode(1)) OR (NOT opcode(1))
    condition_met <= (flag_selected and opcode(1)) or (not opcode(1));
    
    -- Branch is taken if opcode(0) = '1' AND condition is met
    branch_taken <= opcode(0) and condition_met;
  end process;
end architecture behavioral;