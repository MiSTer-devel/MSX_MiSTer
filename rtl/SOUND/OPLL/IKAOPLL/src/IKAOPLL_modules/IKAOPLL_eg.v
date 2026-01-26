module IKAOPLL_eg (
    //master clock
    input   wire            i_EMUCLK, //emulator master clock

    //master reset
    input   wire            i_RST_n,

    //internal clock
    input   wire            i_phi1_PCEN_n, //positive edge clock enable for emulation
    input   wire            i_phi1_NCEN_n, //negative edge clock enable for emulation

    //timings
    input   wire            i_CYCLE_00, i_CYCLE_21, i_MnC_SEL, i_HH_TT_SEL,

    //parameter input
    input   wire    [3:0]   i_TEST,
    input   wire    [8:0]   i_FNUM,
    input   wire    [2:0]   i_BLOCK,
    input   wire            i_KON,
    input   wire            i_SUSEN,
    input   wire    [5:0]   i_TL,
    input   wire            i_ETYP,
    input   wire            i_AM,
    input   wire    [3:0]   i_AMVAL,
    input   wire            i_KSR,
    input   wire    [1:0]   i_KSL,
    input   wire    [3:0]   i_AR, i_DR, i_RR, i_SL,

    //control input
    input   wire            i_EG_ENVCNTR_TEST_DATA,

    //control output
    output  wire            o_PG_PHASE_RST,
    output  wire    [6:0]   o_OP_ATTNLV,
    output  wire            o_OP_ATTNLV_MAX
);


///////////////////////////////////////////////////////////
//////  Clock and reset
////

wire            emuclk = i_EMUCLK;
wire            phi1pcen_n = i_phi1_PCEN_n;
wire            phi1ncen_n = i_phi1_NCEN_n;



///////////////////////////////////////////////////////////
//////  EG prescaler
////

reg     [1:0]   eg_prescaler;
reg             eg_prescaler_d0_z;
wire            serial_val_latch = i_CYCLE_00 & eg_prescaler_d0_z;
always @(posedge emuclk) begin
    if(!i_RST_n) eg_prescaler <= 2'd0;
    else begin if(!phi1ncen_n) begin
        if(i_CYCLE_21) eg_prescaler <= eg_prescaler + 2'd1;
    end end

    if(!phi1ncen_n) eg_prescaler_d0_z <= eg_prescaler[0];
end



///////////////////////////////////////////////////////////
//////  Envelope counter
////

reg     [17:0]  envcntr_sr;
reg             envcntr_adder_co_z;
wire    [1:0]   envcntr_adder = ((envcntr_adder_co_z | i_CYCLE_00) & eg_prescaler == 2'd3) + envcntr_sr[0];
always @(posedge emuclk) if(!phi1ncen_n) begin
    envcntr_adder_co_z <= envcntr_adder[1] & i_RST_n; //save carry

    envcntr_sr[17] <= envcntr_adder[0] & i_RST_n;
    envcntr_sr[16] <= i_TEST[3] ? i_EG_ENVCNTR_TEST_DATA : envcntr_sr[17];
    envcntr_sr[15:0] <= envcntr_sr[16:1]; 
end

reg     [1:0]   envcntr;
always @(posedge emuclk) if(!phi1pcen_n) if(serial_val_latch) envcntr <= envcntr_sr[1:0];

reg     [16:0]  debug_envcntr;
always @(posedge emuclk) if(!phi1pcen_n) if(serial_val_latch) debug_envcntr <= envcntr_sr[16:0];


///////////////////////////////////////////////////////////
//////  Consecutive zero bit counter
////

reg             rst_z;
reg             det_one;
reg     [16:0]  zb_sr;
always @(posedge emuclk) if(!phi1ncen_n) begin
    rst_z <= ~i_RST_n;

    det_one <= ~(~(i_CYCLE_00 | rst_z) & (envcntr_sr[17] | ~det_one));

    zb_sr[16] <= det_one & envcntr_sr[17];
    zb_sr[15:0] <= zb_sr[16:1];
end

reg     [3:0]   conseczerobitcntr;
always @(posedge emuclk) if(!phi1pcen_n) if(serial_val_latch) begin
    conseczerobitcntr[3] <= zb_sr[7] | zb_sr[8] | zb_sr[9] | zb_sr[10] | zb_sr[11] | zb_sr[12];
    conseczerobitcntr[2] <= zb_sr[3] | zb_sr[4] | zb_sr[5] | zb_sr[6]  | zb_sr[11] | zb_sr[12];
    conseczerobitcntr[1] <= zb_sr[1] | zb_sr[2] | zb_sr[5] | zb_sr[6]  | zb_sr[9]  | zb_sr[10];
    conseczerobitcntr[0] <= zb_sr[0] | zb_sr[2] | zb_sr[4] | zb_sr[6]  | zb_sr[8]  | zb_sr[10] | zb_sr[12];
end



///////////////////////////////////////////////////////////
//////  Cycle 2-19: Envelope state machine
////

//envelope status sr
wire    [1:0]   cyc2c_next_envstat;
wire    [1:0]   cyc17r_envstat, cyc19r_envstat;
IKAOPLL_sr #(.WIDTH(2), .LENGTH(18), .TAP0(16)) u_cyc2r_cyc19r_envstatreg
(.i_EMUCLK(i_EMUCLK), .i_CEN_n(i_phi1_NCEN_n), .i_D(cyc2c_next_envstat), .o_Q_TAP0(cyc17r_envstat), .o_Q_LAST(cyc19r_envstat),
 .o_Q_TAP1(), .o_Q_TAP2());

//attenuation level flags, declare here first
wire            cyc2c_decay_end, cyc2c_attnlv_min, cyc18c_attnlv_quite; //min = minimum(zero), quite = human perception of loudness(-???dB)

//delay something
reg             cyc18r_kon, cyc19r_kon;
reg             cyc18r_attnlv_quite, cyc19r_attnlv_quite;
always @(posedge emuclk) if(!phi1ncen_n) begin
    cyc18r_kon <= i_KON;
    cyc19r_kon <= cyc18r_kon;

    cyc18r_attnlv_quite <= cyc18c_attnlv_quite;
    cyc19r_attnlv_quite <= cyc18r_attnlv_quite;
end

//start attack flag
wire            cyc18c_start_attack = cyc17r_envstat == 2'd3 & cyc18c_attnlv_quite & i_KON;
reg             cyc18r_start_attack, cyc19r_start_attack;
always @(posedge emuclk) if(!phi1ncen_n) begin
    cyc18r_start_attack <= cyc18c_start_attack;
    cyc19r_start_attack <= cyc18r_start_attack;
end

//phase reset signal
reg     [14:0]  hh_tt_start_attack_dly; //delays rhythm "start attack" signal for HH(ch8m) and TT(ch9m)
assign  o_PG_PHASE_RST = i_HH_TT_SEL ? hh_tt_start_attack_dly[14] : cyc18r_start_attack;
always @(posedge emuclk) if(!phi1ncen_n) begin
    hh_tt_start_attack_dly[0] <= cyc18r_start_attack;
    hh_tt_start_attack_dly[14:1] <= hh_tt_start_attack_dly[13:0];
end

//masked envelope status
wire    [1:0]   envstat_masked = cyc17r_envstat & {2{~cyc18c_start_attack}};

//make envelope status state machine transition conditions
assign  cyc2c_next_envstat[1] = |{~i_RST_n,
                                  ~cyc19r_start_attack & ~cyc19r_kon,
                                  ~cyc19r_start_attack &  cyc19r_envstat == 2'd3,
                                  ~cyc19r_start_attack &  cyc19r_envstat == 2'd2,
                                  ~cyc19r_start_attack &  cyc19r_envstat == 2'd1 &  cyc2c_decay_end};

assign  cyc2c_next_envstat[0] = |{~i_RST_n,
                                  ~cyc19r_start_attack & ~cyc19r_kon,
                                  ~cyc19r_start_attack &  cyc19r_envstat == 2'd3,
                                  ~cyc19r_start_attack &  cyc19r_envstat == 2'd1 & ~cyc2c_decay_end,
                                  ~cyc19r_start_attack &  cyc19r_envstat == 2'd0 &  cyc2c_attnlv_min};



///////////////////////////////////////////////////////////
//////  Cycle 0: select a rate should be applied
////

//latch the values
wire    [1:0]   cyc0c_egparam_sel = {( i_KON & cyc17r_envstat == 2'd3 & ~cyc18c_attnlv_quite), (~i_KON & ~i_SUSEN & ~i_MnC_SEL & ~i_ETYP)};
reg     [3:0]   cyc0r_egparam_muxed;
reg     [3:0]   cyc0r_ksr_factor;
always @(posedge emuclk) if(!phi1ncen_n) begin
    case(cyc0c_egparam_sel)
        2'b10: cyc0r_egparam_muxed <= 4'd12; //DP rate, "damp" the previous envelope to start the new envelope
        2'b01: cyc0r_egparam_muxed <= 4'd7;  //KON off, attenuating envelope, carrier
        2'b00: begin
            case(envstat_masked)
                2'd0: cyc0r_egparam_muxed <= i_AR;
                2'd1: cyc0r_egparam_muxed <= i_DR;
                2'd2: cyc0r_egparam_muxed <= i_ETYP ? 4'd0 : i_RR;
                2'd3: cyc0r_egparam_muxed <= i_SUSEN ? 4'd5 : i_RR;
            endcase
        end
        2'b11: cyc0r_egparam_muxed <= 4'd15; //bus contention, will not happen
    endcase

    cyc0r_ksr_factor <= i_KSR ? {i_BLOCK[2:0], i_FNUM[8]} : {2'b00, i_BLOCK[2:1]};
end



///////////////////////////////////////////////////////////
//////  Cycle 1: scale egparam and latch some values
////

//combinational
wire    [4:0]   cyc1c_egparam_scaled = cyc0r_egparam_muxed + cyc0r_ksr_factor[3:2];
wire    [3:0]   cyc1c_egparam_saturated = cyc1c_egparam_scaled[4] ? 4'd15 : cyc1c_egparam_scaled[3:0]; //saturation

//register
reg     [1:0]   cyc1r_eg_prescaler;
reg     [3:0]   cyc1r_egparam_saturated;
reg     [3:0]   cyc1r_attenrate; //consecutive zero bit counter
reg             cyc1r_envdeltaweight_intensity;
reg     [1:0]   cyc1r_ksr_factor_lo;
reg             cyc1r_egparam_zero;
always @(posedge emuclk) if(!phi1ncen_n) begin
    cyc1r_eg_prescaler <= eg_prescaler;
    cyc1r_egparam_saturated <= cyc1c_egparam_saturated;
    cyc1r_attenrate <= conseczerobitcntr;
    cyc1r_envdeltaweight_intensity <= (cyc0r_ksr_factor[1]      & ~envcntr[0]) |
							          (cyc0r_ksr_factor[0]      &  envcntr == 2'd0) |
							          (cyc0r_ksr_factor == 2'd3 &  envcntr == 2'd1);
    cyc1r_ksr_factor_lo <= cyc0r_ksr_factor[1:0];
    cyc1r_egparam_zero <= cyc0r_egparam_muxed == 4'd0;
end



///////////////////////////////////////////////////////////
//////  Cycle 2: generate attn delta selector signals
////

wire    [3:0]   cyc2c_egparam_final = cyc1r_egparam_saturated + cyc1r_attenrate; //discard carry
wire            cyc2c_slow_atten = (cyc2c_egparam_final == 4'd12 & cyc1r_egparam_saturated < 4'd12 & ~cyc1r_egparam_zero) |
                                   (cyc2c_egparam_final == 4'd13 & cyc1r_egparam_saturated < 4'd12 & ~cyc1r_egparam_zero & cyc1r_ksr_factor_lo[1]) |
                                   (cyc2c_egparam_final == 4'd14 & cyc1r_egparam_saturated < 4'd12 & ~cyc1r_egparam_zero & cyc1r_ksr_factor_lo[0]);

//activate attenuation: decrease volume linearly
wire            cyc2c_attn_act = (~cyc19r_attnlv_quite & cyc19r_envstat[1]      & ~cyc19r_start_attack) |
                                 (~cyc19r_attnlv_quite & cyc19r_envstat == 2'd1 & ~cyc19r_start_attack & ~cyc2c_decay_end);

//select signals
wire    [3:0]   cyc2c_attndelta_sel;
assign  cyc2c_attndelta_sel[0] =  cyc2c_slow_atten | 
                                 (cyc1r_egparam_saturated == 4'd12 & ~cyc1r_envdeltaweight_intensity);

assign  cyc2c_attndelta_sel[1] = (cyc1r_egparam_saturated == 4'd12 &  cyc1r_envdeltaweight_intensity) |
                                 (cyc1r_egparam_saturated == 4'd13 & ~cyc1r_envdeltaweight_intensity);

assign  cyc2c_attndelta_sel[2] = (cyc1r_egparam_saturated == 4'd13 &                               cyc1r_envdeltaweight_intensity) |
                                 (cyc1r_egparam_saturated == 4'd14 &                              ~cyc1r_envdeltaweight_intensity) |
                                 (cyc1r_egparam_saturated == 4'd12 & cyc1r_eg_prescaler == 2'd3 & ~cyc1r_envdeltaweight_intensity & cyc2c_attn_act) |
                                 (cyc1r_egparam_saturated == 4'd12 & cyc1r_eg_prescaler[0]      &  cyc1r_envdeltaweight_intensity & cyc2c_attn_act) |
                                 (cyc1r_egparam_saturated == 4'd13 & cyc1r_eg_prescaler[0]      & ~cyc1r_envdeltaweight_intensity & cyc2c_attn_act) |
                                 (cyc2c_slow_atten                 & cyc1r_eg_prescaler == 2'd3                                   & cyc2c_attn_act);
                                 
assign  cyc2c_attndelta_sel[3] = (cyc1r_egparam_saturated == 4'd14 &  cyc1r_envdeltaweight_intensity) |
                                  cyc1r_egparam_saturated == 4'd15;


//select attenuation delta(addend 0)
wire            cyc2c_dec_attnlv = cyc19r_envstat == 2'd0 & cyc19r_kon & cyc1r_egparam_saturated != 4'd15 & ~cyc2c_attnlv_min;
wire    [6:0]   cyc19r_attnlv;
wire    [6:0]   cyc19r_attnlv_masked = cyc2c_dec_attnlv ? ~cyc19r_attnlv : 7'd0;

//YM2413 used AOIs to simplify conditional selector, typical one-hot coded selector will not work
wire    [6:0]   cyc2c_attndelta_in0 = cyc2c_attndelta_sel[0] ? {{4{cyc2c_dec_attnlv}}, cyc19r_attnlv_masked[6:4]} : 7'd0;
wire    [6:0]   cyc2c_attndelta_in1 = cyc2c_attndelta_sel[1] ? {{3{cyc2c_dec_attnlv}}, cyc19r_attnlv_masked[6:3]} : 7'd0;
wire    [6:0]   cyc2c_attndelta_in2 = cyc2c_attndelta_sel[2] ? {{2{cyc2c_dec_attnlv}}, cyc19r_attnlv_masked[6:3], cyc2c_attn_act | cyc19r_attnlv_masked[2]} : 7'd0;
wire    [6:0]   cyc2c_attndelta_in3 = cyc2c_attndelta_sel[3] ? {{1{cyc2c_dec_attnlv}}, cyc19r_attnlv_masked[6:3], cyc2c_attn_act | cyc19r_attnlv_masked[2], cyc19r_attnlv_masked[1]} : 7'd0;
wire    [6:0]   cyc2c_attndelta = cyc2c_attndelta_in0 | cyc2c_attndelta_in1 | cyc2c_attndelta_in2 | cyc2c_attndelta_in3;


//control previous attenuation value(addend 1)
wire            cyc2c_curr_attnlv_en = ~(cyc1r_egparam_saturated == 4'd15 & cyc19r_start_attack);
wire            cyc2c_curr_attnlv_force_max = (cyc19r_attnlv_quite & |{cyc19r_envstat} & ~cyc19r_start_attack) | ~i_RST_n;
wire    [6:0]   cyc2c_curr_attnlv = cyc2c_curr_attnlv_force_max ? 7'd127 :
                                                                  cyc2c_curr_attnlv_en ? cyc19r_attnlv : 7'd0;

//sum two addends
wire    [6:0]   cyc2c_next_attnlv = cyc2c_curr_attnlv + cyc2c_attndelta; //discard carry

//register part
reg     [6:0]   cyc2r_attnlv;
always @(posedge emuclk) if(!phi1ncen_n) cyc2r_attnlv <= i_RST_n ? cyc2c_next_attnlv : 7'd127;



///////////////////////////////////////////////////////////
//////  Cycle 3-19 attenuation level storage
////

//cycle 3 to 19
wire    [6:0]   cyc17r_attnlv, cyc18r_attnlv;
IKAOPLL_sr #(.WIDTH(7), .LENGTH(17), .TAP0(15), .TAP1(16)) u_cyc3r_cyc19r_attnlvreg
(.i_EMUCLK(i_EMUCLK), .i_CEN_n(phi1ncen_n), .i_D(cyc2r_attnlv), .o_Q_TAP0(cyc17r_attnlv), .o_Q_TAP1(cyc18r_attnlv), .o_Q_LAST(cyc19r_attnlv),
 .o_Q_TAP2());

//cycle 18
assign  cyc18c_attnlv_quite = cyc17r_attnlv[6:2] == 5'b11111;
reg     [3:0]   cyc18r_sl;
always @(posedge emuclk) if(!phi1ncen_n) cyc18r_sl <= i_SL;

//cycle 19
reg     [3:0]   cyc19r_sl;
always @(posedge emuclk) if(!phi1ncen_n) cyc19r_sl <= cyc18r_sl;

//cycle 2
assign  cyc2c_attnlv_min = cyc19r_attnlv == 7'd0;
assign  o_OP_ATTNLV_MAX = cyc19r_attnlv == 7'd127;
assign  cyc2c_decay_end = cyc19r_attnlv[6:3] == cyc19r_sl;




///////////////////////////////////////////////////////////
//////  Cycle 18: generate key scale value
////

//base attenuation value according to the frequency
reg     [6:0]   cyc18c_ksval_base;
always @(*) begin
    case(i_FNUM[8:5])
        4'h0: cyc18c_ksval_base = 7'd0;
        4'h1: cyc18c_ksval_base = 7'd32;
        4'h2: cyc18c_ksval_base = 7'd40;
        4'h3: cyc18c_ksval_base = 7'd45;
        4'h4: cyc18c_ksval_base = 7'd48;
        4'h5: cyc18c_ksval_base = 7'd51;
        4'h6: cyc18c_ksval_base = 7'd53;
        4'h7: cyc18c_ksval_base = 7'd55;
        4'h8: cyc18c_ksval_base = 7'd56;
        4'h9: cyc18c_ksval_base = 7'd58;
        4'hA: cyc18c_ksval_base = 7'd59;
        4'hB: cyc18c_ksval_base = 7'd60;
        4'hC: cyc18c_ksval_base = 7'd61;
        4'hD: cyc18c_ksval_base = 7'd62;
        4'hE: cyc18c_ksval_base = 7'd63;
        4'hF: cyc18c_ksval_base = 7'd64;
    endcase
end

//additional tuning
wire    [3:0]   cyc18c_ksval_adder_hi = cyc18c_ksval_base[5:3] + i_BLOCK;
wire    [5:0]   cyc18c_ksval = (cyc18c_ksval_adder_hi[3] | cyc18c_ksval_base[6]) ? {cyc18c_ksval_adder_hi[2:0], cyc18c_ksval_base[2:0]} : 6'd0;

//shift
reg     [6:0]   cyc18c_ksval_shifted;
always @(*) begin
    case(i_KSL)
        2'd0: cyc18c_ksval_shifted = 7'd0;
        2'd1: cyc18c_ksval_shifted = {2'b00, cyc18c_ksval[5:1]};
        2'd2: cyc18c_ksval_shifted = {1'b0, cyc18c_ksval};
        2'd3: cyc18c_ksval_shifted = {cyc18c_ksval, 1'b0};
    endcase
end

//add TL
reg     [7:0]   cyc18r_ksval_tl;
always @(posedge emuclk) if(!phi1ncen_n) cyc18r_ksval_tl <= cyc18c_ksval_shifted + {i_TL, 1'b0};

//latch AM bit
reg     [7:0]   cyc18r_am;
always @(posedge emuclk) if(!phi1ncen_n) cyc18r_am <= i_AM;



///////////////////////////////////////////////////////////
//////  Cycle 19: apply AMVAL
////

//apply the amplitude modulation value to the key scale value
wire    [7:0]   cyc19c_ksval_am = cyc18r_ksval_tl[6:0] + (cyc18r_am ? i_AMVAL : 4'd0);

//apply the final key scale value to the base attenuation level
wire    [7:0]   cyc19c_attnlv_scaled = cyc19c_ksval_am[6:0] + cyc18r_attnlv;

//collect the overflow bits
wire            cyc19c_ksval_ovfl = cyc18r_ksval_tl[7] | cyc19c_ksval_am[7] | cyc19c_attnlv_scaled[7];

//saturation
wire    [6:0]   cyc19c_attnlv_saturated = cyc19c_ksval_ovfl ? 7'd127 : cyc19c_attnlv_scaled[6:0];

//register part
reg     [6:0]   cyc19r_final_attnlv;
always @(posedge emuclk) if(!phi1ncen_n) cyc19r_final_attnlv <= i_TEST[0] ? 7'd0 : cyc19c_attnlv_saturated;

assign  o_OP_ATTNLV = cyc19r_final_attnlv;



///////////////////////////////////////////////////////////
//////  STATIC ENVELOPE REGISTERS FOR DEBUGGING
////

reg     [4:0]   debug_cyccntr = 5'd0;
reg     [6:0]   debug_envreg_static[0:17];
reg     [1:0]   debug_envstat_static[0:17];
reg     [1:0]   debug_cyc2r_next_envstat;
always @(posedge emuclk) if(!phi1ncen_n) begin
    if(i_CYCLE_21) debug_cyccntr <= 5'd0;
    else debug_cyccntr <= debug_cyccntr + 5'd1;

    case(debug_cyccntr)
        5'd1 : debug_envreg_static[0]  <= ~o_OP_ATTNLV; //Ch.1 M
        5'd4 : debug_envreg_static[1]  <= ~o_OP_ATTNLV; //Ch.1 C
        5'd2 : debug_envreg_static[2]  <= ~o_OP_ATTNLV; //Ch.2 M
        5'd5 : debug_envreg_static[3]  <= ~o_OP_ATTNLV; //Ch.2 C
        5'd3 : debug_envreg_static[4]  <= ~o_OP_ATTNLV; //Ch.3 M
        5'd6 : debug_envreg_static[5]  <= ~o_OP_ATTNLV; //Ch.3 C
        5'd7 : debug_envreg_static[6]  <= ~o_OP_ATTNLV; //Ch.4 M
        5'd10: debug_envreg_static[7]  <= ~o_OP_ATTNLV; //Ch.4 C
        5'd8 : debug_envreg_static[8]  <= ~o_OP_ATTNLV; //Ch.5 M
        5'd11: debug_envreg_static[9]  <= ~o_OP_ATTNLV; //Ch.5 C
        5'd9 : debug_envreg_static[10] <= ~o_OP_ATTNLV; //Ch.6 M
        5'd12: debug_envreg_static[11] <= ~o_OP_ATTNLV; //Ch.6 C
        5'd13: debug_envreg_static[12] <= ~o_OP_ATTNLV; //Ch.7 M | BD M
        5'd16: debug_envreg_static[13] <= ~o_OP_ATTNLV; //Ch.7 C | BD C
        5'd14: debug_envreg_static[14] <= ~o_OP_ATTNLV; //Ch.8 M | HH
        5'd17: debug_envreg_static[15] <= ~o_OP_ATTNLV; //Ch.8 C | SD
        5'd15: debug_envreg_static[16] <= ~o_OP_ATTNLV; //Ch.9 M | TT
        5'd0 : debug_envreg_static[17] <= ~o_OP_ATTNLV; //Ch.9 C | TC
        default: ;
    endcase

    debug_cyc2r_next_envstat <= cyc2c_next_envstat;
    case(debug_cyccntr)
        5'd2 : debug_envstat_static[0]  <= debug_cyc2r_next_envstat; //Ch.1 M
        5'd5 : debug_envstat_static[1]  <= debug_cyc2r_next_envstat; //Ch.1 C
        5'd3 : debug_envstat_static[2]  <= debug_cyc2r_next_envstat; //Ch.2 M
        5'd6 : debug_envstat_static[3]  <= debug_cyc2r_next_envstat; //Ch.2 C
        5'd4 : debug_envstat_static[4]  <= debug_cyc2r_next_envstat; //Ch.3 M
        5'd7 : debug_envstat_static[5]  <= debug_cyc2r_next_envstat; //Ch.3 C
        5'd8 : debug_envstat_static[6]  <= debug_cyc2r_next_envstat; //Ch.4 M
        5'd11: debug_envstat_static[7]  <= debug_cyc2r_next_envstat; //Ch.4 C
        5'd9 : debug_envstat_static[8]  <= debug_cyc2r_next_envstat; //Ch.5 M
        5'd12: debug_envstat_static[9]  <= debug_cyc2r_next_envstat; //Ch.5 C
        5'd10: debug_envstat_static[10] <= debug_cyc2r_next_envstat; //Ch.6 M
        5'd13: debug_envstat_static[11] <= debug_cyc2r_next_envstat; //Ch.6 C
        5'd14: debug_envstat_static[12] <= debug_cyc2r_next_envstat; //Ch.7 M | BD M
        5'd17: debug_envstat_static[13] <= debug_cyc2r_next_envstat; //Ch.7 C | BD C
        5'd15: debug_envstat_static[14] <= debug_cyc2r_next_envstat; //Ch.8 M | HH
        5'd0 : debug_envstat_static[15] <= debug_cyc2r_next_envstat; //Ch.8 C | SD
        5'd16: debug_envstat_static[16] <= debug_cyc2r_next_envstat; //Ch.9 M | TT
        5'd1 : debug_envstat_static[17] <= debug_cyc2r_next_envstat; //Ch.9 C | TC
        default: ;
    endcase
end


endmodule