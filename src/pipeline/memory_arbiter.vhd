-- ============================================================================
-- Memory Arbiter for Von Neumann Architecture
-- ============================================================================
-- Arbitrates between Fetch stage (instruction reads) and Memory stage 
-- (data reads/writes) for access to unified memory.
-- 
-- Priority: Memory stage has higher priority than Fetch stage
-- Uses record types from memory_interface_pkg for cleaner interfaces.
-- ============================================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.memory_interface_pkg.all;

entity memory_arbiter is
    port(
        -- Clock and reset
        clk     : in std_logic;
        reset   : in std_logic;
        
        -- Fetch stage interface (using record types)
        fetch_req       : in  fetch_mem_req_t;              -- Request from fetch
        fetch_resp      : out fetch_mem_resp_t;             -- Response to fetch
        
        -- Memory stage interface (using record types)
        mem_req         : in  data_mem_req_t;               -- Request from memory stage
        mem_resp        : out data_mem_resp_t;              -- Response to memory stage
        
        -- RAM interface (using record types)
        ram_req         : out ext_mem_req_t;                -- Request to RAM
        ram_resp        : in  ext_mem_resp_t                -- Response from RAM
    );
end entity memory_arbiter;

architecture Behavioral of memory_arbiter is
    -- Internal signals
    signal mem_active   : std_logic;  -- Memory stage is requesting
    signal fetch_active : std_logic;  -- Fetch stage is requesting
    
begin
    -- Determine active requests
    mem_active   <= mem_req.read_req or mem_req.write_req;
    fetch_active <= fetch_req.read_req;
    
    -- ========================================================================
    -- Arbiter Combinational Logic
    -- Priority: Memory stage > Fetch stage
    -- ========================================================================
    arbiter_logic: process(mem_active, fetch_active, mem_req, fetch_req, ram_resp)
    begin
        -- Default outputs
        ram_req         <= EXT_MEM_REQ_RESET;
        fetch_resp      <= FETCH_MEM_RESP_RESET;
        mem_resp        <= DATA_MEM_RESP_RESET;
        
        if mem_active = '1' then
            -- Memory stage has priority - grant access
            ram_req.addr     <= mem_req.addr;
            ram_req.read_en  <= mem_req.read_req;
            ram_req.write_en <= mem_req.write_req;
            ram_req.data_in  <= mem_req.write_data;
            mem_resp.read_data <= ram_resp.data_out;
            
            -- Stall fetch stage while memory is active
            fetch_resp.stall <= '1';
            mem_resp.stall   <= '0';
            
        elsif fetch_active = '1' then
            -- Fetch stage - grant access when memory is idle
            ram_req.addr     <= fetch_req.addr;
            ram_req.read_en  <= fetch_req.read_req;
            ram_req.write_en <= '0';
            fetch_resp.data  <= ram_resp.data_out;
            
            fetch_resp.stall <= '0';
            mem_resp.stall   <= '0';
            
        else
            -- No active requests - idle state
            fetch_resp.stall <= '0';
            mem_resp.stall   <= '0';
        end if;
    end process arbiter_logic;

end architecture Behavioral;
