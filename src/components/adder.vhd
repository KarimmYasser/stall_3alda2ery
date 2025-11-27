LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Generic N-bit adder with carry in/out and overflow detection
-- Use cases: PC increment, ALU operations, SP increment/decrement, address calculation
ENTITY generic_adder IS
    GENERIC (
        N : POSITIVE := 32 -- Default 32-bit width (processor word size)
    );
    PORT (
        A : IN STD_LOGIC_VECTOR(N - 1 DOWNTO 0);      -- First operand
        B : IN STD_LOGIC_VECTOR(N - 1 DOWNTO 0);      -- Second operand
        Cin : IN STD_LOGIC := '0';                    -- Carry in (optional, default 0)
        Sum : OUT STD_LOGIC_VECTOR(N - 1 DOWNTO 0);   -- Sum output
        Cout : OUT STD_LOGIC;                         -- Carry out
        Overflow : OUT STD_LOGIC                      -- Overflow flag (for signed arithmetic)
    );
END ENTITY generic_adder;

ARCHITECTURE Behavioral OF generic_adder IS
    SIGNAL temp_sum : UNSIGNED(N DOWNTO 0); -- N+1 bits to capture carry
    SIGNAL a_unsigned : UNSIGNED(N - 1 DOWNTO 0);
    SIGNAL b_unsigned : UNSIGNED(N - 1 DOWNTO 0);
    SIGNAL cin_unsigned : UNSIGNED(0 DOWNTO 0);
BEGIN
    -- Convert inputs to unsigned for arithmetic
    a_unsigned <= UNSIGNED(A);
    b_unsigned <= UNSIGNED(B);
    cin_unsigned(0) <= Cin;

    -- Perform addition with carry
    temp_sum <= ('0' & a_unsigned) + ('0' & b_unsigned) + cin_unsigned;

    -- Assign outputs
    Sum <= STD_LOGIC_VECTOR(temp_sum(N - 1 DOWNTO 0));
    Cout <= temp_sum(N); -- MSB is the carry out

    -- Overflow detection for signed arithmetic
    -- Overflow occurs when:
    -- - Adding two positive numbers gives a negative result
    -- - Adding two negative numbers gives a positive result
    Overflow <= (A(N - 1) AND B(N - 1) AND NOT temp_sum(N - 1)) OR
                (NOT A(N - 1) AND NOT B(N - 1) AND temp_sum(N - 1));

END ARCHITECTURE Behavioral;
