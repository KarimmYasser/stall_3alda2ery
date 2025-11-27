LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_textio.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.numeric_std.ALL;
USE std.textio.ALL;

ENTITY ram IS
    PORT (
        clk         : IN STD_LOGIC;
        reset       : IN STD_LOGIC;
        mem_read    : IN STD_LOGIC;
        mem_write   : IN STD_LOGIC;
        addr        : IN STD_LOGIC_VECTOR(17 DOWNTO 0);  -- 2^18 words = 1 MB (word-addressable)
        data_in     : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        data_out    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END ENTITY ram;

ARCHITECTURE arch_ram OF ram IS
    -- Define memory array: 1 MB total (2^18 words × 32-bit = 262,144 words)
    TYPE MemoryArray IS ARRAY(0 TO 262143) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    
    -- Declare memory signal with default initialization
    SIGNAL memory : MemoryArray := (OTHERS => (OTHERS => '0'));

BEGIN

    ram_process : PROCESS (clk, reset, addr, data_in, mem_write, mem_read, memory) IS
        FILE memory_file : TEXT;
        VARIABLE fileLineContent : LINE;
        VARIABLE temp_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
        VARIABLE address_index : INTEGER;
    BEGIN
        -- Reset: Load memory from file
        IF (reset = '1') THEN
            -- Open memory initialization file
            file_open(memory_file, "memory_init.txt", READ_MODE);
            
            -- Load program/data from file
            FOR i IN memory'RANGE LOOP
                IF NOT ENDFILE(memory_file) THEN
                    readline(memory_file, fileLineContent);
                    read(fileLineContent, temp_data);
                    memory(i) <= temp_data;
                ELSE
                    -- If file ends before filling all memory, close and exit
                    file_close(memory_file);
                    EXIT;
                END IF;
            END LOOP;
            
            -- Initialize output
            data_out <= (OTHERS => '0');
            
        -- Normal operation on clock edge
        ELSIF rising_edge(clk) THEN
            address_index := to_integer(unsigned(addr));
            
            -- Write operation
            IF mem_write = '1' THEN
                memory(address_index) <= data_in;
            END IF;
            
            -- Read operation
            IF mem_read = '1' THEN
                data_out <= memory(address_index);
            END IF;
        END IF;
    END PROCESS ram_process;

END ARCHITECTURE arch_ram;
