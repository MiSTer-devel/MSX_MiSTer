//============================================================================
//  MSX replica
// 
//  Port to MiSTer
//  Copyright (C) 2017 Sorgelig
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
	inout  [44:0] HPS_BUS,

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

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)
	input         TAPE_IN,

	// SD-SPI
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
	output        SDRAM_nWE
);

assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;

assign LED_USER  = sd_act;
assign LED_DISK  = 0;
assign LED_POWER = 0;

assign VIDEO_ARX = status[9] ? 8'd16 : 8'd4;
assign VIDEO_ARY = status[9] ? 8'd9  : 8'd3;

`include "build_id.v"
localparam CONF_STR = {
	"MSX;;",
	"-;",
	"O9,Aspect ratio,4:3,16:9;",
	"-;",
	"O1,CPU speed,Normal,Turbo(+F11);",
	"-;",
	"O4,Slot1,Empty,MegaSCC+ 1MB;",
	"O56,Slot2,Empty,MegaSCC+ 2MB,MegaRAM ASCII-8K 1MB,MegaRAM ASCII-16K 2MB;",
	"-;",
	"O7,Internal Mapper,2048KB RAM,4096KB RAM;",
	"-;",
	"TA,Reset;",
	"J,Fire 1,Fire 2;",
	"V,v3.50.11.",`BUILD_DATE
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
wire reset = cold_reset | buttons[1] | status[10];

reg initReset_n = 0;
always @(posedge clk_sys) begin
	integer timeout = 0;
	
	if(timeout < 5000000) timeout <= timeout + 1;
	else initReset_n <= 1;
end

//////////////////   HPS I/O   ///////////////////
wire        ps2_kbd_clk_out;
wire        ps2_kbd_data_out;
wire        ps2_mouse_clk_out;
wire        ps2_mouse_data_out;
wire        ps2_caps_led;
wire        forced_scandoubler;

wire [15:0] joy_0;
wire [15:0] joy_1;
wire  [1:0] buttons;
wire [31:0] status;
wire [64:0] rtc;

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.joystick_0(joy_0),
	.joystick_1(joy_1),

	.buttons(buttons),
	.status(status),
	.forced_scandoubler(forced_scandoubler),

	.RTC(rtc),
	.ps2_kbd_clk_out(ps2_kbd_clk_out),
	.ps2_kbd_data_out(ps2_kbd_data_out),
	.ps2_mouse_clk_out(ps2_mouse_clk_out),
	.ps2_mouse_data_out(ps2_mouse_data_out),

	.ps2_kbd_led_use(3'b001),
	.ps2_kbd_led_status({2'b00, ps2_caps_led}),

	.sd_lba(0),
	.sd_rd(0),
	.sd_wr(0),
	.sd_conf(0),
	.sd_buff_din(0),
	.ioctl_wait(0)
);

assign CLK_VIDEO = clk_sys;
assign CE_PIXEL = 1;
assign {VGA_R[1:0], VGA_G[1:0], VGA_B[1:0]} = {VGA_R[7:6], VGA_G[7:6], VGA_B[7:6]};

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

emsx_top emsx
(
	.clk21m(clk_sys),
	.memclk(clk_mem),
	.pReset(reset),
	.pColdReset(cold_reset),

	.pMemCke(SDRAM_CKE),
	.pMemCs_n(SDRAM_nCS),
	.pMemRas_n(SDRAM_nRAS),
	.pMemCas_n(SDRAM_nCAS),
	.pMemWe_n(SDRAM_nWE),
	.pMemUdq(SDRAM_DQMH),
	.pMemLdq(SDRAM_DQML),
	.pMemBa1(SDRAM_BA[1]),
	.pMemBa0(SDRAM_BA[0]),
	.pMemAdr(SDRAM_A),
	.pMemDat(SDRAM_DQ),

	.pPs2Clk(ps2_kbd_clk_out),
	.pPs2Dat(ps2_kbd_data_out),
	.pCaps(ps2_caps_led),

	.rtc_setup(cold_reset),
	.rtc_time(rtc),

	.pJoyA(use_mouse ? mdata : ~{joy_0[5:4], joy_0[0], joy_0[1], joy_0[2], joy_0[3]}),
	.pStrA(mstrobe),
	.pJoyB(~{joy_1[5:4], joy_1[0], joy_1[1], joy_1[2], joy_1[3]}),
	.pStrB(),

	.mmc_sck(SD_SCK),
	.mmc_mosi(SD_MOSI),
	.mmc_cs(SD_CS),
	.mmc_miso(SD_MISO),

	.pDip({1'b0,~status[7],~status[6:5],~status[4],2'b00,~status[1]}),
	.pLed(),
	.pLedPwr(),

	.pDac_VR(VGA_R[7:2]),
	.pDac_VG(VGA_G[7:2]),
	.pDac_VB(VGA_B[7:2]),
	.pVideoDE(VGA_DE),
	.pVideoHS(VGA_HS),
	.pVideoVS(VGA_VS),
	.pScandoubler(forced_scandoubler),

	.pAudioPSG(audioPSG),   //10bits unsigned
	.pAudioOPLL(audioOPLL), //14bits signed
	.pAudioPCM(audioPCM)    //16bits signed
);

wire [5:0] mdata;
wire       mstrobe;

ps2mouse mouse
(
	.clk(clk_sys),
	.reset(reset),
	.strobe(mstrobe),
	.data(mdata),
	.ps2_mouse_data(ps2_mouse_data_out),
	.ps2_mouse_clk(ps2_mouse_clk_out)
);

reg use_mouse = 0;
always @(posedge clk_sys) begin
	if(reset) use_mouse <= 0;
	
	if(~ps2_mouse_clk_out) use_mouse <= 1;
	if(joy_0[5:0]) use_mouse <= 0;
end


//////////////////   SD LED   ///////////////////
reg sd_act;

always @(posedge clk_sys) begin
	reg old_mosi, old_miso;
	integer timeout = 0;

	old_mosi <= SD_MOSI;
	old_miso <= SD_MISO;

	sd_act <= 0;
	if(timeout < 1000000) begin
		timeout <= timeout + 1;
		sd_act <= 1;
	end

	if((old_mosi ^ SD_MOSI) || (old_miso ^ SD_MISO)) timeout <= 0;
end

endmodule
