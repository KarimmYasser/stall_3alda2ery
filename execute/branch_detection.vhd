library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity branch_detection is
  port (
    -- OpCode[3, 2] determine the type of branch, [1] determine immediate or not, [0] determine branch inst or not
    OpCode : in std_logic_vector(3 downto 0); -- Operation code -- change the var name later
    CCR : in std_logic_vector(2 downto 0); -- Condition Code Register: [2]=C, [1]=N, [0]=Z
    BranchTaken : out std_logic -- '1' if branch is taken, '0' otherwise
  );
end entity branch_detection;

architecture Behavioral of branch_detection is
  signal flag_selected : std_logic;
  signal condition_met : std_logic;
begin
  process(OpCode, CCR)
  begin
    -- Select the appropriate flag based on OpCode(3 downto 2)
    -- 00: JZ (CCR(0) = Z)
    -- 01: JN (CCR(1) = N)
    -- 10: JC (CCR(2) = C)
    case OpCode(3 downto 2) is
      when "00" => flag_selected <= CCR(0);  -- JZ
      when "01" => flag_selected <= CCR(1);  -- JN
      when "10" => flag_selected <= CCR(2);  -- JC
      when others => flag_selected <= '0';
    end case;
    
    -- Compute: (flag_selected AND OpCode(1)) OR (NOT OpCode(1))
    condition_met <= (flag_selected and OpCode(1)) or (not OpCode(1));
    
    -- Branch is taken if OpCode(0) = '1' AND condition is met
    BranchTaken <= OpCode(0) and condition_met;
  end process;
end architecture Behavioral;