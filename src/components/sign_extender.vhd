LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Sign Extender: Converts 16-bit immediate values to 32-bit
-- Used for instructions with immediate operands:
--   - IADD Rdst, Rsrc, Imm   (Add immediate)
--   - LDM Rdst, Imm           (Load immediate)
--   - LDD Rdst, offset(Rsrc)  (Load with offset)
--   - STD Rsrc, offset(Rdst)  (Store with offset)
--   - JZ, JN, JC, JMP Imm     (Branch with immediate address)
--   - CALL Imm                (Call with immediate address)
--
-- Sign extension preserves the sign of signed numbers:
--   - Positive: 0x0010 → 0x00000010
--   - Negative: 0xFFF0 → 0xFFFFFFF0
ENTITY sign_extender IS
    PORT (
        -- Input: 16-bit immediate value from instruction
        input_16  : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
        
        -- Output: 32-bit sign-extended value
        output_32 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END ENTITY sign_extender;

ARCHITECTURE Behavioral OF sign_extender IS
BEGIN
    -- Sign extension: replicate MSB (bit 15) to upper 16 bits
    -- Bits 31:16 = all copies of input_16(15)
    -- Bits 15:0  = input_16
    --
    -- Examples:
    --   input_16 = 0x0005 (0000000000000101) → output_32 = 0x00000005
    --   input_16 = 0xFFFB (1111111111111011) → output_32 = 0xFFFFFFFB
    --   input_16 = 0x7FFF (0111111111111111) → output_32 = 0x00007FFF
    --   input_16 = 0x8000 (1000000000000000) → output_32 = 0xFFFF8000
    
    output_32 <= (31 DOWNTO 16 => input_16(15)) & input_16(15 DOWNTO 0);
    
    -- Alternative implementation (equivalent):
    -- output_32(15 DOWNTO 0)  <= input_16;
    -- output_32(31 DOWNTO 16) <= (OTHERS => input_16(15));

END ARCHITECTURE Behavioral;
