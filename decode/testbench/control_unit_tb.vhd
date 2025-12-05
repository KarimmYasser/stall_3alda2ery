-- filepath: c:\Users\ASUS\Desktop\SWE_Ass\stall_3alda2ery\decode\testbench\control_unit_tb.vhd
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_textio.ALL;
USE STD.textio.ALL;

ENTITY control_unit_tb IS
END ENTITY control_unit_tb;

ARCHITECTURE testbench OF control_unit_tb IS
    -- Component declaration
    COMPONENT Control_Unit IS
        PORT(
            clk: IN Std_logic;
            inturrupt : in std_logic;
            op_code : in std_logic_vector(4 downto 0);
            data_ready : in std_logic;
            FD_enable : out std_logic;
            Micro_inst: out std_logic_vector(4 downto 0);
            Stall :out std_logic;
            DE_enable :out  std_logic;
            EM_enable : out std_logic;
            MW_enable :out std_logic;
            Branch_Decode: out std_logic;
            ID_flush :out std_logic;
            WB_flages: out std_logic_vector(2 downto 0);
            EXE_flages: out std_logic_vector(4 downto 0);
            MEM_flages: out std_logic_vector(6 downto 0);
            IO_flages: out std_logic_vector(1 downto 0);
            CSwap : out std_logic 
        );
    END COMPONENT;

    -- Signals
    SIGNAL clk : std_logic;
    SIGNAL inturrupt : std_logic;
    SIGNAL op_code : std_logic_vector(4 downto 0);
    SIGNAL data_ready : std_logic;
    SIGNAL FD_enable : std_logic;
    SIGNAL Micro_inst: std_logic_vector(4 downto 0);
    SIGNAL Stall : std_logic;
    SIGNAL DE_enable : std_logic;
    SIGNAL EM_enable : std_logic;
    SIGNAL MW_enable : std_logic;
    SIGNAL Branch_Decode: std_logic;
    SIGNAL ID_flush : std_logic;
    SIGNAL WB_flages: std_logic_vector(2 downto 0);
    SIGNAL EXE_flages: std_logic_vector(4 downto 0);
    SIGNAL MEM_flages: std_logic_vector(6 downto 0);
    SIGNAL IO_flages: std_logic_vector(1 downto 0);
    SIGNAL CSwap : std_logic;

END ARCHITECTURE testbench;
