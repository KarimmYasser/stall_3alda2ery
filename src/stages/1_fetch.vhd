library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;  -- Added for unsigned type

entity Fetch is 
    port(
        -- Control signals
        clk : in std_logic;
        reset : in std_logic;
        Stall : in std_logic;
        inturrupt : in std_logic; 
        -- Input instruction from memory
        instruction_in : in std_logic_vector(31 downto 0);
        mem_flages : in std_logic_vector(5 downto 0); --(5)MEMRead, (4)MEMWrite, (3)StackRead, (2)StackWrite, (1)CCRStore/CCRLoad, (0)CCRLoad
        branch_exe : in std_logic;
        branch_decode: in std_logic;
        mem_branch : in std_logic;
        mem_read_data_in : in std_logic_vector(31 downto 0); --data from memory stage
        -- Microcode from Control Unit (comes back from decode stage)
        Micro_inst : in std_logic_vector(4 downto 0);
        immediate_in : in std_logic_vector(31 downto 0);
        
        -- Output instruction (with potentially replaced opcode)
        instruction_out : out std_logic_vector(26 downto 0);
        opcode_out : out std_logic_vector(4 downto 0);
        pc_out : out std_logic_vector(31 downto 0)
    );
end entity Fetch;

architecture Behavior of Fetch is
    component PC is
        port(
            clk : in std_logic;
            pc_in : in std_logic_vector(31 downto 0);
            pc_out : out std_logic_vector(31 downto 0);
            pc_enable : in std_logic;
        );
    end component PC;
    signal pc_next : std_logic_vector(31 downto 0);
    signal data_from_mem_fetch : std_logic_vector(31 downto 0);
    signal data_from_mem_stage : std_logic_vector(31 downto 0);
    signal pc_current : std_logic_vector(31 downto 0);
    signal pc_enable_signal : std_logic;
begin
    -- MUX: When stalled or interrupted, use microcode as opcode
    -- Otherwise, pass through the instruction from memory
    
    -- Pass through the rest of the instruction bits unchanged
    instruction_out(26 downto 0) <= instruction_in(26 downto 0);
    opcode_out <= Micro_inst when (Stall = '1' or inturrupt = '1') 
    else instruction_in(31 downto 27);
    -- Program Counter instance
    PC_inst : PC
        port map (
            clk => clk,
            pc_in => pc_next,
            pc_out => pc_current,
            pc_enable => pc_enable_signal
        );
    pc_out <= pc_current;
    pc_enable_signal <= not (Stall);
    -- Combinational logic for next PC calculation
    process(reset, mem_branch, mem_flages, branch_decode, branch_exe, 
            data_from_mem_stage, immediate_in, pc_current)
    begin
        if (reset = '1') then
            pc_next <= data_from_mem_fetch;  -- Reset PC to 0
        elsif (mem_branch = '1' and (mem_flages(5) = '1' or mem_flages(3) = '1')) then
            pc_next <= mem_read_data_in;  -- Branch from memory stage
        elsif (branch_decode = '1' or branch_exe = '1') then
            pc_next <= immediate_in;  -- Branch to immediate address
        else
            pc_next <= std_logic_vector(unsigned(pc_current) + 1);  -- Normal increment
        end if;
    end process;
    
end architecture Behavior;
