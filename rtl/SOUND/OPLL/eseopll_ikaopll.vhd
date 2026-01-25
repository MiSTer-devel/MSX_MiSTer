--
-- eseopll_ikaopll.vhd
-- Wrapper for IKAOPLL (YM2413) on ESE-MSX bus
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity eseopll is
  port(
    clk21m  : in std_logic;
    reset   : in std_logic;
    clkena  : in std_logic;
    enawait : in std_logic;
    req     : in std_logic;
    ack     : out std_logic;
    wrt     : in std_logic;
    adr     : in std_logic_vector(15 downto 0);
    dbo     : in std_logic_vector(7 downto 0);
    wav     : out std_logic_vector(13 downto 0)
 );
end eseopll;

architecture RTL of eseopll is

  signal D_reg  : std_logic_vector(7 downto 0) := (others => '0');
  signal A_reg  : std_logic := '0';
  signal CS_n   : std_logic := '1';
  signal WR_n   : std_logic := '1';
  signal IC_n   : std_logic := '1';
  signal wrt_reg : std_logic := '0';
  signal write_count : integer range 0 to 3 := 0;
  signal wait_counter : integer range 0 to 84 := 0;

  signal phim_div  : unsigned(2 downto 0) := (others => '0');
  signal phim_cen  : std_logic := '0';
  signal ic_hold_counter : integer range 0 to 72 := 0;

  signal wav16   : signed(15 downto 0);
  signal wav14_s : signed(13 downto 0);

  component IKAOPLL
      generic (
        FULLY_SYNCHRONOUS        : integer := 1;
        FAST_RESET               : integer := 1;
        ALTPATCH_CONFIG_MODE     : integer := 0;
        USE_PIPELINED_MULTIPLIER : integer := 1
    );
    port (
      i_XIN_EMUCLK         : in  std_logic;
      o_XOUT               : out std_logic;
      i_phiM_PCEN_n        : in  std_logic;
      i_IC_n               : in  std_logic;
      i_ALTPATCH_EN        : in  std_logic;
      i_CS_n               : in  std_logic;
      i_WR_n               : in  std_logic;
      i_A0                 : in  std_logic;
      i_D                  : in  std_logic_vector(7 downto 0);
      o_D                  : out std_logic_vector(1 downto 0);
      o_D_OE               : out std_logic;
      o_DAC_EN_MO          : out std_logic;
      o_DAC_EN_RO          : out std_logic;
      o_IMP_NOFLUC_SIGN    : out std_logic;
      o_IMP_NOFLUC_MAG     : out std_logic_vector(7 downto 0);
      o_IMP_FLUC_SIGNED_MO : out signed(9 downto 0);
      o_IMP_FLUC_SIGNED_RO : out signed(9 downto 0);
      i_ACC_SIGNED_MOVOL   : in  signed(4 downto 0);
      i_ACC_SIGNED_ROVOL   : in  signed(4 downto 0);
      o_ACC_SIGNED_STRB    : out std_logic;
      o_ACC_SIGNED         : out signed(15 downto 0)
    );
  end component;

begin

  IC_n <= '0' when (reset = '1' or ic_hold_counter /= 0) else '1';
  ack <= req when (write_count = 0 and wait_counter = 0) else '0';

  process(clk21m)
  begin
    if rising_edge(clk21m) then
      if phim_div = "101" then
        phim_div <= (others => '0');
        phim_cen <= '1';
      else
        phim_div <= phim_div + 1;
        phim_cen <= '0';
      end if;

      if reset = '1' then
        write_count <= 0;
        wait_counter <= 0;
        ic_hold_counter <= 72;
        CS_n <= '1';
        WR_n <= '1';
        D_reg <= (others => '0');
        A_reg <= '0';
        wrt_reg <= '0';
      else
        if phim_cen = '1' then
          if ic_hold_counter /= 0 then
            ic_hold_counter <= ic_hold_counter - 1;
          end if;
          if wait_counter /= 0 then
            wait_counter <= wait_counter - 1;
          end if;
          if write_count /= 0 then
            write_count <= write_count - 1;
          end if;
        end if;

        if req = '1' and write_count = 0 and wait_counter = 0 then
          A_reg <= adr(0);
          D_reg <= dbo;
          wrt_reg <= wrt;
          write_count <= 2;
          if enawait = '1' then
            if adr(0) = '0' then
              wait_counter <= 12;
            else
              wait_counter <= 84;
            end if;
          end if;
        end if;

        if write_count /= 0 then
          CS_n <= '0';
          WR_n <= not wrt_reg;
        else
          CS_n <= '1';
          WR_n <= '1';
        end if;
      end if;
    end if;
  end process;

  U1 : IKAOPLL
    generic map (
        FULLY_SYNCHRONOUS        => 1,
        FAST_RESET               => 1,
        ALTPATCH_CONFIG_MODE     => 0,
        USE_PIPELINED_MULTIPLIER => 1
    )
    port map (
      i_XIN_EMUCLK         => clk21m,
      o_XOUT               => open,
      i_phiM_PCEN_n        => not phim_cen,
      i_IC_n               => IC_n,
      i_ALTPATCH_EN        => '0',
      i_CS_n               => CS_n,
      i_WR_n               => WR_n,
      i_A0                 => A_reg,
      i_D                  => D_reg,
      o_D                  => open,
      o_D_OE               => open,
      o_DAC_EN_MO          => open,
      o_DAC_EN_RO          => open,
      o_IMP_NOFLUC_SIGN    => open,
      o_IMP_NOFLUC_MAG     => open,
      o_IMP_FLUC_SIGNED_MO => open,
      o_IMP_FLUC_SIGNED_RO => open,
      i_ACC_SIGNED_MOVOL   => to_signed(4, 5),
      i_ACC_SIGNED_ROVOL   => to_signed(5, 5),
      o_ACC_SIGNED_STRB    => open,
      o_ACC_SIGNED         => wav16
    );

  wav14_s <= wav16(15) & wav16(13 downto 1);
  wav <= std_logic_vector(wav14_s);

end RTL;
