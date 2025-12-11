library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity alu_controller is
  port (
    alu_func_signal : in std_logic;                 -- Enable ALU function
    not_signal : in std_logic;                      -- Enable NOT operation
    add_offset_signal : in std_logic;               -- Enable add offset operation
    pass_data1_signal : in std_logic;               -- Pass first operand
    pass_data2_signal : in std_logic;               -- Pass second operand
    setc_signal : in std_logic;                     -- Set carry signal
    func : in std_logic_vector(1 downto 0);         -- ALU function select
    alu_control : out std_logic_vector(3 downto 0)  -- ALU control output
  );
end entity alu_controller;

architecture behavioral of alu_controller is
begin
  process(alu_func_signal, not_signal, pass_data1_signal, pass_data2_signal, func)
  begin
        -- Default: no ALU operation (000)
        alu_control <= "0000";

        -- Check if ALU operation is enabled
        IF alu_func_signal = '1' THEN
            CASE func IS
                WHEN "00" => -- Add operation
                    alu_control <= "0001"; -- Output: 001
                WHEN "01" => -- Subtract operation
                    alu_control <= "0010"; -- Output: 010
                WHEN "10" => -- AND operation
                    alu_control <= "0011"; -- Output: 011
                WHEN "11" => -- Increment operation
                    alu_control <= "0100"; -- Output: 100
                WHEN OTHERS =>
                    alu_control <= "0000"; -- Default to no ALU operation
            END CASE;
        ELSIF not_signal = '1' THEN
            -- Handle NOT operation (if enabled)
            alu_control <= "0101"; -- Output: 101 for NOT operation
        ELSIF pass_data1_signal = '1' THEN
            -- Pass data from the first input
            alu_control <= "0110"; -- Output: 110 for passing data_1
        ELSIF pass_data2_signal = '1' THEN
            -- Pass data from the second input
            alu_control <= "0111"; -- Output: 111 for passing data_2
        ELSIF add_offset_signal = '1' THEN
            -- Add offset operation
            alu_control <= "1000"; -- Output: 1000 for add offset
        ELSIF setc_signal = '1' THEN
            -- Set carry operation
            alu_control <= "1001"; -- Output: 1001 for set carry
        ELSE
            -- Default: No ALU operation
            alu_control <= "0000"; -- No ALU operation
        END IF;
    END PROCESS;
END behavioral;

-- 0000 -> np --  0001 -> add -- 0010 -> sub -- 0011 -> and -- 0100 -> inc --` 0101 -> not -- 0110 -> pass_data_1 -- 0111 -> pass_data_2  -- 1000 -> add_offset -- 1001 -> set_carry