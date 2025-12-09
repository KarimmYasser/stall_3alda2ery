-- ============================================================================
-- Data Memory Interface Controller
-- ============================================================================
-- Interface controller for Memory stage to perform load/store operations.
-- Uses record types from memory_interface_pkg for cleaner interface.
-- ============================================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.memory_interface_pkg.all;

entity data_mem_interface is
    port(
        -- Clock and reset
        clk             : in std_logic;
        reset           : in std_logic;
        
        -- Memory stage signals
        mem_addr        : in  std_logic_vector(31 downto 0);  -- Address (from ALU/SP)
        mem_read        : in  std_logic;                       -- Load operation
        mem_write       : in  std_logic;                       -- Store operation
        mem_write_data  : in  std_logic_vector(31 downto 0);  -- Data to store
        mem_read_data   : out std_logic_vector(31 downto 0);  -- Data loaded
        mem_stall       : out std_logic;                       -- Stall to memory stage
        
        -- Arbiter interface using record types
        arb_if          : out data_mem_req_t;                  -- Request to arbiter
        arb_resp        : in  data_mem_resp_t                  -- Response from arbiter
    );
end entity data_mem_interface;

architecture Behavioral of data_mem_interface is
begin
    
    -- Connect address (lower 18 bits) to arbiter
    arb_if.addr       <= mem_addr(17 downto 0);
    
    -- Pass read/write requests to arbiter
    arb_if.read_req   <= mem_read;
    arb_if.write_req  <= mem_write;
    
    -- Pass write data to arbiter
    arb_if.write_data <= mem_write_data;
    
    -- Pass read data from arbiter to memory stage
    mem_read_data     <= arb_resp.read_data;
    
    -- Pass stall signal from arbiter to memory stage
    mem_stall         <= arb_resp.stall;

end architecture Behavioral;
