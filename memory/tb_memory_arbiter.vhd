-- ============================================================================
-- Testbench for Memory Arbiter
-- ============================================================================
-- Verifies:
--   1. Fetch-only access
--   2. Memory-only access (read and write)
--   3. Simultaneous access (Memory has priority)
--   4. Stall signal generation
--
-- Uses record types from memory_interface_pkg.
-- ============================================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.memory_interface_pkg.all;

entity tb_memory_arbiter is
end entity tb_memory_arbiter;

architecture Behavioral of tb_memory_arbiter is

    -- Component under test
    component memory_arbiter is
        port(
            clk         : in std_logic;
            reset       : in std_logic;
            fetch_req   : in  fetch_mem_req_t;
            fetch_resp  : out fetch_mem_resp_t;
            mem_req     : in  data_mem_req_t;
            mem_resp    : out data_mem_resp_t;
            ram_req     : out ext_mem_req_t;
            ram_resp    : in  ext_mem_resp_t
        );
    end component memory_arbiter;

    -- Clock period
    constant CLK_PERIOD : time := 10 ns;
    
    -- Signals
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    
    -- Fetch interface (using records)
    signal fetch_req    : fetch_mem_req_t := FETCH_MEM_REQ_RESET;
    signal fetch_resp   : fetch_mem_resp_t;
    
    -- Memory interface (using records)
    signal mem_req      : data_mem_req_t := DATA_MEM_REQ_RESET;
    signal mem_resp     : data_mem_resp_t;
    
    -- RAM interface (using records)
    signal ram_req      : ext_mem_req_t;
    signal ram_resp     : ext_mem_resp_t := EXT_MEM_RESP_RESET;
    
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

    -- Device Under Test
    DUT: memory_arbiter
        port map(
            clk         => clk,
            reset       => reset,
            fetch_req   => fetch_req,
            fetch_resp  => fetch_resp,
            mem_req     => mem_req,
            mem_resp    => mem_resp,
            ram_req     => ram_req,
            ram_resp    => ram_resp
        );

    -- Testbench stimulus
    stimulus: process
    begin
        -- Initialize
        report "=== Memory Arbiter Testbench Started ===" severity note;
        reset <= '1';
        wait for CLK_PERIOD * 2;
        reset <= '0';
        wait for CLK_PERIOD;
        
        -- ====================================================================
        -- Test 1: Fetch-only access
        -- ====================================================================
        report "Test 1: Fetch-only access" severity note;
        fetch_req.addr <= "000000000000000100";  -- Address 4
        fetch_req.read_req <= '1';
        ram_resp.data_out <= x"DEADBEEF";  -- Simulated RAM response
        wait for CLK_PERIOD;
        
        -- Verify: RAM should receive fetch request
        assert ram_req.addr = "000000000000000100"
            report "FAIL: RAM address mismatch in fetch-only test" severity error;
        assert ram_req.read_en = '1'
            report "FAIL: RAM read not asserted in fetch-only test" severity error;
        assert fetch_resp.stall = '0'
            report "FAIL: Fetch should not be stalled" severity error;
        assert fetch_resp.data = x"DEADBEEF"
            report "FAIL: Fetch data mismatch" severity error;
        
        report "Test 1: PASSED" severity note;
        fetch_req <= FETCH_MEM_REQ_RESET;
        wait for CLK_PERIOD;
        
        -- ====================================================================
        -- Test 2: Memory read access
        -- ====================================================================
        report "Test 2: Memory read access" severity note;
        mem_req.addr <= "000000000000001000";  -- Address 8
        mem_req.read_req <= '1';
        ram_resp.data_out <= x"CAFEBABE";
        wait for CLK_PERIOD;
        
        -- Verify: RAM should receive memory request
        assert ram_req.addr = "000000000000001000"
            report "FAIL: RAM address mismatch in memory read test" severity error;
        assert ram_req.read_en = '1'
            report "FAIL: RAM read not asserted in memory read test" severity error;
        assert mem_resp.read_data = x"CAFEBABE"
            report "FAIL: Memory data mismatch" severity error;
            
        report "Test 2: PASSED" severity note;
        mem_req <= DATA_MEM_REQ_RESET;
        wait for CLK_PERIOD;
        
        -- ====================================================================
        -- Test 3: Memory write access
        -- ====================================================================
        report "Test 3: Memory write access" severity note;
        mem_req.addr <= "000000000000010000";  -- Address 16
        mem_req.write_req <= '1';
        mem_req.write_data <= x"12345678";
        wait for CLK_PERIOD;
        
        -- Verify: RAM should receive write request
        assert ram_req.addr = "000000000000010000"
            report "FAIL: RAM address mismatch in memory write test" severity error;
        assert ram_req.write_en = '1'
            report "FAIL: RAM write not asserted" severity error;
        assert ram_req.data_in = x"12345678"
            report "FAIL: RAM data input mismatch" severity error;
            
        report "Test 3: PASSED" severity note;
        mem_req <= DATA_MEM_REQ_RESET;
        wait for CLK_PERIOD;
        
        -- ====================================================================
        -- Test 4: Simultaneous access (Memory has priority)
        -- ====================================================================
        report "Test 4: Simultaneous access - Memory priority" severity note;
        fetch_req.addr <= "000000000000000001";  -- Fetch at address 1
        fetch_req.read_req <= '1';
        mem_req.addr <= "000000000000000010";    -- Memory at address 2
        mem_req.read_req <= '1';
        ram_resp.data_out <= x"AABBCCDD";
        wait for CLK_PERIOD;
        
        -- Verify: Memory should win, Fetch should be stalled
        assert ram_req.addr = "000000000000000010"
            report "FAIL: Memory should have priority over Fetch" severity error;
        assert fetch_resp.stall = '1'
            report "FAIL: Fetch should be stalled when Memory is active" severity error;
        assert mem_resp.stall = '0'
            report "FAIL: Memory should not be stalled" severity error;
        assert mem_resp.read_data = x"AABBCCDD"
            report "FAIL: Memory data output mismatch" severity error;
            
        report "Test 4: PASSED" severity note;
        fetch_req <= FETCH_MEM_REQ_RESET;
        mem_req <= DATA_MEM_REQ_RESET;
        wait for CLK_PERIOD;
        
        -- ====================================================================
        -- Test 5: No active requests
        -- ====================================================================
        report "Test 5: No active requests (idle state)" severity note;
        wait for CLK_PERIOD;
        
        assert fetch_resp.stall = '0'
            report "FAIL: Fetch should not be stalled when idle" severity error;
        assert mem_resp.stall = '0'
            report "FAIL: Memory should not be stalled when idle" severity error;
            
        report "Test 5: PASSED" severity note;
        
        -- ====================================================================
        -- All tests completed
        -- ====================================================================
        report "=== All Memory Arbiter Tests PASSED ===" severity note;
        
        test_done <= true;
        wait;
    end process stimulus;

end architecture Behavioral;
