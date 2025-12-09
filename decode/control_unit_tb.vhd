-- filepath: c:\Users\ASUS\Desktop\SWE_Ass\stall_3alda2ery\decode\control_unit_tb.vhd
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_textio.ALL;
USE STD.textio.ALL;

ENTITY control_unit_tb IS
END ENTITY control_unit_tb;

ARCHITECTURE testbench OF control_unit_tb IS
    -- Component declaration (updated to match actual entity)
    COMPONENT Control_Unit IS
        PORT(
            clk: IN Std_logic;
            inturrupt : in std_logic;
            op_code : in std_logic_vector(4 downto 0);
            data_ready : in std_logic;
            mem_will_be_used : in std_logic;  -- Added
            FD_enable : out std_logic;
            Micro_inst: out std_logic_vector(4 downto 0);
            Stall :out std_logic;
            DE_enable :out  std_logic;
            EM_enable : out std_logic;
            MW_enable :out std_logic;
            Branch_Decode: out std_logic;
            ID_flush :out std_logic;
            mem_usage_predict : out std_logic;  -- Added
            WB_flages: out std_logic_vector(2 downto 0);
            EXE_flages: out std_logic_vector(4 downto 0);
            MEM_flages: out std_logic_vector(6 downto 0);
            IO_flages: out std_logic_vector(1 downto 0);
            CSwap : out std_logic;
            Branch_Exec: out std_logic_vector(3 downto 0);  -- Added
            CCR_enable : out std_logic;  -- Added
            Imm_predict : out std_logic;  -- Added
            Imm_in_use: in std_logic;  -- Added
            ForwardEnable : out std_logic;  -- Added
            Write_in_Src2: out std_logic  -- Added
        );
    END COMPONENT;

    -- Testbench signals (add missing signals)
    signal clk : std_logic := '0';
    signal inturrupt : std_logic := '0';
    signal op_code : std_logic_vector(4 downto 0) := (others => '0');
    signal data_ready : std_logic := '1';
    signal mem_will_be_used : std_logic := '0';  -- Added
    signal Imm_in_use : std_logic := '0';  -- Added
    
    signal FD_enable : std_logic;
    signal Micro_inst : std_logic_vector(4 downto 0);
    signal Stall : std_logic;
    signal DE_enable : std_logic;
    signal EM_enable : std_logic;
    signal MW_enable : std_logic;
    signal Branch_Decode : std_logic;
    signal ID_flush : std_logic;
    signal mem_usage_predict : std_logic;  -- Added
    signal WB_flages : std_logic_vector(2 downto 0);
    signal EXE_flages : std_logic_vector(4 downto 0);
    signal MEM_flages : std_logic_vector(6 downto 0);
    signal IO_flages : std_logic_vector(1 downto 0);
    signal CSwap : std_logic;
    signal Branch_Exec : std_logic_vector(3 downto 0);  -- Added
    signal CCR_enable : std_logic;  -- Added
    signal Imm_predict : std_logic;  -- Added
    signal ForwardEnable : std_logic;  -- Added
    signal Write_in_Src2 : std_logic;  -- Added

    -- Clock period
    constant clk_period : time := 10 ns;
    
    -- Test control
    signal test_done : boolean := false;

BEGIN
    -- Instantiate the Unit Under Test (UUT)
    UUT: Control_Unit PORT MAP (
        clk => clk,
        inturrupt => inturrupt,
        op_code => op_code,
        data_ready => data_ready,
        mem_will_be_used => mem_will_be_used,  -- Added
        FD_enable => FD_enable,
        Micro_inst => Micro_inst,
        Stall => Stall,
        DE_enable => DE_enable,
        EM_enable => EM_enable,
        MW_enable => MW_enable,
        Branch_Decode => Branch_Decode,
        ID_flush => ID_flush,
        mem_usage_predict => mem_usage_predict,  -- Added
        WB_flages => WB_flages,
        EXE_flages => EXE_flages,
        MEM_flages => MEM_flages,
        IO_flages => IO_flages,
        CSwap => CSwap,
        Branch_Exec => Branch_Exec,  -- Added
        CCR_enable => CCR_enable,  -- Added
        Imm_predict => Imm_predict,  -- Added
        Imm_in_use => Imm_in_use,  -- Added
        ForwardEnable => ForwardEnable,  -- Added
        Write_in_Src2 => Write_in_Src2  -- Added
    );

    -- Clock process
    clk_process: PROCESS
    BEGIN
        WHILE NOT test_done LOOP
            clk <= '0';
            WAIT FOR clk_period/2;
            clk <= '1';
            WAIT FOR clk_period/2;
        END LOOP;
        WAIT;
    END PROCESS;

    -- Stimulus process
    stim_proc: PROCESS
        VARIABLE l : line;
        
        -- Procedure to log all outputs
        PROCEDURE log_outputs(test_name : string) IS
        BEGIN
            write(l, string'("  Outputs for ") & test_name & string'(":"));
            writeline(output, l);
            write(l, string'("    FD_enable=") & std_logic'image(FD_enable) & 
                     string'(" DE_enable=") & std_logic'image(DE_enable) &
                     string'(" EM_enable=") & std_logic'image(EM_enable) &
                     string'(" MW_enable=") & std_logic'image(MW_enable));
            writeline(output, l);
            write(l, string'("    Stall=") & std_logic'image(Stall) &
                     string'(" Branch_Decode=") & std_logic'image(Branch_Decode) &
                     string'(" ID_flush=") & std_logic'image(ID_flush) &
                     string'(" CSwap=") & std_logic'image(CSwap));
            writeline(output, l);
            write(l, string'("    WB_flages="));
            for i in WB_flages'range loop
                write(l, std_logic'image(WB_flages(i)));
            end loop;
            write(l, string'(" (RegWrite=") & std_logic'image(WB_flages(2)) &
                     string'(" MemtoReg=") & std_logic'image(WB_flages(1)) &
                     string'(" PC-sel=") & std_logic'image(WB_flages(0)) & string'(")"));
            writeline(output, l);
            write(l, string'("    EXE_flages="));
            for i in EXE_flages'range loop
                write(l, std_logic'image(EXE_flages(i)));
            end loop;
            write(l, string'(" (ALUOp="));
            for i in 4 downto 2 loop
                write(l, std_logic'image(EXE_flages(i)));
            end loop;
            write(l, string'(" ALUSrc=") & std_logic'image(EXE_flages(1)) &
                     string'(" Index=") & std_logic'image(EXE_flages(0)) & string'(")"));
            writeline(output, l);
            write(l, string'("    MEM_flages="));
            for i in MEM_flages'range loop
                write(l, std_logic'image(MEM_flages(i)));
            end loop;
            write(l, string'(" (WDsel=") & std_logic'image(MEM_flages(6)) &
                     string'(" MEMRd=") & std_logic'image(MEM_flages(5)) &
                     string'(" MEMWr=") & std_logic'image(MEM_flages(4)) &
                     string'(" StkRd=") & std_logic'image(MEM_flages(3)) &
                     string'(" StkWr=") & std_logic'image(MEM_flages(2)) &
                     string'(" CCRSt=") & std_logic'image(MEM_flages(1)) &
                     string'(" CCRLd=") & std_logic'image(MEM_flages(0)) & string'(")"));
            writeline(output, l);
            write(l, string'("    IO_flages="));
            for i in IO_flages'range loop
                write(l, std_logic'image(IO_flages(i)));
            end loop;
            write(l, string'(" (Out=") & std_logic'image(IO_flages(1)) &
                     string'(" In=") & std_logic'image(IO_flages(0)) & string'(")"));
            writeline(output, l);
            write(l, string'("    Micro_inst="));
            for i in Micro_inst'range loop
                write(l, std_logic'image(Micro_inst(i)));
            end loop;
            writeline(output, l);
        END PROCEDURE;
        
    BEGIN
        -- Wait for initial settling
        WAIT FOR clk_period * 2;

        write(l, string'("========================================"));
        writeline(output, l);
        write(l, string'("Starting Control Unit Test"));
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);

        -- Test 1: NOOP (00000)
        write(l, string'("Test 1: NOOP (00000)"));
        writeline(output, l);
        op_code <= "00000";
        WAIT FOR clk_period;
        log_outputs("NOOP");
        ASSERT Stall = '0' REPORT "NOOP: Stall should be 0" SEVERITY ERROR;
        
        -- Test 2: HLT (00001)
        write(l, string'("Test 2: HLT (00001)"));
        writeline(output, l);
        op_code <= "00001";
        WAIT FOR clk_period;
        log_outputs("HLT");
        ASSERT FD_enable = '0' REPORT "HLT: FD_enable should be 0" SEVERITY ERROR;
        ASSERT DE_enable = '0' REPORT "HLT: DE_enable should be 0" SEVERITY ERROR;
        ASSERT Stall = '1' REPORT "HLT: Stall should be 1" SEVERITY ERROR;
        writeline(output, l);

        -- Test 3: SETC (00010)
        write(l, string'("Test 3: SETC (00010)"));
        writeline(output, l);
        op_code <= "00010";
        WAIT FOR clk_period;
        log_outputs("SETC");
        ASSERT EXE_flages(4 downto 2) = "111" REPORT "SETC: EXE_flages(4:2) should be 111" SEVERITY ERROR;
        writeline(output, l);

        -- Test 4: INC (00011)
        write(l, string'("Test 4: INC (00011)"));
        writeline(output, l);
        op_code <= "00011";
        WAIT FOR clk_period;
        log_outputs("INC");
        ASSERT EXE_flages(4 downto 2) = "000" REPORT "INC: EXE_flages(4:2) should be 000" SEVERITY ERROR;
        ASSERT WB_flages(2) = '1' REPORT "INC: RegWrite should be 1" SEVERITY ERROR;
        writeline(output, l);

        -- Test 5: NOT (00100)
        write(l, string'("Test 5: NOT (00100)"));
        writeline(output, l);
        op_code <= "00100";
        WAIT FOR clk_period;
        log_outputs("NOT");
        ASSERT EXE_flages(4 downto 2) = "001" REPORT "NOT: EXE_flages(4:2) should be 001" SEVERITY ERROR;
        ASSERT WB_flages(2) = '1' REPORT "NOT: RegWrite should be 1" SEVERITY ERROR;
        writeline(output, l);

        -- Test 6: LDM (00101)
        write(l, string'("Test 6: LDM (00101)"));
        writeline(output, l);
        op_code <= "00101";
        WAIT FOR clk_period;
        log_outputs("LDM");
        ASSERT EXE_flages(4 downto 2) = "010" REPORT "LDM: EXE_flages(4:2) should be 010" SEVERITY ERROR;
        ASSERT EXE_flages(1) = '1' REPORT "LDM: ALUSrc should be 1" SEVERITY ERROR;
        ASSERT WB_flages(2) = '1' REPORT "LDM: RegWrite should be 1" SEVERITY ERROR;
        writeline(output, l);

        -- Test 7: MOV (00110)
        write(l, string'("Test 7: MOV (00110)"));
        writeline(output, l);
        op_code <= "00110";
        WAIT FOR clk_period;
        log_outputs("MOV");
        ASSERT WB_flages(2) = '1' REPORT "MOV: RegWrite should be 1" SEVERITY ERROR;
        writeline(output, l);

        -- Test 8: SWAP (00111) - Multi-cycle with micro-instruction
        write(l, string'("Test 8: SWAP (00111) - Multi-cycle"));
        writeline(output, l);
        op_code <= "00111";
        WAIT FOR clk_period;
        write(l, string'("  Cycle 1:"));
        writeline(output, l);
        log_outputs("SWAP-C1");
        ASSERT Stall = '1' REPORT "SWAP Cycle 1: Stall should be 1" SEVERITY ERROR;
        -- Follow micro-instruction in next cycle
        op_code <= Micro_inst;
        WAIT FOR clk_period;
        write(l, string'("  Cycle 2:"));
        writeline(output, l);
        log_outputs("SWAP-C2");
        ASSERT CSwap = '1' REPORT "SWAP Cycle 2: CSwap should be 1" SEVERITY ERROR;
        WAIT FOR clk_period; -- Return to idle
        writeline(output, l);

        -- Test 9: IADD (01000)
        write(l, string'("Test 9: IADD (01000)"));
        writeline(output, l);
        op_code <= "01000";
        WAIT FOR clk_period;
        log_outputs("IADD");
        ASSERT EXE_flages(4 downto 2) = "010" REPORT "IADD: EXE_flages(4:2) should be 010" SEVERITY ERROR;
        ASSERT EXE_flages(1) = '1' REPORT "IADD: ALUSrc should be 1" SEVERITY ERROR;
        ASSERT WB_flages(2) = '1' REPORT "IADD: RegWrite should be 1" SEVERITY ERROR;
        writeline(output, l);

        -- Test 10: ADD (01001)
        write(l, string'("Test 10: ADD (01001)"));
        writeline(output, l);
        op_code <= "01001";
        WAIT FOR clk_period;
        log_outputs("ADD");
        ASSERT EXE_flages(4 downto 2) = "010" REPORT "ADD: EXE_flages(4:2) should be 010" SEVERITY ERROR;
        ASSERT WB_flages(2) = '1' REPORT "ADD: RegWrite should be 1" SEVERITY ERROR;
        writeline(output, l);

        -- Test 11: SUB (01010)
        write(l, string'("Test 11: SUB (01010)"));
        writeline(output, l);
        op_code <= "01010";
        WAIT FOR clk_period;
        log_outputs("SUB");
        ASSERT EXE_flages(4 downto 2) = "011" REPORT "SUB: EXE_flages(4:2) should be 011" SEVERITY ERROR;
        ASSERT WB_flages(2) = '1' REPORT "SUB: RegWrite should be 1" SEVERITY ERROR;
        writeline(output, l);

        -- Test 12: AND (01011)
        write(l, string'("Test 12: AND (01011)"));
        writeline(output, l);
        op_code <= "01011";
        WAIT FOR clk_period;
        log_outputs("AND");
        ASSERT EXE_flages(4 downto 2) = "100" REPORT "AND: EXE_flages(4:2) should be 100" SEVERITY ERROR;
        ASSERT WB_flages(2) = '1' REPORT "AND: RegWrite should be 1" SEVERITY ERROR;
        writeline(output, l);

        -- Test 13: JMP (01111)
        write(l, string'("Test 13: JMP (01111)"));
        writeline(output, l);
        op_code <= "01111";
        WAIT FOR clk_period;
        log_outputs("JMP");
        ASSERT Branch_Decode = '1' REPORT "JMP: Branch_Decode should be 1" SEVERITY ERROR;
        ASSERT ID_flush = '1' REPORT "JMP: ID_flush should be 1" SEVERITY ERROR;
        writeline(output, l);

        -- Test 14: OUT (10000)
        write(l, string'("Test 14: OUT (10000)"));
        writeline(output, l);
        op_code <= "10000";
        WAIT FOR clk_period;
        log_outputs("OUT");
        ASSERT IO_flages(1) = '1' REPORT "OUT: IO_flages(1) should be 1" SEVERITY ERROR;
        writeline(output, l);

        -- Test 15: IN (10001)
        write(l, string'("Test 15: IN (10001)"));
        writeline(output, l);
        op_code <= "10001";
        WAIT FOR clk_period;
        log_outputs("IN");
        ASSERT IO_flages(0) = '1' REPORT "IN: IO_flages(0) should be 1" SEVERITY ERROR;
        ASSERT WB_flages(2) = '1' REPORT "IN: RegWrite should be 1" SEVERITY ERROR;
        writeline(output, l);

        -- Test 16: PUSH (10010)
        write(l, string'("Test 16: PUSH (10010)"));
        writeline(output, l);
        op_code <= "10010";
        WAIT FOR clk_period;
        log_outputs("PUSH");
        ASSERT MEM_flages(2) = '1' REPORT "PUSH: StackWrite should be 1" SEVERITY ERROR;
        ASSERT MEM_flages(6) = '0' REPORT "PUSH: WDselect should be 0" SEVERITY ERROR;
        writeline(output, l);

        -- Test 17: POP (10011)
        write(l, string'("Test 17: POP (10011)"));
        writeline(output, l);
        op_code <= "10011";
        WAIT FOR clk_period;
        log_outputs("POP");
        ASSERT MEM_flages(3) = '1' REPORT "POP: StackRead should be 1" SEVERITY ERROR;
        ASSERT WB_flages(2) = '1' REPORT "POP: RegWrite should be 1" SEVERITY ERROR;
        writeline(output, l);

        -- Test 18: LDD (10100)
        write(l, string'("Test 18: LDD (10100)"));
        writeline(output, l);
        op_code <= "10100";
        WAIT FOR clk_period;
        log_outputs("LDD");
        ASSERT MEM_flages(5) = '1' REPORT "LDD: MEMRead should be 1" SEVERITY ERROR;
        ASSERT WB_flages(1) = '1' REPORT "LDD: MemtoReg should be 1" SEVERITY ERROR;
        ASSERT WB_flages(2) = '1' REPORT "LDD: RegWrite should be 1" SEVERITY ERROR;
        ASSERT EXE_flages(1) = '1' REPORT "LDD: ALUSrc should be 1" SEVERITY ERROR;
        writeline(output, l);

        -- Test 19: STD (10101)
        write(l, string'("Test 19: STD (10101)"));
        writeline(output, l);
        op_code <= "10101";
        WAIT FOR clk_period;
        log_outputs("STD");
        ASSERT MEM_flages(4) = '1' REPORT "STD: MEMWrite should be 1" SEVERITY ERROR;
        ASSERT EXE_flages(1) = '1' REPORT "STD: ALUSrc should be 1" SEVERITY ERROR;
        ASSERT MEM_flages(6) = '0' REPORT "STD: WDselect should be 0" SEVERITY ERROR;
        writeline(output, l);

        -- Test 20: CALL (10110)
        write(l, string'("Test 20: CALL (10110)"));
        writeline(output, l);
        op_code <= "10110";
        WAIT FOR clk_period;
        log_outputs("CALL");
        ASSERT Branch_Decode = '1' REPORT "CALL: Branch_Decode should be 1" SEVERITY ERROR;
        ASSERT ID_flush = '1' REPORT "CALL: ID_flush should be 1" SEVERITY ERROR;
        ASSERT MEM_flages(2) = '1' REPORT "CALL: StackWrite should be 1" SEVERITY ERROR;
        ASSERT MEM_flages(6) = '1' REPORT "CALL: WDselect should be 1" SEVERITY ERROR;
        ASSERT WB_flages(0) = '1' REPORT "CALL: PC-select should be 1" SEVERITY ERROR;
        writeline(output, l);

        -- Test 21: RET (10111)
        write(l, string'("Test 21: RET (10111)"));
        writeline(output, l);
        op_code <= "10111";
        WAIT FOR clk_period;
        log_outputs("RET");
        ASSERT MEM_flages(3) = '1' REPORT "RET: StackRead should be 1" SEVERITY ERROR;
        writeline(output, l);

        -- Test 22: INT (11000) - Multi-cycle with micro-instruction
        write(l, string'("Test 22: INT (11000) - Multi-cycle"));
        writeline(output, l);
        op_code <= "11000";
        WAIT FOR clk_period;
        write(l, string'("  Cycle 1:"));
        writeline(output, l);
        log_outputs("INT-C1");
        ASSERT Stall = '1' REPORT "INT Cycle 1: Stall should be 1" SEVERITY ERROR;
        ASSERT MEM_flages(2) = '1' REPORT "INT Cycle 1: StackWrite should be 1" SEVERITY ERROR;
        -- Follow micro-instruction sequence
        op_code <= Micro_inst;
        WAIT FOR clk_period;
        write(l, string'("  Cycle 2:"));
        writeline(output, l);
        log_outputs("INT-C2");
        ASSERT MEM_flages(1) = '1' REPORT "INT Cycle 2: CCRStore should be 1" SEVERITY ERROR;
        op_code <= Micro_inst;
        WAIT FOR clk_period;
        write(l, string'("  Cycle 3:"));
        writeline(output, l);
        log_outputs("INT-C3");
        ASSERT MEM_flages(5) = '1' REPORT "INT Cycle 3: MEMRead should be 1" SEVERITY ERROR;
        WAIT FOR clk_period; -- Return to idle
        writeline(output, l);

        -- Test 23: RTI (11001) - Multi-cycle with micro-instruction
        write(l, string'("Test 23: RTI (11001) - Multi-cycle"));
        writeline(output, l);
        op_code <= "11001";
        WAIT FOR clk_period;
        write(l, string'("  Cycle 1:"));
        writeline(output, l);
        log_outputs("RTI-C1");
        ASSERT Stall = '1' REPORT "RTI Cycle 1: Stall should be 1" SEVERITY ERROR;
        -- Follow micro-instruction
        op_code <= Micro_inst;
        WAIT FOR clk_period;
        write(l, string'("  Cycle 2:"));
        writeline(output, l);
        log_outputs("RTI-C2");
        ASSERT MEM_flages(3) = '1' REPORT "RTI Cycle 2: StackRead should be 1" SEVERITY ERROR;
        WAIT FOR clk_period; -- Return to idle
        writeline(output, l);

        -- Test 24: External Interrupt Signal - Multi-cycle
        write(l, string'("Test 24: External Interrupt Signal - Multi-cycle"));
        writeline(output, l);
        op_code <= "00000"; -- NOOP
        inturrupt <= '1';
        WAIT FOR clk_period;
        write(l, string'("  Cycle 1:"));
        writeline(output, l);
        log_outputs("EXT_INT-C1");
        ASSERT Stall = '1' REPORT "INT_SIG Cycle 1: Stall should be 1" SEVERITY ERROR;
        ASSERT MEM_flages(2) = '1' REPORT "INT_SIG Cycle 1: StackWrite should be 1" SEVERITY ERROR;
        -- Follow micro-instruction sequence
        op_code <= Micro_inst;
        inturrupt <= '0';
        WAIT FOR clk_period;
        write(l, string'("  Cycle 2:"));
        writeline(output, l);
        log_outputs("EXT_INT-C2");
        ASSERT MEM_flages(1) = '1' REPORT "INT_SIG Cycle 2: CCRStore should be 1" SEVERITY ERROR;
        op_code <= Micro_inst;
        WAIT FOR clk_period;
        write(l, string'("  Cycle 3:"));
        writeline(output, l);
        log_outputs("EXT_INT-C3");
        ASSERT MEM_flages(5) = '1' REPORT "INT_SIG Cycle 3: MEMRead should be 1" SEVERITY ERROR;
        WAIT FOR clk_period; -- Return to idle
        writeline(output, l);

        write(l, string'("========================================"));
        writeline(output, l);
        write(l, string'("All Tests Completed"));
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);

        test_done <= true;
        WAIT;
    END PROCESS;

END ARCHITECTURE testbench;