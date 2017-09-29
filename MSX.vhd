library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
 
entity emu is port
(
	-- Master input clock
   CLK_50M          : in    std_logic;

   -- Async reset from top-level module.
   -- Can be used as initial reset.
   RESET            : in    std_logic;

	-- Must be passed to hps_io module
	HPS_BUS          : inout std_logic_vector(37 downto 0);

   -- Base video clock. Usually equals to CLK_SYS.
   CLK_VIDEO        : out   std_logic;

   -- Multiple resolutions are supported using different CE_PIXEL rates.
   -- Must be based on CLK_VIDEO
   CE_PIXEL         : out   std_logic;

   -- Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
   VIDEO_ARX        : out   std_logic_vector(7 downto 0);
   VIDEO_ARY        : out   std_logic_vector(7 downto 0);

   -- VGA
   VGA_R            : out   std_logic_vector(7 downto 0);
   VGA_G            : out   std_logic_vector(7 downto 0);
   VGA_B            : out   std_logic_vector(7 downto 0);
   VGA_HS           : out   std_logic; -- positive pulse!
   VGA_VS           : out   std_logic; -- positive pulse!
   VGA_DE           : out   std_logic; -- = not (VBlank or HBlank)

   -- LED
   LED_USER         : out   std_logic; -- 1 - ON, 0 - OFF.

	-- b[1]: 0 - LED status is system status ORed with b[0]
	--       1 - LED status is controled solely by b[0]
	-- hint: supply 2'b00 to let the system control the LED.
	LED_POWER        : out   std_logic_vector(1 downto 0);
	LED_DISK         : out   std_logic_vector(1 downto 0);

   -- AUDIO
   AUDIO_L          : out   std_logic_vector(15 downto 0);
   AUDIO_R          : out   std_logic_vector(15 downto 0);
   AUDIO_S          : out   std_logic; -- 1 - signed audio samples, 0 - unsigned
   TAPE_IN          : in    std_logic;

	-- Secondary SD
	SD_SCK           : out   std_logic;
	SD_MOSI          : out   std_logic;
	SD_MISO          : in    std_logic;
	SD_CS            : out   std_logic;

	-- High latency DDR3 RAM interface
	-- Use for non-critical time purposes
	DDRAM_CLK        : out   std_logic;
	DDRAM_BUSY       : in    std_logic;
	DDRAM_BURSTCNT   : out   std_logic_vector(7 downto 0);
	DDRAM_ADDR       : out   std_logic_vector(28 downto 0);
	DDRAM_DOUT       : in    std_logic_vector(63 downto 0);
	DDRAM_DOUT_READY : in    std_logic;
	DDRAM_RD         : out   std_logic;
	DDRAM_DIN        : out   std_logic_vector(63 downto 0);
	DDRAM_BE         : out   std_logic_vector(7 downto 0);
	DDRAM_WE         : out   std_logic;

   -- SDRAM interface with lower latency
   SDRAM_CLK        : out   std_logic;
   SDRAM_CKE        : out   std_logic;
   SDRAM_A          : out   std_logic_vector(12 downto 0);
   SDRAM_BA         : out   std_logic_vector(1 downto 0);
   SDRAM_DQ         : inout std_logic_vector(15 downto 0);
   SDRAM_DQML       : out   std_logic;
   SDRAM_DQMH       : out   std_logic;
   SDRAM_nCS        : out   std_logic;
   SDRAM_nCAS       : out   std_logic;
   SDRAM_nRAS       : out   std_logic;
   SDRAM_nWE        : out   std_logic
);
end entity; 

architecture rtl of emu is

signal mreset      : std_logic;
signal pll_locked  : std_logic;
signal clk21m      : std_logic;
signal memclk      : std_logic;

signal audiol   : std_logic_vector(15 downto 0);
signal audior   : std_logic_vector(15 downto 0);

signal VGA_HS_n : std_logic;
signal VGA_VS_n : std_logic;

-- user_io
signal buttons : std_logic_vector(1 downto 0);
signal status  : std_logic_vector(31 downto 0);
signal joy_0   : std_logic_vector(15 downto 0);
signal joy_1   : std_logic_vector(15 downto 0);
signal joyn_0  : std_logic_vector(5 downto 0);
signal joyn_1  : std_logic_vector(5 downto 0);


-- PS/2 Keyboard
signal ps2_keyboard_clk_in  : std_logic;
signal ps2_keyboard_dat_in  : std_logic;
signal ps2_keyboard_clk_out : std_logic;
signal ps2_keyboard_dat_out : std_logic;

-- PS/2 Mouse
signal ps2_mouse_clk_in   : std_logic;
signal ps2_mouse_dat_in   : std_logic;
signal ps2_mouse_clk_out  : std_logic;
signal ps2_mouse_dat_out  : std_logic;


-- Sigma Delta audio
COMPONENT hybrid_pwm_sd
	PORT
	(
		clk		: IN STD_LOGIC;
		n_reset	: IN STD_LOGIC;
		din		: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		dout		: OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT video_vga_dither
	GENERIC ( outbits : INTEGER := 4 );
	PORT
	(
		clk		: IN STD_LOGIC;
		hsync		: IN STD_LOGIC;
		vsync		: IN STD_LOGIC;
		vid_ena	: IN STD_LOGIC;
		iRed		: IN UNSIGNED(7 DOWNTO 0);
		iGreen	: IN UNSIGNED(7 DOWNTO 0);
		iBlue		: IN UNSIGNED(7 DOWNTO 0);
		oRed		: OUT UNSIGNED(outbits-1 DOWNTO 0);
		oGreen	: OUT UNSIGNED(outbits-1 DOWNTO 0);
		oBlue		: OUT UNSIGNED(outbits-1 DOWNTO 0)
	);
END COMPONENT;

function to_slv(s: string) return std_logic_vector is
    constant ss: string(1 to s'length) := s;
    variable rval: std_logic_vector(1 to 8 * s'length);
    variable p: integer;
    variable c: integer;
  
  begin  
    for i in ss'range loop
      p := 8 * i;
      c := character'pos(ss(i));
      rval(p - 7 to p) := std_logic_vector(to_unsigned(c,8));
    end loop;
    return rval;

end function;
  
component hps_io generic(STRLEN : integer := 0; PS2WE : integer := 0); port
(
	CLK_SYS           : in  std_logic;
	HPS_BUS           : inout std_logic_vector(37 downto 0);

	conf_str          : in  std_logic_vector(8*STRLEN-1 downto 0);

	buttons           : out std_logic_vector(1 downto 0);
	forced_scandoubler : out std_logic;

	joystick_0        : out std_logic_vector(15 downto 0);
	joystick_1        : out std_logic_vector(15 downto 0);
	joystick_analog_0 : out std_logic_vector(15 downto 0);
	joystick_analog_1 : out std_logic_vector(15 downto 0);
	status            : out std_logic_vector(31 downto 0);

	sd_lba            : in  std_logic_vector(31 downto 0);
	sd_rd             : in  std_logic;
	sd_wr             : in  std_logic;
	sd_ack            : out std_logic;
	sd_conf           : in  std_logic;
	sd_ack_conf       : out std_logic;

	sd_buff_addr      : out std_logic_vector(8 downto 0);
	sd_buff_dout      : out std_logic_vector(7 downto 0);
	sd_buff_din       : in  std_logic_vector(7 downto 0);
	sd_buff_wr        : out std_logic;

	img_mounted       : out std_logic;
	img_size          : out std_logic_vector(63 downto 0);
	img_readonly      : out std_logic;

	ps2_kbd_clk_out   : out std_logic;
	ps2_kbd_data_out  : out std_logic;
	ps2_kbd_clk_in    : in  std_logic;
	ps2_kbd_data_in   : in  std_logic;

	ps2_mouse_clk_out : out std_logic;
	ps2_mouse_data_out: out std_logic;
	ps2_mouse_clk_in  : in  std_logic;
	ps2_mouse_data_in : in  std_logic;

	ps2_kbd_led_use   : in  std_logic_vector(2 downto 0);
	ps2_kbd_led_status: in  std_logic_vector(2 downto 0);

	ioctl_download    : out std_logic;
	ioctl_index       : out std_logic_vector(7 downto 0);
	ioctl_wr          : out std_logic;
	ioctl_addr        : out std_logic_vector(24 downto 0);
	ioctl_dout        : out std_logic_vector(7 downto 0)
);
end component hps_io; 
  
component sd_card
   port (  
		io_lba 	: out std_logic_vector(31 downto 0);
		io_rd  	: out std_logic;
		io_wr  	: out std_logic;
		io_ack 	: in std_logic;
		io_sdhc 	: out std_logic;
		io_conf 	: out std_logic;
		io_din 	: in std_logic_vector(7 downto 0);
		io_din_strobe : in std_logic;
		io_dout 	: out std_logic_vector(7 downto 0);
		io_dout_strobe : in std_logic;

		allow_sdhc : in std_logic;

		sd_cs 		:	in std_logic;
		sd_sck 	:	in std_logic;
		sd_sdi 	:	in std_logic;
		sd_sdo 	:	out std_logic
	);
  end component sd_card;

component pll
   port (  
		refclk   : in std_logic;
		rst      : in std_logic;
		outclk_0 : out std_logic;
		outclk_1 : out std_logic;
		outclk_2 : out std_logic;
		locked   : out std_logic
	);
  end component pll;

begin

LED_DISK  <= "00";
LED_POWER <= "00";
LED_USER  <= '0';

U00 : pll
	port map(
		rst      => '0',
		refclk   => CLK_50M,
		outclk_0 => memclk,     -- 85.72MHz = 21.43MHz x 4
		outclk_1 => SDRAM_CLK,  -- 85.72MHz external
		outclk_2 => clk21m,     -- 21.43MHz internal (50*3/7)
		locked   => pll_locked
	);

SDRAM_A(12)<='0';

-- reset from IO controller
-- status bit 0 is always triggered by the i ocontroller on its own reset
-- button 1 is the core specfic button in the mists front
mreset <= '0' when status(0)='1' or buttons(1)='1' or pll_locked = '0' or RESET = '1' else '1';

emsx_top : entity work.Virtual_Toplevel
	generic map(
		mouse_fourbyte => '0',
		mouse_init => '0'
	)
  port map(
    -- Clock, Reset ports
		clk21m => clk21m,
		memclk => memclk,
		lock_n => mreset,

--    -- MSX cartridge slot ports
--    pSltClk     : out std_logic;	-- pCpuClk returns here, for Z80, etc.
--    pSltRst_n   : in std_logic :='1';		-- pCpuRst_n returns here
--    pSltSltsl_n : inout std_logic:='1';
--    pSltSlts2_n : inout std_logic:='1';
--    pSltIorq_n  : inout std_logic:='1';
--    pSltRd_n    : inout std_logic:='1';
--    pSltWr_n    : inout std_logic:='1';
--    pSltAdr     : inout std_logic_vector(15 downto 0):=(others=>'1');
--    pSltDat     : inout std_logic_vector(7 downto 0):=(others=>'1');
--    pSltBdir_n  : out std_logic;	-- Bus direction (not used in master mode)
--
--    pSltCs1_n   : inout std_logic:='1';
--    pSltCs2_n   : inout std_logic:='1';
--    pSltCs12_n  : inout std_logic:='1';
--    pSltRfsh_n  : inout std_logic:='1';
--    pSltWait_n  : inout std_logic:='1';
--    pSltInt_n   : inout std_logic:='1';
--    pSltM1_n    : inout std_logic:='1';
--    pSltMerq_n  : inout std_logic:='1';
--
--    pSltRsv5    : out std_logic;            -- Reserved
--    pSltRsv16   : out std_logic;            -- Reserved (w/ external pull-up)
--    pSltSw1     : inout std_logic:='1';          -- Reserved (w/ external pull-up)
--    pSltSw2     : inout std_logic:='1';          -- Reserved

    -- SDRAM DE1 ports
--	 pMemClk => sd_clk,
    pMemCke => SDRAM_CKE,
    pMemCs_n => SDRAM_nCS,
    pMemRas_n => SDRAM_nRAS,
    pMemCas_n => SDRAM_nCAS,
    pMemWe_n => SDRAM_nWE,
    pMemUdq => SDRAM_DQMH,
    pMemLdq => SDRAM_DQML,
    pMemBa1 => SDRAM_BA(1),
    pMemBa0 => SDRAM_BA(0),
    pMemAdr => SDRAM_A(11 downto 0),
    pMemDat => SDRAM_DQ,

    -- PS/2 keyboard ports
	 pPs2Clk_in => ps2_keyboard_clk_in,
	 pPs2Dat_in => ps2_keyboard_dat_in,
	 pPs2Clk_out => ps2_keyboard_clk_out,
	 pPs2Dat_out => ps2_keyboard_dat_out,

    -- PS/2 mouse ports
	 ps2m_clk_in => ps2_mouse_clk_in,
	 ps2m_dat_in => ps2_mouse_dat_in,
	 ps2m_clk_out => ps2_mouse_clk_out,
	 ps2m_dat_out => ps2_mouse_dat_out,

	 pJoyA => joyn_0,
	 pJoyB => joyn_1,
--    -- Joystick ports (Port_A, Port_B)
--    pJoyA => std_logic_vector(c64_joy1), --       : inout std_logic_vector( 5 downto 0):=(others=>'1');
--    pStrA       : out std_logic;
--    pJoyB => std_logic_vector(c64_joy2), --       : inout std_logic_vector( 5 downto 0):=(others=>'1');
--    pStrB       : out std_logic;

    -- SD/MMC slot ports
    pSd_Ck => SD_SCK,
    pSd_Cm => SD_MOSI,
--  pSd_Dt	    : inout std_logic_vector( 3 downto 0);  -- pin 1(D3), 9(D2), 8(D1), 7(D0)
    pSd_Dt3	=> SD_CS,
    pSd_Dt0	=> SD_MISO,

-- DIP switch, Lamp ports
    pSW => "111"&mreset,
    pDip => "0000111001",
    pLedG => open,
    pLedR => open,

    -- Video, Audio/CMT ports
    pDac_VR => VGA_R,
    pDac_VG => VGA_G,
    pDac_VB => VGA_B,
	 pVideoDE => VGA_DE,

--    pDac_S 		: out   std_logic;						-- Sound
--    pREM_out	: out   std_logic;						-- REM output; 1 - Tape On
--    pCMT_out	: out   std_logic;						-- CMT output
--    pCMT_in		: in    std_logic :='1';						-- CMT input

    pVideoHS_n => VGA_HS_n,
    pVideoVS_n => VGA_VS_n,
    --pVideoHS_OSD_n => VGA_HS_n,
    --pVideoVS_OSD_n => VGA_VS_n,

    -- DE1 7-SEG Display
    hex => open,

	 SOUND_L => audiol,
	 SOUND_R => audior,
	 CmtIn => '1',
	 
	 RS232_RxD => '0',
	 RS232_TxD => open
);

CE_PIXEL <= '1';
CLK_VIDEO <= clk21m;
VGA_HS  <= not VGA_HS_n;
VGA_VS  <= not VGA_VS_n;
AUDIO_L <= audiol;
AUDIO_R <= audior;
AUDIO_S <= '0';

VIDEO_ARX  <= "00000100"; -- when (status(4) = '0') else "00010000";
VIDEO_ARY  <= "00000011"; -- when (status(4) = '0') else "00001001";

hps_io_d : hps_io
    generic map (STRLEN => 5)
    port map (
		clk_sys => clk21m,
		HPS_BUS => HPS_BUS,
      conf_str => X"4f434d5358",   -- no config string -> no osd
      status => status,

      joystick_0 => joy_0,
      joystick_1 => joy_1,
		
		sd_lba => (others => '0'),
		sd_rd => '0',
		sd_wr => '0',
		sd_conf => '0',
		sd_buff_din => (others => '0'),
		ps2_kbd_led_use => (others => '0'),
		ps2_kbd_led_status => (others => '0'),

		BUTTONS => buttons,
      ps2_kbd_clk_out => ps2_keyboard_clk_in,
      ps2_kbd_data_out => ps2_keyboard_dat_in,
      ps2_kbd_clk_in => ps2_keyboard_clk_out,
      ps2_kbd_data_in => ps2_keyboard_dat_out,

      ps2_mouse_clk_out => ps2_mouse_clk_in,
      ps2_mouse_data_out => ps2_mouse_dat_in,
      ps2_mouse_clk_in => ps2_mouse_clk_out,
      ps2_mouse_data_in => ps2_mouse_dat_out
 );
 
-- swap, invert and remap joystick bits
 joyn_0 <= not joy_1(5) & not joy_1(4) & not joy_1(0) & not joy_1(1) & not joy_1(2) & not joy_1(3);
 joyn_1 <= not joy_0(5) & not joy_0(4) & not joy_0(0) & not joy_0(1) & not joy_0(2) & not joy_0(3);
 

end architecture;
