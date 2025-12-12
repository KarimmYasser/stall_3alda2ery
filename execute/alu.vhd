-- ALU Operations:
-- 0: NOP, 1: Add, 2: Sub, 3: AND, 4: Inc, 5: NOT, 6: SETC

-- Flags: [0]=Carry, [1]=Negative, [2]=Zero

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity alu is
  port (
    alu_operand_1 : in std_logic_vector(31 downto 0);   -- First operand
    alu_operand_2 : in std_logic_vector(31 downto 0);   -- Second operand
    alu_control : in std_logic_vector(2 downto 0);      -- ALU operation control [3:0]
    alu_enable : in std_logic;                             -- ALU enable signal
    flags_enable_out : out std_logic_vector(2 downto 0); -- Flags update enable
    result : out std_logic_vector(31 downto 0);         -- ALU result
    flags : out std_logic_vector(2 downto 0)            -- Output flags [C,N,Z]
  );
end entity alu;

architecture behavioral of alu is
begin
  process(alu_operand_1, alu_operand_2, alu_control)
    variable temp_result : std_logic_vector(32 downto 0); -- Extra bit for carry
  begin
    -- Default values
    flags_enable_out <= "000";
    flags <= "000";
    result <= (others => '0');
    temp_result := (others => '0');

    -- ALU operations based on control bits [3:0]
    case alu_control(2 downto 0) is        
      when "001" => -- Add
        temp_result := ('0' & alu_operand_1) + ('0' & alu_operand_2);
        result <= temp_result(31 downto 0);
        if(alu_enable = '1') then
          flags_enable_out <= "111"; -- Enable C, N, Z
        else
          flags_enable_out <= "000"; -- No flags updated
        end if;
        
      when "010" => -- Subtract
        temp_result := ('0' & alu_operand_1) - ('0' & alu_operand_2);
        result <= temp_result(31 downto 0);
        if(alu_enable = '1') then
          flags_enable_out <= "111"; -- Enable C, N, Z
        else
          flags_enable_out <= "000"; -- No flags updated
        end if;
        
      when "011" => -- AND
        temp_result := ('0' & alu_operand_1) and ('0' & alu_operand_2);
        result <= temp_result(31 downto 0);
        if(alu_enable = '1') then
          flags_enable_out <= "110"; -- Enable N, Z (no carry)
        else
          flags_enable_out <= "000"; -- No flags updated
        end if;
        
      when "100" => -- Increment
        temp_result := ('0' & alu_operand_1) + 1;
        result <= temp_result(31 downto 0);
        if(alu_enable = '1') then
          flags_enable_out <= "111"; -- Enable C, N, Z
        else
          flags_enable_out <= "000"; -- No flags updated
        end if;
        
      when "101" => -- NOT
        temp_result := '0' & (not alu_operand_1);
        result <= temp_result(31 downto 0);
        if(alu_enable = '1') then
          flags_enable_out <= "110"; -- Enable N, Z (no carry)
        else
          flags_enable_out <= "000"; -- No flags updated
        end if;
        
      when "110" => -- SETC
        temp_result := '1' & alu_operand_1;  -- Set carry bit to '1'
        result <= temp_result(31 downto 0);
        if(alu_enable = '1') then
          flags_enable_out <= "001"; -- Enable C only [bit 0 = Carry]
        else
          flags_enable_out <= "000"; -- No flags updated
        end if;
      
      when "111" => -- PASS 1
        result <= alu_operand_1; -- Pass through
        flags_enable_out <= "000"; -- No flags updated
        
      when others => -- Reserved
        result <= (others => '0');
        flags_enable_out <= "000";
    end case;

    -- Calculate flags
    flags(0) <= temp_result(32); -- Carry flag
    flags(1) <= temp_result(31); -- Negative flag (sign bit)
    if temp_result(31 downto 0) = x"00000000" then
      flags(2) <= '1'; -- Zero flag
    else
      flags(2) <= '0';
    end if;

  end process;

end behavioral;