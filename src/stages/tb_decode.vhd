library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;

entity tb_decode is
end entity tb_decode;

architecture testbench of tb_decode is
    -- Component declaration
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
            WB_flages_in : in std_logic_vector(2 downto 0);
            EXE_flages_in : in std_logic_vector(5 downto 0);
            MEM_flages_in : in std_logic_vector(6 downto 0);
            IO_flages_in : in std_logic_vector(1 downto 0);
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
            CSwap_out: out std_logic;
            CCR_enable_out: out std_logic;
            Imm_hazard_out: out std_logic;
            FU_enable_out: out std_logic;
            Rrs1_out: out std_logic_vector(31 downto 0);
            Rrs2_out: out std_logic_vector(31 downto 0);
            index_out: out std_logic_vector(1 downto 0);
            pc_out: out std_logic_vector(31 downto 0);
            rs1_addr_out: out std_logic_vector(2 downto 0);
            rs2_addr_out: out std_logic_vector(2 downto 0);
            rd_addr_out: out std_logic_vector(2 downto 0)
        );
    end component Decode;

    -- Test signals
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal inturrupt : std_logic := '0';
    signal instruction : std_logic_vector(31 downto 0) := (others => '0');
    signal PC : std_logic_vector(31 downto 0) := X"00000100";
    signal mem_br : std_logic := '0';
    signal exe_br : std_logic := '0';
    signal WB_flages_in : std_logic_vector(2 downto 0) := (others => '0');
    signal EXE_flages_in : std_logic_vector(5 downto 0) := (others => '0');
    signal MEM_flages_in : std_logic_vector(6 downto 0) := (others => '0');
    signal IO_flages_in : std_logic_vector(1 downto 0) := (others => '0');
    
    -- Output signals
    signal FD_enable : std_logic;
    signal Stall : std_logic;
    signal DE_enable : std_logic;
    signal EM_enable : std_logic;
    signal MW_enable : std_logic;
    signal Branch_Decode : std_logic;
    signal Micro_inst : std_logic_vector(4 downto 0);
    signal mem_usage_predict : std_logic;
    signal imm_predict : std_logic;
    signal WB_flages : std_logic_vector(2 downto 0);
    signal EXE_flages : std_logic_vector(5 downto 0);
    signal MEM_flages : std_logic_vector(6 downto 0);
    signal IO_flages : std_logic_vector(1 downto 0);
    signal Branch_Exec : std_logic_vector(3 downto 0);
    signal CCR_enable : std_logic;
    signal Imm_hazard : std_logic;
    signal FU_enable : std_logic;
    signal Rrs1 : std_logic_vector(31 downto 0);
    signal Rrs2 : std_logic_vector(31 downto 0);
    signal index : std_logic_vector(1 downto 0);
    signal pc_out_main : std_logic_vector(31 downto 0);
    signal rs1_addr : std_logic_vector(2 downto 0);
    signal rs2_addr : std_logic_vector(2 downto 0);
    signal rd_addr : std_logic_vector(2 downto 0);
    
    -- Clock period
    constant clk_period : time := 10 ns;
    
    -- Procedure to log outputs
    procedure log_outputs(
        constant inst_name : in string;
        constant opcode : in std_logic_vector(4 downto 0);
        signal p_instruction : in std_logic_vector(31 downto 0);
        signal p_fd_enable : in std_logic;
        signal p_stall : in std_logic;
        signal p_de_enable : in std_logic;
        signal p_em_enable : in std_logic;
        signal p_mw_enable : in std_logic;
        signal p_branch_decode : in std_logic;
        signal p_wb_flages : in std_logic_vector(2 downto 0);
        signal p_exe_flages : in std_logic_vector(5 downto 0);
        signal p_mem_flages : in std_logic_vector(6 downto 0);
        signal p_io_flages : in std_logic_vector(1 downto 0);
        signal p_branch_exec : in std_logic_vector(3 downto 0);
        signal p_index : in std_logic_vector(1 downto 0);
        signal p_rd_addr : in std_logic_vector(2 downto 0);
        signal p_rs1_addr : in std_logic_vector(2 downto 0);
        signal p_rs2_addr : in std_logic_vector(2 downto 0)
    ) is
        variable l : line;
    begin
        write(l, string'("========================================"));
        writeline(output, l);
        write(l, string'("Instruction: ") & inst_name);
        writeline(output, l);
        write(l, string'("Opcode: "));
        write(l, opcode);
        writeline(output, l);
        write(l, string'("Full Instruction: "));
        hwrite(l, p_instruction);
        writeline(output, l);
        write(l, string'("----------------------------------------"));
        writeline(output, l);
        write(l, string'("Pipeline Control Signals:"));
        writeline(output, l);
        write(l, string'("  FD_enable    : ") & std_logic'image(p_fd_enable));
        writeline(output, l);
        write(l, string'("  DE_enable    : ") & std_logic'image(p_de_enable));
        writeline(output, l);
        write(l, string'("  EM_enable    : ") & std_logic'image(p_em_enable));
        writeline(output, l);
        write(l, string'("  MW_enable    : ") & std_logic'image(p_mw_enable));
        writeline(output, l);
        write(l, string'("  Stall        : ") & std_logic'image(p_stall));
        writeline(output, l);
        write(l, string'("  Branch_Decode: ") & std_logic'image(p_branch_decode));
        writeline(output, l);
        write(l, string'("----------------------------------------"));
        writeline(output, l);
        write(l, string'("Register Addresses:"));
        writeline(output, l);
        write(l, string'("  rd  [8:6]  : "));
        write(l, p_rd_addr);
        writeline(output, l);
        write(l, string'("  rs1 [5:3]  : "));
        write(l, p_rs1_addr);
        writeline(output, l);
        write(l, string'("  rs2 [2:0]  : "));
        write(l, p_rs2_addr);
        writeline(output, l);
        write(l, string'("  index[26:25]: "));
        write(l, p_index);
        writeline(output, l);
        write(l, string'("----------------------------------------"));
        writeline(output, l);
        write(l, string'("Control Flags:"));
        writeline(output, l);
        write(l, string'("  WB_flages [2:0]  : "));
        write(l, p_wb_flages);
        write(l, string'(" (PC+1,MemtoReg,RegWrite)"));
        writeline(output, l);
        write(l, string'("  EXE_flages[4:0]  : "));
        write(l, p_exe_flages);
        write(l, string'(" (ALUOp[4:2],ALUSrc,Index)"));
        writeline(output, l);
        write(l, string'("  MEM_flages[6:0]  : "));
        write(l, p_mem_flages);
        write(l, string'(" (WDsel,MEMRd,MEMWr,StkRd,StkWr,CCRLd,CCRSt)"));
        writeline(output, l);
        write(l, string'("  IO_flages [1:0]  : "));
        write(l, p_io_flages);
        write(l, string'(" (Input,Output)"));
        writeline(output, l);
        write(l, string'("  Branch_Exec[3:0]: "));
        write(l, p_branch_exec);
        write(l, string'(" (sel1,sel0,imm,branch)"));
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);
        write(l, string'(""));
        writeline(output, l);
    end procedure;
    
    -- Procedure to create instruction
    function make_instruction(
        opcode : std_logic_vector(4 downto 0);
        p_index  : std_logic_vector(1 downto 0);
        rd     : std_logic_vector(2 downto 0);
        rs1    : std_logic_vector(2 downto 0);
        rs2    : std_logic_vector(2 downto 0)
    ) return std_logic_vector is
        variable inst : std_logic_vector(31 downto 0);
    begin
        inst := (others => '0');
        inst(31 downto 27) := opcode;  -- opcode
        inst(26 downto 25) := p_index;   -- index (2 bits)
        inst(8 downto 6)   := rd;      -- rd
        inst(5 downto 3)   := rs1;     -- rs1
        inst(2 downto 0)   := rs2;     -- rs2
        return inst;
    end function;

begin
    -- Instantiate DUT
    DUT: Decode port map(
        clk => clk,
        reset => reset,
        inturrupt => inturrupt,
        instruction => instruction(26 downto 0),
        opcode => instruction(31 downto 27),
        PC => PC,
        mem_br => mem_br,
        exe_br => exe_br,
        WB_flages_in => WB_flages_in,
        EXE_flages_in => EXE_flages_in,
        MEM_flages_in => MEM_flages_in,
        IO_flages_in => IO_flages_in,
        FD_enable => FD_enable,
        Stall => Stall,
        DE_enable => DE_enable,
        EM_enable => EM_enable,
        MW_enable => MW_enable,
        Branch_Decode => Branch_Decode,
        Micro_inst_out => Micro_inst,

        WB_flages_out => WB_flages,
        EXE_flages_out => EXE_flages,
        MEM_flages_out => MEM_flages,
        IO_flages_out => IO_flages,
        Branch_Exec_out => Branch_Exec,
        CSwap_out => open,
        CCR_enable_out => CCR_enable,
        Imm_hazard_out => Imm_hazard,
        FU_enable_out => FU_enable,
        Rrs1_out => Rrs1,
        Rrs2_out => Rrs2,
        index_out => index,
        pc_out => pc_out_main,
        rs1_addr_out => rs1_addr,
        rs2_addr_out => rs2_addr,
        rd_addr_out => rd_addr
    );

    -- Clock generation
    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
        variable l : line;
    begin
        -- Print header
        write(l, string'(""));
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);
        write(l, string'("   DECODE STAGE TESTBENCH"));
        writeline(output, l);
        write(l, string'("   Testing all instructions"));
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);
        write(l, string'(""));
        writeline(output, l);
        
        -- Reset
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait for clk_period;
        
        -- Test GROUP 0 Instructions (opcode bit 4 = 0)
        
        -- Test 1: NOP (00000)
        instruction <= make_instruction("00000", "00", "001", "010", "011");
        wait for clk_period;
        log_outputs("NOP", "00000", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 2: HLT (00001)
        instruction <= make_instruction("00001", "00", "001", "010", "011");
        wait for clk_period;
        log_outputs("HLT", "00001", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 3: SETC (00010)
        instruction <= make_instruction("00010", "00", "001", "010", "011");
        wait for clk_period;
        log_outputs("SETC", "00010", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 4: INC (00011)
        instruction <= make_instruction("00011", "00", "001", "010", "011");
        wait for clk_period;
        log_outputs("INC", "00011", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 5: NOT (00100)
        instruction <= make_instruction("00100", "01", "010", "011", "100");
        wait for clk_period;
        log_outputs("NOT", "00100", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 6: LDM (00101)
        instruction <= make_instruction("00101", "10", "011", "100", "101");
        wait for clk_period;
        log_outputs("LDM", "00101", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 7: MOV (00110)
        instruction <= make_instruction("00110", "00", "100", "101", "110");
        wait for clk_period;
        log_outputs("MOV", "00110", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 8: SWAP (00111)
        instruction <= make_instruction("00111", "00", "101", "110", "111");
        wait for clk_period * 3;  -- SWAP is multi-cycle
        log_outputs("SWAP", "00111", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 9: IADD (01000)
        instruction <= make_instruction("01000", "11", "110", "111", "000");
        wait for clk_period;
        log_outputs("IADD", "01000", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 10: ADD (01001)
        instruction <= make_instruction("01001", "00", "111", "000", "001");
        wait for clk_period;
        log_outputs("ADD", "01001", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 11: SUB (01010)
        instruction <= make_instruction("01010", "00", "000", "001", "010");
        wait for clk_period;
        log_outputs("SUB", "01010", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 12: AND (01011)
        instruction <= make_instruction("01011", "00", "001", "010", "011");
        wait for clk_period;
        log_outputs("AND", "01011", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 13: JZ (01100)
        instruction <= make_instruction("01100", "00", "010", "011", "100");
        wait for clk_period;
        log_outputs("JZ", "01100", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 14: JN (01101)
        instruction <= make_instruction("01101", "01", "011", "100", "101");
        wait for clk_period;
        log_outputs("JN", "01101", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 15: JC (01110)
        instruction <= make_instruction("01110", "10", "100", "101", "110");
        wait for clk_period;
        log_outputs("JC", "01110", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 16: JMP (01111)
        instruction <= make_instruction("01111", "11", "101", "110", "111");
        wait for clk_period;
        log_outputs("JMP", "01111", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test GROUP 1 Instructions (opcode bit 4 = 1)
        
        -- Test 17: OUT (10000)
        instruction <= make_instruction("10000", "00", "110", "111", "000");
        wait for clk_period;
        log_outputs("OUT", "10000", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 18: IN (10001)
        instruction <= make_instruction("10001", "00", "111", "000", "001");
        wait for clk_period;
        log_outputs("IN", "10001", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 19: PUSH (10010)
        instruction <= make_instruction("10010", "00", "000", "001", "010");
        wait for clk_period * 3;  -- PUSH has stall cycles
        log_outputs("PUSH", "10010", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 20: POP (10011)
        instruction <= make_instruction("10011", "00", "001", "010", "011");
        wait for clk_period * 3;  -- POP has stall cycles
        log_outputs("POP", "10011", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 21: LDD (10100)
        instruction <= make_instruction("10100", "01", "010", "011", "100");
        wait for clk_period * 3;  -- LDD has stall cycles
        log_outputs("LDD", "10100", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 22: STD (10101)
        instruction <= make_instruction("10101", "10", "011", "100", "101");
        wait for clk_period * 3;  -- STD has stall cycles
        log_outputs("STD", "10101", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 23: CALL (10110)
        instruction <= make_instruction("10110", "11", "100", "101", "110");
        wait for clk_period * 3;  -- CALL has stall cycles
        log_outputs("CALL", "10110", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 24: RET (10111)
        instruction <= make_instruction("10111", "00", "101", "110", "111");
        wait for clk_period * 3;  -- RET has stall cycles
        log_outputs("RET", "10111", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 25: INT (11000)
        instruction <= make_instruction("11000", "01", "110", "111", "000");
        wait for clk_period * 4;  -- INT is multi-cycle (3 cycles)
        log_outputs("INT", "11000", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Test 26: RTI (11001)
        instruction <= make_instruction("11001", "10", "111", "000", "001");
        wait for clk_period * 4;  -- RTI is multi-cycle (2 cycles)
        log_outputs("RTI", "11001", instruction, FD_enable, Stall, DE_enable, 
                    EM_enable, MW_enable, Branch_Decode, WB_flages, EXE_flages, 
                    MEM_flages, IO_flages, Branch_Exec, index, rd_addr, rs1_addr, rs2_addr);
        
        -- Print footer
        write(l, string'(""));
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);
        write(l, string'("   ALL TESTS COMPLETED"));
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);
        
        wait;
    end process;

end architecture testbench;
