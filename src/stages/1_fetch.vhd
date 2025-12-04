library IEEE;
use IEEE.std_logic_1164.all;

entity Fetch is 
    port(
        -- Control signals
        Stall : in std_logic;
        inturrupt : in std_logic;
        
        -- Input instruction from memory
        instruction_in : in std_logic_vector(31 downto 0);
        
        -- Microcode from Control Unit (comes back from decode stage)
        Micro_inst : in std_logic_vector(4 downto 0);
        
        -- Output instruction (with potentially replaced opcode)
        instruction_out : out std_logic_vector(31 downto 0)
    );
end entity Fetch;

architecture Behavior of Fetch is
begin
    -- MUX: When stalled or interrupted, use microcode as opcode
    -- Otherwise, pass through the instruction from memory
    instruction_out(31 downto 27) <= Micro_inst when (Stall = '1' or inturrupt = '1') 
                                     else instruction_in(31 downto 27);
    
    -- Pass through the rest of the instruction bits unchanged
    instruction_out(26 downto 0) <= instruction_in(26 downto 0);
    
end architecture Behavior;
