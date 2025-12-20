library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity execute_stage is
  port (
    -- Clock and Control
    clk : in std_logic;
    rst : in std_logic;
    flush : in std_logic;

    -- ID/EX Pipeline Register Fields
    predict : in std_logic_vector(1 downto 0); -- Branch prediction bits
    wb_signals : in std_logic_vector(2 downto 0); -- Writeback control signals
    mem_signals : in std_logic_vector(6 downto 0); -- Memory control signals
    exe_signals : in std_logic_vector(5 downto 0); -- Execute control signals
    output_signal : in std_logic; -- Output port enable
    input_signal : in std_logic; -- Input port select
    swap_signal : in std_logic; -- Forwarding enable
    branch_opcode : in std_logic_vector(3 downto 0); -- Branch operation code
    rs1_data : in std_logic_vector(31 downto 0); -- Source register 1 data
    rs2_data : in std_logic_vector(31 downto 0); -- Source register 2 data
    index : in std_logic_vector(1 downto 0); -- Index value
    pc : in std_logic_vector(31 downto 0); -- Program counter
    rs1_addr : in std_logic_vector(2 downto 0); -- Source register 1 address
    rs2_addr : in std_logic_vector(2 downto 0); -- Source register 2 address
    rd_addr : in std_logic_vector(2 downto 0); -- Destination register address

    -- Additional Inputs
    immediate : in std_logic_vector(31 downto 0); -- Immediate value
    in_port : in std_logic_vector(31 downto 0); -- Input port data

    -- CCR Control
    ccr_enable : in std_logic; -- CCR update enable
    ccr_load : in std_logic; -- Return from interrupt
    ccr_from_stack : in std_logic_vector(2 downto 0); -- Flags to restore on RTI

    -- Forwarding Inputs
    rdst_mem : in std_logic_vector(2 downto 0); -- Destination register (MEM stage)
    rdst_wb : in std_logic_vector(2 downto 0); -- Destination register (WB stage)
    reg_write_mem : in std_logic; -- Register write enable (MEM)
    reg_write_wb : in std_logic; -- Register write enable (WB)
    mem_forwarded_data : in std_logic_vector(31 downto 0); -- Forwarded data from MEM
    wb_forwarded_data : in std_logic_vector(31 downto 0); -- Forwarded data from WB
    swap_forwarded_data : in std_logic_vector(31 downto 0); -- Forwarded data for SWAP

    -- EX/MEM Pipeline Register Outputs
    ex_mem_wb_signals : out std_logic_vector(2 downto 0); -- WB control signals
    ex_mem_mem_signals : out std_logic_vector(6 downto 0); -- MEM control signals
    ex_mem_output_signal : out std_logic; -- Output port enable
    ex_mem_branch_taken : out std_logic; -- Branch taken
    ex_mem_ccr : out std_logic_vector(2 downto 0); -- Condition flags
    ex_mem_rs2_data : out std_logic_vector(31 downto 0); -- Rs2 data
    ex_mem_alu_result : out std_logic_vector(31 downto 0); -- ALU result
    ex_mem_pc : out std_logic_vector(31 downto 0); -- Program counter
    ex_mem_rd_addr : out std_logic_vector(2 downto 0); -- Destination register

    -- Branch Enable Output
    branch_enable : out std_logic -- Branch enable
  );
end entity execute_stage;

architecture behavioral of execute_stage is
  -- Component Declarations

  component alu is
    port (
      alu_operand_1 : in std_logic_vector(31 downto 0); -- First operand
      alu_operand_2 : in std_logic_vector(31 downto 0); -- Second operand
      alu_control : in std_logic_vector(2 downto 0); -- ALU operation control
      alu_enable : in std_logic; -- ALU enable signal
      flags_enable_out : out std_logic_vector(2 downto 0); -- Flags update enable
      result : out std_logic_vector(31 downto 0); -- ALU result
      flags : out std_logic_vector(2 downto 0) -- Flags [0]=C,[1]=N,[2]=Z
    );
  end component;

  component forward_unit is
    port (
      rs1_addr : in std_logic_vector(2 downto 0); -- Rs1 address
      rs2_addr : in std_logic_vector(2 downto 0); -- Rs2 address
      rdst_mem : in std_logic_vector(2 downto 0); -- Rd address (MEM)
      rdst_wb : in std_logic_vector(2 downto 0); -- Rd address (WB)
      reg_write_mem : in std_logic; -- Write enable (MEM)
      reg_write_wb : in std_logic; -- Write enable (WB)
      swap_signal : in std_logic; -- SWAP instruction
      forward1_signal : out std_logic_vector(1 downto 0); -- Forward control 1
      forward2_signal : out std_logic_vector(1 downto 0) -- Forward control 2
    );
  end component;

  component ccr is
    port (
      rst : in std_logic; -- Reset signal
      clk : in std_logic; -- Clock signal
      enable : in std_logic; -- Enable update
      ccr_load : in std_logic; -- RTI restore enable
      ccr_from_stack : in std_logic_vector(2 downto 0); -- Flags to restore
      alu_flags_enable : in std_logic_vector(2 downto 0); -- ALU update enables
      alu_flags : in std_logic_vector(2 downto 0); -- ALU flag values
      flags_out : out std_logic_vector(2 downto 0) -- Current flags
    );
  end component;

  component branch_detection is
    port (
      opcode : in std_logic_vector(3 downto 0); -- Branch opcode
      ccr : in std_logic_vector(2 downto 0); -- Condition flags [0]=C,[1]=N,[2]=Z
      branch_taken : out std_logic -- Branch decision
    );
  end component;

  component input_port is
    GENERIC (
        DATA_SIZE : INTEGER := 32
    );
    PORT (
        clk : IN STD_LOGIC; -- Clock signal
        reset : IN STD_LOGIC; -- Reset signal
        enable : IN STD_LOGIC; -- Enable signal
        data_in : IN STD_LOGIC_VECTOR(DATA_SIZE - 1 DOWNTO 0);
        data_out : OUT STD_LOGIC_VECTOR(DATA_SIZE - 1 DOWNTO 0)
    );
  end component input_port;


  -- Internal Signals
  signal forward1_signal : std_logic_vector(1 downto 0); -- Forward control for operand 1
  signal forward2_signal : std_logic_vector(1 downto 0); -- Forward control for operand 2
  signal ccr_out_sig : std_logic_vector(2 downto 0); -- CCR output flags
  signal branch_taken_sig : std_logic; -- Branch taken decision

  signal variant_operand : std_logic_vector(31 downto 0); -- Selected operand (Rs2/Imm/Index)
  signal alu_operand_1 : std_logic_vector(31 downto 0); -- ALU input 1 (after forwarding)
  signal alu_operand_2 : std_logic_vector(31 downto 0); -- ALU input 2 (after forwarding)
  signal alu_result : std_logic_vector(31 downto 0); -- ALU result
  signal alu_flags : std_logic_vector(2 downto 0); -- ALU flags [0]=C,[1]=N,[2]=Z
  signal alu_flags_enable : std_logic_vector(2 downto 0); -- ALU flags enable
  signal input_port_data : std_logic_vector(31 downto 0); -- Sign-extended immediate
begin
  -- Forward Unit Instance
  FU : forward_unit
  port map(
    rs1_addr => rs1_addr,
    rs2_addr => rs2_addr,
    rdst_mem => rdst_mem,
    rdst_wb => rdst_wb,
    reg_write_mem => reg_write_mem,
    reg_write_wb => reg_write_wb,
    swap_signal => swap_signal,
    forward1_signal => forward1_signal,
    forward2_signal => forward2_signal
  );

  -- Mux 1: Select variant operand (Rs2, Immediate, or Index)
  with exe_signals(1 downto 0) select
  variant_operand <= rs2_data when "00", -- Use Rs2 data
                     immediate when "01", -- Use immediate value
                     (x"0000" & "00000000000000" & index) when "10", -- Index zero-extended
                     (others => '0') when others; -- Default

  -- Mux 2: Forward mux for first ALU operand (Rs1 with forwarding)
  with forward1_signal select
    alu_operand_1 <= rs1_data when "00", -- No forwarding needed
    mem_forwarded_data when "01", -- Forward from MEM stage
    wb_forwarded_data when "10", -- Forward from WB stage
    swap_forwarded_data when others; -- Swap forwarding

  -- Mux 3: Forward mux for second ALU operand (variant with forwarding)
  with forward2_signal select
    alu_operand_2 <= variant_operand when "00", -- No forwarding needed
    mem_forwarded_data when "01", -- Forward from MEM stage
    wb_forwarded_data when "10", -- Forward from WB stage
    (others => '0') when others; -- Default

  -- ALU Instance
  -- Control bits [5:2] from exe_signals passed directly to ALU
  ALU_INST : alu
  port map(
    alu_operand_1 => alu_operand_1,
    alu_operand_2 => alu_operand_2,
    alu_control => exe_signals(4 downto 2), -- Direct control from decode stage
    alu_enable => exe_signals(5),
    flags_enable_out => alu_flags_enable,
    result => alu_result,
    flags => alu_flags
  );

  -- CCR Instance
  CCR_INST : ccr
  port map(
    rst => rst,
    clk => clk,
    enable => ccr_enable,
    ccr_load => ccr_load,
    ccr_from_stack => ccr_from_stack,
    alu_flags_enable => alu_flags_enable,
    alu_flags => alu_flags,
    flags_out => ccr_out_sig
  );

  -- Branch Detection Instance
  BR_DET : branch_detection
  port map(
    opcode => branch_opcode,
    ccr => ccr_out_sig,
    branch_taken => branch_taken_sig
  );
  input_PORT_INST : input_port
    GENERIC MAP (DATA_SIZE => 32)
    PORT MAP (
        clk => clk,
        reset => rst,
        enable => input_signal,
        data_in => in_port,
        data_out => input_port_data
    );

  -- EX/MEM Pipeline Register Outputs with Flush Logic
  ex_mem_wb_signals <= wb_signals when flush = '0' else
                       (others => '0');
  ex_mem_mem_signals <= mem_signals when flush = '0' else
                        (others => '0');
  ex_mem_output_signal <= output_signal when flush = '0' else
                          '0';
  ex_mem_branch_taken <= branch_taken_sig;
  ex_mem_ccr <= ccr_out_sig;
  ex_mem_rs2_data <= rs2_data;

  -- Select between ALU result or INPORT
  with input_signal select
    ex_mem_alu_result <= alu_result when '0',
    input_port_data when '1',
    (others => '0') when others;

  ex_mem_pc <= pc;
  ex_mem_rd_addr <= rd_addr;

  -- Branch enable output
  branch_enable <= branch_taken_sig and not(mem_signals(5) or mem_signals(3));

end architecture behavioral;