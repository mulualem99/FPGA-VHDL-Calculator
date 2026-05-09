
------------------------------------------------------------------------------
--  Name                : double_dabble_6bit.vhd
--  Description         : Double dabble algorithm with 6-bit input data
--
--
--
--  Revision History    :
--      09/16/2024  THK     Init
--

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;
  
 
entity double_dabble_6bit is
  port(
    clk                         : in  std_logic;
    reset                       : in  std_logic;
    ce                          : in  std_logic;    
    i_start                     : in  std_logic;    
    i_data                      : in  std_logic_vector(5 downto 0);     -- 6bit of input data
    o_done                      : out std_logic;        
    o_bcd                       : out std_logic_vector(7 downto 0));    -- two hex digits in BCD format
  end entity;
    
architecture beh of double_dabble_6bit is  

  signal    z1_start                     : std_logic;
  signal    z2_start                     : std_logic;  
  signal    z1_data                      : std_logic_vector(5 downto 0);
  signal    z1_data_abs                  : std_logic_vector(5 downto 0);
  signal    start_pulse                  : std_logic;
  signal    shift_reg                    : std_logic_vector(13 downto 0);
  signal    count                        : unsigned(2 downto 0);
  signal    count_in_progress            : std_logic;
  signal    done                         : std_logic;
  alias     bcd_tens                     : std_logic_vector(3 downto 0) is shift_reg(13 downto 10);
  alias     bcd_ones                     : std_logic_vector(3 downto 0) is shift_reg(9 downto 6);
  
  
begin
  
  ------------------------------------------------------------------------------
  --  Input register
  --
  process(clk)
  begin
    if rising_edge(clk) then
      z1_start <= i_start;
      z2_start <= z1_start;    
      z1_data  <= i_data;
    end if;
  end process;

      
  ------------------------------------------------------------------------------
  --  Leading edge detection
  --
  start_pulse <= z1_start and not z2_start;
      

  ------------------------------------------------------------------------------
  --  perform abs() on the result
  --
  z1_data_abs  <= std_logic_vector(abs(signed(z1_data)));


  ------------------------------------------------------------------------------
  --  performs double-dabble algorithm to convert hex number to BCD
  --
  process(clk)
    variable    shift_reg_temp                    : std_logic_vector(13 downto 0);

  begin
    if rising_edge(clk) then
      if reset = '1' then
        shift_reg <= (others => '0');
      else
        if start_pulse = '1' then
          shift_reg   <= "00000000" & z1_data_abs(5 downto 0);
        elsif count_in_progress = '1' then
          if count < to_unsigned(5, count'length) then
            shift_reg_temp := shift_reg;
            if unsigned(shift_reg(8 downto 5)) >= "0101" then
              shift_reg_temp := std_logic_vector(unsigned(shift_reg_temp) + "00000001100000");
            end if;

            if unsigned(shift_reg(13 downto 9)) >= "0101" then
              shift_reg_temp := std_logic_vector(unsigned(shift_reg_temp) + "00001100000000");
            end if;

            shift_reg   <= shift_reg_temp(shift_reg_temp'high -1 downto 0) & '0';
          else
            shift_reg   <= shift_reg(shift_reg'high -1 downto 0) & '0';     
          end if;
        end if;                                   
      end if;
    end if;
  end process;

                                     
  ------------------------------------------------------------------------------
  --  count_in_progress goes high at start_pulse, and comes down when counter is 5.
  --
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        count_in_progress <= '0';
      else                                 
        if count = "101" then
          count_in_progress <= '0';
        elsif start_pulse = '1' then
          count_in_progress <= '1';
        end if;
      end if;
    end if;
  end process;
      
      
  ------------------------------------------------------------------------------
  --  Count up as long as count_in_progress is high
  --
  process(clk)
  begin
    if rising_edge(clk) then
      if count_in_progress = '0' then
        count <= (others => '0');
      else
        count <= count + 1;
      end if;
    end if;
  end process;

                                     
  ------------------------------------------------------------------------------
  --  drives count done. 
  --
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        done <= '0';
      else                                 
        if count = "101" then
          done <= '1';
        else
          done <= '0';
        end if;
      end if;
    end if;
  end process;
                      
                                 
  ------------------------------------------------------------------------------
  --  Output register
  --
  process(clk)
  begin
    if rising_edge(clk) then
      o_done    <= done;
      o_bcd     <= shift_reg(13 downto 6);                                     
    end if;
  end process;
                                 
  
  

  
  
  
  
  
  
end beh;