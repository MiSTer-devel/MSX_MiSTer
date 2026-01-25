module IKAOPLL_lfo (
    //master clock
    input   wire            i_EMUCLK, //emulator master clock

    //internal clock
    input   wire            i_phi1_PCEN_n, //positive edge clock enable for emulation
    input   wire            i_phi1_NCEN_n, //negative edge clock enable for emulation

    input   wire            i_RST_n,

    //timings
    input   wire            i_CYCLE_00, i_CYCLE_21, i_CYCLE_D4, i_CYCLE_D3_ZZ,

    //test register
    input   wire    [3:0]   i_TEST,

    output  wire    [2:0]   o_PMVAL,
    output  reg     [3:0]   o_AMVAL
);


///////////////////////////////////////////////////////////
//////  Clock and reset
////

wire            emuclk = i_EMUCLK;
wire            phi1pcen_n = i_phi1_PCEN_n;
wire            phi1ncen_n = i_phi1_NCEN_n;



///////////////////////////////////////////////////////////
//////  Prescaler
////

reg     [5:0]   prescaler;
wire            prescaler_co = (prescaler == 6'd63) & i_CYCLE_21;
always @(posedge emuclk) if(!phi1ncen_n) begin
    if(i_TEST[1] || ~i_RST_n) prescaler <= 6'd0;
    else begin
        if(i_CYCLE_21) prescaler <= prescaler + 6'd1;
    end
end



///////////////////////////////////////////////////////////
//////  Phase modulation value generator(vibrato)
////

reg     [3:0]   pm_prescaler;
wire            pm_prescaler_co = (pm_prescaler == 4'd15) & prescaler_co;
always @(posedge emuclk) if(!phi1ncen_n) begin
    if(i_TEST[1] || ~i_RST_n) pm_prescaler <= 4'd0;
    else begin
        if(prescaler_co) pm_prescaler <= pm_prescaler + 4'd1;
    end
end

reg     [2:0]   pm_cntr;
always @(posedge emuclk) if(!phi1ncen_n) begin
    if(i_TEST[1] || ~i_RST_n) pm_cntr <= 3'd0;
    else begin
        if(pm_prescaler_co || (i_CYCLE_21 && i_TEST[3])) pm_cntr <= pm_cntr + 3'd1;
    end
end

assign  o_PMVAL = pm_cntr;



///////////////////////////////////////////////////////////
//////  Amplitude modulation value generator(tremolo)
////

//D-latch, latches data @ CYCLE_21, should sample data at positive edge
reg             amval_cntup;
always @(posedge emuclk) if(!phi1pcen_n) if(i_CYCLE_21) amval_cntup <= prescaler_co;

//addend generator
reg             cycle_d3_zzz;
always @(posedge emuclk) if(!phi1ncen_n) cycle_d3_zzz <= i_CYCLE_D3_ZZ;

wire            amval_addend_en0 = amval_cntup | i_TEST[3]; //de morgan
wire            amval_addend_en1 = ~(i_CYCLE_D4 | cycle_d3_zzz);

wire            amval_addend_src0; //tff output
wire            amval_addend_src1 = i_CYCLE_00;

reg             amval_addend_co_z; //previous C output

wire            amval_addend_cin = amval_addend_co_z & amval_addend_en1;
wire            amval_addend_a; //feedback
wire            amval_addend_b = ((amval_addend_src0 & amval_addend_en0) | (amval_addend_src1 & amval_addend_en0)) & amval_addend_en1;
wire    [1:0]   sum = amval_addend_a + amval_addend_b + amval_addend_cin;

always @(posedge emuclk) if(!phi1ncen_n) amval_addend_co_z <= sum[1] & i_RST_n;

//TFF section
wire            amval_sr_000_000_0XX;
wire            amval_sr_1XX_1X1_1XX;

reg             amval_tff;
assign  amval_addend_src0 = amval_tff;
always @(posedge emuclk) if(!phi1ncen_n) begin
    if(i_TEST[1] || ~i_RST_n) amval_tff <= 1'b0;
    else begin
        if((amval_sr_000_000_0XX || amval_sr_1XX_1X1_1XX) && amval_cntup) amval_tff <= ~amval_tff;
    end    
end

//SR section
reg     [8:0]   amval_sr;
wire            amval_sr_d = ~(~i_RST_n | i_TEST[1] | ~sum[0]);
assign  amval_addend_a = amval_sr[0];
always @(posedge emuclk) if(!phi1ncen_n) begin
    amval_sr[8] <= amval_sr_d;
    amval_sr[7:0] <= amval_sr[8:1];
end

assign  amval_sr_000_000_0XX = ~|{amval_sr[6:0], ~amval_tff, ~i_CYCLE_00};
assign  amval_sr_1XX_1X1_1XX = ~|{~amval_sr[6:5], ~amval_sr[3], ~amval_sr[0], amval_tff, ~i_CYCLE_00};

//AM value D-latch, latches data @ CYCLE_00, should sample data at positive edge
always @(posedge emuclk) if(!phi1pcen_n) if(i_CYCLE_00) o_AMVAL <= amval_sr[6:3];

endmodule