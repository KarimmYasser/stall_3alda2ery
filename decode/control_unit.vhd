LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
Entity Control_Unit is
    Port(
        clk: IN Std_logic;
        inturrupt : in std_logic;
        op_code : in std_logic_vector(4 downto 0); --uses mem| sel--
        data_ready : in std_logic;
        ccr_data : in std_logic_vector(2 downto 0);
        FD_enable : out std_logic;
        Micro_inst: out std_logic_vector(4 downto 0);
        Stall :out std_logic;
        DE_enable :out  std_logic;
        EM_enable : out std_logic;
        MW_enable :out std_logic;
        Branch_Decode: out std_logic;
        ID_flush :out std_logic;
        WB_flages: out std_logic_vector(2 downto 0); --RegWrite,MemtoReg,PC-select--
        EXE_flages: out std_logic_vector(4 downto 0); --ALUOp(3),ALUSrc,Index--
        MEM_flages: out std_logic_vector(6 downto 0); --WDselect,MEMRead,MEMWrite,StackRead,StackWrite,CCRStore,CCRLoad--
        IO_flages: out std_logic_vector(1 downto 0); --output, input--
        CSwap : out std_logic 
    );
END entity Control_Unit;

architecture behavior of Control_Unit is
    signal counter : integer := 0;
    constant inturrupt_counter_limit : integer := 3;
    constant Swap_RTI_counter_limit : integer := 2;

    begin
        Process(clk)
        begin
            if  rising_edge(clk) THEN
                -- Default signal assignments
                FD_enable <= '1';
                DE_enable <= '1';
                EM_enable <= '1';
                MW_enable <= '1';
                Stall <= '0';
                ID_flush <= '0';
                Branch_Decode <= '0';
                CSwap <= '0';
                Micro_inst <= (others => '0');
                WB_flages <= (others => '0');
                EXE_flages <= (others => '0');
                MEM_flages <= (others => '0');
                IO_flages <= (others => '0');
                if inturrupt = '1' THEN
                    --handle interrupt
                    if counter < inturrupt_counter_limit THEN
                        Stall <= '1';

                        case counter is
                            when 0 => --data write mux sel is 00 
                                Micro_inst <= "11111";
                                MEM_flages(2) <= '1'; --StackWrite
                                MEM_flages(6) <= '1'; --WDselect
                            when 1 => --data write mux sel is 11
                                Micro_inst <= "11111";
                                MEM_flages(1) <= '1'; --CCRStore
                                MEM_flages(6) <= '0'; --WDselect
                                MEM_flages(4) <= '1'; --MEMWrite   ################################
                            when 2 => --data read
                                Micro_inst <= "11111";
                                MEM_flages(5) <= '1'; --MEMRead
                            when others =>
                                Micro_inst <= (others => '0');
                        end case;
                        counter <=counter+1;
                    else
                        counter <= 0;
                    end if;
                elsif op_code(4) ='0' then
                    case op_code(3 downto 0) is
                        when "0000" => --noop--
                        
                        when "0001" => -- hlt--
                            FD_enable <= '0';
                            DE_enable <= '0';
                            CStall <= '1';
                        when "0010" => -- SetC--
                            EXE_flages(4 downto 2) <= "111"; --Indexing ########## waiting for ALU Op codes setc
                        when "0011" => --inc--
                            EXE_flages(4 downto 2) <= "000"; --Indexing ########## waiting for ALU Op codes add 1
                            WB_flages(2) <= '1'; --RegWrite
                        when "0100" => --not--
                            EXE_flages(4 downto 2) <= "001"; --Indexing ########## waiting for ALU Op codes not
                            WB_flages(2) <= '1'; --RegWrite
                        when "0101" => --LDM--
                            EXE_flages(4 downto 2) <= "010"; --Indexing ########## waiting for ALU Op codes add
                            EXE_flages(1) <= '1'; --ALUSrc
                            WB_flages(2) <= '1'; --RegWrite
                        when "0110" => --mov--
                            WB_flages(2) <= '1'; --RegWrite
                        when "0111" => --SWAP--
                            if counter < Swap_RTI_counter_limit THEN
                                Stall <= '1';
                                Micro_inst <= "10111"; --SWAP micro-instruction
                                case counter is
                                    when 0 => 
                                        WB_flages(2) <= '1'; --RegWrite
                                        CSwap <= '1';
                                    when 1 => 
                                        WB_flages(2) <= '1'; --RegWrite
                                        CSwap <= '1';
                                    when others =>
                                        Micro_inst <= (others => '0');
                                end case;
                                counter <=counter+1;
                            else
                                counter <= 0;
                            end if;
                        when "1000" => --IADD--
                            EXE_flages(4 downto 2) <= "010"; --Indexing ########## waiting for ALU Op codes add
                            EXE_flages(1) <= '1'; --ALUSrc
                            WB_flages(2) <= '1'; --RegWrite
                        when "1001" => --add--
                            EXE_flages(4 downto 2) <= "010"; --Indexing ########## waiting for ALU Op codes add
                            WB_flages(2) <= '1'; --RegWrite
                        when "1010" => --sub--
                            EXE_flages(4 downto 2) <= "011"; --Indexing ########## waiting for ALU Op codes sub
                            WB_flages(2) <= '1'; --RegWrite
                        when "1011" => --AND--
                            EXE_flages(4 downto 2) <= "100"; --Indexing ########## waiting for ALU Op codes and
                            WB_flages(2) <= '1'; --RegWrite
                        when "1100" => --JZ--
                         
                        when "1101" => --JNZ--
                            
                        when "1110" => --JC--
                            
                        when "1111" => --JMP--
                            branch_Decode <= '1';
                            ID_flush <= '1';
                        when others =>
                            null;
                    end case;
                else
                    case op_code(3 downto 0) is
                        when "0000" => --out--
                            IO_flages(1) <= '1'; --output
                        when "0001" => --in--
                            IO_flages(0) <= '1'; --input
                            WB_flages(2) <= '1'; --RegWrite

                        when "0010" => --push--
                            MEM_flages(2) <= '1'; --StackWrite
                            MEM_flages(6) <= '0'; --WDselect

                        when "0011" => --pop--
                            MEM_flages(3) <= '1'; --StackRead
                            WB_flages(2) <= '1'; --RegWrite
                            --#####################################################################################
                        when "0100" --LDD--
                            MEM_flages(0) <= '1'; --MEMRead
                            WB_flages(1) <= '1'; --MemtoReg
                            WB_flages(2) <= '1'; --RegWrite
                            EXE_flages(1) <= '1'; --ALUSrc
                        when "0101" --STD--
                            MEM_flages(4) <= '1'; --MEMWrite
                            EXE_flages(1) <= '1'; --ALUSrc
                            MEM_flages(6) <= '0'; --WDselect
                        when "0110"  --call--
                            branch_Decode <= '1';
                            ID_flush <= '1';
                            MEM_flages(2) <= '1'; --StackWrite
                            MEM_flages(6) <= '1'; --WDselect
                            WB_flages(0) <= '1'; --PC-select
                            ALU_flages(1) <= '1'; --ALUSrc
                        when "0111"  --ret--
                            MEM_flages(3) <= '1'; --StackRead
                        when "1000" --int--
                            if counter < inturrupt_counter_limit THEN
                                Stall <= '1';

                                case counter is
                                    when 0 => --data write mux sel is 00 
                                        Micro_inst <= "11000";
                                        MEM_flages(2) <= '1'; --StackWrite
                                        MEM_flages(6) <= '1'; --WDselect
                                        WB_flages(0) <= '1'; --Write to PC+1
                                    when 1 => --data write mux sel is 11
                                        Micro_inst <= "11000"; 
                                        MEM_flages(1) <= '1'; --CCRStore
                                        MEM_flages(6) <= '0'; --WDselect
                                        MEM_flages(4) <= '1'; --MEMWrite
                                    when 2 => --data read
                                        Micro_inst <= "11000";
                                        MEM_flages(5) <= '1'; --MEMRead
                                        ALU_flages(1) <= '0'; --ALUSrc
                                        ALU_flages(0) <= '1'; --Index
                                        ALU_flages(4 downto 2) <= "010"; --Indexing ########## waiting for ALU Op codes add
                                    when others =>
                                        Micro_inst <= (others => '0');
                                end case;
                                counter <=counter+1;
                            else
                                counter <= 0;
                            end if;
                        when "1001" => --rti--
                            if counter < Swap_RTI_counter_limit THEN
                                Stall <= '1';
                                Micro_inst <= "11001"; --RTI micro-instruction
                                case counter is
                                    when 0 => 
                                        MEM_flages(6) <= '1'; --WDselect
                                        MEM_flages(1) <= '1'; --CCRLoad
                                    when 1 => 
                                        MEM_flages(3) <= '1'; --StackRead
                                    when others =>
                                        Micro_inst <= (others => '0');
                                end case;
                                counter <=counter+1;
                            else
                                counter <= 0;
                            end if;
                        when others =>
                            null;
                    end case;
            end if;
        end if;
    end Process;
end architecture behavior;
