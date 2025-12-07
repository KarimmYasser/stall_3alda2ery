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
    predict : in std_logic_vector(1 downto 0);           -- Branch prediction bits
    wb_signals : in std_logic_vector(2 downto 0);        -- Writeback control signals
    mem_signals : in std_logic_vector(6 downto 0);       -- Memory control signals
    exe_signals : in std_logic_vector(5 downto 0);       -- Execute control signals
    output_signal : in std_logic;                        -- Output port enable
    input_signal : in std_logic;                         -- Input port select
    branch_opcode : in std_logic_vector(3 downto 0);     -- Branch operation code
    rs1_data : in std_logic_vector(31 downto 0);         -- Source register 1 data
    rs2_data : in std_logic_vector(31 downto 0);         -- Source register 2 data
    index : in std_logic_vector(1 downto 0);             -- Index value
    pc : in std_logic_vector(31 downto 0);               -- Program counter
    rs1_addr : in std_logic_vector(2 downto 0);          -- Source register 1 address
    rs2_addr : in std_logic_vector(2 downto 0);          -- Source register 2 address
    rd_addr : in std_logic_vector(2 downto 0);           -- Destination register address
    
    -- Additional Inputs
    immediate : in std_logic_vector(31 downto 0);        -- Immediate value
    in_port : in std_logic_vector(31 downto 0);          -- Input port data
    
    -- CCR Control
    ccr_enable : in std_logic;                           -- CCR update enable
    set_carry : in std_logic;                            -- Set carry flag
    ccr_load : in std_logic;                           -- Return from interrupt
    ccr_from_stack : in std_logic_vector(2 downto 0);         -- Flags to restore on RTI
    
    -- Forwarding Inputs
    rdst_mem : in std_logic_vector(2 downto 0);          -- Destination register (MEM stage)
    rdst_wb : in std_logic_vector(2 downto 0);           -- Destination register (WB stage)
    reg_write_mem : in std_logic;                        -- Register write enable (MEM)
    reg_write_wb : in std_logic;                         -- Register write enable (WB)
    mem_forwarded_data : in std_logic_vector(31 downto 0); -- Forwarded data from MEM
    wb_forwarded_data : in std_logic_vector(31 downto 0);  -- Forwarded data from WB
    swap_forwarded_data : in std_logic_vector(31 downto 0); -- Forwarded data for SWAP

    -- Outputs
    ex_mem_reg : out std_logic_vector(114 downto 0);    -- EX/MEM pipeline register
    branch_enable : out std_logic                        -- Branch taken signal
  );
end entity execute_stage;

architecture behavioral of execute_stage is
  -- Component Declarations

  component alu is
    port (
      alu_operand_1 : in std_logic_vector(15 downto 0);          -- First operand
      alu_operand_2 : in std_logic_vector(15 downto 0);          -- Second operand
      alu_control : in std_logic_vector(3 downto 0);       -- ALU operation code
      flags_enable_out : out std_logic_vector(2 downto 0); -- Flags update enable
      result : out std_logic_vector(15 downto 0);          -- ALU result
      flags : out std_logic_vector(2 downto 0)             -- Flags [C,N,Z]
    );
  end component;

  component alu_controller is
    port (
      alu_func_signal : in std_logic;                 -- Enable ALU function
      not_signal : in std_logic;                      -- Enable NOT operation
      add_offset_signal : in std_logic;               -- Enable add offset
      pass_data1_signal : in std_logic;               -- Pass operand 1
      pass_data2_signal : in std_logic;               -- Pass operand 2
      func : in std_logic_vector(1 downto 0);         -- Function select
      alu_control : out std_logic_vector(3 downto 0)  -- ALU control output
    );
  end component;

  component forward_unit is
    port (
      rs1_addr : in std_logic_vector(2 downto 0);        -- Rs1 address
      rs2_addr : in std_logic_vector(2 downto 0);        -- Rs2 address
      rdst_mem : in std_logic_vector(2 downto 0);            -- Rd address (MEM)
      rdst_wb : in std_logic_vector(2 downto 0);             -- Rd address (WB)
      reg_write_mem : in std_logic;                    -- Write enable (MEM)
      reg_write_wb : in std_logic;                     -- Write enable (WB)
      swap_signal : in std_logic;                             -- SWAP instruction
      forward1_signal : out std_logic_vector(1 downto 0);     -- Forward control 1
      forward2_signal : out std_logic_vector(1 downto 0)      -- Forward control 2
    );
  end component;

  component ccr is
    port (
      rst : in std_logic;                                  -- Reset signal
      clk : in std_logic;                                  -- Clock signal
      enable : in std_logic;                               -- Enable update
      set_carry : in std_logic;                            -- Set carry flag
      ccr_load : in std_logic;                             -- RTI restore enable
      ccr_from_stack : in std_logic_vector(2 downto 0);    -- Flags to restore
      alu_flags_enable : in std_logic_vector(2 downto 0);  -- ALU update enables
      alu_flags : in std_logic_vector(2 downto 0);         -- ALU flag values
      flags_out : out std_logic_vector(2 downto 0)         -- Current flags
    );
  end component;

  component branch_detection is
    port (
      opcode : in std_logic_vector(3 downto 0);  -- Branch opcode
      ccr : in std_logic_vector(2 downto 0);     -- Condition flags
      branch_taken : out std_logic               -- Branch decision
    );
  end component;

  -- Internal Signals
  signal alu_control_sig : std_logic_vector(3 downto 0);       -- ALU control
  signal forward1_signal : std_logic_vector(1 downto 0);          -- Forward control for operand 1
  signal forward2_signal : std_logic_vector(1 downto 0);          -- Forward control for operand 2
  signal ccr_out_sig : std_logic_vector(2 downto 0);           -- CCR output flags
  signal branch_taken_sig : std_logic;                         -- Branch taken decision

  signal variant_operand : std_logic_vector(31 downto 0);      -- Selected operand (Rs2/Imm/Index)
  signal alu_operand_1 : std_logic_vector(31 downto 0);        -- ALU input 1 (after forwarding)
  signal alu_operand_2 : std_logic_vector(31 downto 0);        -- ALU input 2 (after forwarding)
  signal alu_result : std_logic_vector(31 downto 0);           -- ALU result
  signal alu_flags : std_logic_vector(2 downto 0);             -- ALU flags output [C,N,Z]
  signal alu_flags_enable : std_logic_vector(2 downto 0);      -- ALU flags enable
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
    swap_signal => exe_signals(5),
    forward1_signal => forward1_signal,
    forward2_signal => forward2_signal
  );

  -- Mux 1: Select variant operand (Rs2, Immediate, or Index)
  with exe_signals(1 downto 0) select
    variant_operand <= rs2_data when "00",                              -- Use Rs2 data
                       immediate when "01",                             -- Use immediate value
                       (x"0000" & "00000000000000" & index) when "10", -- Index zero-extended
                       (others => '0') when others;                     -- Default

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

  -- ALU Controller Instance
  ALU_CTRL : alu_controller
  port map(
    alu_func_signal => exe_signals(4), -- ALU function enable
    not_signal => '0', -- NOT operation disabled
    add_offset_signal => '0', -- Add offset disabled
    pass_data1_signal => '0', -- Pass data 1 disabled
    pass_data2_signal => '0', -- Pass data 2 disabled
    func => exe_signals(3 downto 2), -- ALU function
    alu_control => alu_control_sig
  );

  -- ALU Instance
  ALU_INST : alu
  port map(
    alu_operand_1 => alu_operand_1,
    alu_operand_2 => alu_operand_2,
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
    enable => ccr_enable,
    set_carry => set_carry,
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

  -- EX_MEM Pipeline Register Assignment with Flush Logic
  -- Total: 114 bits (113 downto 0)
  
  -- WB signals (3 bits): 113-111
  ex_mem_reg(113 downto 111) <= wb_signals when flush = '0' else (others => '0');
  
  -- MEM signals (7 bits): 110-104
  ex_mem_reg(110 downto 104) <= mem_signals when flush = '0' else (others => '0');
  
  -- Output signal (1 bit): 103
  ex_mem_reg(103) <= output_signal when flush = '0' else '0';
  
  -- Branch taken (1 bit): 102
  ex_mem_reg(102) <= branch_taken_sig;
  
  -- CCR (3 bits): 101-99
  ex_mem_reg(101 downto 99) <= ccr_out_sig;
  
  -- R[Rs2] data (32 bits): 98-67
  ex_mem_reg(98 downto 67) <= rs2_data;
  
  -- ALU result or INPORT (32 bits): 66-35
  with input_signal select
    ex_mem_reg(66 downto 35) <= alu_result when '0', -- Normal ALU operation
                                 in_port when '1';    -- IN instruction
  
  -- PC (32 bits): 34-3
  ex_mem_reg(34 downto 3) <= pc;
  
  -- Rd address (3 bits): 2-0
  ex_mem_reg(2 downto 0) <= rd_addr;

  -- Branch enable output: branch_taken AND mem_signals(5) AND mem_signals(3)
  branch_enable <= branch_taken_sig and mem_signals(5) and mem_signals(3);

end architecture behavioral;