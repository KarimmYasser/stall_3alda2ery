-- ============================================================================
-- Memory Interface Package - Interface record types for Von Neumann Architecture
-- ============================================================================
-- Defines standardized memory interface records for Fetch and Memory stages
-- to communicate with the Memory Arbiter.
--
-- Records are split into request/response for clean port mapping:
--   - Request records: Stage → Arbiter
--   - Response records: Arbiter → Stage
-- ============================================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package memory_interface_pkg is

    -- ========================================================================
    -- Fetch Stage Memory Interface
    -- ========================================================================
    
    -- Request: Fetch → Arbiter
    type fetch_mem_req_t is record
        addr        : std_logic_vector(17 downto 0);  -- Address (PC[17:0])
        read_req    : std_logic;                       -- Read request
    end record fetch_mem_req_t;
    
    -- Response: Arbiter → Fetch
    type fetch_mem_resp_t is record
        data        : std_logic_vector(31 downto 0);  -- Instruction data
        stall       : std_logic;                       -- Stall signal
    end record fetch_mem_resp_t;
    
    -- Reset values
    constant FETCH_MEM_REQ_RESET : fetch_mem_req_t := (
        addr        => (others => '0'),
        read_req    => '0'
    );
    
    constant FETCH_MEM_RESP_RESET : fetch_mem_resp_t := (
        data        => (others => '0'),
        stall       => '0'
    );
    
    -- ========================================================================
    -- Data Memory Interface (Memory Stage)
    -- ========================================================================
    
    -- Request: Memory Stage → Arbiter
    type data_mem_req_t is record
        addr        : std_logic_vector(17 downto 0);  -- Data address
        read_req    : std_logic;                       -- Read request
        write_req   : std_logic;                       -- Write request
        write_data  : std_logic_vector(31 downto 0);  -- Data to write
    end record data_mem_req_t;
    
    -- Response: Arbiter → Memory Stage
    type data_mem_resp_t is record
        read_data   : std_logic_vector(31 downto 0);  -- Data read
        stall       : std_logic;                       -- Stall signal
    end record data_mem_resp_t;
    
    -- Reset values
    constant DATA_MEM_REQ_RESET : data_mem_req_t := (
        addr        => (others => '0'),
        read_req    => '0',
        write_req   => '0',
        write_data  => (others => '0')
    );
    
    constant DATA_MEM_RESP_RESET : data_mem_resp_t := (
        read_data   => (others => '0'),
        stall       => '0'
    );
    
    -- ========================================================================
    -- External Memory Interface (Arbiter → Memory Unit)
    -- ========================================================================
    
    -- Request: Arbiter → RAM
    type ext_mem_req_t is record
        addr        : std_logic_vector(17 downto 0);
        read_en     : std_logic;
        write_en    : std_logic;
        data_in     : std_logic_vector(31 downto 0);
    end record ext_mem_req_t;
    
    -- Response: RAM → Arbiter
    type ext_mem_resp_t is record
        data_out    : std_logic_vector(31 downto 0);
    end record ext_mem_resp_t;
    
    -- Reset values
    constant EXT_MEM_REQ_RESET : ext_mem_req_t := (
        addr        => (others => '0'),
        read_en     => '0',
        write_en    => '0',
        data_in     => (others => '0')
    );
    
    constant EXT_MEM_RESP_RESET : ext_mem_resp_t := (
        data_out    => (others => '0')
    );

end package memory_interface_pkg;
