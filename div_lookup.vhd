
------------------------------------------------------------------------------
--  Name                : div_lookup.vhd
--  Description         : Division lookup table for low number of bits.
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
  
 
entity div_lookup is
  generic(
    NUM_WIDTH                   :     integer := 4;    -- numerator width
    DENOM_WIDTH                 :     integer := 4);   -- denominator width

  port(
    clk                         : in  std_logic;
    reset                       : in  std_logic;
    ce                          : in  std_logic;    
    i_valid                     : in  std_logic;    
    i_num                       : in  std_logic_vector(NUM_WIDTH-1 downto 0);
    i_denom                     : in  std_logic_vector(DENOM_WIDTH-1 downto 0);    
    o_valid                     : out std_logic;        
    o_quo                       : out std_logic_vector(NUM_WIDTH-1 downto 0));
  end entity;
    
architecture beh of div_lookup is    

  
  ------------------------------------------------------------------------------
  --  constants
  --
  constant  ROM_SIZE                    : integer := 2**(NUM_WIDTH+DENOM_WIDTH);

  ------------------------------------------------------------------------------
  --  New type definitions
  --
  type T_array_slv is array (integer range <>) of std_logic_vector;


  ------------------------------------------------------------------------------
  --  Signal declarations
  --
  signal    z_valid                     : std_logic;    
  signal    z_num                       : std_logic_vector(NUM_WIDTH-1 downto 0);
  signal    z_denom                     : std_logic_vector(DENOM_WIDTH-1 downto 0);    
  signal    rom_addr                    : std_logic_vector(NUM_WIDTH+DENOM_WIDTH-1 downto 0);    
  signal    rom_out                     : std_logic_vector(NUM_WIDTH-1 downto 0);    
  signal    z1_z_valid                  : std_logic;    


  ------------------------------------------------------------------------------
  --  function description for the lookup
  --
  function div_lookup_gen (NUM_WIDTH  : in integer; DENOM_WIDTH : in integer) return T_array_slv is
    constant  MAX_IDX         : integer := 2**(NUM_WIDTH+DENOM_WIDTH);
    constant  MAX_DENOM       : integer := 2**DENOM_WIDTH;
    constant  MIN_NUMBER      : integer := -(2**(NUM_WIDTH-1));
    constant  MAX_NUMBER      : integer := 2**(NUM_WIDTH-1)-1;      
    variable  numerator       : integer := 0;
    variable  denominator     : integer := 1;
    variable  result          : integer := 0;
    variable  counter         : unsigned(NUM_WIDTH+DENOM_WIDTH-1 downto 0);
    variable  num             : signed(NUM_WIDTH-1 downto 0);
    variable  denom           : signed(DENOM_WIDTH-1 downto 0);
      
    variable  rom_contents    : T_array_slv(MAX_IDX-1 downto 0)(NUM_WIDTH-1 downto 0);
  begin
    
    for i in 0 to MAX_IDX-1 loop
      counter           := to_unsigned(i, counter'length);
      num               := signed(counter(counter'high downto DENOM_WIDTH));
      denom             := signed(counter(DENOM_WIDTH-1 downto 0));
          
      numerator         := to_integer(num);
      denominator       := to_integer(denom); 
      if denominator = 0 then
        if num >= 0 then
          result          := MAX_NUMBER; 
        else
          result          := MIN_NUMBER; 
        end if;
      else
        result          := numerator/denominator;
      end if;
      rom_contents(i)   := std_logic_vector(to_signed(result, NUM_WIDTH));
    end loop;
    
    return rom_contents;
  end function;


  ------------------------------------------------------------------------------
  --  Defines a lookup table
  --
  signal    div_rom                     : T_array_slv(ROM_SIZE-1 downto 0)(NUM_WIDTH-1 downto 0) := div_lookup_gen(NUM_WIDTH => NUM_WIDTH, DENOM_WIDTH => DENOM_WIDTH);    



begin


  --HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
  --
  --  input pipe registers
  --
  --HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH  

  process(clk)
  begin
    if rising_edge(clk) then
      z_valid   <= i_valid;
      z_num     <= i_num;
      z_denom   <= i_denom;
    end if;
  end process;


  --HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
  --
  --  Perform lookup
  --
  --HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH  


  ---------------------------------------------------------------------------------
  -- generate rom address by concatenating the numberator and the denominator
  -- 
  rom_addr  <= z_num & z_denom;


  ---------------------------------------------------------------------------------
  -- rom implementation
  -- 
  process(clk)
  begin
    if rising_edge(clk) then
      rom_out       <= div_rom(to_integer(unsigned(rom_addr)));
      z1_z_valid    <= z_valid;
    end if;
  end process;



  
  --HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
  --
  --  Output pipe registers
  --
  --HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH  
  
  o_quo     <= rom_out;
  o_valid   <= z1_z_valid;
  
end beh;
