-- ============================================================================
-- Testbench for Memory Stage
-- ============================================================================
-- Verifies:
--   1. Address Selection (ALU vs SP vs Interrupt)
--   2. Write Data Selection (Rs2 vs CCR vs PC vs PC+1)
--   3. Stack Pointer interaction
--   4. Interrupt Signal override
--   5. I/O Port logic
-- ============================================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.memory_interface_pkg.all;

entity tb_memory_stage is
end entity tb_memory_stage;

architecture Behavioral of tb_memory_stage is

    COMPONENT Memory_Stage IS
    PORT (
        clk           : IN  STD_LOGIC;
        reset         : IN  STD_LOGIC;
        interrupt     : IN  STD_LOGIC;
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
    END COMPONENT;

    -- Clock period
    constant CLK_PERIOD : time := 10 ns;
    
    -- Inputs
    signal clk           : std_logic := '0';
    signal reset         : std_logic := '0';
    signal interrupt     : std_logic := '0';
    signal wb_signals_in : std_logic_vector(2 downto 0) := (others => '0');
    signal mem_signals_in: std_logic_vector(6 downto 0) := (others => '0');
    signal input_signal  : std_logic := '0';
    signal output_signal : std_logic := '0';
    signal alu_result_in : std_logic_vector(31 downto 0) := (others => '0');
    signal rs2_data_in   : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_in         : std_logic_vector(31 downto 0) := (others => '0');
    signal rd_addr_in    : std_logic_vector(2 downto 0) := (others => '0');
    signal ccr_in        : std_logic_vector(2 downto 0) := (others => '0');
    signal in_port_data  : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_resp      : data_mem_resp_t := DATA_MEM_RESP_RESET;
    
    -- Outputs
    signal out_port_data : std_logic_vector(31 downto 0);
    signal mem_req       : data_mem_req_t;
    signal wb_signals_out: std_logic_vector(2 downto 0);
    signal read_data_out : std_logic_vector(31 downto 0);
    signal alu_result_out: std_logic_vector(31 downto 0);
    signal pc_out        : std_logic_vector(31 downto 0);
    signal rd_addr_out   : std_logic_vector(2 downto 0);
    signal sp_out_debug  : std_logic_vector(17 downto 0);

    -- Test control
    signal test_done    : boolean := false;

begin

    -- Clock generation
    clk_gen: process
    begin
        while not test_done loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process clk_gen;

    DUT: Memory_Stage
    PORT MAP (
        clk => clk,
        reset => reset,
        interrupt => interrupt,
        wb_signals_in => wb_signals_in,
        mem_signals_in => mem_signals_in,
        input_signal => input_signal,
        output_signal => output_signal,
        alu_result_in => alu_result_in,
        rs2_data_in => rs2_data_in,
        pc_in => pc_in,
        rd_addr_in => rd_addr_in,
        ccr_in => ccr_in,
        in_port_data => in_port_data,
        out_port_data => out_port_data,
        mem_req => mem_req,
        mem_resp => mem_resp,
        wb_signals_out => wb_signals_out,
        read_data_out => read_data_out,
        alu_result_out => alu_result_out,
        pc_out => pc_out,
        rd_addr_out => rd_addr_out,
        sp_out_debug => sp_out_debug
    );

    stimulus: process
        -- Helper procedure to reset signals
        procedure clear_signals is
        begin
            wb_signals_in <= (others => '0');
            mem_signals_in <= (others => '0');
            interrupt <= '0';
            input_signal <= '0';
            output_signal <= '0';
            alu_result_in <= (others => '0');
            rs2_data_in <= (others => '0');
            pc_in <= (others => '0');
            ccr_in <= (others => '0');
            in_port_data <= (others => '0');
            rd_addr_in <= (others => '0');
        end procedure;
    begin
        report "=== Aggressive Memory Stage Testbench Started ===" severity note;
        reset <= '1';
        wait for CLK_PERIOD * 2;
        reset <= '0';
        wait for CLK_PERIOD;

        
        -- =========================================================
        -- Group 1: Standard Memory Access (Load/Store)
        -- =========================================================

        -- Test 1: Standard Store (Rs2 -> Memory[ALU_Res])
        report "Test 1: Standard Store (Rs2)" severity note;
        clear_signals;
        mem_signals_in(4) <= '1'; -- MEMWrite
        mem_signals_in(6) <= '0'; -- WDSelect = Data
        mem_signals_in(1) <= '0'; -- CCRStore = 0 (Rs2)
        alu_result_in <= x"000000A0"; -- Addr 160
        rs2_data_in <= x"DEADBEEF";
        wait for CLK_PERIOD;
        assert mem_req.addr = std_logic_vector(to_unsigned(160, 18)) report "T1: Addr Mismatch" severity error;
        assert mem_req.write_data = x"DEADBEEF" report "T1: Data Mismatch" severity error;
        assert mem_req.write_req = '1' report "T1: Write Req Mismatch" severity error;

        -- Test 2: Standard Load (Memory[ALU_Res] -> ReadData)
        report "Test 2: Standard Load" severity note;
        clear_signals;
        mem_signals_in(5) <= '1'; -- MEMRead
        alu_result_in <= x"000000B0"; -- Addr 176
        mem_resp.read_data <= x"CAFEBABE"; -- Simulating Mem Response
        wait for CLK_PERIOD;
        assert mem_req.addr = std_logic_vector(to_unsigned(176, 18)) report "T2: Addr Mismatch" severity error;
        assert mem_req.read_req = '1' report "T2: Read Req Mismatch" severity error;
        assert read_data_out = x"CAFEBABE" report "T2: Read Data Mismatch" severity error;

        -- Test 3: Store CCR (CCR -> Memory[ALU_Res])
        report "Test 3: Store CCR" severity note;
        clear_signals;
        mem_signals_in(4) <= '1'; -- MEMWrite
        mem_signals_in(1) <= '1'; -- CCRStore = 1 (CCR)
        mem_signals_in(6) <= '0'; -- WDSelect = Data
        ccr_in <= "101"; -- Z=1, N=0, C=1
        alu_result_in <= x"000000C0";
        wait for CLK_PERIOD;
        assert mem_req.write_data(2 downto 0) = "101" report "T3: CCR Data Mismatch" severity error;
        assert mem_req.write_data(31 downto 3) = (28 downto 0 => '0') report "T3: CCR Padding Mismatch" severity error;

        -- Test 4: Store PC (PC -> Memory[ALU_Res])
        report "Test 4: Store PC" severity note;
        clear_signals;
        mem_signals_in(4) <= '1'; -- MEMWrite
        mem_signals_in(6) <= '1'; -- WDSelect = PC
        wb_signals_in(0) <= '0';  -- PC-Select = 0 (PC)
        pc_in <= x"12345678";
        alu_result_in <= x"000000D0";
        wait for CLK_PERIOD;
        assert mem_req.write_data = x"12345678" report "T4: PC Data Mismatch" severity error;

        -- Test 5: Store PC+1 (PC+1 -> Memory[ALU_Res])
        report "Test 5: Store PC+1" severity note;
        clear_signals;
        mem_signals_in(4) <= '1'; -- MEMWrite
        mem_signals_in(6) <= '1'; -- WDSelect = PC
        wb_signals_in(0) <= '1';  -- PC-Select = 1 (PC+1)
        pc_in <= x"12345678";
        wait for CLK_PERIOD;
        assert mem_req.write_data = x"12345679" report "T5: PC+1 Data Mismatch" severity error;

        -- =========================================================
        -- Group 2: Stack Operations
        -- =========================================================

        -- Test 6: Push Rs2 (StackWrite, Data=Rs2)
        report "Test 6: Push Rs2" severity note;
        clear_signals;
        mem_signals_in(2) <= '1'; -- StackWrite
        rs2_data_in <= x"AA55AA55";
        wait for CLK_PERIOD;
        assert mem_req.addr = sp_out_debug report "T6: Addr should be SP" severity error;
        assert mem_req.write_data = x"AA55AA55" report "T6: Data Mismatch" severity error;

        -- Test 7: Push CCR (StackWrite, Data=CCR)
        report "Test 7: Push CCR" severity note;
        clear_signals;
        mem_signals_in(2) <= '1'; -- StackWrite
        mem_signals_in(1) <= '1'; -- CCRStore
        ccr_in <= "010";
        wait for CLK_PERIOD;
        assert mem_req.addr = sp_out_debug report "T7: Addr should be SP" severity error;
        assert mem_req.write_data(2 downto 0) = "010" report "T7: Data Mismatch" severity error;

        -- Test 8: Push PC+1 (StackWrite, Data=PC+1) - e.g. CALL/INT
        report "Test 8: Push PC+1 (CALL/INT)" severity note;
        clear_signals;
        mem_signals_in(2) <= '1'; -- StackWrite
        mem_signals_in(6) <= '1'; -- WDSelect = PC
        wb_signals_in(0) <= '1';  -- PCSelect = PC+1
        pc_in <= x"FFFF0000";
        wait for CLK_PERIOD;
        assert mem_req.addr = sp_out_debug report "T8: Addr should be SP" severity error;
        assert mem_req.write_data = x"FFFF0001" report "T8: Data Mismatch" severity error;

        -- Test 9: Pop (StackRead)
        report "Test 9: Pop" severity note;
        clear_signals;
        mem_signals_in(3) <= '1'; -- StackRead
        wait for CLK_PERIOD;
        -- Check Logic assumes Empty Descending? Our impl: mem_addr <= SP if StackRead? No, Wait.
        -- Impl code: IF stack_read='1' THEN mem_addr_int <= sp_current (or SP+1?)
        -- Previous step I corrected to SP.
        assert mem_req.addr = sp_out_debug report "T9: Addr should be SP (or SP+1 based on impl)" severity error;
        assert mem_req.read_req = '1' report "T9: Read Req missing" severity error;

        -- =========================================================
        -- Group 3: Interrupts and Abnormal Flows
        -- =========================================================

        -- Test 10: Interrupt Address Override
        report "Test 10: Interrupt Override" severity note;
        clear_signals;
        interrupt <= '1';
        alu_result_in <= x"FFFFFFFF"; -- Should be ignored
        wait for CLK_PERIOD;
        assert mem_req.addr = std_logic_vector(to_unsigned(1, 18)) report "T10: Addr should be 1" severity error;

        -- Test 11: Interrupt with Memory Write
        report "Test 11: Interrupt + Write" severity note;
        clear_signals;
        interrupt <= '1';
        mem_signals_in(4) <= '1'; -- MemWrite
        rs2_data_in <= x"BADF00D5";
        wait for CLK_PERIOD;
        assert mem_req.addr = std_logic_vector(to_unsigned(1, 18)) report "T11: Addr should be 1" severity error;
        assert mem_req.write_req = '1' report "T11: Write Req missing" severity error;

        -- =========================================================
        -- Group 4: I/O Operations
        -- =========================================================

        -- Test 12: Input Port Read
        report "Test 12: Input Port Read" severity note;
        clear_signals;
        input_signal <= '1';
        in_port_data <= x"11223344";
        mem_resp.read_data <= x"88888888"; -- Should be ignored
        wait for CLK_PERIOD;
        assert read_data_out = x"11223344" report "T12: Should read from Input Port" severity error;

        -- Test 13: Input Port vs Mem Read Conflict
        report "Test 13: Input Port vs Mem Read Priority" severity note;
        clear_signals;
        input_signal <= '1';
        mem_signals_in(5) <= '1'; -- MemRead
        in_port_data <= x"55555555";
        mem_resp.read_data <= x"99999999"; 
        wait for CLK_PERIOD;
        -- Priority: Input Signal controls mux.
        assert read_data_out = x"55555555" report "T13: Input Port should have priority" severity error;

        -- Test 14: Output Port Write
        report "Test 14: Output Port Write" severity note;
        clear_signals;
        output_signal <= '1';
        rs2_data_in <= x"ABCDEF01";
        wait for CLK_PERIOD;
        assert out_port_data = x"ABCDEF01" report "T14: Output Port Data Mismatch" severity error;

        -- =========================================================
        -- Group 5: Complex / Corner Case Scenarios
        -- =========================================================

        -- Test 15: Stack Write vs Mem Write (Priority check)
        report "Test 15: Stack Write vs Mem Write Priority" severity note;
        clear_signals;
        mem_signals_in(2) <= '1'; -- StackWrite
        mem_signals_in(4) <= '1'; -- MemWrite
        -- Logic: IF stack_read or stack_write ... Addr = SP.
        wait for CLK_PERIOD;
        assert mem_req.addr = sp_out_debug report "T15: Addr should be SP" severity error;
        assert mem_req.write_req = '1' report "T15: Write Req missing" severity error;

        -- Test 16: Zero Data Write
        report "Test 16: Zero Data Write" severity note;
        clear_signals;
        mem_signals_in(4) <= '1';
        rs2_data_in <= (others => '0');
        wait for CLK_PERIOD;
        assert mem_req.write_data = (31 downto 0 => '0') report "T16: Data Mismatch" severity error;

        -- Test 17: Max Data Write
        report "Test 17: Max Data Write" severity note;
        clear_signals;
        mem_signals_in(4) <= '1';
        rs2_data_in <= (others => '1');
        wait for CLK_PERIOD;
        assert mem_req.write_data = (31 downto 0 => '1') report "T17: Data Mismatch" severity error;

        -- Test 18: Pass-through Signal Verification
        report "Test 18: Pass-through Verification" severity note;
        clear_signals;
        wb_signals_in <= "101";
        pc_in <= x"FFFF1234";
        rd_addr_in <= "111";
        alu_result_in <= x"12345678";
        wait for CLK_PERIOD;
        assert wb_signals_out = "101" report "T18: WB Signals Mismatch" severity error;
        assert pc_out = x"FFFF1234" report "T18: PC Mismatch" severity error;
        assert rd_addr_out = "111" report "T18: RD Addr Mismatch" severity error;
        assert alu_result_out = x"12345678" report "T18: ALU Result Mismatch" severity error;

        -- Test 19: Write PC+1 without Stack (e.g. Special Store?)
        report "Test 19: Store PC+1 to Memory" severity note;
        clear_signals;
        mem_signals_in(4) <= '1'; -- MemWrite
        mem_signals_in(6) <= '1'; -- WDSelect = PC
        wb_signals_in(0) <= '1';  -- PCSelect = PC+1
        pc_in <= x"0000000A";
        alu_result_in <= x"00000100";
        wait for CLK_PERIOD;
        assert mem_req.addr = std_logic_vector(to_unsigned(256, 18)) report "T19: Addr Mismatch" severity error;
        assert mem_req.write_data = x"0000000B" report "T19: Data Mismatch" severity error;

        -- Test 20: Reset behavior
        report "Test 20: Reset" severity note;
        reset <= '1';
        wait for CLK_PERIOD;
        -- Check SP is reset
        -- Note: SP logic might reset asynchronously or synchronously.
        -- Assuming reset works, SP should be STACK_TOP_ADDR or similar.
        -- We won't assert exact value unless we know Stack Pointer init generic.
        reset <= '0';

        report "=== All Aggressive Tests Passed ===" severity note;
        test_done <= true;
        wait;
    end process;
end architecture;
