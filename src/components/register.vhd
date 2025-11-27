LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Generic Register with configurable size and reset value
-- Used as building block for PC, SP, and pipeline registers
-- Features asynchronous reset for immediate response
ENTITY general_register IS
    GENERIC (
        REGISTER_SIZE : INTEGER := 32;  -- Default 32-bit for processor word size
        RESET_VALUE   : INTEGER := 0    -- Configurable reset value
    );
    PORT (
        clk          : IN  STD_LOGIC;
        reset        : IN  STD_LOGIC;   -- Asynchronous active-high reset
        write_enable : IN  STD_LOGIC;   -- Write enable (active high)
        data_in      : IN  STD_LOGIC_VECTOR(REGISTER_SIZE - 1 DOWNTO 0);
        data_out     : OUT STD_LOGIC_VECTOR(REGISTER_SIZE - 1 DOWNTO 0)
    );
END ENTITY general_register;

ARCHITECTURE Behavioral OF general_register IS
    SIGNAL temp_data_out : STD_LOGIC_VECTOR(REGISTER_SIZE - 1 DOWNTO 0);
BEGIN
    -- Output assignment
    data_out <= temp_data_out;

    -- Register process with asynchronous reset
    PROCESS (clk, reset)
    BEGIN
        IF (reset = '1') THEN
            -- Asynchronous reset to specified value
            temp_data_out <= STD_LOGIC_VECTOR(TO_UNSIGNED(RESET_VALUE, REGISTER_SIZE));
            
        ELSIF rising_edge(clk) THEN
            -- Synchronous write when enabled
            IF (write_enable = '1') THEN
                temp_data_out <= data_in;
            END IF;
        END IF;
    END PROCESS;
    
END ARCHITECTURE Behavioral;
