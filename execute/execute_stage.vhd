library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity execute_stage is
  port (
    -- Inputs:
    -- - ID_EX_reg = (WB sigs, MEM sigs, EXE sigs, IO sigs, BR sigs), (R[Rs1], R[Rs2], Index), PC, Rs1, Rs2, Rdst
    -- - Immediate: directly from IF_ID_reg
    -- - INPORT
    -- - ccr load signal
    -- - ccr data input
    -- - flush signal
    -- - forwarded data from MEM and WB stages

    clk : in std_logic;
    rst : in std_logic;
    id_ix_reg : in std_logic_vector(126 downto 0);
    immediate : in std_logic_vector(31 downto 0);
    in_port : in std_logic_vector(31 downto 0);
    set_carry_signal : in std_logic;
    rti_signal : in std_logic;
    rti_flags : in std_logic_vector(2 downto 0);
    flush : in std_logic;

    rdst_mem : in std_logic_vector(2 downto 0);
    rdst_wb : in std_logic_vector(2 downto 0);
    reg_w_mem_signal : in std_logic;
    reg_w_wb_signal : in std_logic;
    -- swap_signal : in std_logic; -- coming from inside?
    mem_forwarded_data : in std_logic_vector(31 downto 0);
    wb_forwarded_data : in std_logic_vector(31 downto 0);
    swap_forwarded_data : in std_logic_vector(31 downto 0);

    -- Outputs:
    -- - EX_MEM_reg = (WB sigs, MEM sigs, O sig), BR sig, CCR, (R[Rs1], R[Rs2], Index), PC, Rs1, Rs2, Rdst
    -- - Branch_Enable
    ex_mem_reg : out std_logic_vector(113 downto 0);
    branch_enable : out std_logic;
    ccr_to_cu : out std_logic
  );
end entity execute_stage;

architecture Behavioral of execute_stage is

  -- Component Declarations
  component alu_controller is
    port (
      alu_func_signal : in std_logic;
      not_signal : in std_logic;
      add_offset_signal : in std_logic;
      pass_data1_signal : in std_logic;
      pass_data2_signal : in std_logic;
      func : in std_logic_vector(1 downto 0);
      alu_control : out std_logic_vector(3 downto 0)
    );
  end component;

  component forward_unit is
    port (
      rsrc1_execute : in std_logic_vector(2 downto 0);
      rsrc2_execute : in std_logic_vector(2 downto 0);
      rdst_mem : in std_logic_vector(2 downto 0);
      rdst_wb : in std_logic_vector(2 downto 0);
      reg_write_signal_mem : in std_logic;
      reg_write_signal_wb : in std_logic;
      swap_signal : in std_logic;
      forward1_signal : out std_logic_vector(1 downto 0);
      forward2_signal : out std_logic_vector(1 downto 0)
    );
  end component;

  component ccr is
    port (
      rst : in std_logic;
      clk : in std_logic;
      set_carry : in std_logic;
      rti_signal : in std_logic;
      flags_in_rti : in std_logic_vector(2 downto 0);
      flags_enable_from_alu : in std_logic_vector(2 downto 0);
      flags_from_alu : in std_logic_vector(2 downto 0);
      flags_out : out std_logic_vector(2 downto 0)
    );
  end component;

  component branch_detection is
    port (
      opcode : in std_logic_vector(3 downto 0);
      ccr : in std_logic_vector(2 downto 0);
      branch_taken : out std_logic
    );
  end component;

  -- Signals for interconnections
  signal alu_control_sig : std_logic_vector(3 downto 0);
  signal forward1_sig : std_logic_vector(1 downto 0);
  signal forward2_sig : std_logic_vector(1 downto 0);
  signal ccr_out_sig : std_logic_vector(2 downto 0);
  signal branch_taken_sig : std_logic;

  -- Extracted signals from ID_EX pipeline register (126 downto 0)
  -- WB signals (3 bits)
  signal wb_signals : std_logic_vector(2 downto 0); -- Bits 126-124

  -- MEM signals (6 bits)
  signal mem_signals : std_logic_vector(5 downto 0); -- Bits 123-118

  -- EXE signals (5 bits)
  -- 4, 3 -> second operand selectors
  -- 2 -> swap signal
  -- 1, 0 -> ALU function selectors
  signal exe_signals : std_logic_vector(4 downto 0); -- Bits 117-113

  -- I/O signals (2 bits)
  signal output_signal : std_logic; -- Bit 112: OUT signal
  signal input_signal : std_logic; -- Bit 111: IN signal

  -- Branch OpCode (4 bits)
  signal branch_opcode : std_logic_vector(3 downto 0); -- Bits 110-107

  -- Register data (32 bits each)
  signal rs1_data : std_logic_vector(31 downto 0); -- Bits 106-75: R[Rs1]
  signal rs2_data : std_logic_vector(31 downto 0); -- Bits 74-43: R[Rs2]

  -- Index (2 bits)
  signal index : std_logic_vector(1 downto 0); -- Bits 42-41

  -- Program Counter (32 bits)
  signal pc : std_logic_vector(31 downto 0); -- Bits 40-9

  -- Register addresses (3 bits each)
  signal rs1_addr : std_logic_vector(2 downto 0); -- Bits 8-6: Rs1 address
  signal rs2_addr : std_logic_vector(2 downto 0); -- Bits 5-3: Rs2 address
  signal rd_addr : std_logic_vector(2 downto 0); -- Bits 2-0: Rd address

  -- ALU operand selection
  signal variant_operand : std_logic_vector(31 downto 0); -- Rs2, Imm, or Index
  signal alu_operand_1 : std_logic_vector(31 downto 0); -- First ALU input (with forwarding)
  signal alu_operand_2 : std_logic_vector(31 downto 0); -- Second ALU input (with forwarding)
  signal alu_result : std_logic_vector(31 downto 0); -- ALU computation result
  signal alu_flags : std_logic_vector(2 downto 0); -- Flags from ALU [Z, N, C]
  signal alu_flags_enable : std_logic_vector(2 downto 0); -- Flag enable signals from ALU
begin
  -- Extract all fields from ID_EX pipeline register (126 downto 0)
  wb_signals <= id_ix_reg(126 downto 124); -- WB control signals
  mem_signals <= id_ix_reg(123 downto 118); -- MEM control signals
  exe_signals <= id_ix_reg(117 downto 113); -- EXE control signals
  output_signal <= id_ix_reg(112); -- OUT signal
  input_signal <= id_ix_reg(111); -- IN signal
  branch_opcode <= id_ix_reg(110 downto 107); -- Branch operation code
  rs1_data <= id_ix_reg(106 downto 75); -- R[Rs1] data
  rs2_data <= id_ix_reg(74 downto 43); -- R[Rs2] data
  index <= id_ix_reg(42 downto 41); -- Index value
  pc <= id_ix_reg(40 downto 9); -- Program counter
  rs1_addr <= id_ix_reg(8 downto 6); -- Rs1 register address
  rs2_addr <= id_ix_reg(5 downto 3); -- Rs2 register address
  rd_addr <= id_ix_reg(2 downto 0); -- Rd register address

  -- Forward Unit Instance
  FU : forward_unit
  port map(
    rsrc1_execute => rs1_addr,
    rsrc2_execute => rs2_addr,
    rdst_mem => rdst_mem,
    rdst_wb => rdst_wb,
    reg_write_signal_mem => reg_w_mem_signal,
    reg_write_signal_wb => reg_w_wb_signal,
    swap_signal => exe_signals(2),
    forward1_signal => forward1_sig,
    forward2_signal => forward2_sig
  );

  -- Mux 1: Select variant operand (Rs2, Immediate, or Index)
  with exe_signals(4 downto 3) select
  variant_operand <= rs2_data when "00", -- Use Rs2 data
                     immediate when "01", -- Use immediate value
                     -- (index sign-extended) when "10", -- Use index (TODO)
                     (others => '0') when others; -- Default

  -- Mux 2: Forward mux for first ALU operand (Rs1 with forwarding)
  with forward1_sig select
    alu_operand_1 <= rs1_data when "00", -- No forwarding needed
    mem_forwarded_data when "01", -- Forward from MEM stage
    wb_forwarded_data when "10", -- Forward from WB stage
    swap_forwarded_data when others; -- Swap forwarding

  -- Mux 3: Forward mux for second ALU operand (variant with forwarding)
  with forward2_sig select
    alu_operand_2 <= variant_operand when "00", -- No forwarding needed
    mem_forwarded_data when "01", -- Forward from MEM stage
    wb_forwarded_data when "10", -- Forward from WB stage
    (others => '0') when others; -- Default

  -- ALU Controller Instance
  ALU_CTRL : alu_controller
  port map(
    alu_func_signal => exe_signals(2), -- ALU function enable
    not_signal => '0', -- NOT operation disabled
    add_offset_signal => '0', -- Add offset disabled
    pass_data1_signal => '0', -- Pass data 1 disabled
    pass_data2_signal => '0', -- Pass data 2 disabled
    func => exe_signals(1 downto 0), -- ALU function
    alu_control => alu_control_sig
  );

  -- ALU Instance
  ALU_INST : alu
  port map(
    input_1 => alu_operand_1,
    input_2 => alu_operand_2,
    alu_control => alu_control_sig,
    flags_enable_out => alu_flags_enable,
    result => alu_result,
    flags => alu_flags
  );

  -- CCR Instance
  CCR_INST : ccr
  port map(
    rst => rst,
    clk => clk,
    set_carry => set_carry_signal,
    rti_signal => rti_signal,
    flags_in_rti => rti_flags,
    flags_enable_from_alu => alu_flags_enable,
    flags_from_alu => alu_flags,
    flags_out => ccr_out_sig
  );

  -- Mux 4: Select between ALU result or INPORT for output
  with input_signal select
    ex_mem_reg(100 downto 79) <= alu_result when '0', -- Normal ALU operation
    in_port when '1'; -- IN instruction

  -- Branch Detection Instance
  BR_DET : branch_detection
  port map(
    opcode => branch_opcode,
    ccr => ccr_out_sig,
    branch_taken => branch_taken_sig
  );

  -- EX_MEM Pipeline Register Assignment with Flush Logic
  -- Total: 113 bits (112 downto 0)
  
  -- WB signals (3 bits): 112-110
  ex_mem_reg(112 downto 110) <= wb_signals when flush = '0' else (others => '0');
  
  -- MEM signals (6 bits): 109-104
  ex_mem_reg(109 downto 104) <= mem_signals when flush = '0' else (others => '0');
  
  -- Output signal (1 bit): 103
  ex_mem_reg(103) <= output_signal when flush = '0' else '0';
  
  -- Branch taken (1 bit): 102
  ex_mem_reg(102) <= branch_taken_sig;
  
  -- CCR (3 bits): 101-99
  ex_mem_reg(101 downto 99) <= ccr_out_sig;
  
  -- R[Rs2] data (32 bits): 98-67
  ex_mem_reg(98 downto 67) <= rs2_data;
  
  -- ALU result (32 bits): 66-35
  ex_mem_reg(66 downto 35) <= alu_result;
  
  -- PC (32 bits): 34-3
  ex_mem_reg(34 downto 3) <= pc;
  
  -- Rd address (3 bits): 2-0
  ex_mem_reg(2 downto 0) <= rd_addr;

  -- Branch enable output: branch_taken AND NOR(mem_signals middle 2 bits)
  branch_enable <= branch_taken_sig and not (mem_signals(3) or mem_signals(2));

end architecture Behavioral;