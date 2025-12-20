LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Stack Pointer Handler for 32-bit RISC Processor
-- Manages SP updates for PUSH, POP, CALL, RET, INT, and RTI operations
-- 
-- IMPORTANT: SP value is updated on rising edge of clock (new value appears at rising edge)
-- but data memory must read the OLD value DM[SP] before the update
-- 
-- Design Notes:
-- - SP initialized to top of stack (2^18 - 1 = 262143) for 1MB memory
-- - Decrements on PUSH, CALL, INT (stack grows downward)
-- - Increments on POP, RET, RTI (stack shrinks upward)
-- - Asynchronous reset for immediate response
ENTITY stack_pointer IS
    GENERIC (
        ADDR_WIDTH     : INTEGER := 18;         -- Address width (2^18 = 256K words = 1MB)
        STACK_TOP_ADDR : INTEGER := 262143      -- Initial SP value (2^18 - 1)
    );
    PORT (
        clk   : IN STD_LOGIC;                   -- Clock signal
        reset : IN STD_LOGIC;                   -- Asynchronous active-high reset
        
        -- Stack operation control signals
        stack_read  : IN STD_LOGIC;             -- POP/RET/RTI operation (increment SP)
        stack_write : IN STD_LOGIC;             -- PUSH/CALL/INT operation (decrement SP)
        ccr_load : in std_logic;
        ccr_store :in std_logic;
        
        -- Stack pointer output
        sp_out : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0)
    );
END ENTITY stack_pointer;

ARCHITECTURE Behavioral OF stack_pointer IS
    -- Internal SP register (initialized to stack top)
    SIGNAL sp      : UNSIGNED(ADDR_WIDTH - 1 DOWNTO 0) := TO_UNSIGNED(STACK_TOP_ADDR, ADDR_WIDTH);
    SIGNAL sp_next : UNSIGNED(ADDR_WIDTH - 1 DOWNTO 0); -- Next state of SP
    
BEGIN
    -- Output current SP value
    sp_out <= STD_LOGIC_VECTOR(sp);

    -- Sequential logic: Update SP on clock edge or reset
    PROCESS (clk, reset,stack_read, ccr_load)
    BEGIN
        IF (reset = '1') THEN
            -- Asynchronous reset: Set SP to top of stack
            sp <= TO_UNSIGNED(STACK_TOP_ADDR, ADDR_WIDTH);
            
        ELSIF rising_edge(clk) THEN
            -- Synchronous update: Load next SP value
            sp <= sp_next;
        END IF;
        IF ((stack_read = '1' or ccr_load ='1') and clk ='1') THEN
            sp <= sp + 1;
        end if;
    END PROCESS;

    -- Combinational logic: Calculate next SP value
    PROCESS (sp, stack_write, ccr_store)
    BEGIN
        -- Default: No change to SP
        sp_next <= sp;

        -- Decrement SP (stack grows downward)
        -- Priority: WRITE (PUSH, CALL, INT)
        IF (stack_write = '1' or ccr_store ='1') THEN
            sp_next <= sp - 1;
        
        -- Increment SP (stack shrinks upward)
        -- READ (POP, RET, RTI)

        END IF;
    END PROCESS;

END ARCHITECTURE Behavioral;
