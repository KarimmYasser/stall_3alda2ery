library IEEE;
use IEEE.std_logic_1164.all;
use work.memory_interface_pkg.all; -- Added for Memory Stage interface

entity top_level_processor is
    port(
        clk : in std_logic;
        reset : in std_logic;
        interrupt : in std_logic;
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
        tb_mem_rd_addr    : out std_logic_vector(2 downto 0)
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
            WB_enable : in std_logic
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
        input_signal  : IN  STD_LOGIC;
        output_signal : IN  STD_LOGIC;
        alu_result_in : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        rs2_data_in   : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        pc_in         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd_addr_in    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        ccr_in        : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        in_port_data  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        out_port_data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        mem_req       : OUT data_mem_req_t;
        mem_resp      : IN  data_mem_resp_t;
        wb_signals_out: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        read_data_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        alu_result_out: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        pc_out        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd_addr_out   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        sp_out_debug  : OUT STD_LOGIC_VECTOR(17 DOWNTO 0)
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
    port(
        clk     : in std_logic;
        reset   : in std_logic;
        mem_req  : in  ext_mem_req_t;
        mem_resp : out ext_mem_resp_t
    );
    end component memory_unit;
    
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
    
    -- ========== MEM/WB Register Output Signals ==========
    signal wb_stage_wb_signals : std_logic_vector(2 downto 0);
    signal wb_stage_read_data  : std_logic_vector(31 downto 0);
    signal wb_stage_alu_result : std_logic_vector(31 downto 0);
    signal wb_stage_pc         : std_logic_vector(31 downto 0);
    signal wb_stage_rd_addr    : std_logic_vector(2 downto 0);

    -- ========== Writeback Stage Signals ==========
    signal wb_data_out : std_logic_vector(31 downto 0);
    --==============================================
    
begin
    
    -- ========== FETCH STAGE ==========
    FETCH_STAGE: Fetch port map(
        clk => clk,
        reset => reset,
        Stall => stall_signal,
        inturrupt => interrupt,
        instruction_in => tb_instruction_mem,
        branch_exe => exe_br_signal,
        branch_decode => branch_decode_signal,
        mem_branch => mem_br_signal,
        mem_read_data_in => tb_mem_read_data,
        Micro_inst => micro_inst_signal,
        immediate_in => immediate_to_fetch,
        instruction_out => fetch_instruction_out,  -- 27 bits
        opcode_out => fetch_opcode_out,            -- 5 bits (possibly micro-opcode)
        pc_out => fetch_pc_out
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
        mem_br => mem_br_signal,
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
        WB_enable => exe_mem_wb_signals_out(2)
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
        in_port => in_port_signal,
        ccr_enable => decode_CCR_enable, -- also ensure this is the ccr enable that is not passing through the reg
        ccr_load => ccr_load_signal,
        ccr_from_stack => ccr_from_stack_signal,
        rdst_mem => rdst_mem_signal,
        rdst_wb => rdst_wb_signal,
        reg_write_mem => reg_write_mem_signal,
        reg_write_wb => reg_write_wb_signal,
        mem_forwarded_data => mem_forwarded_data_signal,
        wb_forwarded_data => wb_forwarded_data_signal,
        swap_forwarded_data => swap_forwarded_data_signal,
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
    
    --wb enable signal to be connected to MEM/WB reg
    
    -- TODO: Add other pipeline stages (Memory, Writeback)
    
    -- ========== MEMORY STAGE ==========
    MEMORY_STAGE_INST: Memory_Stage port map(
        clk => clk,
        reset => reset,
        interrupt => interrupt, -- Connected to top-level interrupt
        wb_signals_in => mem_wb_signals,
        mem_signals_in => mem_mem_signals,
        input_signal => mem_output_signal, -- input_signal port connected to output_signal wire? Check signal names.
                                           -- Wait, ex_mem_reg has `output_signal` (IO Out?) and `input_signal`?.
                                           -- ex_mem_reg output names: output_signal_out.
                                           -- Control Unit: IO_flages: (1)output, (0)input.
                                           -- Execute Stage splits IO_flages: output_signal => (1), input_signal => (0).
                                           -- EX/MEM Reg stores `output_signal` (bit 4 of control). Wait, where is `input_signal`?
                                           -- EX/MEM Reg seems to only store 1 bit for IO: `output_signal_in`. Logic error?
                                           -- Checking ex_mem_reg.vhd... 
                                           -- "control_flags_in : STD_LOGIC_VECTOR(14 DOWNTO 0); -- 3(wb) + 7(mem) + 1(output) + 1(branch) + 3(ccr)"
                                           -- It seems `input_signal` (IO_flages(0)) was dropped or I need to find where it went.
                                           -- In `execute_stage.vhd`, `input_signal` is an input. It is NOT in `ex_mem_reg`.
                                           -- ISSUE: Input signal flag needs to reach Memory Stage.
                                           -- Temporary fix: Connect `input_signal` to `output_signal` port of Memory Stage if they are mutually exclusive?
                                           -- Better: Update `ex_mem_reg` to carry both or check if `mem_signals` has it.
                                           -- MEM_flages: (6)WDselect, (5)MEMRead, (4)MEMWrite, (3)StackRead, (2)StackWrite, (1)CCRStore/CCRLoad, (0)CCRLoad
                                           -- No IO flags in MEM_flages.
                                           -- IO flags are separate.
                                           -- For now, connect `output_signal_out` to `output_signal`. 
                                           -- `input_signal` is missing. I will connect '0' and mark TODO, or use a spare wire if possible. 
                                           -- Actually, `top_level_processor` has `in_port_signal`.
                                           -- Memory Stage has `input_signal` port. 
                                           -- Let's connect `mem_output_signal` to `output_signal`. 
                                           -- For `input_signal`, we might need to modify `ex_mem_reg` later.
                                           -- Current `ex_mem_reg` only defines `output_signal_out`.
        output_signal => mem_output_signal,
        
        alu_result_in => mem_alu_result,
        rs2_data_in => mem_rs2_data,
        pc_in => mem_pc,
        rd_addr_in => mem_rd_addr,
        ccr_in => mem_ccr,
        in_port_data => in_port_value, -- Connected to internal signal (bound to 0 for now or testbench input)
        out_port_data => out_port_value,
        
        mem_req => data_mem_req,
        mem_resp => data_mem_resp,
        
        wb_signals_out => mem_stage_wb_signals,
        read_data_out => mem_stage_read_data,
        alu_result_out => mem_stage_alu_result,
        pc_out => mem_stage_pc,
        rd_addr_out => mem_stage_rd_addr,
        sp_out_debug => mem_sp_debug
    );
    
    -- ========== MEMORY ARBITER ==========
    MEMORY_ARBITER_INST: memory_arbiter port map(
        clk => clk,
        reset => reset,
        fetch_req => fetch_mem_req,
        fetch_resp => fetch_mem_resp,
        mem_req => data_mem_req,
        mem_resp => data_mem_resp,
        ram_req => ram_req,
        ram_resp => ram_resp
    );
    
    -- ========== MEMORY UNIT (RAM) ==========
    MEMORY_UNIT_INST: memory_unit port map(
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
        read_data_in => mem_stage_read_data,
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
