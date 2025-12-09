LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- IF/ID Pipeline Register
-- Stores instruction and PC from Fetch stage to Decode stage
-- Uses general_register components with appropriate sizes
ENTITY if_id_register IS
    PORT (
        clk             : IN  STD_LOGIC;
        reset           : IN  STD_LOGIC;
        write_enable    : IN  STD_LOGIC;
        
        -- Inputs from Fetch stage (split instruction)
        instruction_in  : IN  STD_LOGIC_VECTOR(26 DOWNTO 0);  -- Lower 27 bits
        opcode_in       : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);   -- Top 5 bits (may be micro-opcode)
        pc_in           : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        
        -- Outputs to Decode stage
        instruction_out : OUT STD_LOGIC_VECTOR(26 DOWNTO 0);
        opcode_out      : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        pc_out          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END ENTITY if_id_register;

ARCHITECTURE Behavioral OF if_id_register IS
    -- Component declaration for general_register
    COMPONENT general_register IS
        GENERIC (
            REGISTER_SIZE : INTEGER := 32;
            RESET_VALUE   : INTEGER := 0
        );
        PORT (
            clk          : IN  STD_LOGIC;
            reset        : IN  STD_LOGIC;
            write_enable : IN  STD_LOGIC;
            data_in      : IN  STD_LOGIC_VECTOR(REGISTER_SIZE - 1 DOWNTO 0);
            data_out     : OUT STD_LOGIC_VECTOR(REGISTER_SIZE - 1 DOWNTO 0)
        );
    END COMPONENT;
    
BEGIN
    -- Instruction register (27 bits - exact size)
    REG_INSTRUCTION: general_register
        GENERIC MAP (REGISTER_SIZE => 27, RESET_VALUE => 0)
        PORT MAP (
            clk => clk,
            reset => reset,
            write_enable => write_enable,
            data_in => instruction_in,
            data_out => instruction_out
        );
    
    -- Opcode register (5 bits - exact size)
    REG_OPCODE: general_register
        GENERIC MAP (REGISTER_SIZE => 5, RESET_VALUE => 0)
        PORT MAP (
            clk => clk,
            reset => reset,
            write_enable => write_enable,
            data_in => opcode_in,
            data_out => opcode_out
        );
    
    -- PC register (32 bits)
    REG_PC: general_register
        GENERIC MAP (REGISTER_SIZE => 32, RESET_VALUE => 0)
        PORT MAP (
            clk => clk,
            reset => reset,
            write_enable => write_enable,
            data_in => pc_in,
            data_out => pc_out
        );
    
END ARCHITECTURE Behavioral;
