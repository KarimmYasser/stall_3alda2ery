-- 000 -> np --  001 -> add -- 010 -> sub -- 011 -> and -- 100 -> inc 
-- 101 -> not -- 110 -> pass_data_1 -- 111 -> pass_data_2 -- 1000 -> add_offset

-- flags enable signal 1 

-- Flags: [2]=Carry, [1]=Negative, [0]=Zero

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity alu is
  port (
    input_1 : in std_logic_vector(15 downto 0);          -- First operand
    input_2 : in std_logic_vector(15 downto 0);          -- Second operand
    alu_control : in std_logic_vector(3 downto 0);       -- ALU operation control
    flags_enable_out : out std_logic_vector(2 downto 0); -- Flags update enable
    result : out std_logic_vector(15 downto 0);          -- ALU result
    flags : out std_logic_vector(2 downto 0)             -- Output flags [C,N,Z]
  );
end entity alu;

architecture behavioral of alu is
begin
  process(input_1, input_2, alu_control)
        VARIABLE temp_result : STD_LOGIC_VECTOR(16 DOWNTO 0); -- Extra bit to handle overflows
    BEGIN
        -- Default: no flags enabled
        flags_enable_out <= "000";
        flags <= "000";
        result <= (OTHERS => '0');
        temp_result := (OTHERS => '0'); -- Initialize the variable

        -- Check ALU control signals
        CASE alu_control IS
            WHEN "0000" => -- No ALU operation
                flags_enable_out <= "000";
                flags <= "000";
                result <= (OTHERS => '0');
            WHEN "0001" => -- Add operation
                temp_result := ("0" & input_1) + ("0" & input_2); -- Signed addition with overflow handling
                result <= temp_result(15 DOWNTO 0); -- Assign result to lower 8 bits
                flags_enable_out <= "111"; -- Indicate flags are being updated

            WHEN "0010" => -- Subtract operation
                temp_result := ("0" & input_1) - ("0" & input_2); -- Signed subtraction
                result <= temp_result(15 DOWNTO 0); -- Assign result to lower 8 bits
                flags_enable_out <= "111"; -- Indicate flags are being updated

            WHEN "0011" => -- AND operation
                temp_result := ("0" & input_1) AND ("0" & input_2);
                result <= temp_result(15 DOWNTO 0); -- Assign result to lower 8 bits
                flags_enable_out <= "110"; -- Indicate flags are being updated

            WHEN "0100" => -- Increment operation
                temp_result := ("0" & input_1) + 1; -- Increment input_1
                result <= temp_result(15 DOWNTO 0); -- Assign result to lower 8 bits
                flags_enable_out <= "111"; -- Indicate flags are being updated

            WHEN "0101" => -- NOT operation
                temp_result := ("0" & (NOT input_1)); -- Bitwise NOT of input_1
                result <= temp_result(15 DOWNTO 0); -- Assign result to lower 8 bits
                flags_enable_out <= "110"; -- Indicate flags are being updated

            WHEN "0110" => -- Pass data from first input
                temp_result := ("0" & input_1);
                result <= temp_result(15 DOWNTO 0); -- Assign result to lower 8 bits
                flags_enable_out <= "000"; -- Indicate flags are being updated

            WHEN "0111" => -- Pass data from second input
                temp_result := ("0" & input_2);
                result <= temp_result(15 DOWNTO 0); -- Assign result to lower 8 bits
                flags_enable_out <= "000"; -- Indicate flags are being updated

            WHEN "1000" => -- Add offset operation
                temp_result := ("0" & input_1) + ("0" & input_2); -- Signed addition with overflow handling
                result <= temp_result(15 DOWNTO 0); -- Assign result to lower 8 bits
                flags_enable_out <= "000"; -- Indicate flags are being updated

            WHEN OTHERS =>
                flags_enable_out <= "000";
                flags <= "000";
                result <= (OTHERS => '0');
        END CASE;

        IF temp_result(15 DOWNTO 0) = "0000000000000000" THEN
            flags(2) <= '1'; -- Zero flag
        END IF;
        flags(1) <= temp_result(15); -- Negative flag
        flags(0) <= temp_result(16); -- Carry flag

    END PROCESS;

END behavioral;