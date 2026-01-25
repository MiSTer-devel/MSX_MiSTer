module IKAOPLL_pg #(parameter USE_PIPELINED_MULTIPLIER = 1) (
    //master clock
    input   wire            i_EMUCLK, //emulator master clock

    //master reset
    input   wire            i_RST_n,

    //internal clock
    input   wire            i_phi1_PCEN_n, //positive edge clock enable for emulation
    input   wire            i_phi1_NCEN_n, //negative edge clock enable for emulation

    //timings
    input   wire            i_CYCLE_17, i_CYCLE_20, i_CYCLE_21,

    //parameters
    input   wire    [3:0]   i_TEST,
    input   wire            i_RHYTHM_EN,
    input   wire    [8:0]   i_FNUM,
    input   wire    [2:0]   i_BLOCK,
    input   wire            i_PM,
    input   wire    [2:0]   i_PMVAL,
    input   wire    [3:0]   i_MUL,

    //control
    input   wire            i_PG_PHASE_RST,

    //output
    output  wire    [9:0]   o_OP_PHASE
);


///////////////////////////////////////////////////////////
//////  Clock and reset
////

wire            emuclk = i_EMUCLK;
wire            phi1pcen_n = i_phi1_PCEN_n;
wire            phi1ncen_n = i_phi1_NCEN_n;



///////////////////////////////////////////////////////////
//////  Cycle 0: Latch FNUM and BLOCK
////

reg     [8:0]   cyc0r_fnum;
reg     [2:0]   cyc0r_block;
reg     [3:0]   cyc0r_mul;
reg             cyc0r_pm;
always @(posedge emuclk) if(!phi1ncen_n) begin
    cyc0r_fnum <= i_FNUM;
    cyc0r_block <= i_BLOCK;
    cyc0r_mul <= i_MUL;
    cyc0r_pm <= i_PM;
end



//declare cyc3r variable first
reg     [18:0]  cyc3r_phase_current;

//cycle 18 out
wire    [18:0]  cyc18r_phase_sr_out;

generate
if(USE_PIPELINED_MULTIPLIER == 1) begin : USE_PIPELINED_MULTIPLIER_1

///////////////////////////////////////////////////////////
//////  Cycle 1: Add PMVAL and shift
////

//make phase modulation value using high bits of the FNUM
wire            cyc1c_pmamt_sign = i_PMVAL[2] & cyc0r_pm;
reg     [2:0]   cyc1c_pmamt_val;
always @(*) begin
    case(i_PMVAL[1:0] & {2{cyc0r_pm}})
        2'b00: cyc1c_pmamt_val = 3'b000                  ^ {3{cyc1c_pmamt_sign}};
        2'b01: cyc1c_pmamt_val = {1'b0, cyc0r_fnum[8:7]} ^ {3{cyc1c_pmamt_sign}};
        2'b10: cyc1c_pmamt_val = {cyc0r_fnum[8:6]}       ^ {3{cyc1c_pmamt_sign}};
        2'b11: cyc1c_pmamt_val = {1'b0, cyc0r_fnum[8:7]} ^ {3{cyc1c_pmamt_sign}};
    endcase
end

//debug
wire    [9:0]   debug_cyc1c_pmamt_full = {{7{cyc1c_pmamt_sign}}, cyc1c_pmamt_val} + cyc1c_pmamt_sign;

//modulate phase by adding the modulation value
wire    [10:0]  cyc1c_pdelta_modded_val = {cyc0r_fnum, 1'b0} + {{7{cyc1c_pmamt_sign}}, cyc1c_pmamt_val} + cyc1c_pmamt_sign;
wire            cyc1c_pdelta_modded_msb = cyc1c_pdelta_modded_val[10] & ~cyc1c_pmamt_sign;
wire    [10:0]  cyc1c_pdelta_modded = {cyc1c_pdelta_modded_msb, cyc1c_pdelta_modded_val[9:0]}; 

//do block shift(octave)
reg     [13:0]  cyc1c_blockshifter0;
reg     [16:0]  cyc1c_blockshifter1;
always @(*) begin
    case(cyc0r_block[1:0])
        2'b00: cyc1c_blockshifter0 = {3'b000, cyc1c_pdelta_modded};
        2'b01: cyc1c_blockshifter0 = {2'b00, cyc1c_pdelta_modded, 1'b0};
        2'b10: cyc1c_blockshifter0 = {1'b0, cyc1c_pdelta_modded, 2'b00};
        2'b11: cyc1c_blockshifter0 = {cyc1c_pdelta_modded, 3'b000};
    endcase

    case(cyc0r_block[2])
        1'b0: cyc1c_blockshifter1 = {4'b0000, cyc1c_blockshifter0[13:1]};
        1'b1: cyc1c_blockshifter1 = {cyc1c_blockshifter0, 3'b000};
    endcase
end

//register part
reg     [3:0]   cyc1r_mul;
reg     [16:0]  cyc1r_pdelta_shifted;
reg     [18:0]  cyc1r_phase_prev;
always @(posedge emuclk) if(!phi1ncen_n) begin
    case(cyc0r_mul)
        4'h0: cyc1r_mul <= 4'd0;
        4'h1: cyc1r_mul <= 4'd1;
        4'h2: cyc1r_mul <= 4'd2;
        4'h3: cyc1r_mul <= 4'd3;
        4'h4: cyc1r_mul <= 4'd4;
        4'h5: cyc1r_mul <= 4'd5;
        4'h6: cyc1r_mul <= 4'd6;
        4'h7: cyc1r_mul <= 4'd7;
        4'h8: cyc1r_mul <= 4'd8;
        4'h9: cyc1r_mul <= 4'd9;
        4'hA: cyc1r_mul <= 4'd10;
        4'hB: cyc1r_mul <= 4'd10;
        4'hC: cyc1r_mul <= 4'd12;
        4'hD: cyc1r_mul <= 4'd12;
        4'hE: cyc1r_mul <= 4'd15;
        4'hF: cyc1r_mul <= 4'd15;
    endcase
    cyc1r_pdelta_shifted <= cyc1c_blockshifter1;

    cyc1r_phase_prev <= ~(i_PG_PHASE_RST | i_TEST[2]) ? cyc18r_phase_sr_out : 19'd0;
end



///////////////////////////////////////////////////////////
//////  Cycle 2: Apply MUL
////

reg     [20:0]  cyc2r_pdelta_multiplied; //use 19-bit only
reg     [18:0]  cyc2r_phase_prev;
always @(posedge emuclk) if(!phi1ncen_n) begin
    if(cyc1r_mul == 4'd0) cyc2r_pdelta_multiplied <= {5'b00000, cyc1r_pdelta_shifted[16:1]};
    else begin
        cyc2r_pdelta_multiplied <= cyc1r_pdelta_shifted * cyc1r_mul;
    end

    cyc2r_phase_prev <= cyc1r_phase_prev;
end



///////////////////////////////////////////////////////////
//////  Cycle 3: Add phase delta to the previous phase
////

always @(posedge emuclk) if(!phi1ncen_n) begin
    cyc3r_phase_current <= cyc2r_pdelta_multiplied[18:0] + cyc2r_phase_prev;
end

end
else begin : USE_PIPELINED_MULTIPLIER_0

///////////////////////////////////////////////////////////
//////  Cycle 1: Add PMVAL, shift, and apply MUL
////

//make phase modulation value using high bits of the FNUM
wire            cyc1c_pmamt_sign = i_PMVAL[2] & cyc0r_pm;
reg     [2:0]   cyc1c_pmamt_val;
always @(*) begin
    case(i_PMVAL[1:0] & {2{cyc0r_pm}})
        2'b00: cyc1c_pmamt_val = 3'b000                  ^ {3{cyc1c_pmamt_sign}};
        2'b01: cyc1c_pmamt_val = {1'b0, cyc0r_fnum[8:7]} ^ {3{cyc1c_pmamt_sign}};
        2'b10: cyc1c_pmamt_val = {cyc0r_fnum[8:6]}       ^ {3{cyc1c_pmamt_sign}};
        2'b11: cyc1c_pmamt_val = {1'b0, cyc0r_fnum[8:7]} ^ {3{cyc1c_pmamt_sign}};
    endcase
end

//modulate phase by adding the modulation value
wire    [10:0]  cyc1c_pdelta_modded_val = {cyc0r_fnum, 1'b0} + {{7{cyc1c_pmamt_sign}}, cyc1c_pmamt_val} + cyc1c_pmamt_sign;
wire            cyc1c_pdelta_modded_sign = cyc1c_pdelta_modded_val[10] & ~cyc1c_pmamt_sign;
wire    [10:0]  cyc1c_pdelta_modded = {cyc1c_pdelta_modded_sign, cyc1c_pdelta_modded_val[9:0]}; 

//do block shift(octave)
reg     [13:0]  cyc1c_blockshifter0;
reg     [16:0]  cyc1c_blockshifter1;
always @(*) begin
    case(cyc0r_block[1:0])
        2'b00: cyc1c_blockshifter0 = {3'b000, cyc1c_pdelta_modded};
        2'b01: cyc1c_blockshifter0 = {2'b00, cyc1c_pdelta_modded, 1'b0};
        2'b10: cyc1c_blockshifter0 = {1'b0, cyc1c_pdelta_modded, 2'b00};
        2'b11: cyc1c_blockshifter0 = {cyc1c_pdelta_modded, 3'b000};
    endcase

    case(cyc0r_block[2])
        1'b0: cyc1c_blockshifter1 = {4'b0000, cyc1c_blockshifter0[13:1]};
        1'b1: cyc1c_blockshifter1 = {cyc1c_blockshifter0, 3'b000};
    endcase
end

//apply MUL
reg     [20:0]  cyc1c_pdelta_multiplied;
always @(*) begin
    case(cyc0r_mul)
        4'h0: cyc1c_pdelta_multiplied = {5'b00000, cyc1c_blockshifter1[16:1]};
        4'h1: cyc1c_pdelta_multiplied = cyc1c_blockshifter1 * 4'd1;
        4'h2: cyc1c_pdelta_multiplied = cyc1c_blockshifter1 * 4'd2;
        4'h3: cyc1c_pdelta_multiplied = cyc1c_blockshifter1 * 4'd3;
        4'h4: cyc1c_pdelta_multiplied = cyc1c_blockshifter1 * 4'd4;
        4'h5: cyc1c_pdelta_multiplied = cyc1c_blockshifter1 * 4'd5;
        4'h6: cyc1c_pdelta_multiplied = cyc1c_blockshifter1 * 4'd6;
        4'h7: cyc1c_pdelta_multiplied = cyc1c_blockshifter1 * 4'd7;
        4'h8: cyc1c_pdelta_multiplied = cyc1c_blockshifter1 * 4'd8;
        4'h9: cyc1c_pdelta_multiplied = cyc1c_blockshifter1 * 4'd9;
        4'hA: cyc1c_pdelta_multiplied = cyc1c_blockshifter1 * 4'd10;
        4'hB: cyc1c_pdelta_multiplied = cyc1c_blockshifter1 * 4'd10;
        4'hC: cyc1c_pdelta_multiplied = cyc1c_blockshifter1 * 4'd12;
        4'hD: cyc1c_pdelta_multiplied = cyc1c_blockshifter1 * 4'd12;
        4'hE: cyc1c_pdelta_multiplied = cyc1c_blockshifter1 * 4'd15;
        4'hF: cyc1c_pdelta_multiplied = cyc1c_blockshifter1 * 4'd15;
    endcase
end

//previous phase
wire    [18:0]  cyc1c_phase_prev;

//register part
reg     [18:0]  cyc1r_pdelta_multiplied;
reg     [18:0]  cyc1r_phase_prev;
always @(posedge emuclk) if(!phi1ncen_n) begin
    cyc1r_pdelta_multiplied <= cyc1c_pdelta_multiplied[18:0];
    cyc1r_phase_prev <= ~(~i_PG_PHASE_RST | i_TEST[2]) ? cyc18r_phase_sr_out : 19'd0;
end



///////////////////////////////////////////////////////////
//////  Cycle 2: Add phase delta to the previous phase
////

reg     [18:0]  cyc2r_phase_current;
always @(posedge emuclk) if(!phi1ncen_n) begin
    cyc2r_phase_current <= cyc1r_pdelta_multiplied + cyc1r_phase_prev;
end



///////////////////////////////////////////////////////////
//////  Cycle 3: NOP
////

always @(posedge emuclk) if(!phi1ncen_n) begin
    cyc3r_phase_current <= cyc2r_phase_current;
end

end
endgenerate



///////////////////////////////////////////////////////////
//////  Cycle 4-18: delay shift register
////

IKAOPLL_sr #(.WIDTH(19), .LENGTH(15)) u_cyc4r_cyc18r_phase_sr
(.i_EMUCLK(emuclk), .i_CEN_n(phi1ncen_n), .i_D(i_RST_n ? cyc3r_phase_current : 19'd0), .o_Q_LAST(cyc18r_phase_sr_out),
 .o_Q_TAP0(), .o_Q_TAP1(), .o_Q_TAP2()); //reset input added



///////////////////////////////////////////////////////////
//////  Rhythm phase generator/phase selector
////

/*
    CH7 M = BD0
    CH7 C = BD1
    CH8 M = HH
    CH8 C = SD
    CH9 M = TT
    CH9 C = TC

    HH phase arrives at the SR final stage at cycle 17
    SD phase arrives at the SR final stage at cycle 20
    TC phase arrives at the SR final stage at cycle 21
*/

//rhythm phase enables
wire            hh_phase_en = i_CYCLE_17 & i_RHYTHM_EN;
wire            sd_phase_en = i_CYCLE_20 & i_RHYTHM_EN;
wire            tc_phase_en = i_CYCLE_21 & i_RHYTHM_EN;

//phase latch
reg     [3:0]   hh_phase_z;
reg     [1:0]   tc_phase_z;
always @(posedge emuclk) if(!phi1pcen_n) begin
    if(i_CYCLE_17)  hh_phase_z <= {cyc18r_phase_sr_out[17:16], cyc18r_phase_sr_out[12:11]};
    if(tc_phase_en) tc_phase_z <= {cyc18r_phase_sr_out[14], cyc18r_phase_sr_out[12]};
end

//make alias signals
wire            hh_phase_z_d17 = hh_phase_z[3];
wire            hh_phase_z_d16 = hh_phase_z[2];
wire            hh_phase_z_d12 = hh_phase_z[1];
wire            hh_phase_z_d11 = hh_phase_z[0];
wire            tc_phase_z_d14 = tc_phase_z[1];
wire            tc_phase_z_d12 = tc_phase_z[0];

//what the fuck??
wire            scramble_phase = |{(hh_phase_z_d16 ^ hh_phase_z_d11),
                                   (hh_phase_z_d12 ^ tc_phase_z_d14),
                                   (tc_phase_z_d14 ^ tc_phase_z_d12)};

//declare the LFSR noise output port first...
wire            noise_out;
wire            noise_inv = noise_out ^ scramble_phase;

//generate rhythm phase
reg     [9:0]   rhythm_phase;
always @(*) begin
    case({hh_phase_en, sd_phase_en, tc_phase_en})
        3'b100:  rhythm_phase = {scramble_phase, 1'b0, {2{noise_inv}}, ~noise_inv, 1'b1, 1'b0, ~noise_inv, 2'b00}; //1'b1 <- optimized
        3'b010:  rhythm_phase = {hh_phase_z_d17, noise_out ^ hh_phase_z_d17, 8'b0000_0000}; //negative input XNOR -> XNOR
        3'b001:  rhythm_phase = {scramble_phase, 1'b1, 8'b0000_0000};
        default: rhythm_phase = 10'b00_0000_0000;
    endcase
end

wire            pgmem_out_en = ~((i_CYCLE_17 | i_CYCLE_20 | i_CYCLE_21) & i_RHYTHM_EN);
assign  o_OP_PHASE = rhythm_phase | (cyc18r_phase_sr_out[18:9] & {10{pgmem_out_en}});



///////////////////////////////////////////////////////////
//////  LFSR
////

reg     [22:0]  noise_lfsr;
wire            noise_lfsr_zero = noise_lfsr == 23'd0;
assign  noise_out = noise_lfsr[22];

always @(posedge emuclk) begin
    if(!i_RST_n) noise_lfsr <= 23'd0; //parallel reset added: the original design doesnt't have this
    else begin if(!phi1ncen_n) begin
        noise_lfsr[0] <= (noise_lfsr[22] ^ noise_lfsr[8]) | noise_lfsr_zero | i_TEST[1];
        noise_lfsr[22:1] <= noise_lfsr[21:0];
    end end
end



///////////////////////////////////////////////////////////
//////  STATIC PHASE REGISTERS FOR DEBUGGING
////

reg     [4:0]   debug_cyccntr = 5'd0;
reg     [9:0]   debug_phasereg_static[0:17];
always @(posedge emuclk) if(!phi1ncen_n) begin
    if(i_CYCLE_21) debug_cyccntr <= 5'd0;
    else debug_cyccntr <= debug_cyccntr + 5'd1;

    case(debug_cyccntr)
        5'd0 : debug_phasereg_static[0]  <= o_OP_PHASE; //Ch.1 M
        5'd3 : debug_phasereg_static[1]  <= o_OP_PHASE; //Ch.1 C
        5'd1 : debug_phasereg_static[2]  <= o_OP_PHASE; //Ch.2 M
        5'd4 : debug_phasereg_static[3]  <= o_OP_PHASE; //Ch.2 C
        5'd2 : debug_phasereg_static[4]  <= o_OP_PHASE; //Ch.3 M
        5'd5 : debug_phasereg_static[5]  <= o_OP_PHASE; //Ch.3 C
        5'd6 : debug_phasereg_static[6]  <= o_OP_PHASE; //Ch.4 M
        5'd9 : debug_phasereg_static[7]  <= o_OP_PHASE; //Ch.4 C
        5'd7 : debug_phasereg_static[8]  <= o_OP_PHASE; //Ch.5 M
        5'd10: debug_phasereg_static[9]  <= o_OP_PHASE; //Ch.5 C
        5'd8 : debug_phasereg_static[10] <= o_OP_PHASE; //Ch.6 M
        5'd11: debug_phasereg_static[11] <= o_OP_PHASE; //Ch.6 C
        5'd12: debug_phasereg_static[12] <= o_OP_PHASE; //Ch.7 M | BD M
        5'd15: debug_phasereg_static[13] <= o_OP_PHASE; //Ch.7 C | BD C
        5'd13: debug_phasereg_static[14] <= o_OP_PHASE; //Ch.8 M | HH
        5'd16: debug_phasereg_static[15] <= o_OP_PHASE; //Ch.8 C | SD
        5'd14: debug_phasereg_static[16] <= o_OP_PHASE; //Ch.9 M | TT
        5'd17: debug_phasereg_static[17] <= o_OP_PHASE; //Ch.9 C | TC
        default: ;
    endcase
end

endmodule