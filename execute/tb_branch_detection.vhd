library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_branch_detection is
end entity tb_branch_detection;

architecture testbench of tb_branch_detection is
  -- Component Declaration
  component branch_detection is
    port (
      opcode : in std_logic_vector(3 downto 0);
      ccr : in std_logic_vector(2 downto 0);
      branch_taken : out std_logic
    );
  end component;

  -- Test Signals
  signal opcode : std_logic_vector(3 downto 0) := (others => '0');
  signal ccr : std_logic_vector(2 downto 0) := (others => '0');
  signal branch_taken : std_logic;

  -- Test control
  signal test_done : boolean := false;
  
  -- Test counters
  shared variable test_count : integer := 0;
  shared variable pass_count : integer := 0;
  shared variable fail_count : integer := 0;

begin
  -- Instantiate DUT
  DUT : branch_detection
  port map (
    opcode => opcode,
    ccr => ccr,
    branch_taken => branch_taken
  );

  -- Test Process
  test_process : process
    variable l : line;

    -- Helper Procedures
    procedure print_separator is
      variable l : line;
    begin
      write(l, string'("================================================================================"));
      writeline(output, l);
    end procedure;

    procedure print_header(test_name : string) is
      variable l : line;
    begin
      write(l, LF);
      print_separator;
      write(l, string'("TEST "));
      write(l, test_count);
      write(l, string'(": "));
      write(l, test_name);
      writeline(output, l);
      print_separator;
    end procedure;

    procedure print_inputs is
      variable l : line;
    begin
      write(l, LF);
      write(l, string'("INPUTS:"));
      writeline(output, l);
      write(l, string'("  opcode = "));
      write(l, opcode);
      write(l, string'(" ("));
      case opcode(3 downto 2) is
        when "00" => write(l, string'("JZ"));
        when "01" => write(l, string'("JN"));
        when "10" => write(l, string'("JC"));
        when others => write(l, string'("??"));
      end case;
      write(l, string'(", enable="));
      write(l, opcode(0));
      write(l, string'(")"));
      writeline(output, l);
      write(l, string'("  ccr    = "));
      write(l, ccr);
      write(l, string'(" [C="));
      write(l, ccr(0));
      write(l, string'(", N="));
      write(l, ccr(1));
      write(l, string'(", Z="));
      write(l, ccr(2));
      write(l, string'("]"));
      writeline(output, l);
    end procedure;

    procedure print_outputs is
      variable l : line;
    begin
      write(l, LF);
      write(l, string'("OUTPUTS:"));
      writeline(output, l);
      write(l, string'("  branch_taken = "));
      write(l, branch_taken);
      writeline(output, l);
    end procedure;

    procedure clear_signals is
    begin
      opcode <= (others => '0');
      ccr <= (others => '0');
    end procedure;

    procedure check_result(
      expected_branch : std_logic;
      test_desc : string
    ) is
      variable l : line;
      variable test_passed : boolean := true;
    begin
      write(l, LF);
      write(l, string'("CHECKING: "));
      write(l, test_desc);
      writeline(output, l);

      -- Check branch_taken
      if branch_taken /= expected_branch then
        write(l, string'("  FAIL: branch_taken mismatch"));
        writeline(output, l);
        write(l, string'("    Expected: "));
        write(l, expected_branch);
        writeline(output, l);
        write(l, string'("    Got:      "));
        write(l, branch_taken);
        writeline(output, l);
        test_passed := false;
      else
        write(l, string'("  PASS: branch_taken = "));
        write(l, branch_taken);
        writeline(output, l);
      end if;

      if test_passed then
        write(l, string'(">>> TEST PASSED <<<"));
        writeline(output, l);
        pass_count := pass_count + 1;
      else
        write(l, string'(">>> TEST FAILED <<<"));
        writeline(output, l);
        fail_count := fail_count + 1;
      end if;
    end procedure;

  begin
    -- Test Banner
    write(l, LF & LF);
    write(l, string'("================================================================================"));
    writeline(output, l);
    write(l, string'("        BRANCH DETECTION UNIT TESTBENCH - COMPREHENSIVE VALIDATION"));
    writeline(output, l);
    write(l, string'("================================================================================"));
    writeline(output, l);
    write(l, LF);
    write(l, string'("Testing all branch types: JZ (Jump if Zero), JN (Jump if Negative), JC (Jump if Carry)"));
    writeline(output, l);
    write(l, string'("Opcode format: [3:2]=type, [1]=invert, [0]=enable"));
    writeline(output, l);
    write(l, string'("CCR format: [0]=Carry, [1]=Negative, [2]=Zero"));
    writeline(output, l);

    wait for 10 ns;

    --------------------------------------------------------------------------------
    -- Test 1: JZ - Branch Taken (Z=1, enable=1)
    --------------------------------------------------------------------------------
    test_count := test_count + 1;
    print_header("JZ - Jump if Zero (Taken)");
    clear_signals;
    
    opcode <= "0011";  -- JZ with enable
    ccr <= "100";      -- Zero flag set
    
    wait for 1 ns;
    print_inputs;
    wait for 1 ns;
    print_outputs;
    
    check_result(
      expected_branch => '1',
      test_desc => "JZ should branch when Zero flag is set"
    );

    --------------------------------------------------------------------------------
    -- Test 2: JZ - Branch Not Taken (Z=0, enable=1)
    --------------------------------------------------------------------------------
    test_count := test_count + 1;
    print_header("JZ - Jump if Zero (Not Taken)");
    clear_signals;
    
    opcode <= "0011";  -- JZ with enable
    ccr <= "010";      -- Negative flag set, Zero clear
    
    wait for 1 ns;
    print_inputs;
    wait for 1 ns;
    print_outputs;
    
    check_result(
      expected_branch => '0',
      test_desc => "JZ should not branch when Zero flag is clear"
    );

    --------------------------------------------------------------------------------
    -- Test 3: JZ - Disabled (Z=1, enable=0)
    --------------------------------------------------------------------------------
    test_count := test_count + 1;
    print_header("JZ - Branch Disabled");
    clear_signals;
    
    opcode <= "0010";  -- JZ without enable (bit 0 = 0)
    ccr <= "100";      -- Zero flag set
    
    wait for 1 ns;
    print_inputs;
    wait for 1 ns;
    print_outputs;
    
    check_result(
      expected_branch => '0',
      test_desc => "JZ should not branch when enable bit is 0"
    );

    --------------------------------------------------------------------------------
    -- Test 4: JN - Branch Taken (N=1, enable=1)
    --------------------------------------------------------------------------------
    test_count := test_count + 1;
    print_header("JN - Jump if Negative (Taken)");
    clear_signals;
    
    opcode <= "0111";  -- JN with enable
    ccr <= "010";      -- Negative flag set
    
    wait for 1 ns;
    print_inputs;
    wait for 1 ns;
    print_outputs;
    
    check_result(
      expected_branch => '1',
      test_desc => "JN should branch when Negative flag is set"
    );

    --------------------------------------------------------------------------------
    -- Test 5: JN - Branch Not Taken (N=0, enable=1)
    --------------------------------------------------------------------------------
    test_count := test_count + 1;
    print_header("JN - Jump if Negative (Not Taken)");
    clear_signals;
    
    opcode <= "0111";  -- JN with enable
    ccr <= "100";      -- Zero flag set, Negative clear
    
    wait for 1 ns;
    print_inputs;
    wait for 1 ns;
    print_outputs;
    
    check_result(
      expected_branch => '0',
      test_desc => "JN should not branch when Negative flag is clear"
    );

    --------------------------------------------------------------------------------
    -- Test 6: JN - Disabled (N=1, enable=0)
    --------------------------------------------------------------------------------
    test_count := test_count + 1;
    print_header("JN - Branch Disabled");
    clear_signals;
    
    opcode <= "0110";  -- JN without enable
    ccr <= "010";      -- Negative flag set
    
    wait for 1 ns;
    print_inputs;
    wait for 1 ns;
    print_outputs;
    
    check_result(
      expected_branch => '0',
      test_desc => "JN should not branch when enable bit is 0"
    );

    --------------------------------------------------------------------------------
    -- Test 7: JC - Branch Taken (C=1, enable=1)
    --------------------------------------------------------------------------------
    test_count := test_count + 1;
    print_header("JC - Jump if Carry (Taken)");
    clear_signals;
    
    opcode <= "1011";  -- JC with enable
    ccr <= "001";      -- Carry flag set
    
    wait for 1 ns;
    print_inputs;
    wait for 1 ns;
    print_outputs;
    
    check_result(
      expected_branch => '1',
      test_desc => "JC should branch when Carry flag is set"
    );

    --------------------------------------------------------------------------------
    -- Test 8: JC - Branch Not Taken (C=0, enable=1)
    --------------------------------------------------------------------------------
    test_count := test_count + 1;
    print_header("JC - Jump if Carry (Not Taken)");
    clear_signals;
    
    opcode <= "1011";  -- JC with enable
    ccr <= "110";      -- Zero + Negative flags set, Carry clear
    
    wait for 1 ns;
    print_inputs;
    wait for 1 ns;
    print_outputs;
    
    check_result(
      expected_branch => '0',
      test_desc => "JC should not branch when Carry flag is clear"
    );

    --------------------------------------------------------------------------------
    -- Test 9: JC - Disabled (C=1, enable=0)
    --------------------------------------------------------------------------------
    test_count := test_count + 1;
    print_header("JC - Branch Disabled");
    clear_signals;
    
    opcode <= "1010";  -- JC without enable
    ccr <= "001";      -- Carry flag set
    
    wait for 1 ns;
    print_inputs;
    wait for 1 ns;
    print_outputs;
    
    check_result(
      expected_branch => '0',
      test_desc => "JC should not branch when enable bit is 0"
    );

    --------------------------------------------------------------------------------
    -- Test 10: Multiple Flags Set - JZ
    --------------------------------------------------------------------------------
    test_count := test_count + 1;
    print_header("JZ - Multiple Flags Set");
    clear_signals;
    
    opcode <= "0011";  -- JZ with enable
    ccr <= "111";      -- All flags set
    
    wait for 1 ns;
    print_inputs;
    wait for 1 ns;
    print_outputs;
    
    check_result(
      expected_branch => '1',
      test_desc => "JZ should branch when Zero flag is set (regardless of other flags)"
    );

    --------------------------------------------------------------------------------
    -- Test 11: Multiple Flags Set - JN
    --------------------------------------------------------------------------------
    test_count := test_count + 1;
    print_header("JN - Multiple Flags Set");
    clear_signals;
    
    opcode <= "0111";  -- JN with enable
    ccr <= "111";      -- All flags set
    
    wait for 1 ns;
    print_inputs;
    wait for 1 ns;
    print_outputs;
    
    check_result(
      expected_branch => '1',
      test_desc => "JN should branch when Negative flag is set (regardless of other flags)"
    );

    --------------------------------------------------------------------------------
    -- Test 12: Multiple Flags Set - JC
    --------------------------------------------------------------------------------
    test_count := test_count + 1;
    print_header("JC - Multiple Flags Set");
    clear_signals;
    
    opcode <= "1011";  -- JC with enable
    ccr <= "111";      -- All flags set
    
    wait for 1 ns;
    print_inputs;
    wait for 1 ns;
    print_outputs;
    
    check_result(
      expected_branch => '1',
      test_desc => "JC should branch when Carry flag is set (regardless of other flags)"
    );

    --------------------------------------------------------------------------------
    -- Test 13: No Flags Set - JZ
    --------------------------------------------------------------------------------
    test_count := test_count + 1;
    print_header("JZ - No Flags Set");
    clear_signals;
    
    opcode <= "0011";  -- JZ with enable
    ccr <= "000";      -- No flags set
    
    wait for 1 ns;
    print_inputs;
    wait for 1 ns;
    print_outputs;
    
    check_result(
      expected_branch => '0',
      test_desc => "JZ should not branch when no flags are set"
    );

    --------------------------------------------------------------------------------
    -- Test 14: No Flags Set - JN
    --------------------------------------------------------------------------------
    test_count := test_count + 1;
    print_header("JN - No Flags Set");
    clear_signals;
    
    opcode <= "0111";  -- JN with enable
    ccr <= "000";      -- No flags set
    
    wait for 1 ns;
    print_inputs;
    wait for 1 ns;
    print_outputs;
    
    check_result(
      expected_branch => '0',
      test_desc => "JN should not branch when no flags are set"
    );

    --------------------------------------------------------------------------------
    -- Test 15: No Flags Set - JC
    --------------------------------------------------------------------------------
    test_count := test_count + 1;
    print_header("JC - No Flags Set");
    clear_signals;
    
    opcode <= "1011";  -- JC with enable
    ccr <= "000";      -- No flags set
    
    wait for 1 ns;
    print_inputs;
    wait for 1 ns;
    print_outputs;
    
    check_result(
      expected_branch => '0',
      test_desc => "JC should not branch when no flags are set"
    );

    --------------------------------------------------------------------------------
    -- Test Summary
    --------------------------------------------------------------------------------
    write(l, LF & LF);
    write(l, string'("================================================================================"));
    writeline(output, l);
    write(l, string'("                          TEST SUMMARY"));
    writeline(output, l);
    write(l, string'("================================================================================"));
    writeline(output, l);
    write(l, string'("Total Tests: "));
    write(l, test_count);
    writeline(output, l);
    write(l, string'("Passed:      "));
    write(l, pass_count);
    writeline(output, l);
    write(l, string'("Failed:      "));
    write(l, fail_count);
    writeline(output, l);
    
    if fail_count = 0 then
      write(l, LF);
      write(l, string'("*** ALL TESTS PASSED ***"));
      writeline(output, l);
    else
      write(l, LF);
      write(l, string'("*** SOME TESTS FAILED ***"));
      writeline(output, l);
    end if;
    write(l, string'("================================================================================"));
    writeline(output, l);
    
    test_done <= true;
    wait;
  end process;

end architecture testbench;
