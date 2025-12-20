LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- 8×32-bit General Purpose Register File (R0-R7)
-- Dual-Edge Clocking Strategy:
--   - READS:  Combinational (asynchronous) - always reflect current register values
--   - WRITES: Falling edge - updates occur on negative clock edge
-- 
-- This design provides natural hazard mitigation:
--   Rising edge:  Decode stage reads operands from register file
--   Falling edge: Write-back stage updates destination register
--   Result: Write completes before next instruction reads, reducing forwarding needs
--
-- Note: Ensure your entire pipeline uses consistent dual-edge strategy
ENTITY general_register_file IS
    GENERIC (
        REGISTER_SIZE   : INTEGER := 32;  -- 32-bit word size (updated from 16)
        REGISTER_NUMBER : INTEGER := 8    -- 8 registers (R0-R7)
    );
    PORT (
        clk           : IN  STD_LOGIC;
        reset         : IN  STD_LOGIC;    -- Synchronous reset (active high)
        write_enable  : IN  STD_LOGIC;    -- Write enable (active high)
        
        -- Read ports (3-bit addresses for R0-R7)
        read_address1 : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);  -- Source register 1
        read_address2 : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);  -- Source register 2
        read_data1    : OUT STD_LOGIC_VECTOR(REGISTER_SIZE - 1 DOWNTO 0);
        read_data2    : OUT STD_LOGIC_VECTOR(REGISTER_SIZE - 1 DOWNTO 0);
        
        -- Write port
        write_address : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);  -- Destination register
        write_data    : IN  STD_LOGIC_VECTOR(REGISTER_SIZE - 1 DOWNTO 0)
    );
END ENTITY general_register_file;

ARCHITECTURE Behavioral OF general_register_file IS
    -- Register array type definition
    TYPE register_array IS ARRAY(NATURAL RANGE <>) OF STD_LOGIC_VECTOR(REGISTER_SIZE - 1 DOWNTO 0);
    
    -- 8 general-purpose registers, initialized to zero
    SIGNAL general_register : register_array(0 TO REGISTER_NUMBER - 1) := (OTHERS => (OTHERS => '0'));
    
BEGIN
    -- Asynchronous (combinational) read ports
    -- Reads always reflect current register values with zero delay
    -- This allows reading updated values immediately after falling-edge write
    read_data1 <= general_register(TO_INTEGER(UNSIGNED(read_address1)));
    read_data2 <= general_register(TO_INTEGER(UNSIGNED(read_address2)));

    -- Synchronous write process on FALLING EDGE
    -- Strategy: Write on falling edge, read on rising edge (in other pipeline stages)
    -- This provides half-cycle separation between write and subsequent read
    write_proc: PROCESS (clk)
    BEGIN
        IF falling_edge(clk) THEN
            IF (reset = '1') THEN
                -- Initialize registers: R0=0, R1=1, R2=2, ..., R7=7
                FOR i IN 0 TO REGISTER_NUMBER - 1 LOOP
                    general_register(i) <= std_logic_vector(to_unsigned(i, REGISTER_SIZE));
                END LOOP;
                
            ELSIF (write_enable = '1') THEN
                -- Write data to destination register
                general_register(TO_INTEGER(UNSIGNED(write_address))) <= write_data;
                
                -- Optional: Hardwire R0 to zero (uncomment if needed)
                general_register(0) <= (OTHERS => '0');
            END IF;
        END IF;
    END PROCESS write_proc;

END ARCHITECTURE Behavioral;
