--============================================================
-- Testbench for Project1
-- Entity Under Test: project1
--============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity project1_tb is
end entity;

architecture tb of project1_tb is

    -- DUT (Device Under Test) component declaration
    component project1
        port(
            clock_50 : in  std_logic;
            key      : in  std_logic_vector(3 downto 0);
            sw       : in  std_logic_vector(17 downto 0);
            hex0, hex1, hex2, hex3 : out std_logic_vector(6 downto 0);
            hex4, hex5, hex6, hex7 : out std_logic_vector(6 downto 0);
            ledr : out std_logic_vector(17 downto 0);
            ledg : out std_logic_vector(8 downto 0)
        );
    end component;

    -- Testbench signals
    signal clock_50 : std_logic := '0';
    signal key      : std_logic_vector(3 downto 0) := (others => '1'); -- active low
    signal sw       : std_logic_vector(17 downto 0) := (others => '0');
    signal hex0, hex1, hex2, hex3 : std_logic_vector(6 downto 0);
    signal hex4, hex5, hex6, hex7 : std_logic_vector(6 downto 0);
    signal ledr : std_logic_vector(17 downto 0);
    signal ledg : std_logic_vector(8 downto 0);

    constant CLK_PERIOD : time := 20 ns;

begin
    ----------------------------------------------------------------
    -- Instantiate the DUT
    ----------------------------------------------------------------
    uut: project1
        port map(
            clock_50 => clock_50,
            key      => key,
            sw       => sw,
            hex0     => hex0,
            hex1     => hex1,
            hex2     => hex2,
            hex3     => hex3,
            hex4     => hex4,
            hex5     => hex5,
            hex6     => hex6,
            hex7     => hex7,
            ledr     => ledr,
            ledg     => ledg
        );

    ----------------------------------------------------------------
    -- Clock generation (50 MHz simulation)
    ----------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            clock_50 <= '0';
            wait for CLK_PERIOD / 2;
            clock_50 <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    ----------------------------------------------------------------
    -- Stimulus Process
    ----------------------------------------------------------------
    stim_proc : process
    begin
        ----------------------------------------------------------------
        report "=== Starting 4-bit Calculator Testbench Simulation ===";
        ----------------------------------------------------------------
        -- RESET
        key(3) <= '0';  -- assert reset (active low)
        wait for 40 ns;
        key(3) <= '1';  -- release reset
        wait for 40 ns;

        ----------------------------------------------------------------
        -- TEST 1: Addition (3 + 4)
        ----------------------------------------------------------------
        report "Test 1: Addition (3 + 4)";
        sw(7 downto 4) <= "0011";  -- A = 3
        sw(3 downto 0) <= "0100";  -- B = 4
        sw(17 downto 16) <= "00";  -- Add
        key(0) <= '0'; wait for 20 ns; key(0) <= '1';
        wait for 200 ns;

        ----------------------------------------------------------------
        -- TEST 2: Subtraction (9 - 6)
        ----------------------------------------------------------------
        report "Test 2: Subtraction (9 - 6)";
        sw(7 downto 4) <= "1001";  -- A = 9
        sw(3 downto 0) <= "0110";  -- B = 6
        sw(17 downto 16) <= "01";  -- Sub
        key(0) <= '0'; wait for 20 ns; key(0) <= '1';
        wait for 200 ns;

        ----------------------------------------------------------------
        -- TEST 3: Multiplication (5 * 7)
        ----------------------------------------------------------------
        report "Test 3: Multiplication (5 * 7)";
        sw(7 downto 4) <= "0101";  -- A = 5
        sw(3 downto 0) <= "0111";  -- B = 7
        sw(17 downto 16) <= "10";  -- Mul
        key(0) <= '0'; wait for 20 ns; key(0) <= '1';
        wait for 200 ns;

        ----------------------------------------------------------------
        -- TEST 4: Division (8 / 2)
        ----------------------------------------------------------------
        report "Test 4: Division (8 / 2)";
        sw(7 downto 4) <= "1000";  -- A = 8
        sw(3 downto 0) <= "0010";  -- B = 2
        sw(17 downto 16) <= "11";  -- Div
        key(0) <= '0'; wait for 20 ns; key(0) <= '1';
        wait for 200 ns;

        ----------------------------------------------------------------
        -- TEST 5: Division by Zero (9 / 0)
        ----------------------------------------------------------------
        report "Test 5: Division by Zero (9 / 0)";
        sw(7 downto 4) <= "1001";  -- A = 9
        sw(3 downto 0) <= "0000";  -- B = 0
        sw(17 downto 16) <= "11";  -- Div
        key(0) <= '0'; wait for 20 ns; key(0) <= '1';
        wait for 200 ns;

        ----------------------------------------------------------------
        -- TEST 6: Invalid Input (A = 12)
        ----------------------------------------------------------------
        report "Test 6: Invalid Input (A = 12)";
        sw(7 downto 4) <= "1100";  -- Invalid
        sw(3 downto 0) <= "0011";  -- B = 3
        sw(17 downto 16) <= "00";  -- Add
        key(0) <= '0'; wait for 20 ns; key(0) <= '1';
        wait for 200 ns;

        ----------------------------------------------------------------
        report "=== Simulation Completed ===";
        wait;
    end process;

end architecture tb;
