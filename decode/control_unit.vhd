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
    type state_type is (Noop, Hlt, SetC, Inc, Not_, LDM, Mov, SWAP, IADD, ADD, SUB, AND_, JZ, JNZ, JC,
     JMP, OUT_, IN_, PUSH, POP, LDD, STD, CALL, RET, INT_, RTI,interrupt_handle);
     signal state : state_type := Noop;
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
                        state <= interrupt_handle;
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
    if state = interrupt_handle then
        Stall <= '1';

    end if;
end architecture behavior;

architecture chat of Control_Unit is
       ------------------------------------------------------------------
    -- Micro-FSM types & signals (synchronous)
    ------------------------------------------------------------------
    type micro_state_type is (
        M_IDLE,
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

    ------------------------------------------------------------------
    -- Final outputs are multiplexed between micro_ and main_
    ------------------------------------------------------------------
begin

    ------------------------------------------------------------------
    -- Micro FSM synchronous state register
    ------------------------------------------------------------------
    micro_fsm_seq : process(clk)
    begin
        if rising_edge(clk) then
            micro_state <= micro_next;
        end if;
    end process micro_fsm_seq;

    ------------------------------------------------------------------
    -- Micro FSM next-state + outputs (Moore style)
    -- Implements INT (3 cycles), SWAP (2 cycles), RTI (2 cycles)
    ------------------------------------------------------------------
    micro_fsm_comb : process(micro_state, inturrupt)
    begin
        -- defaults for micro signals (inactive)
        micro_next <= micro_state;
        micro_active <= '0';

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
                -- default idle: if external interrupt asserted, start INT micro sequence
                if inturrupt = '1' then
                    micro_next <= M_INT_0;
                else
                    micro_next <= M_IDLE;
                end if;

            -- INTERRUPT ENTRY: 3 cycles (INT_0, INT_1, INT_2)
            when M_INT_0 =>
                micro_active <= '1';
                micro_Stall <= '1';
                -- cycle 0: push PC+? to stack (StackWrite), set write-data-select
                micro_Micro_inst <= "11000"; -- example micro opcode (you used "11000" earlier)
                micro_MEM_flages(3) <= '0'; -- StackRead = 0
                micro_MEM_flages(2) <= '1'; -- StackWrite
                micro_MEM_flages(6) <= '1'; -- WDselect
                micro_WB_flages(0) <= '1'; -- PC-select maybe for write-back to stack
                micro_next <= M_INT_1;

            when M_INT_1 =>
                micro_active <= '1';
                micro_Stall <= '1';
                -- cycle 1: store CCR then write memory (CCRStore + MEMWrite)
                micro_Micro_inst <= "11000";
                micro_MEM_flages(1) <= '1'; -- CCRStore
                micro_MEM_flages(6) <= '0'; -- WDselect = 0 (different data)
                micro_MEM_flages(4) <= '1'; -- MEMWrite
                micro_next <= M_INT_2;

            when M_INT_2 =>
                micro_active <= '1';
                micro_Stall <= '1';
                -- cycle 2: read ISR address from memory (MEMRead)
                micro_Micro_indirect_label: null; -- no-op label (for clarity)
                micro_Micro_inst <= "11000";
                micro_MEM_flages(5) <= '1'; -- MEMRead
                -- configure ALU flags as needed (example)
                micro_EXE_flages(1) <= '0'; -- ALUSrc
                micro_EXE_flages(0) <= '1'; -- Index bit if needed
                micro_EXE_flages(4 downto 2) <= "010"; -- ALU opcode add (example)
                micro_next <= M_IDLE;

            -- SWAP micro sequence (2 cycles)
            when M_SWAP_0 =>
                micro_active <= '1';
                micro_Stall <= '1';
                micro_Micro_inst <= "10111"; -- SWAP micro-instruction from your code
                micro_WB_flages(2) <= '1'; -- RegWrite
                micro_CSwap <= '1';
                micro_next <= M_SWAP_1;

            when M_SWAP_1 =>
                micro_active <= '1';
                micro_Stall <= '1';
                micro_Micro_inst <= "10111";
                micro_WB_flages(2) <= '1';
                micro_CSwap <= '1';
                micro_next <= M_IDLE;

            -- RTI micro (2 cycles)
            when M_RTI_0 =>
                micro_active <= '1';
                micro_Stall <= '1';
                micro_Micro_inst <= "11001"; -- RTI micro-instruction as in your code
                micro_MEM_flages(6) <= '1'; -- WDselect
                micro_MEM_flages(1) <= '1'; -- CCRLoad
                micro_next <= M_RTI_1;

            when M_RTI_1 =>
                micro_active <= '1';
                micro_Stall <= '1';
                micro_Micro_inst <= "11001";
                micro_MEM_flages(3) <= '1'; -- StackRead
                micro_next <= M_IDLE;

            when others =>
                micro_next <= M_IDLE;
        end case;
    end process micro_fsm_comb;

    ------------------------------------------------------------------
    -- Main combinational decoder (pure combinational logic)
    -- Produces control signals immediately from op_code
    ------------------------------------------------------------------
    main_decoder : process(op_code, data_ready, ccr_data)
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

        -- decide between instruction groups using MSB (as your original)
        if op_code(4) = '0' then
            case op_code(3 downto 0) is
                when "0000" => -- NOOP
                    null;
                when "0001" => -- HLT
                    main_FD_enable <= '0';
                    main_DE_enable <= '0';
                    main_Stall <= '1';
                when "0010" => -- SetC
                    main_EXE_flages(4 downto 2) <= "111";
                when "0011" => -- INC
                    main_EXE_flages(4 downto 2) <= "000";
                    main_WB_flages(2) <= '1';
                when "0100" => -- NOT
                    main_EXE_flages(4 downto 2) <= "001";
                    main_WB_flages(2) <= '1';
                when "0101" => -- LDM
                    main_EXE_flages(4 downto 2) <= "010";
                    main_EXE_flages(1) <= '1'; -- ALUSrc
                    main_WB_flages(2) <= '1';
                when "0110" => -- MOV
                    main_WB_flages(2) <= '1';
                when "0111" => -- SWAP (start micro sequence)
                    main_Stall <= '1'; -- hint: stall while micro runs
                    -- request micro-level SWAP by transitioning micro_fsm:
                    -- We use micro_state transitions by setting micro_next when op seen.
                    -- But because micro_fsm_comb only looks at inturrupt in M_IDLE,
                    -- we must provide a mechanism to request SWAP. We'll set a request
                    -- signal by writing to main_Micro_inst here and rely on a small
                    -- handshake below to start micro (see start_requests).
                    main_Micro_inst <= "10111";
                    -- set a "request" via a simple mechanism (see start signals later)
                when "1000" => -- IADD
                    main_EXE_flages(4 downto 2) <= "010";
                    main_EXE_flages(1) <= '1';
                    main_WB_flages(2) <= '1';
                when "1001" => -- ADD
                    main_EXE_flages(4 downto 2) <= "010";
                    main_WB_flages(2) <= '1';
                when "1010" => -- SUB
                    main_EXE_flages(4 downto 2) <= "011";
                    main_WB_flages(2) <= '1';
                when "1011" => -- AND
                    main_EXE_flages(4 downto 2) <= "100";
                    main_WB_flages(2) <= '1';
                when "1111" => -- JMP
                    main_Branch_Decode <= '1';
                    main_ID_flush <= '1';
                when others =>
                    null;
            end case;
        else
            case op_code(3 downto 0) is
                when "0000" => -- OUT
                    main_IO_flages(1) <= '1';
                when "0001" => -- IN
                    main_IO_flages(0) <= '1';
                    main_WB_flages(2) <= '1';
                when "0010" => -- PUSH
                    main_MEM_flages(2) <= '1'; -- StackWrite
                    main_MEM_flages(6) <= '0'; -- WDselect
                when "0011" => -- POP
                    main_MEM_flages(3) <= '1'; -- StackRead
                    main_WB_flages(2) <= '1';
                when "0100" => -- LDD
                    main_MEM_flages(0) <= '1'; -- MEMRead
                    main_WB_flages(1) <= '1'; -- MemtoReg
                    main_WB_flages(2) <= '1';
                    main_EXE_flages(1) <= '1';
                when "0101" => -- STD
                    main_MEM_flages(4) <= '1'; -- MEMWrite
                    main_EXE_flages(1) <= '1'; -- ALUSrc
                    main_MEM_flages(6) <= '0';
                when "0110" => -- CALL
                    main_Branch_Decode <= '1';
                    main_ID_flush <= '1';
                    main_MEM_flages(2) <= '1'; -- StackWrite
                    main_MEM_flages(6) <= '1';
                    main_WB_flages(0) <= '1'; -- PC-select
                    main_EXE_flages(1) <= '1';
                when "0111" => -- RET (start RTI-like sequence or just stack read)
                    main_MEM_flages(3) <= '1';
                when "1000" => -- INT (request micro INT sequence)
                    main_Stall <= '1'; -- stall until micro finishes
                    main_Micro_inst <= "11000"; -- indicate request
                when "1001" => -- RTI (request micro RTI sequence)
                    main_Stall <= '1';
                    main_Micro_inst <= "11001";
                when others =>
                    null;
            end case;
        end if;
    end process main_decoder;

    ------------------------------------------------------------------
    -- Simple handshake to start micro sequences when main decoder requests them.
    -- We implement 'start_swap_req' and 'start_int_req' and 'start_rti_req'.
    -- When in M_IDLE the micro FSM will look for these start signals to begin.
    ------------------------------------------------------------------
    signal start_swap_req : std_logic := '0';
    signal start_int_req  : std_logic := '0';
    signal start_rti_req  : std_logic := '0';

    start_request_proc : process(clk)
    begin
        if rising_edge(clk) then
            -- default clear requests
            start_swap_req <= '0';
            start_int_req  <= '0';
            start_rti_req  <= '0';

            -- create requests based on op_code sampling (on rising edge)
            -- these requests will be seen by a small micro-start process below
            if op_code(4) = '0' and op_code(3 downto 0) = "0111" then -- SWAP opcode
                start_swap_req <= '1';
            end if;

            if op_code(4) = '1' and op_code(3 downto 0) = "1000" then -- INT opcode
                start_int_req <= '1';
            end if;

            if op_code(4) = '1' and op_code(3 downto 0) = "1001" then -- RTI opcode
                start_rti_req <= '1';
            end if;
        end if;
    end process start_request_proc;

    ------------------------------------------------------------------
    -- Micro start control: when micro is idle and a request exists start sequence
    ------------------------------------------------------------------
    micro_start_proc : process(clk)
    begin
        if rising_edge(clk) then
            if micro_state = M_IDLE then
                if start_int_req = '1' or inturrupt = '1' then
                    micro_state <= M_INT_0;
                elsif start_swap_req = '1' then
                    micro_state <= M_SWAP_0;
                elsif start_rti_req = '1' then
                    micro_state <= M_RTI_0;
                else
                    micro_state <= M_IDLE;
                end if;
            end if;
        end if;
    end process micro_start_proc;

    ------------------------------------------------------------------
    -- Output multiplexing: micro controls override main controls when active
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

end architecture chat;
