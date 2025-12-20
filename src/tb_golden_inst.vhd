library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.memory_interface_pkg.all;

entity tb_golden_inst is
end entity;

architecture behavior of tb_golden_inst is

    type reg_array_t is array (0 to 7) of std_logic_vector(31 downto 0);

    component top_level_processor is
        generic (
            INIT_FILENAME : string := "../assembler/output/golden_inst.mem"
        );
        port(
            clk : in std_logic;
            reset : in std_logic;
            interrupt : in std_logic;
            inputport_data : in std_logic_vector(31 downto 0);
            tb_instruction_mem : in std_logic_vector(31 downto 0);
            tb_mem_read_data : in std_logic_vector(31 downto 0);
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
    end component;

    signal clk : std_logic := '0';
    signal reset : std_logic := '1';
    signal interrupt : std_logic := '0';
    signal inputport_data : std_logic_vector(31 downto 0) := (others => '0');
    signal tb_instruction_mem : std_logic_vector(31 downto 0) := (others => '0');
    signal tb_mem_read_data : std_logic_vector(31 downto 0) := (others => '0');

    signal tb_exe_alu_result : std_logic_vector(31 downto 0);
    signal tb_exe_ccr : std_logic_vector(2 downto 0);
    signal tb_exe_branch_taken : std_logic;
    signal tb_exe_rd_addr : std_logic_vector(2 downto 0);
    signal tb_mem_wb_signals : std_logic_vector(2 downto 0);
    signal tb_mem_stage_read_data_out  : std_logic_vector(31 downto 0);
    signal tb_mem_alu_result : std_logic_vector(31 downto 0);
    signal tb_mem_rd_addr    : std_logic_vector(2 downto 0);

    signal dbg_pc : std_logic_vector(31 downto 0);
    signal dbg_fetched_instruction : std_logic_vector(31 downto 0);
    signal dbg_sp : std_logic_vector(17 downto 0);
    signal dbg_stall : std_logic;
    signal dbg_ram_addr : std_logic_vector(17 downto 0);
    signal dbg_ram_read_en : std_logic;
    signal dbg_ram_write_en : std_logic;
    signal dbg_ram_data_in : std_logic_vector(31 downto 0);
    signal dbg_ram_data_out : std_logic_vector(31 downto 0);

    constant clk_period : time := 10 ns;
    constant MAX_CYCLES : integer := 2000;

    constant EXPECT_DATA : std_logic_vector(31 downto 0) := x"00001234";
    constant EXPECT_R0 : std_logic_vector(31 downto 0) := x"000003E8";

begin

    DUT: top_level_processor
        generic map(
            INIT_FILENAME => "../assembler/output/golden_inst.mem"
        )
        port map(
            clk => clk,
            reset => reset,
            interrupt => interrupt,
            inputport_data => inputport_data,
            tb_instruction_mem => tb_instruction_mem,
            tb_mem_read_data => tb_mem_read_data,
            tb_exe_alu_result => tb_exe_alu_result,
            tb_exe_ccr => tb_exe_ccr,
            tb_exe_branch_taken => tb_exe_branch_taken,
            tb_exe_rd_addr => tb_exe_rd_addr,
            tb_mem_wb_signals => tb_mem_wb_signals,
            tb_mem_stage_read_data_out => tb_mem_stage_read_data_out,
            tb_mem_alu_result => tb_mem_alu_result,
            tb_mem_rd_addr => tb_mem_rd_addr,

            dbg_pc => dbg_pc,
            dbg_fetched_instruction => dbg_fetched_instruction,
            dbg_sp => dbg_sp,
            dbg_stall => dbg_stall,
            dbg_ram_addr => dbg_ram_addr,
            dbg_ram_read_en => dbg_ram_read_en,
            dbg_ram_write_en => dbg_ram_write_en,
            dbg_ram_data_in => dbg_ram_data_in,
            dbg_ram_data_out => dbg_ram_data_out
        );

    clk_proc: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    function is_watch_addr(a : std_logic_vector(17 downto 0)) return boolean is
        variable ai : integer;
    begin
        ai := to_integer(unsigned(a));
        return (ai = 1000) or (ai = 2000) or (ai = 2001) or (ai = 2002) or (ai = 2003) or (ai > 262000);
    end function;

    stim_proc: process
        variable l : line;
        variable store_seen : boolean := false;
        variable load_seen : boolean := false;
        variable push_seen : boolean := false;
        variable pop_seen : boolean := false;
        variable r0_seen : boolean := false;
        variable r1_seen : boolean := false;
        variable r2_seen : boolean := false;
        variable r3_seen : boolean := false;
        variable store_data : std_logic_vector(31 downto 0) := (others => '0');
        variable load_data : std_logic_vector(31 downto 0) := (others => '0');
        variable push_data : std_logic_vector(31 downto 0) := (others => '0');
        variable pop_data : std_logic_vector(31 downto 0) := (others => '0');
        variable r0_data : std_logic_vector(31 downto 0) := (others => '0');
        variable r1_data : std_logic_vector(31 downto 0) := (others => '0');
        variable r2_data : std_logic_vector(31 downto 0) := (others => '0');
        variable r3_data : std_logic_vector(31 downto 0) := (others => '0');
        variable push_addr : std_logic_vector(17 downto 0) := (others => '0');
    begin
        reset <= '1';
        inputport_data <= x"00000000";
        tb_instruction_mem <= (others => '0');
        tb_mem_read_data <= (others => '0');
        wait for clk_period * 2;
        reset <= '0';
        wait for clk_period;

        for i in 0 to MAX_CYCLES-1 loop
            wait until rising_edge(clk);
            wait for 1 ns;

            if (dbg_ram_write_en = '1') then
                if is_watch_addr(dbg_ram_addr) then
                    write(l, string'("MEM_WR A="));
                    hwrite(l, (31 downto 18 => '0') & dbg_ram_addr);
                    write(l, string'(" D="));
                    hwrite(l, dbg_ram_data_in);
                    writeline(output, l);
                end if;
                if (dbg_ram_addr = std_logic_vector(to_unsigned(1000, 18))) then
                    store_seen := true;
                    store_data := dbg_ram_data_in;
                end if;

                if (dbg_ram_addr = std_logic_vector(to_unsigned(2000, 18))) then
                    r0_seen := true;
                    r0_data := dbg_ram_data_in;
                end if;
                if (dbg_ram_addr = std_logic_vector(to_unsigned(2001, 18))) then
                    r1_seen := true;
                    r1_data := dbg_ram_data_in;
                end if;
                if (dbg_ram_addr = std_logic_vector(to_unsigned(2002, 18))) then
                    r2_seen := true;
                    r2_data := dbg_ram_data_in;
                end if;
                if (dbg_ram_addr = std_logic_vector(to_unsigned(2003, 18))) then
                    r3_seen := true;
                    r3_data := dbg_ram_data_in;
                end if;

                if (push_seen = false) and (dbg_ram_addr = std_logic_vector(to_unsigned(262143, 18))) then
                    push_seen := true;
                    push_addr := dbg_ram_addr;
                    push_data := dbg_ram_data_in;
                end if;
            end if;

            if (dbg_ram_read_en = '1') then
                if is_watch_addr(dbg_ram_addr) then
                    write(l, string'("MEM_RD A="));
                    hwrite(l, (31 downto 18 => '0') & dbg_ram_addr);
                    write(l, string'(" Q="));
                    hwrite(l, dbg_ram_data_out);
                    writeline(output, l);
                end if;
                if (dbg_ram_addr = std_logic_vector(to_unsigned(1000, 18))) then
                    load_seen := true;
                    load_data := dbg_ram_data_out;
                end if;
                if (push_seen = true) and (pop_seen = false) and (unsigned(dbg_ram_addr) > to_unsigned(262000, 18)) and (dbg_ram_data_out = push_data) then
                    pop_seen := true;
                    pop_data := dbg_ram_data_out;
                end if;
            end if;
        end loop;

        assert store_seen
            report "FAIL: did not observe STD write to address 1000"
            severity error;

        if store_seen then
            assert store_data = EXPECT_DATA
                report "FAIL: STD wrote unexpected data"
                severity error;
        end if;

        assert load_seen
            report "FAIL: did not observe LDD read from address 1000"
            severity error;

        if load_seen then
            assert load_data = EXPECT_DATA
                report "FAIL: LDD read unexpected data"
                severity error;
        end if;

        assert push_seen
            report "FAIL: did not observe PUSH write at top-of-stack"
            severity error;

        if push_seen then
            assert push_data = EXPECT_DATA
                report "FAIL: PUSH wrote unexpected data"
                severity error;
        end if;

        assert pop_seen
            report "FAIL: did not observe POP read returning pushed data"
            severity error;

        if pop_seen then
            assert pop_data = EXPECT_DATA
                report "FAIL: POP read unexpected data"
                severity error;
        end if;

        assert r0_seen and (r0_data = EXPECT_R0)
            report "FAIL: R0 final value mismatch (from store to M[2000])"
            severity error;
        assert r1_seen and (r1_data = EXPECT_DATA)
            report "FAIL: R1 final value mismatch (from store to M[2001])"
            severity error;
        assert r2_seen and (r2_data = EXPECT_DATA)
            report "FAIL: R2 final value mismatch (from store to M[2002])"
            severity error;
        assert r3_seen and (r3_data = EXPECT_DATA)
            report "FAIL: R3 final value mismatch (from store to M[2003])"
            severity error;

        wait;
    end process;

end architecture;
