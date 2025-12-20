LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.memory_interface_pkg.ALL;

ENTITY Memory_Stage IS
    PORT (
        clk           : IN  STD_LOGIC;
        reset         : IN  STD_LOGIC;
        interrupt     : IN  STD_LOGIC; -- Added Interrupt signal for Address Override
        
        -- Control Signals from EX/MEM
        wb_signals_in : IN  STD_LOGIC_VECTOR(2 DOWNTO 0); -- (2)RegWrite, (1)MemtoReg, (0)PC-select (Used for PC vs PC+1)
        mem_signals_in: IN  STD_LOGIC_VECTOR(6 DOWNTO 0); -- (6)WDselect, (5)MEMRead, (4)MEMWrite, (3)StackRead, (2)StackWrite, (1)CCRStore, (0)CCRLoad
        output_signal : IN  STD_LOGIC;
        
        -- Data from EX/MEM
        alu_result_in : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        rs2_data_in   : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        pc_in         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd_addr_in    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        ccr_in        : IN  STD_LOGIC_VECTOR(2 DOWNTO 0); -- Current CCR
        
        -- External I/O
        out_port_data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        
        -- Memory Interface (to Arbiter)
        mem_req       : OUT data_mem_req_t;
        mem_resp      : IN  data_mem_resp_t;
        
        -- Outputs to MEM/WB
        wb_signals_out: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        read_data_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        alu_result_out: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
       -- pc_out        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- 
        rd_addr_out   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        
        -- Additional Outputs
        sp_out_debug  : OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
        mem_addr_out   : OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
        --for debuging
        output_data : out std_logic_vector(31 downto 0); -- Data to output port
        write_data_to_interface: out std_logic_vector(31 downto 0)
    );
END ENTITY Memory_Stage;

ARCHITECTURE Structural OF Memory_Stage IS

    -- Stack Pointer Component
    COMPONENT stack_pointer IS
        GENERIC (
            ADDR_WIDTH     : INTEGER := 18;
            STACK_TOP_ADDR : INTEGER := 262143
        );
        PORT (
            clk         : IN STD_LOGIC;
            reset       : IN STD_LOGIC;
            stack_read  : IN STD_LOGIC;
            stack_write : IN STD_LOGIC;
            ccr_load :in std_logic;
            ccr_store :in std_logic;
            sp_out      : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0)
        );
    END COMPONENT stack_pointer;

    component output_port IS
    GENERIC (
        DATA_SIZE : INTEGER := 32
    );
    PORT (
        enable: in std_logic;
        data_in : IN STD_LOGIC_VECTOR(DATA_SIZE - 1 DOWNTO 0);
        data_out : OUT STD_LOGIC_VECTOR(DATA_SIZE - 1 DOWNTO 0)
    );
    END component output_port;


    -- Signals
    SIGNAL sp_current    : STD_LOGIC_VECTOR(17 DOWNTO 0);
    SIGNAL input_buffer  : STD_LOGIC_VECTOR(31 DOWNTO 0);
    signal tb_output_data : std_logic_vector(31 downto 0); -- Data to output port
    -- Address Mux Signals
    SIGNAL addr_mux1_out : STD_LOGIC_VECTOR(17 DOWNTO 0);
    SIGNAL mem_addr_final: STD_LOGIC_VECTOR(17 DOWNTO 0);
    
    -- Write Data Mux Signals
    SIGNAL ccr_padded    : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL pc_plus_one   : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL data_mux_out  : STD_LOGIC_VECTOR(31 DOWNTO 0); -- Selects between RS2 and CCR
    SIGNAL pc_mux_out    : STD_LOGIC_VECTOR(31 DOWNTO 0); -- Selects between PC and PC+1
    SIGNAL mem_data_final: STD_LOGIC_VECTOR(31 DOWNTO 0); -- Final Write Data
    
    -- Unpack control signals
    ALIAS wd_select    : STD_LOGIC IS mem_signals_in(6); -- Controls Final Mux (Data vs PC path)
    ALIAS mem_read     : STD_LOGIC IS mem_signals_in(5);
    ALIAS mem_write    : STD_LOGIC IS mem_signals_in(4);
    ALIAS stack_read   : STD_LOGIC IS mem_signals_in(3);
    ALIAS stack_write  : STD_LOGIC IS mem_signals_in(2);
    ALIAS ccr_store    : STD_LOGIC IS mem_signals_in(1); -- Controls Data Mux (Rs2 vs CCR)
    ALIAS ccr_load     : STD_LOGIC is mem_signals_in(0);
    ALIAS pc_select    : STD_LOGIC IS wb_signals_in(0);  -- Controls PC Mux (PC vs PC+1)
    
BEGIN

    -- 1. Stack Pointer Instance
    SP_INST : stack_pointer
        PORT MAP (
            clk         => clk,
            reset       => reset,
            stack_read  => stack_read,
            stack_write => stack_write,
            ccr_load => ccr_load,
            ccr_store => ccr_store,
            sp_out      => sp_current
        );
        
    sp_out_debug <= sp_current;
    OUT_PORT : output_port
    GENERIC MAP (DATA_SIZE => 32)
    PORT MAP (
        enable => output_signal,
        data_in => rs2_data_in,
        data_out => tb_output_data
    );
    output_data <= tb_output_data; -- for tb observation


    -- ========================================================================
    -- 3. Address Generation Logic
    -- ========================================================================
    
    -- Mux 1: Source Selection (ALU vs SP)
    -- If Stack Operation (Push/Pop), select SP. Otherwise ALU.
    -- (Note: For POP, stack_pointer logic might imply SP+1, but here we strictly follow "Use SP as address" 
    --  and let the pointer update logic handle the post/pre increment nature via the component's internal timing 
    --  or we assume SP is correct for the operation. Given prompt: "Stack PUSH/POP: The circuit uses SP as the address.")
    PROCESS (stack_read, stack_write, sp_current, alu_result_in, ccr_load, ccr_store)
    BEGIN
        IF stack_read = '1' OR stack_write = '1' or ccr_load='1' or ccr_store='1' THEN
             addr_mux1_out <= sp_current;
             -- Refinement: If Pop (Empty Descending), we might need SP+1. 
             -- But adhering to "Circuit uses SP as address", we output SP. 
             -- If this is wrong, we fix it based on stack behavior, but strict circuit compliance is prioritized.
             -- *Modification*: For POP (StackRead), we usually access SP+1 in Empty Descending. 
             -- However, let's assume strict diagram compliance if possible.
             -- Diagram says: "Source Selection: ... select between ALU res and SP".
             -- It does NOT mention SP+1. So use SP.
        ELSE
             addr_mux1_out <= alu_result_in(17 DOWNTO 0); 
        END IF;
    END PROCESS;
    
    -- Mux 2: Interrupt Override
    -- Selects between Mux1 Output and Hardcoded 1.
    -- Controlled by Interrupt signal.
    PROCESS (interrupt, addr_mux1_out)
    BEGIN
        IF interrupt = '1' THEN
            mem_addr_final <= std_logic_vector(to_unsigned(1, 18));
        ELSE
            mem_addr_final <= addr_mux1_out;
        END IF;
    END PROCESS;

    -- ========================================================================
    -- 4. Write Data Selection Logic
    -- ========================================================================
    
    -- Prepare Data Inputs
    ccr_padded <= (31 downto 3 => '0') & ccr_in;
    pc_plus_one <= std_logic_vector(unsigned(pc_in) + 1);
    
    -- Mux A: General Data vs CCR
    -- Selects between RS2 and CCR.
    PROCESS (ccr_store, rs2_data_in, ccr_padded)
    BEGIN
        IF ccr_store = '1' THEN
            data_mux_out <= ccr_padded;
        ELSE
            data_mux_out <= rs2_data_in;
        END IF;
    END PROCESS;
    
    -- Mux B: Program Counter Selection
    -- Selects between PC and PC+1.
    PROCESS (pc_select, pc_in, pc_plus_one)
    BEGIN
        IF pc_select = '1' THEN
            pc_mux_out <= pc_plus_one;
        ELSE
            pc_mux_out <= pc_in;
        END IF;
    END PROCESS;
    
    -- Mux C: Final Selection (WriteData Select)
    -- Selects between Data/CCR path and PC path.
    PROCESS (wd_select, data_mux_out, pc_mux_out)
    BEGIN
        IF wd_select = '1' THEN
            mem_data_final <= pc_mux_out;
        ELSE
            mem_data_final <= data_mux_out;
        END IF;
    END PROCESS;

    -- ========================================================================
    -- 5. Memory Interface Request
    -- ========================================================================
    mem_req.addr       <= mem_addr_final;
    mem_addr_out    <= mem_addr_final; -- Output for interface
    mem_req.read_req   <= mem_read OR stack_read; -- "OR gate combines... MEM Read is driven by control..."
    mem_req.write_req  <= mem_write OR stack_write; -- Logic implies these enable access
    mem_req.write_data <= mem_data_final;

    -- ========================================================================
    -- 6. Outputs
    -- ========================================================================
    
    -- Read Data Mux (Memory vs Input Port) - Kept from previous logical requirement

    -- Output Port Logic (Direct mapping from Rs2, or from Write Data?)
    -- Diagram explanation for Write Data says "prepares payload to be written to memory".
    -- Output Port usually takes Rs2.
    out_port_data <= rs2_data_in WHEN output_signal = '1' ELSE (others => '0');

    -- Pass-throughs
    wb_signals_out <= wb_signals_in;
    alu_result_out <= alu_result_in;
    rd_addr_out    <= rd_addr_in;

    read_data_out <= mem_resp.read_data;
    write_data_to_interface<=mem_data_final;
END ARCHITECTURE Structural;
