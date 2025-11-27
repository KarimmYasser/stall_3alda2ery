LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Generic multiplexer for selecting among N inputs of M-bit width
-- Use cases: Register file output selection, ALU input selection, writeback mux
ENTITY generic_mux IS
    GENERIC (
        M : POSITIVE := 32; -- Width of each input (default 32-bit for word size)
        N : POSITIVE := 8;  -- Number of inputs (default 8 for register count)
        K : POSITIVE := 3   -- Number of select lines (default 3 for 8 registers)
    );
    PORT (
        inputs : IN STD_LOGIC_VECTOR(M * N - 1 DOWNTO 0); -- Concatenated input signals
        sel : IN STD_LOGIC_VECTOR(K - 1 DOWNTO 0);        -- Select lines
        outputs : OUT STD_LOGIC_VECTOR(M - 1 DOWNTO 0)    -- Output signal
    );
END ENTITY generic_mux;

ARCHITECTURE Behavioral OF generic_mux IS
    SIGNAL selected_index : INTEGER RANGE 0 TO N - 1 := 0; -- Index of the selected input
BEGIN
    -- Convert binary select signal to an integer index
    PROCESS (sel)
    BEGIN
        selected_index <= TO_INTEGER(UNSIGNED(sel));
    END PROCESS;

    -- Process to select the appropriate input and assign it to the output
    PROCESS (inputs, selected_index)
    BEGIN
        -- Extract the selected input vector from the concatenated inputs
        outputs <= inputs(((selected_index + 1) * M - 1) DOWNTO selected_index * M);
    END PROCESS;
END ARCHITECTURE Behavioral;