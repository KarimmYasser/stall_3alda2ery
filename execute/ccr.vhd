LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity CCR is
    PORT (
        -- Inputs
        CCR_In  : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);  -- [2]=C, [1]=N, [0]=Z
        
        -- Control signals
        Load_CCR     : IN  STD_LOGIC;  -- '1' = Load flags from inputs
        
        -- Outputs
        CCR_Out  : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)  -- [2]=C, [1]=N, [0]=Z
    );
END ENTITY CCR;

ARCHITECTURE Behavioral OF CCR IS
    -- Internal signal to hold the flags
    SIGNAL CCR_Reg  : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
BEGIN
    -- Process to load flags into CCR
    PROCESS (Load_CCR, CCR_In)
    BEGIN
        IF Load_CCR = '1' THEN
            CCR_Reg <= CCR_In;
        END IF;
    END PROCESS;

    -- Assign internal flags to outputs
    CCR_Out <= CCR_Reg;
END ARCHITECTURE Behavioral;