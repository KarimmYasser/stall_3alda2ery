LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
Entity Control_Unit is
    Port(
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
END entity Control_Unit;

architecture behavior of Control_Unit is
    type micro_state_type is (
        M_IDLE,
        M_INT_Sig_0, M_INT_Sig_1, M_INT_Sig_2,
        M_INT_0, M_INT_1, M_INT_2,
        M_SWAP_0, M_SWAP_1,
        M_RTI_0, M_RTI_1
    );

    signal micro_state : micro_state_type := M_IDLE;
    signal micro_next  : micro_state_type := M_IDLE;
    signal micro_active : std_logic := '0';

    -- micro-generated control signals (active when micro_active = '1')
    signal micro_FD_enable  : std_logic := '1';
    signal micro_DE_enable  : std_logic := '1';
    signal micro_EM_enable  : std_logic := '1';
    signal micro_MW_enable  : std_logic := '1';
    signal micro_Stall      : std_logic := '0';
    signal micro_ID_flush   : std_logic := '0';
    signal micro_Branch_Decode : std_logic := '0';
    signal micro_CSwap      : std_logic := '0';
    signal micro_Micro_inst : std_logic_vector(4 downto 0) := (others => '0');
    signal micro_WB_flages  : std_logic_vector(2 downto 0) := (others => '0');
    signal micro_EXE_flages : std_logic_vector(4 downto 0) := (others => '0');
    signal micro_MEM_flages : std_logic_vector(6 downto 0) := (others => '0');
    signal micro_IO_flages  : std_logic_vector(1 downto 0) := (others => '0');

    ------------------------------------------------------------------
    -- Main (combinational) decoder signals
    ------------------------------------------------------------------
    signal main_FD_enable  : std_logic := '1';
    signal main_DE_enable  : std_logic := '1';
    signal main_EM_enable  : std_logic := '1';
    signal main_MW_enable  : std_logic := '1';
    signal main_Stall      : std_logic := '0';
    signal main_ID_flush   : std_logic := '0';
    signal main_Branch_Decode : std_logic := '0';
    signal main_CSwap      : std_logic := '0';
    signal main_Micro_inst : std_logic_vector(4 downto 0) := (others => '0');
    signal main_WB_flages  : std_logic_vector(2 downto 0) := (others => '0');
    signal main_EXE_flages : std_logic_vector(4 downto 0) := (others => '0');
    signal main_MEM_flages : std_logic_vector(6 downto 0) := (others => '0');
    signal main_IO_flages  : std_logic_vector(1 downto 0) := (others => '0');
    signal start_swap_req : std_logic := '0';
    signal start_int_req  : std_logic := '0';
    signal start_rti_req  : std_logic := '0';
    signal start_int_signal_req  : std_logic := '0';
    ------------------------------------------------------------------
    -- Final outputs are multiplexed between micro_ and main_
    ------------------------------------------------------------------
    begin
    Micro_seq : Process(clk)
        begin
            if rising_edge(clk) then
                micro_state <= micro_next;
            end if;
        end process Micro_seq;

    -- Combinational logic to determine micro_active based on current state
    micro_active <= '0' when micro_state = M_IDLE else '1';

    Micro_comb :process(micro_state,inturrupt,start_int_signal_req,start_swap_req,start_rti_req,
                        start_int_req)
            begin
                -- defaults for micro signals (inactive)
                micro_next <= micro_state;
                micro_FD_enable  <= '1';
                micro_DE_enable  <= '1';
                micro_EM_enable  <= '1';
                micro_MW_enable  <= '1';
                micro_Stall      <= '0';
                micro_ID_flush   <= '0';
                micro_Branch_Decode <= '0';
                micro_CSwap      <= '0';
                micro_Micro_inst <= (others => '0');
                micro_WB_flages  <= (others => '0');
                micro_EXE_flages <= (others => '0');
                micro_MEM_flages <= (others => '0');
                micro_IO_flages  <= (others => '0');
                
                case micro_state is
                    when M_IDLE =>
                        -- Check for micro-sequence requests from main decoder
                        if start_swap_req = '1' then
                            micro_next <= M_SWAP_0;
                        elsif start_int_req = '1' then
                            micro_next <= M_INT_0;
                        elsif start_rti_req = '1' then
                            micro_next <= M_RTI_0;
                        elsif start_int_signal_req = '1' then
                            micro_next <= M_INT_Sig_0;
                        elsif inturrupt = '1' then
                            micro_next <= M_INT_Sig_0;
                        else
                            micro_next <= M_IDLE;
                        end if;
                    
                    -- Interrupt Signal Sequence (external interrupt)
                    when M_INT_Sig_0 =>
                        -- First cycle: write PC to stack
                        micro_Stall <= '1';
                        micro_Micro_inst <= "00000";
                        micro_MEM_flages(2) <= '1'; --StackWrite
                        micro_MEM_flages(6) <= '1'; --WDselect
                        micro_next <= M_INT_Sig_1;
                    when M_INT_Sig_1 =>
                        -- Second cycle: store CCR and write to memory
                        micro_Stall <= '1';
                        micro_Micro_inst <= "00000";
                        micro_MEM_flages(1) <= '1'; --CCRStore
                        micro_MEM_flages(6) <= '0'; --WDselect
                        micro_MEM_flages(4) <= '1'; --MEMWrite
                        micro_next <= M_INT_Sig_2;
                    when M_INT_Sig_2 =>
                        -- Third cycle: read interrupt vector
                        micro_Stall <= '1';
                        micro_Micro_inst <= "00000";
                        micro_MEM_flages(5) <= '1'; --MEMRead
                        micro_next <= M_IDLE;
                    
                    -- INT Instruction Sequence
                    when M_INT_0 =>
                        -- First cycle: write PC+1 to stack
                        micro_Stall <= '1';
                        micro_Micro_inst <= "00000";
                        micro_MEM_flages(2) <= '1'; --StackWrite
                        micro_MEM_flages(6) <= '1'; --WDselect
                        micro_WB_flages(0) <= '1'; --PC+1
                        micro_next <= M_INT_1;
                    when M_INT_1 =>
                        -- Second cycle: store CCR and write to memory
                        micro_Stall <= '1';
                        micro_Micro_inst <= "00000";
                        micro_MEM_flages(1) <= '1'; --CCRStore
                        micro_MEM_flages(6) <= '0'; --WDselect
                        micro_MEM_flages(4) <= '1'; --MEMWrite
                        micro_next <= M_INT_2;
                    when M_INT_2 =>
                        -- Third cycle: read interrupt vector with indexing
                        micro_Stall <= '1';
                        micro_Micro_inst <= "00000";
                        micro_MEM_flages(5) <= '1'; --MEMRead
                        micro_EXE_flages(1) <= '0'; --ALUSrc
                        micro_EXE_flages(0) <= '1'; --Index
                        micro_EXE_flages(4 downto 2) <= "010";
                        micro_next <= M_IDLE;
                    
                    -- SWAP Instruction Sequence
                    when M_SWAP_0 =>
                        -- First cycle: stall, prepare (CSwap=0)
                        micro_Stall <= '1';
                        micro_WB_flages(2) <= '1'; --RegWrite
                        micro_CSwap <= '0';
                        micro_Micro_inst <= "00000";
                        micro_next <= M_SWAP_1;
                    when M_SWAP_1 =>
                        -- Second cycle: perform swap (CSwap=1)
                        micro_Stall <= '1';
                        micro_WB_flages(2) <= '1'; --RegWrite
                        micro_CSwap <= '1';
                        micro_Micro_inst <= "00000";
                        micro_next <= M_IDLE;
                    
                    -- RTI Instruction Sequence
                    when M_RTI_0 =>
                        -- First cycle: prepare, set flags
                        micro_Stall <= '1';
                        micro_MEM_flages(6) <= '1'; --WDselect
                        micro_MEM_flages(0) <= '1'; --CCRLoad
                        micro_Micro_inst <= "00000";
                        micro_next <= M_RTI_1;
                    when M_RTI_1 =>
                        -- Second cycle: read from stack
                        micro_Stall <= '1';
                        micro_MEM_flages(3) <= '1'; --StackRead
                        micro_Micro_inst <= "00000";
                        micro_next <= M_IDLE;
                    
                    when others =>
                        micro_next <= M_IDLE;
                end case;
            end process Micro_comb;

Main_comb :  Process(op_code,data_ready,inturrupt)
        begin
        -- default main outputs
            main_FD_enable  <= '1';
            main_DE_enable  <= '1';
            main_EM_enable  <= '1';
            main_MW_enable  <= '1';
            main_Stall      <= '0';
            main_ID_flush   <= '0';
            main_Branch_Decode <= '0';
            main_CSwap      <= '0';
            main_Micro_inst <= (others => '0');
            main_WB_flages  <= (others => '0');
            main_EXE_flages <= (others => '0');
            main_MEM_flages <= (others => '0');
            main_IO_flages  <= (others => '0');
            start_swap_req <= '0';
            start_int_req  <= '0';
            start_rti_req  <= '0';
            start_int_signal_req  <= '0';
                if(inturrupt='1')then
                    main_Stall <='1';
                    main_Micro_inst <= "11111"; -- request micro INT sequence
                    main_MEM_flages(2) <= '1'; --StackWrite
                    main_MEM_flages(6) <= '1'; --WDselect
                    start_int_signal_req <= '1';

                elsif op_code(4) ='0' then
                    case op_code(3 downto 0) is
                        when "0000" => --noop--
                        null;
                        when "0001" => -- hlt--
                            main_FD_enable <= '0';
                            main_DE_enable <= '0';
                            main_Stall <= '1';
                        when "0010" => -- SetC--
                            main_EXE_flages(4 downto 2) <= "111"; --Indexing ########## waiting for ALU Op codes setc
                        when "0011" => --inc--
                            main_EXE_flages(4 downto 2) <= "000"; --Indexing ########## waiting for ALU Op codes add 1
                            main_WB_flages(2) <= '1'; --RegWrite
                        when "0100" => --not--
                            main_EXE_flages(4 downto 2) <= "001"; --Indexing ########## waiting for ALU Op codes not
                            main_WB_flages(2) <= '1'; --RegWrite
                        when "0101" => --LDM--
                            main_EXE_flages(4 downto 2) <= "010"; --Indexing ########## waiting for ALU Op codes add
                            main_EXE_flages(1) <= '1'; --ALUSrc
                            main_WB_flages(2) <= '1'; --RegWrite
                        when "0110" => --mov--
                            main_WB_flages(2) <= '1'; --RegWrite
                        when "0111" => --SWAP--
                            main_Stall <= '1';
                            main_WB_flages(2) <= '1'; --RegWrite
                            main_CSwap <= '0';
                            start_swap_req <= '1';
                        when "1000" => --IADD--
                            main_EXE_flages(4 downto 2) <= "010";
                            main_EXE_flages(1) <= '1'; --ALUSrc
                            main_WB_flages(2) <= '1'; --RegWrite
                        when "1001" => --add--
                            main_EXE_flages(4 downto 2) <= "010";
                            main_WB_flages(2) <= '1'; --RegWrite
                        when "1010" => --sub--
                            main_EXE_flages(4 downto 2) <= "011";
                            main_WB_flages(2) <= '1'; --RegWrite
                        when "1011" => --AND--
                            main_EXE_flages(4 downto 2) <= "100";
                            main_WB_flages(2) <= '1'; --RegWrite
                        when "1100" => --JZ--
                            null;
                        when "1101" => --JNZ--
                            null;
                        when "1110" => --JC--
                            null;
                        when "1111" => --JMP--
                            main_branch_Decode <= '1';
                            main_ID_flush <= '1';
                        when others =>
                            null;
                    end case;
                else
                    case op_code(3 downto 0) is
                        when "0000" => --out--
                            main_IO_flages(1) <= '1'; --output
                        when "0001" => --in--
                            main_IO_flages(0) <= '1'; --input
                            main_WB_flages(2) <= '1'; --RegWrite
                        when "0010" => --push--
                            main_MEM_flages(2) <= '1'; --StackWrite
                            main_MEM_flages(6) <= '0'; --WDselect
                        when "0011" => --pop--
                            main_MEM_flages(3) <= '1'; --StackRead
                            main_WB_flages(2) <= '1'; --RegWrite
                        when "0100" => --LDD--
                            main_MEM_flages(5) <= '1'; --MEMRead
                            main_WB_flages(1) <= '1'; --MemtoReg
                            main_WB_flages(2) <= '1'; --RegWrite
                            main_EXE_flages(1) <= '1'; --ALUSrc
                        when "0101" => --STD--
                            main_MEM_flages(4) <= '1'; --MEMWrite
                            main_EXE_flages(1) <= '1'; --ALUSrc
                            main_MEM_flages(6) <= '0'; --WDselect
                        when "0110" => --call--
                            main_branch_Decode <= '1';
                            main_ID_flush <= '1';
                            main_MEM_flages(2) <= '1'; --StackWrite
                            main_MEM_flages(6) <= '1'; --WDselect
                            main_WB_flages(0) <= '1'; --PC-select
                            main_EXE_flages(1) <= '1'; --ALUSrc
                        when "0111" => --ret--
                            main_MEM_flages(3) <= '1'; --StackRead
                        when "1000" => --int--
                            main_micro_inst <= "11000";
                            main_Stall <= '1';
                            main_MEM_flages(2) <= '1'; --StackWrite
                            main_MEM_flages(6) <= '1'; --WDselect
                            main_WB_flages(0) <= '1'; --Write to PC+1
                            start_int_req <= '1';
                        when "1001" => --rti--
                            main_micro_inst <= "11001";
                            main_Stall <= '1';
                            main_MEM_flages(6) <= '1'; --WDselect
                            main_MEM_flages(1) <= '1'; --CCRLoad
                            start_rti_req <= '1';
                        when others =>
                            null;
                    end case;
            end if;
    end Process;

    ------------------------------------------------------------------
    FD_enable  <= micro_FD_enable  when micro_active = '1' else main_FD_enable;
    DE_enable  <= micro_DE_enable  when micro_active = '1' else main_DE_enable;
    EM_enable  <= micro_EM_enable  when micro_active = '1' else main_EM_enable;
    MW_enable  <= micro_MW_enable  when micro_active = '1' else main_MW_enable;
    Stall      <= micro_Stall      when micro_active = '1' else main_Stall;
    ID_flush   <= micro_ID_flush   when micro_active = '1' else main_ID_flush;
    Branch_Decode <= micro_Branch_Decode when micro_active = '1' else main_Branch_Decode;
    CSwap      <= micro_CSwap      when micro_active = '1' else main_CSwap;

    Micro_inst <= micro_Micro_inst when micro_active = '1' else main_Micro_inst;

    WB_flages  <= micro_WB_flages  when micro_active = '1' else main_WB_flages;
    EXE_flages <= micro_EXE_flages when micro_active = '1' else main_EXE_flages;
    MEM_flages <= micro_MEM_flages when micro_active = '1' else main_MEM_flages;
    IO_flages  <= micro_IO_flages  when micro_active = '1' else main_IO_flages;
end architecture behavior;