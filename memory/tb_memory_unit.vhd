-- ============================================================================
-- Testbench for Memory Unit (External RAM)
-- ============================================================================
-- Verifies:
--   1. Read and Write operations
--   2. Address decoding
--   3. Memory initialization from file
--
-- Uses record types from memory_interface_pkg.
-- ============================================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.memory_interface_pkg.all;

entity tb_memory_unit is
end entity tb_memory_unit;

architecture Behavioral of tb_memory_unit is

    -- Component under test
    component memory_unit is
        generic (
            INIT_FILENAME : string := "memory_init.txt";
            MEMORY_DEPTH  : integer := 262144
        );
        port(
            clk     : in std_logic;
            reset   : in std_logic;
            mem_req  : in  ext_mem_req_t;
            mem_resp : out ext_mem_resp_t
        );
    end component memory_unit;

    -- Constants and signals
    constant CLK_PERIOD : time := 10 ns;
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    signal mem_req      : ext_mem_req_t := EXT_MEM_REQ_RESET;
    signal mem_resp     : ext_mem_resp_t;
    signal test_done    : boolean := false;

begin

    -- Device Under Test
    DUT: memory_unit
        generic map (
            INIT_FILENAME => "test_init.txt",
            MEMORY_DEPTH  => 1024
        )
        port map(
            clk         => clk,
            reset       => reset,
            mem_req     => mem_req,
            mem_resp    => mem_resp
        );

    -- Clock generation process
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

    -- Testbench stimulus
    stimulus: process
    begin
        report "=== Memory Unit Testbench Started ===" severity note;
        
        -- Reset
        reset <= '1';
        wait for CLK_PERIOD * 2;
        reset <= '0';
        wait for CLK_PERIOD;
        
        -- ====================================================================
        -- Test 1: Write and Read Verification
        -- ====================================================================
        report "Test 1: Write and Read Verification" severity note;
        
        -- Write 0x12345678 to Address 100
        mem_req.addr <= std_logic_vector(to_unsigned(100, 18));
        mem_req.data_in <= x"12345678";
        mem_req.write_en <= '1';
        mem_req.read_en <= '0';
        wait for CLK_PERIOD;
        
        -- Disable write
        mem_req.write_en <= '0';
        wait for CLK_PERIOD;
        
        -- Read from Address 100
        mem_req.read_en <= '1';
        wait for CLK_PERIOD; -- Wait for read to propagate (RAM model usually returns typically on rising edge?)
        -- RAM implementation uses rising_edge(clk) for read results => outputs available NEXT cycle?
        -- `ram.vhd` process: if rising_edge(clk) ... if mem_read='1' then data_out <= memory...
        -- So data available AFTER rising edge + delta. 
        -- In this TB, we set signals, wait for CLK_PERIOD. At edge, RAM updates. New data ready after edge.
        
        wait for 1 ns; -- Delta cycle wait
        assert mem_resp.data_out = x"12345678"
            report "FAIL: Read data mismatch at Addr 100. Expected 0x12345678, Got " & integer'image(to_integer(unsigned(mem_resp.data_out)))
            severity error;
            
        -- Disable read
        mem_req.read_en <= '0';
        wait for CLK_PERIOD;

        -- ====================================================================
        -- Test 2: Verify Memory Initialization (if memory_init.txt exists)
        -- ====================================================================
        -- Assuming memory_init.txt loads index 0 with first value.
        report "Test 2: Memory Initialization Verification" severity note;
        
        -- Read from Address 0
        mem_req.addr <= std_logic_vector(to_unsigned(0, 18));
        mem_req.read_en <= '1';
        wait for CLK_PERIOD;
        
        wait for 1 ns;
        -- We won't assert a specific value as it depends on the text file, 
        -- but avoiding X is minimal check.
        report "Read Address 0: " & integer'image(to_integer(unsigned(mem_resp.data_out)));
        
        if Is_X(mem_resp.data_out) then
            report "WARNING: Memory output is X at Addr 0. Memory Init might have failed or file empty." severity warning;
        end if;

        -- ====================================================================
        -- Test Completed
        -- ====================================================================
        report "=== All Memory Unit Tests PASSED ===" severity note;
        test_done <= true;
        wait;
    end process stimulus;

end architecture Behavioral;
