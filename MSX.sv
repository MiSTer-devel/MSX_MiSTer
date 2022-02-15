//============================================================================
//  MSX replica
// 
//  Port to MiSTer
//  Copyright (C) 2017-2019 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

//assign ADC_BUS  = 'Z;  - We need the ADC for the EAR
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;

assign LED_USER  = vsd_sel & sd_act;
assign LED_DISK  = {1'b1, ~vsd_sel & sd_act};
assign LED_POWER = 0;
assign BUTTONS   = 0;
assign VGA_SCALER= 0;
assign HDMI_FREEZE = 0;

`include "build_id.v"
localparam CONF_STR = {
	"MSX;;",
	"S,VHD;",
	"OE,Reset after Mount,No,Yes;",
	"-;",
	"O89,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O23,Scanlines,No,25%,50%,75%;",
	"-;",
	"OF,Vertical Crop,No,Yes;",
	"OGH,Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"-;",
	"O1,CPU speed,Normal,Turbo(+F11);",
	"OB,CPU type,Z80,R800;",
	"-;",
	"O4,Slot1,Empty,MegaSCC+ 1MB;",
	"O56,Slot2,Empty,MegaSCC+ 2MB,MegaRAM ASCII-8K 1MB,MegaRAM ASCII-16K 2MB;",
	"-;",
	"O7,Internal Mapper,2048KB RAM,4096KB RAM;",
	"-;",
	"OD,Joysticks Swap,No,Yes;",
	"OC,Mouse,Port 1,Port 2;",
	"-;",
	"RA,Reset;",
	"J,Fire 1,Fire 2;",
	"V,v",`BUILD_DATE
};


////////////////////   CLOCKS   ///////////////////

wire locked;
wire clk_sys;
wire clk_mem;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_mem),
	.outclk_1(clk_sys),
	.locked(locked)
);

wire cold_reset = RESET | status[0] | ~initReset_n;
wire reset = cold_reset | buttons[1] | status[10] | (status[14] && img_mounted);

reg initReset_n = 0;
always @(posedge clk_sys) begin
	integer timeout = 0;
	
	if(timeout < 5000000) timeout <= timeout + 1;
	else initReset_n <= 1;
end

//////////////////   HPS I/O   ///////////////////
wire [10:0] ps2_key;
wire [24:0] ps2_mouse;
wire        ps2_caps_led;
wire        forced_scandoubler;
wire        scandoubler = forced_scandoubler || status[3:2];
wire [15:0] joy_A;
wire [15:0] joy_B;
wire  [1:0] buttons;
wire [31:0] status;
wire [64:0] rtc;

wire [31:0] sd_lba;
wire        sd_rd;
wire        sd_wr;
wire        sd_ack;
wire  [8:0] sd_buff_addr;
wire  [7:0] sd_buff_dout;
wire  [7:0] sd_buff_din;
wire        sd_buff_wr;
wire        img_mounted;
wire        img_readonly;
wire [63:0] img_size;

wire [15:0] joy_0 = status[13] ? joy_B : joy_A;
wire [15:0] joy_1 = status[13] ? joy_A : joy_B;

wire [21:0] gamma_bus;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.joystick_0(joy_A),
	.joystick_1(joy_B),

	.buttons(buttons),
	.status(status),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),

	.RTC(rtc),

	.ps2_key(ps2_key),
	.ps2_mouse(ps2_mouse),

	.ps2_kbd_led_use(3'b001),
	.ps2_kbd_led_status({2'b00, ps2_caps_led}),

	.sd_lba('{sd_lba}),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din('{sd_buff_din}),
	.sd_buff_wr(sd_buff_wr),
	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),

	.ioctl_wait(0)
);

wire [13:0] audioOPLL;
wire  [9:0] audioPSG;
wire [15:0] audioPCM;
wire  [7:0] audioTRPCM;

wire [16:0] pcm   = {audioPCM[15], audioPCM} + {audioTRPCM[7], audioTRPCM, 8'd0};
wire [15:0] fm    = {audioOPLL, 2'b00} + {1'b0, audioPSG, 5'b00000};
wire [16:0] audio = {pcm[16], pcm[16:1]} + {fm[15], fm};

wire [15:0] compr[7:0] = '{ {1'b1, audio[13:0], 1'b0}, 16'h8000, 16'h8000, 16'h8000, 16'h7FFF, 16'h7FFF, 16'h7FFF,  {1'b0, audio[13:0], 1'b0}};
assign AUDIO_L = compr[audio[16:14]];
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 1;
assign AUDIO_MIX = 0;

wire [5:0] r,g,b;
wire de,vs,hs;

reg [7:0] ro,go,bo;
reg deo,vso,hso;

assign CLK_VIDEO = clk_mem;
assign CE_PIXEL  = ce_pix;
assign VGA_SL = status[3:2];
assign VGA_F1 = 0;

reg ce_pix = 0;
always @(posedge clk_mem) begin
	reg [2:0] div;
	
	div <= div + 1'd1;

	if(scandoubler) ce_pix <= !div[1:0];
	else ce_pix <= !div;

	if(ce_pix) begin
		ro <= {r,r[5:4]};
		go <= {g,g[5:4]};
		bo <= {b,b[5:4]};
		{deo,hso} <= {de,hs};
		if(~hso & hs) vso <= vs;
	end
end

gamma_fast gamma
(
	.clk_vid(CLK_VIDEO),
	.ce_pix(ce_pix),
	.gamma_bus(gamma_bus),
	.HSync(hso),
	.VSync(vso),
	.DE(deo),
	.RGB_in({ro,go,bo}),

	.HSync_out(VGA_HS),
	.VSync_out(VGA_VS),
	.DE_out(vga_de),
	.RGB_out({VGA_R,VGA_G,VGA_B})
);

reg [11:0] vcrop;
always @(posedge CLK_VIDEO) begin
	vcrop <= (HDMI_HEIGHT == 1080) ? 12'd216 : 12'd240;
	if(scandoubler) vcrop <= 12'd480;
end

wire [1:0] ar = status[9:8];
wire vcrop_en = status[15];
wire vga_de;
video_freak video_freak
(
	.*,
	.VGA_DE_IN(vga_de),
	.ARX((!ar) ? 12'd4 : (ar - 1'd1)),
	.ARY((!ar) ? 12'd3 : 12'd0),
	.CROP_SIZE(vcrop_en ? vcrop : 12'd0),
	.CROP_OFF(0),
	.SCALE(status[17:16])
);


wire [7:0]  sdr_dat;
wire        sdr_dat_en;
reg  [15:0] sdram_dq;

assign SDRAM_DQ = sdram_dq;

always @(posedge clk_mem) begin
	sdram_dq <= 16'bZ;
	if(sdr_dat_en) sdram_dq <= {sdr_dat, sdr_dat};
end

emsx_top emsx
(
	.clk21m(clk_sys),
	.memclk(clk_mem),
	.pReset(reset),
	.pColdReset(cold_reset),

	.pMemCs_n(SDRAM_nCS),
	.pMemRas_n(SDRAM_nRAS),
	.pMemCas_n(SDRAM_nCAS),
	.pMemWe_n(SDRAM_nWE),
	.pMemUdq(SDRAM_DQMH),
	.pMemLdq(SDRAM_DQML),
	.pMemBa1(SDRAM_BA[1]),
	.pMemBa0(SDRAM_BA[0]),
	.pMemAdr(SDRAM_A),
	.pMemDatIn(SDRAM_DQ),
	.pMemDatOut(sdr_dat),
	.pMemDatEn(sdr_dat_en),
	.pMemCke(SDRAM_CKE),

	.ps2_key(ps2_key),
	.pCaps(ps2_caps_led),

	.rtc_setup(cold_reset),
	.rtc_time(rtc),

	.pJoyA((use_mouse & ~status[12]) ? mdata : ~{joy_0[5:4], joy_0[0], joy_0[1], joy_0[2], joy_0[3]}),
	.pStrA(mstrobeA),
	.pJoyB((use_mouse &  status[12]) ? mdata : ~{joy_1[5:4], joy_1[0], joy_1[1], joy_1[2], joy_1[3]}),
	.pStrB(mstrobeB),

	.mmc_sck(sdclk),
	.mmc_mosi(sdmosi),
	.mmc_cs(sdss),
	.mmc_miso(sdmiso),

	.pDip({1'b0,~status[7],~status[6:5],~status[4],2'b00,~status[1]}),
	.pLed(),
	.pLedPwr(),
	.pR800(status[11]),

	.pDac_VR(r),
	.pDac_VG(g),
	.pDac_VB(b),
	.pVideoDE(de),
	.pVideoHS(hs),
	.pVideoVS(vs),
	.pScandoubler(scandoubler),

	.cmtin(tape_in),   		// EAR Added by Fernando Mosquera

	.pAudioPSG(audioPSG),     //10bits unsigned
	.pAudioOPLL(audioOPLL),   //10bits unsigned
	.pAudioPCM(audioPCM),     //16bits signed
	.pAudioTRPCM(audioTRPCM)  //8bits  signed
);

altddio_out
#(
	.extend_oe_disable("OFF"),
	.intended_device_family("Cyclone V"),
	.invert_output("OFF"),
	.lpm_hint("UNUSED"),
	.lpm_type("altddio_out"),
	.oe_reg("UNREGISTERED"),
	.power_up_high("OFF"),
	.width(1)
)
sdramclk_ddr
(
	.datain_h(1'b0),
	.datain_l(1'b1),
	.outclock(clk_mem),
	.dataout(SDRAM_CLK),
	.aclr(1'b0),
	.aset(1'b0),
	.oe(1'b1),
	.outclocken(1'b1),
	.sclr(1'b0),
	.sset(1'b0)
);

wire [5:0] mdata;
wire       mstrobeA,mstrobeB;

ps2mouse mouse
(
	.clk(clk_sys),
	.reset(reset),
	.strobe(status[12] ? mstrobeB : mstrobeA),
	.data(mdata),
	.ps2_mouse(ps2_mouse)
);

reg use_mouse = 0;
always @(posedge clk_sys) begin
	reg old_stb = 0;
	
	old_stb <= ps2_mouse[24];
	if(reset) use_mouse <= 0;
	if(old_stb ^ ps2_mouse[24]) use_mouse <= 1;
	if(status[12] ? joy_1[5:0] : joy_0[5:0]) use_mouse <= 0;
end


//////////////////   SD   ///////////////////

wire sdclk;
wire sdmosi;
wire sdmiso = vsd_sel ? vsdmiso : SD_MISO;
wire sdss;

reg vsd_sel = 0;
always @(posedge clk_sys) if(img_mounted) vsd_sel <= |img_size;

wire vsdmiso;
sd_card sd_card
(
	.*,

	.clk_spi(clk_mem),
	.sdhc(1),
	.sck(sdclk),
	.ss(sdss | ~vsd_sel),
	.mosi(sdmosi),
	.miso(vsdmiso)
);

assign SD_CS   = sdss   |  vsd_sel;
assign SD_SCK  = sdclk  & ~vsd_sel;
assign SD_MOSI = sdmosi & ~vsd_sel;

reg sd_act;

always @(posedge clk_sys) begin
	reg old_mosi, old_miso;
	integer timeout = 0;

	old_mosi <= sdmosi;
	old_miso <= sdmiso;

	sd_act <= 0;
	if(timeout < 1000000) begin
		timeout <= timeout + 1;
		sd_act <= 1;
	end

	if((old_mosi ^ sdmosi) || (old_miso ^ sdmiso)) timeout <= 0;
end

/////////  EAR added by Fernando Mosquera
wire tape_in;
assign tape_in = tape_adc_act & tape_adc;

wire tape_adc, tape_adc_act;
ltc2308_tape ltc2308_tape
(
  .clk(CLK_50M),
  .ADC_BUS(ADC_BUS),
  .dout(tape_adc),
  .active(tape_adc_act)
);
/////////////////////////

endmodule
