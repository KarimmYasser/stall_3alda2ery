-- ============================================================================
-- Memory Unit - External Memory for Von Neumann Architecture
-- ============================================================================
-- This component represents the EXTERNAL memory (RAM) that sits outside
-- the processor. The memory arbiter is inside the processor and arbitrates
-- between Fetch and Memory stages before sending requests here.
--
-- Uses record types from memory_interface_pkg for cleaner interface.
-- ============================================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.memory_interface_pkg.all;

entity memory_unit is
    generic (
        INIT_FILENAME : string := "memory_init.txt";
        MEMORY_DEPTH  : integer := 262144
    );
    port(
        -- Clock and reset
        clk     : in std_logic;
        reset   : in std_logic;
        
        -- Memory interface (using record types)
        mem_req  : in  ext_mem_req_t;       -- Request from arbiter
        mem_resp : out ext_mem_resp_t       -- Response to arbiter
    );
end entity memory_unit;

architecture Structural of memory_unit is
    
    -- RAM component
    component ram is
        generic (
            INIT_FILENAME : string := "memory_init.txt";
            MEMORY_DEPTH  : integer := 262144
        );
        port(
            clk         : in  std_logic;
            reset       : in  std_logic;
            mem_read    : in  std_logic;
            mem_write   : in  std_logic;
            addr        : in  std_logic_vector(17 downto 0);
            data_in     : in  std_logic_vector(31 downto 0);
            data_out    : out std_logic_vector(31 downto 0)
        );
    end component ram;
    
begin
    
    -- RAM instance - connect record fields to RAM ports
    RAM_INST: ram
        generic map (
            INIT_FILENAME => INIT_FILENAME,
            MEMORY_DEPTH  => MEMORY_DEPTH
        )
        port map(
            clk         => clk,
            reset       => reset,
            mem_read    => mem_req.read_en,
            mem_write   => mem_req.write_en,
            addr        => mem_req.addr,
            data_in     => mem_req.data_in,
            data_out    => mem_resp.data_out
        );

end architecture Structural;
