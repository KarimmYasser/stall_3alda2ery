LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_textio.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.numeric_std.ALL;
USE std.textio.ALL;

ENTITY ram IS
    GENERIC (
        INIT_FILENAME : STRING := "memory_init.txt";
        MEMORY_DEPTH  : INTEGER := 262144 -- 2^18 words
    );
    PORT (
        clk         : IN STD_LOGIC;
        reset       : IN STD_LOGIC;
        mem_read    : IN STD_LOGIC;
        mem_write   : IN STD_LOGIC;
        addr        : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
        data_in     : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        data_out    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END ENTITY ram;

ARCHITECTURE arch_ram OF ram IS
    TYPE MemoryArray IS ARRAY(0 TO MEMORY_DEPTH-1) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL memory : MemoryArray := (OTHERS => (OTHERS => '0'));

BEGIN

    ram_process : PROCESS (clk, reset) IS
        FILE memory_file : TEXT;
        VARIABLE fileLineContent : LINE;
        VARIABLE temp_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
        VARIABLE address_index : INTEGER;
        VARIABLE file_status : FILE_OPEN_STATUS;
    BEGIN
        IF (reset = '1') THEN
            -- Safe File Loading
            file_open(file_status, memory_file, INIT_FILENAME, READ_MODE);
            
            IF file_status = OPEN_OK THEN
                FOR i IN memory'RANGE LOOP
                    IF NOT ENDFILE(memory_file) THEN
                        readline(memory_file, fileLineContent);
                        hread(fileLineContent, temp_data);
                        memory(i) <= temp_data;
                    ELSE
                        EXIT;
                    END IF;
                END LOOP;
                file_close(memory_file);
            END IF;
            
            data_out <= (OTHERS => '0'); -- Clear data_out on reset
            
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
