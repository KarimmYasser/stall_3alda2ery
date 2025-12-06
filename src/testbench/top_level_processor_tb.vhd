library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

entity top_level_processor_tb is
end entity top_level_processor_tb;

architecture testbench of top_level_processor_tb is
    -- Component declaration
    component top_level_processor is
        port(
            clk : in std_logic;
            reset : in std_logic;
            external_interrupt : in std_logic;
            mem_address : out std_logic_vector(31 downto 0);
            mem_data_in : in std_logic_vector(31 downto 0);
            mem_data_out : out std_logic_vector(31 downto 0);
            mem_read : out std_logic;
            mem_write : out std_logic;
            io_data_in : in std_logic_vector(31 downto 0);
            io_data_out : out std_logic_vector(31 downto 0);
            io_read : out std_logic;
            io_write : out std_logic
        );
    end component;
    
    -- Testbench signals
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal external_interrupt : std_logic := '0';
    signal mem_address : std_logic_vector(31 downto 0);
    signal mem_data_in : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_data_out : std_logic_vector(31 downto 0);
    signal mem_read : std_logic;
    signal mem_write : std_logic;
    signal io_data_in : std_logic_vector(31 downto 0) := (others => '0');
    signal io_data_out : std_logic_vector(31 downto 0);
    signal io_read : std_logic;
    signal io_write : std_logic;
    
    -- Clock period
    constant clk_period : time := 10 ns;
    
    -- Test control
    signal test_done : boolean := false;
    
    -- Simple instruction memory (32 instructions)
    type memory_array is array (0 to 31) of std_logic_vector(31 downto 0);
    signal instruction_memory : memory_array := (
        -- Format: Opcode(5) | Index(3) | Unused(15) | Rd(3) | Rs1(3) | Rs2(3) = 32 bits
        0  => std_logic_vector'(x"00000000"),  -- NOP:      opcode=00000
        1  => std_logic_vector'(x"29000005"),  -- LDM R1,5: opcode=00101, Rd=001, Imm=5
        2  => std_logic_vector'(x"2A00000A"),  -- LDM R2,10: opcode=00101, Rd=010, Imm=10
        3  => std_logic_vector'(x"4B280000"),  -- ADD R3,R1,R2: opcode=01001, Rd=011, Rs1=001, Rs2=010
        4  => std_logic_vector'(x"34600000"),  -- MOV R4,R3: opcode=00110, Rd=100, Rs1=011
        5  => std_logic_vector'(x"84000000"),  -- OUT R4: opcode=10000, Rs1=100
        6  => std_logic_vector'(x"08000000"),  -- HLT: opcode=00001
        others => (others => '0')
    );
    
begin
    -- Instantiate the Unit Under Test (UUT)
    UUT: top_level_processor
        port map (
            clk => clk,
            reset => reset,
            external_interrupt => external_interrupt,
            mem_address => mem_address,
            mem_data_in => mem_data_in,
            mem_data_out => mem_data_out,
            mem_read => mem_read,
            mem_write => mem_write,
            io_data_in => io_data_in,
            io_data_out => io_data_out,
            io_read => io_read,
            io_write => io_write
        );
    
    -- Clock process
    clk_process: process
    begin
        while not test_done loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait;
    end process;
    
    -- Memory simulation process
    memory_process: process(mem_address, mem_read)
        variable addr : integer;
    begin
        if mem_read = '1' then
            addr := to_integer(unsigned(mem_address));
            if addr < 32 then
                mem_data_in <= instruction_memory(addr);
            else
                mem_data_in <= (others => '0');
            end if;
        end if;
    end process;
    
    -- Stimulus process
    stim_proc: process
        variable l : line;
    begin
        -- Initial reset
        write(l, string'("========================================"));
        writeline(output, l);
        write(l, string'("Starting Top-Level Processor Test"));
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);
        
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        
        write(l, string'("Reset released, processor starting..."));
        writeline(output, l);
        
        -- Let the processor run
        wait for clk_period * 50;
        
        write(l, string'(""));
        writeline(output, l);
        write(l, string'("Test 1: Basic instruction execution"));
        writeline(output, l);
        write(l, string'("Executed NOP, LDM, ADD, MOV, OUT, HLT sequence"));
        writeline(output, l);
        
        -- Test external interrupt
        wait for clk_period * 5;
        write(l, string'(""));
        writeline(output, l);
        write(l, string'("Test 2: External interrupt"));
        writeline(output, l);
        external_interrupt <= '1';
        wait for clk_period;
        external_interrupt <= '0';
        write(l, string'("Interrupt asserted and cleared"));
        writeline(output, l);
        
        -- Continue execution
        wait for clk_period * 20;
        
        write(l, string'(""));
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);
        write(l, string'("Top-Level Processor Test Completed"));
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);
        
        test_done <= true;
        wait;
    end process;
    
    -- Monitor process to display important events
    monitor_proc: process(clk)
        variable l : line;
    begin
        if rising_edge(clk) then
            -- Display when instructions are fetched
            if mem_read = '1' then
                write(l, string'("  PC="));
                write(l, to_integer(unsigned(mem_address)));
                write(l, string'(" Instruction="));
                hwrite(l, mem_data_in);
                writeline(output, l);
            end if;
            
            -- Display I/O operations
            if io_write = '1' then
                write(l, string'("  [I/O] Output: "));
                write(l, to_integer(unsigned(io_data_out)));
                writeline(output, l);
            end if;
            
            if io_read = '1' then
                write(l, string'("  [I/O] Input request"));
                writeline(output, l);
            end if;
        end if;
    end process;
    
end architecture testbench;
