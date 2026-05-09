--============================================================
-- Project #1: Simple 4-bit Calculator
-- EE 421/521 – Programmable Logic Devices and HDL Design
-- Designed by: Mulualem Dereso Ayena
-- Instructor: Thomas Kim
-- Date: October 13, 2025
-- Target: DE2-115 Board
--============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity project1 is
    port(
        clock_50 : in  std_logic;
        key      : in  std_logic_vector(3 downto 0);
        sw       : in  std_logic_vector(17 downto 0);

        hex0, hex1, hex2, hex3 : out std_logic_vector(6 downto 0);
        hex4, hex5, hex6, hex7 : out std_logic_vector(6 downto 0);
        ledr : out std_logic_vector(17 downto 0);
        ledg : out std_logic_vector(8 downto 0)
    );
end entity project1;

architecture rtl of project1 is

    component double_dabble_6bit is
        port(
            binary_in : in  std_logic_vector(5 downto 0);
            bcd_out   : out std_logic_vector(7 downto 0)
        );
    end component;

    signal operand_a, operand_b : std_logic_vector(3 downto 0);
    signal operation_sel        : std_logic_vector(1 downto 0);
    signal calculate_trigger, reset_trigger : std_logic;

    signal a_valid, b_valid : std_logic;
    signal a_unsigned, b_unsigned : unsigned(3 downto 0);
    signal result : signed(7 downto 0);
    signal result_valid : std_logic := '0';
    signal result_negative : std_logic;
    signal result_magnitude : std_logic_vector(5 downto 0);
    signal result_bcd : std_logic_vector(7 downto 0);

begin
    ----------------------------------------------------------------
    -- Input Mapping
    ----------------------------------------------------------------
    operand_a <= sw(7 downto 4);
    operand_b <= sw(3 downto 0);
    operation_sel <= sw(17 downto 16);
    calculate_trigger <= not key(0);
    reset_trigger     <= not key(3);

    ledr(17 downto 16) <= operation_sel;

    ----------------------------------------------------------------
    -- Operand Validation (0–9 valid)
    ----------------------------------------------------------------
    a_unsigned <= unsigned(operand_a);
    b_unsigned <= unsigned(operand_b);

    process(a_unsigned, b_unsigned)
    begin
        if a_unsigned > 9 then
            a_valid <= '0';
        else
            a_valid <= '1';
        end if;

        if b_unsigned > 9 then
            b_valid <= '0';
        else
            b_valid <= '1';
        end if;
    end process;

    ----------------------------------------------------------------
    -- Core Arithmetic Logic
    ----------------------------------------------------------------
    process(clock_50, reset_trigger)
    begin
        if reset_trigger = '1' then
            result <= (others => '0');
            result_valid <= '0';
        elsif rising_edge(clock_50) then
            if calculate_trigger = '1' then
                result_valid <= '1';
                case operation_sel is
                    when "00" =>  -- Addition
                        result <= resize(signed(a_unsigned), 8) + resize(signed(b_unsigned), 8);
                    when "01" =>  -- Subtraction
                        result <= resize(signed(a_unsigned), 8) - resize(signed(b_unsigned), 8);
                    when "10" =>  -- Multiplication
                        result <= signed(resize(a_unsigned * b_unsigned, 8));
                    when "11" =>  -- Division
                        if b_unsigned /= 0 then
                            result <= resize(signed(a_unsigned / b_unsigned), 8);
                        else
                            result <= (others => '0');  -- handled as “E”
                        end if;
                    when others =>
                        result <= (others => '0');
                end case;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- Result Sign and Magnitude
    ----------------------------------------------------------------
    result_negative <= '1' when result < 0 else '0';
    result_magnitude <= std_logic_vector(abs(result(5 downto 0)));

    ----------------------------------------------------------------
    -- Binary-to-BCD Conversion (Result)
    ----------------------------------------------------------------
    dabble_inst : double_dabble_6bit
        port map(
            binary_in => result_magnitude,
            bcd_out   => result_bcd
        );

    ----------------------------------------------------------------
    -- Display Operand A (HEX7–HEX6)
    ----------------------------------------------------------------
    hex7 <= "1111111" when a_valid = '1' else "1001110";  -- 'E' for invalid
    with to_integer(a_unsigned) select
        hex6 <= "1000000" when 0,
                "1111001" when 1,
                "0100100" when 2,
                "0110000" when 3,
                "0011001" when 4,
                "0010010" when 5,
                "0000010" when 6,
                "1111000" when 7,
                "0000000" when 8,
                "0010000" when 9,
                "1001110" when others;

    ----------------------------------------------------------------
    -- Display Operand B (HEX5–HEX4)
    ----------------------------------------------------------------
    hex5 <= "1111111" when b_valid = '1' else "1001110";  -- 'E' for invalid
    with to_integer(b_unsigned) select
        hex4 <= "1000000" when 0,
                "1111001" when 1,
                "0100100" when 2,
                "0110000" when 3,
                "0011001" when 4,
                "0010010" when 5,
                "0000010" when 6,
                "1111000" when 7,
                "0000000" when 8,
                "0010000" when 9,
                "1001110" when others;

    ----------------------------------------------------------------
    -- Display Result (HEX2–HEX0)
    ----------------------------------------------------------------
    hex2 <= "0111111" when result_negative = '1' and result_valid = '1' else "1111111";

    hex1 <= "1000000" when result_bcd(7 downto 4) = "0000" else
            "1111001" when result_bcd(7 downto 4) = "0001" else
            "0100100" when result_bcd(7 downto 4) = "0010" else
            "0110000" when result_bcd(7 downto 4) = "0011" else
            "0011001" when result_bcd(7 downto 4) = "0100" else
            "0010010" when result_bcd(7 downto 4) = "0101" else
            "0000010" when result_bcd(7 downto 4) = "0110" else
            "1111000" when result_bcd(7 downto 4) = "0111" else
            "0000000" when result_bcd(7 downto 4) = "1000" else
            "0010000" when result_bcd(7 downto 4) = "1001" else
            "1111111";

    hex0 <= "1001110" when (operation_sel = "11" and b_unsigned = 0) else
            "1000000" when result_bcd(3 downto 0) = "0000" else
            "1111001" when result_bcd(3 downto 0) = "0001" else
            "0100100" when result_bcd(3 downto 0) = "0010" else
            "0110000" when result_bcd(3 downto 0) = "0011" else
            "0011001" when result_bcd(3 downto 0) = "0100" else
            "0010010" when result_bcd(3 downto 0) = "0101" else
            "0000010" when result_bcd(3 downto 0) = "0110" else
            "1111000" when result_bcd(3 downto 0) = "0111" else
            "0000000" when result_bcd(3 downto 0) = "1000" else
            "0010000" when result_bcd(3 downto 0) = "1001" else
            "1111111";

    hex3 <= (others => '1');

end architecture rtl;

--============================================================
-- 6-bit Double Dabble Converter (Binary → BCD)
--============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity double_dabble_6bit is
    port(
        binary_in : in  std_logic_vector(5 downto 0);
        bcd_out   : out std_logic_vector(7 downto 0)
    );
end entity double_dabble_6bit;

architecture behavioral of double_dabble_6bit is
begin
    process(binary_in)
        variable bcd : unsigned(7 downto 0);
        variable bin : unsigned(5 downto 0);
        variable i   : integer;
    begin
        bcd := (others => '0');
        bin := unsigned(binary_in);

        for i in 0 to 5 loop
            if bcd(3 downto 0) >= 5 then
                bcd(3 downto 0) := bcd(3 downto 0) + 3;
            end if;
            if bcd(7 downto 4) >= 5 then
                bcd(7 downto 4) := bcd(7 downto 4) + 3;
            end if;
            bcd := bcd(6 downto 0) & bin(5);
            bin := bin(4 downto 0) & '0';
        end loop;

        bcd_out <= std_logic_vector(bcd);
    end process;
end architecture behavioral;
