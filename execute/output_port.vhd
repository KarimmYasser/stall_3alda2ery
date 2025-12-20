LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY output_port IS
    GENERIC (
        DATA_SIZE : INTEGER := 32
    );
    PORT (
        enable: in std_logic;
        data_in : IN STD_LOGIC_VECTOR(DATA_SIZE - 1 DOWNTO 0);
        data_out : OUT STD_LOGIC_VECTOR(DATA_SIZE - 1 DOWNTO 0)
    );
END ENTITY output_port;

architecture behavior OF output_port IS

    -- Internal signal for the output port
    SIGNAL output_signal : STD_LOGIC_VECTOR(DATA_SIZE - 1 DOWNTO 0);
    SIGNAL temp_output_value : STD_LOGIC_VECTOR(DATA_SIZE - 1 DOWNTO 0);
BEGIN
    -- Map the data_in port to the internal signal
    process (enable, data_in)
    begin
        if enable = '1' then
            data_out <= data_in;
            else 
            null; -- Do nothing when not enabled
        end if;
    end process;

END ARCHITECTURE behavior;