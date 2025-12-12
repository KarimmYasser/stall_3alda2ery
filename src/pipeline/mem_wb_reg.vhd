LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- MEM/WB Pipeline Register
-- Stores control signals and data from Memory stage for Writeback stage
ENTITY mem_wb_reg IS
    PORT (
        clk             : IN  STD_LOGIC;
        reset           : IN  STD_LOGIC;
        write_enable    : IN  STD_LOGIC;
        
        -- Control signals from Memory
        wb_signals_in        : IN  STD_LOGIC_VECTOR(2 DOWNTO 0); -- (2)RegWrite, (1)MemtoReg, (0)PC-select
        
        -- Data signals from Memory
        read_data_in         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0); -- From Memory or I/O
        alu_result_in        : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        pc_in                : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd_addr_in           : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        
        -- Control signals to Writeback
        wb_signals_out       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        
        -- Data signals to Writeback
        read_data_out        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        alu_result_out       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        pc_out               : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd_addr_out          : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
END ENTITY mem_wb_reg;

ARCHITECTURE Behavioral OF mem_wb_reg IS
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
    
    -- Intermediate signals
    SIGNAL wb_vec_in   : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL wb_vec_out  : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL rd_addr_vec_in  : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL rd_addr_vec_out : STD_LOGIC_VECTOR(2 DOWNTO 0);
    
BEGIN

    wb_vec_in <= wb_signals_in;
    wb_signals_out <= wb_vec_out;
    
    rd_addr_vec_in <= rd_addr_in;
    rd_addr_out <= rd_addr_vec_out;

    -- WB Control Signals Register (3 bits)
    REG_WB_CTRL: general_register
        GENERIC MAP (REGISTER_SIZE => 3, RESET_VALUE => 0)
        PORT MAP (
            clk => clk,
            reset => reset,
            write_enable => write_enable,
            data_in => wb_vec_in,
            data_out => wb_vec_out
        );
        
    -- Read Data Register (32 bits)
    REG_READ_DATA: general_register
        GENERIC MAP (REGISTER_SIZE => 32, RESET_VALUE => 0)
        PORT MAP (
            clk => clk,
            reset => reset,
            write_enable => write_enable,
            data_in => read_data_in,
            data_out => read_data_out
        );
        
    -- ALU Result Register (32 bits)
    REG_ALU_RESULT: general_register
        GENERIC MAP (REGISTER_SIZE => 32, RESET_VALUE => 0)
        PORT MAP (
            clk => clk,
            reset => reset,
            write_enable => write_enable,
            data_in => alu_result_in,
            data_out => alu_result_out
        );
        
    -- PC Register (32 bits)
    REG_PC: general_register
        GENERIC MAP (REGISTER_SIZE => 32, RESET_VALUE => 0)
        PORT MAP (
            clk => clk,
            reset => reset,
            write_enable => write_enable,
            data_in => pc_in,
            data_out => pc_out
        );
        
    -- Destination Address Register (3 bits)
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
