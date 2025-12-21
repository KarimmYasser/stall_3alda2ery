library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Fetch is 
    port(
        -- Control signals
        clk : in std_logic;
        reset : in std_logic;
        Stall : in std_logic;
        inturrupt : in std_logic; 
        -- Input instruction from memory (32 bits)
        instruction_in : in std_logic_vector(31 downto 0);  -- Fixed from 32 downto 0
        branch_exe : in std_logic;
        branch_decode: in std_logic;
        mem_branch : in std_logic;
        mem_read_data_in : in std_logic_vector(31 downto 0);
        -- Microcode from Control Unit (comes back from decode stage)
        Micro_inst : in std_logic_vector(4 downto 0);
        -- Immediate value for branch from decode stage
        immediate_in : in std_logic_vector(31 downto 0);
        
        -- Split output: opcode can be replaced with microcode
        instruction_out : out std_logic_vector(26 downto 0);  -- Lower 27 bits
        opcode_out : out std_logic_vector(4 downto 0);        -- Top 5 bits (may be micro-opcode)
        pc_out : out std_logic_vector(31 downto 0)
    );
end entity Fetch;

architecture Behavior of Fetch is
    component general_register is
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
    end component;
    
    signal pc_next : std_logic_vector(31 downto 0);
    signal pc_current : std_logic_vector(31 downto 0);
    signal pc_enable_signal : std_logic;
    signal instruction_with_micro : std_logic_vector(31 downto 0);
    
begin
    -- Program Counter register using general_register
    PC_REG : general_register
        GENERIC MAP (REGISTER_SIZE => 32, RESET_VALUE => 0)
        PORT MAP (
            clk => clk,
            reset => reset,
            write_enable => pc_enable_signal,
            data_in => pc_next,
            data_out => pc_current
        );
    
    -- Output current PC
    pc_out <= pc_current;
    
    -- PC enable: update PC when not stalled
    pc_enable_signal <= not Stall or mem_branch or branch_exe or branch_decode;
    
    -- MUX: When stalled or interrupted, replace opcode with microcode
    -- Otherwise, use normal opcode from instruction memory
    opcode_out <= Micro_inst when (Stall = '1' or inturrupt = '1')
                  else instruction_in(31 downto 27);
    
    -- Lower 27 bits always pass through unchanged
    instruction_out <= instruction_in(26 downto 0);
    
    -- Combinational logic for next PC calculation
    process(reset, mem_branch, branch_decode, branch_exe, 
            mem_read_data_in, immediate_in, pc_current , instruction_in)
    begin
        if (reset = '1') then
            pc_next <= (others => '0');  -- Reset PC to 0
        elsif (mem_branch = '1') then
            pc_next <= mem_read_data_in;  -- Branch from memory stage
        elsif (branch_exe = '1') then
            pc_next <= immediate_in;  -- Branch from execute stage (using immediate)
        elsif (branch_decode = '1') then
            pc_next <= instruction_in;  -- Branch from decode stage (JMP instruction)
        else
            pc_next <= std_logic_vector(unsigned(pc_current) + 1);  -- Normal increment
        end if;
    end process;

end architecture Behavior;
