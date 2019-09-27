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
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] VIDEO_ARX,
	output  [7:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output  [1:0] VGA_SL,

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

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;

assign LED_USER  = vsd_sel & sd_act;
assign LED_DISK  = {1'b1, ~vsd_sel & sd_act};
assign LED_POWER = 0;
assign BUTTONS   = 0;

assign VIDEO_ARX = status[9] ? 8'd16 : 8'd4;
assign VIDEO_ARY = status[9] ? 8'd9  : 8'd3;

`include "build_id.v"
localparam CONF_STR = {
	"MSX;;",
	"-;",
	"S,VHD;",
	"OE,Reset after Mount,No,Yes;",
	"-;",
	"O9,Aspect ratio,4:3,16:9;",
	"O23,Scanlines,No,25%,50%,75%;",
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
	.outclk_1(SDRAM_CLK),
	.outclk_2(clk_sys),
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
wire        sd_ack_conf;

wire [15:0] joy_0 = status[13] ? joy_B : joy_A;
wire [15:0] joy_1 = status[13] ? joy_A : joy_B;


hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.joystick_0(joy_A),
	.joystick_1(joy_B),

	.buttons(buttons),
	.status(status),
	.forced_scandoubler(forced_scandoubler),

	.RTC(rtc),

	.ps2_key(ps2_key),
	.ps2_mouse(ps2_mouse),

	.ps2_kbd_led_use(3'b001),
	.ps2_kbd_led_status({2'b00, ps2_caps_led}),

	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_ack_conf(sd_ack_conf),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),
	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),

	.ioctl_wait(0)
);

wire [13:0] audioOPLL;
wire  [9:0] audioPSG;
wire [15:0] audioPCM;

wire [15:0] fm    = {audioOPLL, 2'b00} + {1'b0, audioPSG, 5'b00000};
wire [16:0] audio = {audioPCM[15], audioPCM} + {fm[15], fm};

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
assign VGA_DE = deo;
assign VGA_VS = vso;
assign VGA_HS = hso;
assign VGA_SL = status[3:2];
assign VGA_F1 = 0;

reg ce_pix = 0;
always @(posedge clk_mem) begin
	reg [2:0] div;
	
	div <= div + 1'd1;

	if(scandoubler) ce_pix <= !div[1:0];
	else ce_pix <= !div;

	if(ce_pix) begin
		VGA_R <= {r,r[5:4]};
		VGA_G <= {g,g[5:4]};
		VGA_B <= {b,b[5:4]};
		{deo,hso} <= {de,hs};
		if(~hso & hs) vso <= vs;
	end
end

wire [12:0] sdram_a;
assign SDRAM_A[12:11] = (~SDRAM_nCS & ~SDRAM_nRAS & ~(SDRAM_nCAS ^ SDRAM_nWE)) ? sdram_a[12:11] : {SDRAM_DQMH,SDRAM_DQML};
assign SDRAM_A[10:0]  = sdram_a[10:0];
assign SDRAM_CKE      = 1;

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
	.pMemAdr(sdram_a),
	.pMemDat(SDRAM_DQ),

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

	.pAudioPSG(audioPSG),   //10bits unsigned
	.pAudioOPLL(audioOPLL), //14bits signed
	.pAudioPCM(audioPCM)    //16bits signed
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

endmodule
