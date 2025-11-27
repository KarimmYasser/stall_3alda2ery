LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- 32-bit Arithmetic Logic Unit (ALU)
-- Supports all arithmetic and logical operations from the ISA:
--   - ADD, SUB, AND, NOT, INC
--   - Pass-through (for MOV, SWAP)
--   - Flag management (SETC)
--   - Flag restoration (for RTI - Return from Interrupt)
--
-- Flags Generated:
--   Zero (Z):     Result = 0
--   Negative (N): Result < 0 (MSB = 1)
--   Carry (C):    Overflow/carry from arithmetic operations
ENTITY ALU IS
    PORT (
        -- Operands (32-bit)
        Operand1 : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);  -- First operand (Rsrc1 or Rdst)
        Operand2 : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);  -- Second operand (Rsrc2 or Immediate)
        
        -- Control signals
        ALU_Sel  : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);   -- ALU operation select
        
        -- Flag restoration (for RTI instruction)
        Flags_Data : IN  STD_LOGIC_VECTOR(2 DOWNTO 0); -- Saved flags: Z & N & C
        Flags_Sel  : IN  STD_LOGIC;                     -- '1' = restore flags from Flags_Data
        
        -- Outputs
        Result    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- ALU result
        ZeroFlag  : OUT STD_LOGIC;                      -- Z flag
        NegFlag   : OUT STD_LOGIC;                      -- N flag
        CarryFlag : OUT STD_LOGIC                       -- C flag
    );
END ENTITY ALU;

ARCHITECTURE Behavioral OF ALU IS
    -- Extended width for carry detection
    SIGNAL extended_op1 : SIGNED(32 DOWNTO 0);
    SIGNAL extended_op2 : SIGNED(32 DOWNTO 0);
    SIGNAL extended_result : SIGNED(32 DOWNTO 0);
    
BEGIN
    -- Main ALU process
    PROCESS (Operand1, Operand2, ALU_Sel, Flags_Sel, Flags_Data)
        VARIABLE TempResult : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
        VARIABLE Zero       : STD_LOGIC := '0';
        VARIABLE Negative   : STD_LOGIC := '0';
        VARIABLE Carry      : STD_LOGIC := '0';
        VARIABLE temp_sum   : SIGNED(32 DOWNTO 0);  -- 33 bits for carry detection
    BEGIN
        -- Default values
        TempResult := (OTHERS => '0');
        Carry := '0';

        -- ALU Operations based on ALU_Sel
        CASE ALU_Sel IS
            -- 000: Pass Operand1 (for MOV, SWAP, etc.)
            WHEN "000" =>
                TempResult := Operand1;
                
            -- 001: Add (ADD, IADD instructions)
            WHEN "001" =>
                temp_sum := SIGNED('0' & Operand1) + SIGNED('0' & Operand2);
                TempResult := STD_LOGIC_VECTOR(temp_sum(31 DOWNTO 0));
                Carry := temp_sum(32);  -- Carry out from bit 31
                
            -- 010: Subtract (SUB instruction)
            WHEN "010" =>
                temp_sum := SIGNED('0' & Operand1) - SIGNED('0' & Operand2);
                TempResult := STD_LOGIC_VECTOR(temp_sum(31 DOWNTO 0));
                Carry := temp_sum(32);  -- Borrow (inverted carry)
                
            -- 011: Bitwise AND
            WHEN "011" =>
                TempResult := Operand1 AND Operand2;
                
            -- 100: Bitwise NOT (1's complement)
            WHEN "100" =>
                TempResult := NOT Operand1;
                
            -- 101: Increment (INC instruction)
            WHEN "101" =>
                temp_sum := SIGNED('0' & Operand1) + 1;
                TempResult := STD_LOGIC_VECTOR(temp_sum(31 DOWNTO 0));
                Carry := temp_sum(32);  -- Carry from increment
                
            -- 110: Set Carry (SETC instruction)
            WHEN "110" =>
                TempResult := Operand1;  -- Pass through
                Carry := '1';             -- Force carry flag
                
            -- 111: Reserved/Unused
            WHEN OTHERS =>
                TempResult := (OTHERS => '0');
        END CASE;

        -- Generate Zero flag
        IF TempResult = X"00000000" THEN
            Zero := '1';
        ELSE
            Zero := '0';
        END IF;

        -- Generate Negative flag (MSB of result)
        Negative := TempResult(31);

        -- Flag Restoration (for RTI - Return from Interrupt)
        -- When returning from interrupt, restore saved flags
        IF Flags_Sel = '1' THEN
            Zero     := Flags_Data(0);  -- Restore Z
            Negative := Flags_Data(1);  -- Restore N
            Carry    := Flags_Data(2);  -- Restore C
        END IF;

        -- Assign outputs
        Result    <= TempResult;
        ZeroFlag  <= Zero;
        NegFlag   <= Negative;
        CarryFlag <= Carry;
        
    END PROCESS;
    
END ARCHITECTURE Behavioral;
