-- ============================================================================
-- Fetch Memory Interface Controller
-- ============================================================================
-- Interface controller for Fetch stage to request instructions from memory.
-- Uses record types from memory_interface_pkg for cleaner interface.
-- ============================================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.memory_interface_pkg.all;

entity fetch_mem_interface is
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
end entity fetch_mem_interface;

architecture Behavioral of fetch_mem_interface is
begin
    
    -- Connect PC (lower 18 bits) to arbiter address
    -- PC is 32-bit but memory is 18-bit addressable (256K words)
    arb_if.addr     <= pc(17 downto 0);
    
    -- Read request when fetch is enabled
    arb_if.read_req <= fetch_enable;
    
    -- Pass instruction from arbiter to fetch stage
    instruction     <= arb_resp.data;
    
    -- Pass stall signal from arbiter to fetch stage
    fetch_stall     <= arb_resp.stall;

end architecture Behavioral;
