LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- EX/MEM Pipeline Register
-- Stores all control signals and data from Execute stage using general_register components
ENTITY ex_mem_reg IS
    PORT (
        clk             : IN  STD_LOGIC;
        reset           : IN  STD_LOGIC;
        write_enable    : IN  STD_LOGIC;
        
        -- Control signals from Execute
        wb_signals_in        : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        mem_signals_in       : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
        output_signal_in     : IN  STD_LOGIC;
        branch_taken_in      : IN  STD_LOGIC;
        ccr_in               : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        
        -- Control signals to Memory
        wb_signals_out       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        mem_signals_out      : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        output_signal_out    : OUT STD_LOGIC;
        branch_taken_out     : OUT STD_LOGIC;
        ccr_out              : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        
        -- Data signals from Execute
        rs2_data_in          : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        alu_result_in        : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        pc_in                : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd_addr_in           : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        
        -- Data signals to Memory
        rs2_data_out         : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        alu_result_out       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        pc_out               : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd_addr_out          : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
END ENTITY ex_mem_reg;

ARCHITECTURE Behavioral OF ex_mem_reg IS
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
    
    -- Concatenated input/output signals for vector registers
    SIGNAL control_flags_in  : STD_LOGIC_VECTOR(14 DOWNTO 0); -- 3(wb) + 7(mem) + 1(output) + 1(branch) + 3(ccr)
    SIGNAL control_flags_out : STD_LOGIC_VECTOR(14 DOWNTO 0);
    SIGNAL rd_addr_vec_in    : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL rd_addr_vec_out   : STD_LOGIC_VECTOR(2 DOWNTO 0);
    
BEGIN
    -- Pack inputs
    control_flags_in <= wb_signals_in & mem_signals_in & output_signal_in & branch_taken_in & ccr_in;
    rd_addr_vec_in   <= rd_addr_in;
    
    -- Unpack outputs
    wb_signals_out    <= control_flags_out(14 DOWNTO 12);
    mem_signals_out   <= control_flags_out(11 DOWNTO 5);
    output_signal_out <= control_flags_out(4);
    branch_taken_out  <= control_flags_out(3);
    ccr_out           <= control_flags_out(2 DOWNTO 0);
    rd_addr_out       <= rd_addr_vec_out;
    
    -- Control flags register (15 bits)
    REG_CONTROL_FLAGS: general_register
        GENERIC MAP (REGISTER_SIZE => 15, RESET_VALUE => 0)
        PORT MAP (
            clk => clk,
            reset => reset,
            write_enable => write_enable,
            data_in => control_flags_in,
            data_out => control_flags_out
        );
    
    -- Rs2 data register (32 bits)
    REG_RS2_DATA: general_register
        GENERIC MAP (REGISTER_SIZE => 32, RESET_VALUE => 0)
        PORT MAP (
            clk => clk,
            reset => reset,
            write_enable => write_enable,
            data_in => rs2_data_in,
            data_out => rs2_data_out
        );
    
    -- ALU result register (32 bits)
    REG_ALU_RESULT: general_register
        GENERIC MAP (REGISTER_SIZE => 32, RESET_VALUE => 0)
        PORT MAP (
            clk => clk,
            reset => reset,
            write_enable => write_enable,
            data_in => alu_result_in,
            data_out => alu_result_out
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
    
    -- Destination address register (3 bits)
    REG_RD_ADDR: general_register
        GENERIC MAP (REGISTER_SIZE => 3, RESET_VALUE => 0)
        PORT MAP (
            clk => clk,
            reset => reset,
            write_enable => write_enable,
            data_in => rd_addr_vec_in,
            data_out => rd_addr_vec_out
        );
    
END ARCHITECTURE Behavioral;
