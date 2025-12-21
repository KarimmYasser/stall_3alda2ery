library IEEE;
use IEEE.std_logic_1164.all;
use work.memory_interface_pkg.all; -- Added for Memory Stage interface

entity top_level_processor is
    generic (
        INIT_FILENAME : string := "../assembler/output/test_output.mem"
    );
    port(
        clk : in std_logic;
        reset : in std_logic;
        interrupt : in std_logic;
        inputport_data : in std_logic_vector (31 downto 0);
        -- Testbench access for instruction injection (for fetch stage)
        tb_instruction_mem : in std_logic_vector(31 downto 0);
        -- Memory read data (for branches from memory stage)
        tb_mem_read_data : in std_logic_vector(31 downto 0) := (others => '0');
        
        -- Execute stage outputs for testbench observation
        tb_exe_alu_result : out std_logic_vector(31 downto 0);
        tb_exe_ccr : out std_logic_vector(2 downto 0);
        tb_exe_branch_taken : out std_logic;
        tb_exe_rd_addr : out std_logic_vector(2 downto 0);
        
        tb_mem_wb_signals : out std_logic_vector(2 downto 0);
        tb_mem_stage_read_data_out  : out std_logic_vector(31 downto 0);
        tb_mem_alu_result : out std_logic_vector(31 downto 0);
        tb_mem_rd_addr    : out std_logic_vector(2 downto 0);

        dbg_pc : out std_logic_vector(31 downto 0);
        dbg_fetched_instruction : out std_logic_vector(31 downto 0);
        dbg_sp : out std_logic_vector(17 downto 0);
        dbg_stall : out std_logic;
        dbg_ram_addr : out std_logic_vector(17 downto 0);
        dbg_ram_read_en : out std_logic;
        dbg_ram_write_en : out std_logic;
        dbg_ram_data_in : out std_logic_vector(31 downto 0);
        dbg_ram_data_out : out std_logic_vector(31 downto 0)
    );
end entity top_level_processor;

architecture structural of top_level_processor is
    
    -- Component: Fetch Stage (split instruction/opcode outputs)
    component Fetch is 
        port(
            clk : in std_logic;
            reset : in std_logic;
            Stall : in std_logic;
            inturrupt : in std_logic; 
            instruction_in : in std_logic_vector(31 downto 0);
            branch_exe : in std_logic;
            branch_decode: in std_logic;
            mem_branch : in std_logic;
            mem_read_data_in : in std_logic_vector(31 downto 0);
            Micro_inst : in std_logic_vector(4 downto 0);
            immediate_in : in std_logic_vector(31 downto 0);
            instruction_out : out std_logic_vector(26 downto 0);  -- Split output
            opcode_out : out std_logic_vector(4 downto 0);        -- Split output
            pc_out : out std_logic_vector(31 downto 0)
        );
    end component Fetch;
    -- fetch memory interface----
    component fetch_mem_interface is
    port(
        -- Clock and reset
        clk             : in std_logic;
        reset           : in std_logic;
        
        -- Fetch stage signals
        pc              : in  std_logic_vector(31 downto 0);  -- Program counter
        fetch_enable    : in  std_logic;                       -- Enable fetch
        instruction     : out std_logic_vector(31 downto 0);  -- Fetched instruction
        fetch_stall     : out std_logic;                       -- Stall to fetch stage
        
        -- Arbiter interface using record type
        arb_if          : out fetch_mem_req_t;                 -- Request to arbiter
        arb_resp        : in  fetch_mem_resp_t                 -- Response from arbiter
    );
    end component fetch_mem_interface;

    -- Component: IF/ID Pipeline Register (now with split instruction/opcode)
    component if_id_register is
    PORT (
        clk             : IN  STD_LOGIC;
        reset           : IN  STD_LOGIC;
        write_enable    : IN  STD_LOGIC;
        instruction_in  : IN  STD_LOGIC_VECTOR(26 DOWNTO 0);
        opcode_in       : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
        pc_in           : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        instruction_out : OUT STD_LOGIC_VECTOR(26 DOWNTO 0);
        opcode_out      : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        pc_out          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
    end component if_id_register;
    
    -- Component: Decode Stage (now with split inputs)
    component Decode is 
        port(
            inturrupt : in std_logic;
            reset: in std_logic;
            clk: in std_logic;
            instruction : in std_logic_vector(26 downto 0);
            opcode : in std_logic_vector(4 downto 0);
            PC : in std_logic_vector(31 downto 0);
            mem_br: in std_logic;
            exe_br: in std_logic;    
            FD_enable : out std_logic;
            Stall :out std_logic;
            DE_enable :out  std_logic;
            EM_enable : out std_logic;
            MW_enable :out std_logic;
            Branch_Decode: out std_logic;
            Micro_inst_out: out std_logic_vector(4 downto 0);
            WB_flages_out: out std_logic_vector(2 downto 0);
            EXE_flages_out: out std_logic_vector(5 downto 0);
            MEM_flages_out: out std_logic_vector(6 downto 0);
            IO_flages_out: out std_logic_vector(1 downto 0);
            Branch_Exec_out: out std_logic_vector(3 downto 0);
            CCR_enable_out: out std_logic;
            Imm_hazard_out: out std_logic;
            FU_enable_out: out std_logic;
            Rrs1_out: out std_logic_vector(31 downto 0);
            Rrs2_out: out std_logic_vector(31 downto 0);
            index_out: out std_logic_vector(1 downto 0);
            pc_out: out std_logic_vector(31 downto 0);
            rs1_addr_out: out std_logic_vector(2 downto 0);
            rs2_addr_out: out std_logic_vector(2 downto 0);
            rd_addr_out: out std_logic_vector(2 downto 0);
            CSwap_out: out std_logic;
            WB_value : in std_logic_vector(31 downto 0);
            WB_enable : in std_logic;
            WB_addr :in std_logic_vector (2 downto 0) 
        );
    end component Decode;
    
    -- Component: ID/EX Pipeline Register
    component execute_stage is
    port (
        clk : in std_logic;
        rst : in std_logic;
        flush : in std_logic;
        predict : in std_logic_vector(1 downto 0);
        wb_signals : in std_logic_vector(2 downto 0);
        mem_signals : in std_logic_vector(6 downto 0);
        exe_signals : in std_logic_vector(5 downto 0);
        output_signal : in std_logic;
        input_signal : in std_logic;
        swap_signal : in std_logic;
        branch_opcode : in std_logic_vector(3 downto 0);
        rs1_data : in std_logic_vector(31 downto 0);
        rs2_data : in std_logic_vector(31 downto 0);
        index : in std_logic_vector(1 downto 0);
        pc : in std_logic_vector(31 downto 0);
        rs1_addr : in std_logic_vector(2 downto 0);
        rs2_addr : in std_logic_vector(2 downto 0);
        rd_addr : in std_logic_vector(2 downto 0);
        immediate : in std_logic_vector(31 downto 0);
        in_port : in std_logic_vector(31 downto 0);
        ccr_enable : in std_logic;
        ccr_load : in std_logic;
        ccr_from_stack : in std_logic_vector(2 downto 0);
        rdst_mem : in std_logic_vector(2 downto 0);
        rdst_wb : in std_logic_vector(2 downto 0);
        reg_write_mem : in std_logic;
        reg_write_wb : in std_logic;
        mem_forwarded_data : in std_logic_vector(31 downto 0);
        wb_forwarded_data : in std_logic_vector(31 downto 0);
        swap_forwarded_data : in std_logic_vector(31 downto 0);
        ex_mem_wb_signals : out std_logic_vector(2 downto 0);
        ex_mem_mem_signals : out std_logic_vector(6 downto 0);
        ex_mem_output_signal : out std_logic;
        ex_mem_branch_taken : out std_logic;
        ex_mem_ccr : out std_logic_vector(2 downto 0);
        ex_mem_rs2_data : out std_logic_vector(31 downto 0);
        ex_mem_alu_result : out std_logic_vector(31 downto 0);
        ex_mem_pc : out std_logic_vector(31 downto 0);
        ex_mem_rd_addr : out std_logic_vector(2 downto 0);
        branch_enable : out std_logic
    );
    end component execute_stage;
    
    component id_ex_reg_with_feedback is
    PORT (
        clk             : IN  STD_LOGIC;
        reset           : IN  STD_LOGIC;
        write_enable    : IN  STD_LOGIC;
        WB_flages_in    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        EXE_flages_in   : IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
        FU_enable_in    : IN  STD_LOGIC;
        MEM_flages_in   : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
        IO_flages_in    : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        Branch_Exec_in  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        CSwap_in        : IN  STD_LOGIC;
        WB_flages_out   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        EXE_flages_out  : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
        MEM_flages_out  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        IO_flages_out   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        Branch_Exec_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        CSwap_out       : OUT STD_LOGIC;
        FU_enable_out   : OUT STD_LOGIC;
        Rrs1_in         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        Rrs2_in         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        index_in        : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        pc_in           : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        rs1_addr_in     : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        rs2_addr_in     : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        rd_addr_in      : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        Rrs1_out        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        Rrs2_out        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        index_out       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        pc_out          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rs1_addr_out    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        rs2_addr_out    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        rd_addr_out     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
    end component id_ex_reg_with_feedback;
    
    -- Component: EX/MEM Pipeline Register
    component ex_mem_reg is
    PORT (
        clk                  : IN  STD_LOGIC;
        reset                : IN  STD_LOGIC;
        write_enable         : IN  STD_LOGIC;
        wb_signals_in        : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        mem_signals_in       : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
        output_signal_in     : IN  STD_LOGIC;
        branch_taken_in      : IN  STD_LOGIC;
        ccr_in               : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        wb_signals_out       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        mem_signals_out      : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        output_signal_out    : OUT STD_LOGIC;
        branch_taken_out     : OUT STD_LOGIC;
        ccr_out              : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        rs2_data_in          : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        alu_result_in        : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        pc_in                : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd_addr_in           : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        rs2_data_out         : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        alu_result_out       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        pc_out               : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd_addr_out          : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
    end component ex_mem_reg;
    
    -- Component: Memory Stage
    component Memory_Stage is
    PORT (
        clk           : IN  STD_LOGIC;
        reset         : IN  STD_LOGIC;
        interrupt     : IN  STD_LOGIC; -- Added Interrupt Port
        wb_signals_in : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        mem_signals_in: IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
        output_signal : IN  STD_LOGIC;
        alu_result_in : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        rs2_data_in   : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        pc_in         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd_addr_in    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        ccr_in        : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        out_port_data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        mem_req       : OUT data_mem_req_t;
        mem_resp      : IN  data_mem_resp_t;
        wb_signals_out: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        read_data_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        alu_result_out: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd_addr_out   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        sp_out_debug  : OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
        mem_addr_out   : OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
        output_data : out std_logic_vector(31 downto 0);
        write_data_to_interface : out std_logic_vector (31 downto 0)
    );
    end component Memory_Stage;

    -- Component: Memory Arbiter
    component memory_arbiter is
    port(
        clk     : in std_logic;
        reset   : in std_logic;
        fetch_req       : in  fetch_mem_req_t;
        fetch_resp      : out fetch_mem_resp_t;
        mem_req         : in  data_mem_req_t;
        mem_resp        : out data_mem_resp_t;
        ram_req         : out ext_mem_req_t;
        ram_resp        : in  ext_mem_resp_t
    );
    end component memory_arbiter;

    -- Component: MEM/WB Pipeline Register
    component mem_wb_reg is
    PORT (
        clk             : IN  STD_LOGIC;
        reset           : IN  STD_LOGIC;
        write_enable    : IN  STD_LOGIC;
        wb_signals_in        : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        read_data_in         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        alu_result_in        : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        pc_in                : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd_addr_in           : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        wb_signals_out       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        read_data_out        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        alu_result_out       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        pc_out               : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd_addr_out          : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
    end component mem_wb_reg;
    
    -- Component: Memory Unit (RAM)
    component memory_unit is
    generic (
        INIT_FILENAME : string := "test_output.mem";
        MEMORY_DEPTH  : integer := 262144
    );
    port(
        clk     : in std_logic;
        reset   : in std_logic;
        mem_req  : in  ext_mem_req_t;
        mem_resp : out ext_mem_resp_t
    );
    end component memory_unit;
        --================ Data Memory Interface ==================
    component data_mem_interface is
    port(
        -- Clock and reset
        clk             : in std_logic;
        reset           : in std_logic;
        
        -- Memory stage signals
        mem_addr        : in  std_logic_vector(31 downto 0);  -- Address (from ALU/SP)
        mem_read        : in  std_logic;                       -- Load operation
        mem_write       : in  std_logic;                       -- Store operation
        mem_write_data  : in  std_logic_vector(31 downto 0);  -- Data to store
        mem_read_data   : out std_logic_vector(31 downto 0);  -- Data loaded
        mem_stall       : out std_logic;                       -- Stall to memory stage
        
        -- Arbiter interface using record types
        arb_if          : out data_mem_req_t;                  -- Request to arbiter
        arb_resp        : in  data_mem_resp_t                  -- Response from arbiter
    );
    end component data_mem_interface;
    
    -- Component: Writeback Stage
   -- ===============================================
        component writeback is
        port(
            mem_read_data  : in  std_logic_vector(31 downto 0);
            alu_result     : in  std_logic_vector(31 downto 0);
            wb_select      : in  std_logic;
            wb_data        : out std_logic_vector(31 downto 0)
        );
        end component writeback;


    -- =================================================
    

    -- ========== Fetch Stage Signals ==========
    signal fetch_instruction_out : std_logic_vector(26 downto 0);  -- Lower 27 bits
    signal fetch_opcode_out : std_logic_vector(4 downto 0);        -- Top 5 bits (may be micro)
    signal fetch_pc_out : std_logic_vector(31 downto 0);
    
    -- Feedback signals from Decode to Fetch
    signal stall_signal : std_logic;
    signal branch_decode_signal : std_logic;
    signal micro_inst_signal : std_logic_vector(4 downto 0);
    signal immediate_to_fetch : std_logic_vector(31 downto 0) := (others => '0');
    
        --==========fetch memory interface signals=========
    signal fetch_mem_interface_pc: std_logic_vector(31 downto 0);
    signal fetch_mem_interface_enable: std_logic:='1';
    signal fetch_mem_interface_instruction: std_logic_vector(31 downto 0);
    signal fetch_mem_interface_stall: std_logic :='0';
    signal fetch_mem_interface_arb_if: fetch_mem_req_t;
    signal fetch_mem_interface_arb_resp: fetch_mem_resp_t;
    signal fetch_enable_signal : std_logic;
    --====================================================================

    -- ========== IF/ID Register Signals ==========
    signal ifid_instruction_out : std_logic_vector(26 downto 0);  -- Lower 27 bits
    signal ifid_opcode_out : std_logic_vector(4 downto 0);        -- Top 5 bits
    signal ifid_pc_out : std_logic_vector(31 downto 0);
    signal FD_enable_signal : std_logic;
    
    -- ========== Decode Stage Signals ==========
    -- Signals between Decode and ID/EX register
    signal decode_instruction : std_logic_vector(31 downto 0);
    signal decode_PC : std_logic_vector(31 downto 0);
    signal decode_DE_enable : std_logic;
    signal decode_WB_flages : std_logic_vector(2 downto 0);
    signal decode_EXE_flages : std_logic_vector(5 downto 0);
    signal decode_MEM_flages : std_logic_vector(6 downto 0);
    signal decode_IO_flages : std_logic_vector(1 downto 0);
    signal decode_Branch_Exec : std_logic_vector(3 downto 0);
    signal decode_CCR_enable : std_logic;
    signal decode_Imm_hazard : std_logic;
    signal decode_FU_enable : std_logic;
    signal decode_Rrs1 : std_logic_vector(31 downto 0);
    signal decode_Rrs2 : std_logic_vector(31 downto 0);
    signal decode_index : std_logic_vector(1 downto 0);
    signal decode_pc_out : std_logic_vector(31 downto 0);
    signal decode_rs1_addr : std_logic_vector(2 downto 0);
    signal decode_rs2_addr : std_logic_vector(2 downto 0);
    signal decode_rd_addr : std_logic_vector(2 downto 0);
    signal decode_CSwap : std_logic;
    signal EM_enable_signal : std_logic;
    signal MW_enable_signal : std_logic;
    -- Signals from ID/EX register to Execute stage
    signal exe_WB_flages : std_logic_vector(2 downto 0);
    signal exe_EXE_flages : std_logic_vector(5 downto 0);
    signal exe_MEM_flages : std_logic_vector(6 downto 0);
    signal exe_IO_flages : std_logic_vector(1 downto 0);
    signal exe_Branch_Exec : std_logic_vector(3 downto 0);
    signal exe_FU_enable : std_logic;
    signal exe_Rrs1 : std_logic_vector(31 downto 0);
    signal exe_Rrs2 : std_logic_vector(31 downto 0);
    signal exe_index : std_logic_vector(1 downto 0);
    signal exe_pc : std_logic_vector(31 downto 0);
    signal exe_rs1_addr : std_logic_vector(2 downto 0);
    signal exe_rs2_addr : std_logic_vector(2 downto 0);
    signal exe_rd_addr : std_logic_vector(2 downto 0);
    
    -- ========== Execute Stage Output Signals ==========
    signal exe_mem_wb_signals_out : std_logic_vector(2 downto 0);
    signal exe_mem_mem_signals_out : std_logic_vector(6 downto 0);
    signal exe_mem_output_signal_out : std_logic;
    signal exe_mem_branch_taken_out : std_logic;
    signal exe_mem_ccr_out : std_logic_vector(2 downto 0);
    signal exe_mem_rs2_data_out : std_logic_vector(31 downto 0);
    signal exe_mem_alu_result_out : std_logic_vector(31 downto 0);
    signal exe_mem_pc_out : std_logic_vector(31 downto 0);
    signal exe_mem_rd_addr_out : std_logic_vector(2 downto 0);
    signal exe_branch_enable : std_logic;
    signal tb_exe_output_port : std_logic_vector(31 downto 0);
    signal mem_forward_data : std_logic_vector(31 downto 0);
    -- ========== EX/MEM Register Output Signals ==========
    signal mem_wb_signals : std_logic_vector(2 downto 0);
    signal mem_mem_signals : std_logic_vector(6 downto 0);
    signal mem_output_signal : std_logic;
    signal mem_branch_taken : std_logic;
    signal mem_ccr : std_logic_vector(2 downto 0);
    signal mem_rs2_data : std_logic_vector(31 downto 0);
    signal mem_alu_result : std_logic_vector(31 downto 0);
    signal mem_pc : std_logic_vector(31 downto 0);
    signal mem_rd_addr : std_logic_vector(2 downto 0);
    --=============================================== mem branch signal
    signal mem_branch_signal : std_logic ;

    -- ========== Placeholder Signals ==========
    signal mem_br_signal : std_logic := '0';
    signal exe_br_signal : std_logic := '0';
    signal flush_signal : std_logic := '0';
    signal predict_signal : std_logic_vector(1 downto 0) := "00";
    signal immediate_signal : std_logic_vector(31 downto 0) := (others => '0');
    signal in_port_signal : std_logic_vector(31 downto 0) := (others => '0');
    signal set_carry_signal : std_logic := '0';
    signal ccr_load_signal : std_logic := '0';
    signal ccr_from_stack_signal : std_logic_vector(2 downto 0) := "000";
    signal rdst_mem_signal : std_logic_vector(2 downto 0) := "000";
    signal rdst_wb_signal : std_logic_vector(2 downto 0) := "000";
    signal reg_write_mem_signal : std_logic := '0';
    signal reg_write_wb_signal : std_logic := '0';
    signal mem_forwarded_data_signal : std_logic_vector(31 downto 0) := (others => '0');
    signal wb_forwarded_data_signal : std_logic_vector(31 downto 0) := (others => '0');
    signal swap_forwarded_data_signal : std_logic_vector(31 downto 0) := (others => '0');
    signal exe_swap_signal : std_logic;
    
    -- ========== Memory Stage Signals ==========
    signal mem_stage_wb_signals : std_logic_vector(2 downto 0);
    signal mem_stage_read_data  : std_logic_vector(31 downto 0);
    signal mem_stage_alu_result : std_logic_vector(31 downto 0);
    signal mem_stage_pc         : std_logic_vector(31 downto 0);
    signal mem_stage_rd_addr    : std_logic_vector(2 downto 0);
    signal mem_sp_debug         : std_logic_vector(17 downto 0);
     --====================Data Memory Interface Signals =================
    signal data_mem_interface_addr : std_logic_vector(17 downto 0);
    signal data_mem_interface_read : std_logic;
    signal data_mem_interface_write : std_logic;
    signal data_mem_interface_write_data : std_logic_vector(31 downto 0);
    signal data_mem_interface_read_data : std_logic_vector(31 downto 0);
    signal data_mem_interface_stall : std_logic :='0';
    signal data_mem_interface_arb_if : data_mem_req_t;
    signal data_mem_interface_arb_resp : data_mem_resp_t;
    signal write_data_to_interface_signal :std_logic_vector (31 downto 0);
    signal output_port_data_signal :std_logic_vector(31 downto 0);
    --==================================================================== 
    -- I/O Signals
    signal in_port_value  : std_logic_vector(31 downto 0) := (others => '0');
    signal out_port_value : std_logic_vector(31 downto 0);
    
    -- Memory Interface Signals
    signal fetch_mem_req   : fetch_mem_req_t;
    signal fetch_mem_resp  : fetch_mem_resp_t;
    signal data_mem_req    : data_mem_req_t;
    signal data_mem_resp   : data_mem_resp_t;
    signal ram_req         : ext_mem_req_t;
    signal ram_resp        : ext_mem_resp_t;
    signal address_out_mem : std_logic_vector(31 downto 0);
    -- ========== MEM/WB Register Output Signals ==========
    signal wb_stage_wb_signals : std_logic_vector(2 downto 0);
    signal wb_stage_read_data  : std_logic_vector(31 downto 0);
    signal wb_stage_alu_result : std_logic_vector(31 downto 0);
    signal wb_stage_pc         : std_logic_vector(31 downto 0);
    signal wb_stage_rd_addr    : std_logic_vector(2 downto 0);

    -- ========== Writeback Stage Signals ==========
    signal wb_data_out : std_logic_vector(31 downto 0);
    --==============================================
    signal mem_read_or_stack_read : std_logic;
    signal mem_write_or_stack_write : std_logic;
begin
    
    -- ========== FETCH STAGE ==========
    FETCH_STAGE: Fetch port map(
        clk => clk,
        reset => reset,
        Stall => stall_signal,
        inturrupt => interrupt,
        instruction_in => fetch_mem_interface_instruction, --tb_instruction_mem ,
        branch_exe => exe_br_signal,
        branch_decode => branch_decode_signal,
        mem_branch => mem_branch_signal,
        mem_read_data_in => data_mem_interface_read_data,
        Micro_inst => micro_inst_signal,
        immediate_in => immediate_signal,
        instruction_out => fetch_instruction_out,  -- 27 bits
        opcode_out => fetch_opcode_out,            -- 5 bits (possibly micro-opcode)
        pc_out => fetch_pc_out
    );
    fetch_mem_interface_pc <= fetch_pc_out;
    fetch_enable_signal <= not stall_signal;
    --======fetch interface =============
    fetch_memory_interface: fetch_mem_interface port map(
        clk => clk,
        reset => reset,
        pc => fetch_mem_interface_pc,
        fetch_enable => fetch_enable_signal,
        instruction => fetch_mem_interface_instruction,
        fetch_stall => fetch_mem_interface_stall,
        arb_if => fetch_mem_interface_arb_if,
        arb_resp => fetch_mem_interface_arb_resp
    );
    -- ========== IF/ID PIPELINE REGISTER ==========
    IF_ID_REG: if_id_register port map(
        clk => clk,
        reset => reset,
        write_enable => FD_enable_signal,
        instruction_in => fetch_instruction_out,   -- 27 bits from fetch
        opcode_in => fetch_opcode_out,             -- 5 bits from fetch (may be micro)
        pc_in => fetch_pc_out,
        instruction_out => ifid_instruction_out,
        opcode_out => ifid_opcode_out,
        pc_out => ifid_pc_out
    );
    
    -- ========== DECODE STAGE ==========
    DECODE_STAGE: Decode port map(
        clk => clk,
        reset => reset,
        inturrupt => interrupt,
        instruction => ifid_instruction_out,  -- 27 bits
        opcode => ifid_opcode_out,            -- 5 bits (may be micro-opcode)
        PC => ifid_pc_out,
        mem_br => mem_branch_signal,
        exe_br => exe_br_signal,
        FD_enable => FD_enable_signal,
        Stall => stall_signal,
        DE_enable => decode_DE_enable,
        EM_enable => EM_enable_signal,
        MW_enable => MW_enable_signal,
        Branch_Decode => branch_decode_signal,
        Micro_inst_out => micro_inst_signal,
        WB_flages_out => decode_WB_flages,
        EXE_flages_out => decode_EXE_flages,
        MEM_flages_out => decode_MEM_flages,
        IO_flages_out => decode_IO_flages,
        Branch_Exec_out => decode_Branch_Exec,
        CCR_enable_out => decode_CCR_enable,
        Imm_hazard_out => decode_Imm_hazard,
        FU_enable_out => decode_FU_enable,
        Rrs1_out => decode_Rrs1,
        Rrs2_out => decode_Rrs2,
        index_out => decode_index,
        pc_out => decode_pc_out,
        rs1_addr_out => decode_rs1_addr,
        rs2_addr_out => decode_rs2_addr,
        rd_addr_out => decode_rd_addr,
        CSwap_out => decode_CSwap,
        WB_value => wb_data_out,
        WB_enable => wb_stage_wb_signals(2),
        WB_addr =>wb_stage_rd_addr
    );
    
    -- ========== ID/EX PIPELINE REGISTER ==========
    ID_EX_REGISTER: id_ex_reg_with_feedback port map(
        clk => clk,
        reset => reset,
        write_enable => decode_DE_enable,
        WB_flages_in => decode_WB_flages,
        EXE_flages_in => decode_EXE_flages,
        FU_enable_in => decode_FU_enable,
        MEM_flages_in => decode_MEM_flages,
        IO_flages_in => decode_IO_flages,
        Branch_Exec_in => decode_Branch_Exec,
        CSwap_in => decode_CSwap,
        WB_flages_out => exe_WB_flages,
        EXE_flages_out => exe_EXE_flages,
        MEM_flages_out => exe_MEM_flages,
        IO_flages_out => exe_IO_flages,
        Branch_Exec_out => exe_Branch_Exec,
        CSwap_out => exe_swap_signal,
        FU_enable_out => exe_FU_enable,
        Rrs1_in => decode_Rrs1,
        Rrs2_in => decode_Rrs2,
        index_in => decode_index,
        pc_in => decode_pc_out,
        rs1_addr_in => decode_rs1_addr,
        rs2_addr_in => decode_rs2_addr,
        rd_addr_in => decode_rd_addr,
        Rrs1_out => exe_Rrs1,
        Rrs2_out => exe_Rrs2,
        index_out => exe_index,
        pc_out => exe_pc,
        rs1_addr_out => exe_rs1_addr,
        rs2_addr_out => exe_rs2_addr,
        rd_addr_out => exe_rd_addr
    );
    
    -- ========== EXECUTE STAGE ==========
    immediate_signal<= ifid_opcode_out & ifid_instruction_out;
    EXECUTE_STAGE_INST: execute_stage port map(
        clk => clk,
        rst => reset,
        flush => flush_signal,
        predict => predict_signal,
        wb_signals => exe_WB_flages,
        mem_signals => exe_MEM_flages,
        exe_signals => exe_EXE_flages,
        output_signal => exe_IO_flages(1), -- also ensure this order of io bits
        input_signal => exe_IO_flages(0),
        swap_signal => exe_swap_signal, -- Connected corrected signal
        branch_opcode => exe_Branch_Exec,
        rs1_data => exe_Rrs1,
        rs2_data => exe_Rrs2,
        index => exe_index,
        pc => exe_pc,
        rs1_addr => exe_rs1_addr,
        rs2_addr => exe_rs2_addr,
        rd_addr => exe_rd_addr,
        immediate => immediate_signal,
        in_port => inputport_data,
        ccr_enable => decode_CCR_enable, -- also ensure this is the ccr enable that is not passing through the reg
        ccr_load => ccr_load_signal,
        ccr_from_stack => ccr_from_stack_signal,
        rdst_mem => mem_stage_rd_addr, --#########################
        rdst_wb => wb_stage_rd_addr, --############
        reg_write_mem =>mem_wb_signals(2) , --##############
        reg_write_wb => wb_stage_wb_signals(2), --#########
        mem_forwarded_data => mem_forward_data, --##########
        wb_forwarded_data => wb_data_out , --######################
        swap_forwarded_data => swap_forwarded_data_signal, --?????????????????????????????????????????
        ex_mem_wb_signals => exe_mem_wb_signals_out,
        ex_mem_mem_signals => exe_mem_mem_signals_out,
        ex_mem_output_signal => exe_mem_output_signal_out,
        ex_mem_branch_taken => exe_mem_branch_taken_out,
        ex_mem_ccr => exe_mem_ccr_out,
        ex_mem_rs2_data => exe_mem_rs2_data_out,
        ex_mem_alu_result => exe_mem_alu_result_out,
        ex_mem_pc => exe_mem_pc_out,
        ex_mem_rd_addr => exe_mem_rd_addr_out,
        branch_enable => exe_branch_enable
    );
    
    -- Connect branch enable to exe_br_signal for feedback to fetch  
      exe_br_signal <= exe_branch_enable;
    -- ========== EX/MEM PIPELINE REGISTER ==========
    EX_MEM_REGISTER: ex_mem_reg port map(
        clk => clk,
        reset => reset,
        write_enable => EM_enable_signal,  -- TODO: Connect to EM_enable from decode
        wb_signals_in => exe_mem_wb_signals_out,
        mem_signals_in => exe_mem_mem_signals_out,
        output_signal_in => exe_mem_output_signal_out,
        branch_taken_in => exe_mem_branch_taken_out,
        ccr_in => exe_mem_ccr_out,
        wb_signals_out => mem_wb_signals,
        mem_signals_out => mem_mem_signals,
        output_signal_out => mem_output_signal,
        branch_taken_out => mem_branch_taken,
        ccr_out => mem_ccr,
        rs2_data_in => exe_mem_rs2_data_out,
        alu_result_in => exe_mem_alu_result_out,
        pc_in => exe_mem_pc_out,
        rd_addr_in => exe_mem_rd_addr_out,
        rs2_data_out => mem_rs2_data,
        alu_result_out => mem_alu_result,
        pc_out => mem_pc,
        rd_addr_out => mem_rd_addr
    );
    --branch signal
    mem_branch_signal <= (mem_mem_signals(5) or mem_mem_signals(4) ) and mem_branch_taken ;
    --wb enable signal to be connected to MEM/WB reg
    
    -- TODO: Add other pipeline stages (Memory, Writeback)
    
    -- ========== MEMORY STAGE ==========
    MEMORY_STAGE_INST: Memory_Stage port map(
        clk => clk,
        reset => reset,
        interrupt => interrupt, -- Connected to top-level interrupt
        wb_signals_in => mem_wb_signals,
        mem_signals_in => mem_mem_signals,
        output_signal => mem_output_signal,
        
        alu_result_in => mem_alu_result,
        rs2_data_in => mem_rs2_data,
        pc_in => mem_pc,
        rd_addr_in => mem_rd_addr,
        ccr_in => mem_ccr,
        out_port_data => out_port_value,
        
        mem_req => data_mem_req,
        mem_resp => data_mem_resp,
        
        wb_signals_out => mem_stage_wb_signals,
        read_data_out => mem_stage_read_data,
        alu_result_out => mem_stage_alu_result,
        rd_addr_out => mem_stage_rd_addr,
        sp_out_debug => mem_sp_debug,
        mem_addr_out => data_mem_interface_addr,
        output_data => output_port_data_signal,
        write_data_to_interface =>write_data_to_interface_signal
    );
    mem_forward_data <= mem_alu_result when mem_wb_signals(1)='0'else
                            data_mem_interface_read_data ;
---========= Data Memory Interface Instance ==========
address_out_mem <= (31 downto 18 => '0') & data_mem_interface_addr;
    DATA_MEMORY_INTERFACE_INST: data_mem_interface port map(
        clk => clk,
        reset => reset,
        mem_addr => address_out_mem,
        mem_read => mem_read_or_stack_read,  -- Load operation
        mem_write => mem_write_or_stack_write, -- Store operation
        mem_write_data => write_data_to_interface_signal,
        mem_read_data => data_mem_interface_read_data,
        mem_stall => data_mem_interface_stall,
        arb_if => data_mem_interface_arb_if,
        arb_resp => data_mem_interface_arb_resp
    );
  mem_read_or_stack_read <= (mem_mem_signals(5) or mem_mem_signals(3));
  mem_write_or_stack_write <= (mem_mem_signals(4) or mem_mem_signals(2));

    -- ========== MEMORY ARBITER ==========
    MEMORY_ARBITER_INST: memory_arbiter port map(
        clk => clk,
        reset => reset,
        fetch_req => fetch_mem_interface_arb_if,
        fetch_resp => fetch_mem_interface_arb_resp,
        mem_req => data_mem_interface_arb_if,  --####################
        mem_resp => data_mem_interface_arb_resp, --############################# kimo check pls
        ram_req => ram_req,
        ram_resp => ram_resp
    );
    
    -- ========== MEMORY UNIT
    -- Memory Unit
    MEMORY_UNIT_INST: memory_unit
    generic map(
        INIT_FILENAME => INIT_FILENAME,
        MEMORY_DEPTH => 262144
    )
    port map(
        clk => clk,
        reset => reset,
        mem_req => ram_req,
        mem_resp => ram_resp
    );
    
    -- ========== MEM/WB PIPELINE REGISTER ==========
    MEM_WB_REGISTER: mem_wb_reg port map(
        clk => clk,
        reset => reset,
        write_enable => MW_enable_signal, -- Always enable for now
        wb_signals_in => mem_stage_wb_signals,
        read_data_in => data_mem_interface_read_data,
        alu_result_in => mem_stage_alu_result,
        pc_in => mem_stage_pc,
        rd_addr_in => mem_stage_rd_addr,
        
        wb_signals_out => wb_stage_wb_signals,
        read_data_out => wb_stage_read_data,
        alu_result_out => wb_stage_alu_result,
        pc_out => wb_stage_pc,
        rd_addr_out => wb_stage_rd_addr
    );
    
    -- Connect testbench outputs for Execute stage
    tb_exe_alu_result <= exe_mem_alu_result_out;
    tb_exe_ccr <= exe_mem_ccr_out;
    tb_exe_branch_taken <= exe_mem_branch_taken_out;
    tb_exe_rd_addr <= exe_mem_rd_addr_out;
    
    -- Connect testbench outputs for Memory stage
    tb_mem_wb_signals <= wb_stage_wb_signals;
    tb_mem_stage_read_data_out <= wb_stage_read_data;
    tb_mem_alu_result <= wb_stage_alu_result;
    tb_mem_rd_addr <= wb_stage_rd_addr;

    dbg_pc <= fetch_pc_out;
    dbg_fetched_instruction <= fetch_mem_interface_instruction;
    dbg_sp <= mem_sp_debug;
    dbg_stall <= stall_signal;
    dbg_ram_addr <= ram_req.addr;
    dbg_ram_read_en <= ram_req.read_en;
    dbg_ram_write_en <= ram_req.write_en;
    dbg_ram_data_in <= ram_req.data_in;
    dbg_ram_data_out <= ram_resp.data_out;

    -- Writeback Stage

    WRITEBACK_STAGE_INST: writeback port map(
        mem_read_data => wb_stage_read_data,
        alu_result => wb_stage_alu_result,
        wb_select => wb_stage_wb_signals(1),  --confirmed
        -- TODO: MAZEN - Confirm wb_select bit position
        wb_data => wb_data_out
    );

    
    -- TODO: Extract immediate value from instruction for fetch stage (Fix Placeholder)

    
end architecture structural;
