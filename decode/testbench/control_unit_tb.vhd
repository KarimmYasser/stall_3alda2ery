-- filepath: c:\Users\ASUS\Desktop\SWE_Ass\stall_3alda2ery\decode\testbench\control_unit_tb.vhd
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_textio.ALL;
USE STD.textio.ALL;

ENTITY control_unit_tb IS
END ENTITY control_unit_tb;

ARCHITECTURE testbench OF control_unit_tb IS
    -- Component declaration
    COMPONENT Control_Unit IS
        PORT(
            clk: IN Std_logic;
            inturrupt : in std_logic;
            op_code : in std_logic_vector(4 downto 0);
            data_ready : in std_logic;
            mem_will_be_used : in std_logic;
            FD_enable : out std_logic;
            Micro_inst: out std_logic_vector(4 downto 0);
            Stall :out std_logic;
            DE_enable :out  std_logic;
            EM_enable : out std_logic;
            MW_enable :out std_logic;
            Branch_Decode: out std_logic;
            ID_flush :out std_logic;
            mem_usage_predict : out std_logic;
            WB_flages: out std_logic_vector(2 downto 0);
            EXE_flages: out std_logic_vector(4 downto 0);
            MEM_flages: out std_logic_vector(6 downto 0);
            IO_flages: out std_logic_vector(1 downto 0);
            CSwap : out std_logic;
            Branch_Exec: out std_logic_vector(3 downto 0);
            CCR_enable : out std_logic;
            Imm_predict : out std_logic;
            Imm_in_use: in std_logic;
            ForwardEnable : out std_logic
        );
    END COMPONENT;

    -- Testbench signals
    signal clk : std_logic := '0';
    signal inturrupt : std_logic := '0';
    signal op_code : std_logic_vector(4 downto 0) := (others => '0');
    signal data_ready : std_logic := '1';
    signal mem_will_be_used : std_logic := '0';
    signal Imm_in_use : std_logic := '0';
    
    signal FD_enable : std_logic;
    signal Micro_inst : std_logic_vector(4 downto 0);
    signal Stall : std_logic;
    signal DE_enable : std_logic;
    signal EM_enable : std_logic;
    signal MW_enable : std_logic;
    signal Branch_Decode : std_logic;
    signal ID_flush : std_logic;
    signal mem_usage_predict : std_logic;
    signal WB_flages : std_logic_vector(2 downto 0);
    signal EXE_flages : std_logic_vector(4 downto 0);
    signal MEM_flages : std_logic_vector(6 downto 0);
    signal IO_flages : std_logic_vector(1 downto 0);
    signal CSwap : std_logic;
    signal Branch_Exec : std_logic_vector(3 downto 0);
    signal CCR_enable : std_logic;
    signal Imm_predict : std_logic;
    signal ForwardEnable : std_logic;

    -- Clock period
    constant clk_period : time := 10 ns;
    signal test_done : boolean := false;

BEGIN
    -- Instantiate the Unit Under Test (UUT)
    UUT: Control_Unit PORT MAP (
        clk => clk,
        inturrupt => inturrupt,
        op_code => op_code,
        data_ready => data_ready,
        mem_will_be_used => mem_will_be_used,
        FD_enable => FD_enable,
        Micro_inst => Micro_inst,
        Stall => Stall,
        DE_enable => DE_enable,
        EM_enable => EM_enable,
        MW_enable => MW_enable,
        Branch_Decode => Branch_Decode,
        ID_flush => ID_flush,
        mem_usage_predict => mem_usage_predict,
        WB_flages => WB_flages,
        EXE_flages => EXE_flages,
        MEM_flages => MEM_flages,
        IO_flages => IO_flages,
        CSwap => CSwap,
        Branch_Exec => Branch_Exec,
        CCR_enable => CCR_enable,
        Imm_predict => Imm_predict,
        Imm_in_use => Imm_in_use,
        ForwardEnable => ForwardEnable
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
        
        PROCEDURE log_outputs(test_name : string) IS
        BEGIN
            write(l, string'("  Outputs for ") & test_name & string'(":"));
            writeline(output, l);
            write(l, string'("    Pipeline: FD=") & std_logic'image(FD_enable) & 
                     string'(" DE=") & std_logic'image(DE_enable) &
                     string'(" EM=") & std_logic'image(EM_enable) &
                     string'(" MW=") & std_logic'image(MW_enable) &
                     string'(" Stall=") & std_logic'image(Stall));
            writeline(output, l);
            write(l, string'("    Control: Branch_Dec=") & std_logic'image(Branch_Decode) &
                     string'(" ID_flush=") & std_logic'image(ID_flush) &
                     string'(" CSwap=") & std_logic'image(CSwap) &
                     string'(" CCR_en=") & std_logic'image(CCR_enable) &
                     string'(" Fwd_en=") & std_logic'image(ForwardEnable));
            writeline(output, l);
            write(l, string'("    Memory: usage_pred=") & std_logic'image(mem_usage_predict) &
                     string'(" Imm_pred=") & std_logic'image(Imm_predict));
            writeline(output, l);
            write(l, string'("    WB_flags="));
            for i in WB_flages'range loop
                write(l, std_logic'image(WB_flages(i)));
            end loop;
            write(l, string'(" EXE_flags="));
            for i in EXE_flages'range loop
                write(l, std_logic'image(EXE_flages(i)));
            end loop;
            writeline(output, l);
            write(l, string'("    MEM_flags="));
            for i in MEM_flages'range loop
                write(l, std_logic'image(MEM_flages(i)));
            end loop;
            write(l, string'(" Branch_Exec="));
            for i in Branch_Exec'range loop
                write(l, std_logic'image(Branch_Exec(i)));
            end loop;
            writeline(output, l);
        END PROCEDURE;
        
    BEGIN
        -- Test SWAP with ForwardEnable check
        write(l, string'("Test: SWAP (00111) - Check ForwardEnable disabled"));
        writeline(output, l);
        op_code <= "00111";
        WAIT FOR clk_period;
        log_outputs("SWAP-C1");
        ASSERT ForwardEnable = '0' REPORT "SWAP: ForwardEnable should be 0" SEVERITY ERROR;
        
        op_code <= Micro_inst;
        WAIT FOR clk_period;
        log_outputs("SWAP-C2");
        
        WAIT FOR clk_period;
        log_outputs("SWAP-C3");
        ASSERT ForwardEnable = '1' REPORT "POST-SWAP: ForwardEnable should be 1" SEVERITY ERROR;
        
        test_done <= true;
        WAIT;
    END PROCESS;

END ARCHITECTURE testbench;
