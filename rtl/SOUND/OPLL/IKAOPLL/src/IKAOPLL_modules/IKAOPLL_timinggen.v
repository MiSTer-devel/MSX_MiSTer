module IKAOPLL_timinggen #(parameter FULLY_SYNCHRONOUS = 1, parameter FAST_RESET = 0) (
    //chip clock
    input   wire            i_EMUCLK, //emulator master clock
    input   wire            i_phiM_PCEN_n,

    //chip reset
    input   wire            i_IC_n,
    output  wire            o_RST_n,

    //phiM/2
    output  wire            o_phi1_PCEN_n, //internal positive edge clock enable
    output  wire            o_phi1_NCEN_n, //internal negative edge clock enable
    output  wire            o_DAC_EN,

    //rhythm enable
    input   wire            i_RHYTHM_EN,

    //outputs
    output  wire            o_CYCLE_00, o_CYCLE_12, o_CYCLE_17, o_CYCLE_20, o_CYCLE_21,
    output  wire            o_CYCLE_D3_ZZ, o_CYCLE_D4, o_CYCLE_D4_ZZ,
    output  wire            o_MnC_SEL, o_INHIBIT_FDBK,
    output  reg             o_HH_TT_SEL,
    output  wire            o_MO_CTRL, o_RO_CTRL
);


///////////////////////////////////////////////////////////
//////  Clock and reset
////

wire            phi1ncen_n = o_phi1_NCEN_n;


///////////////////////////////////////////////////////////
//////  Reset generator
////

wire            ic_n_zzzz;
reg             ic_n_negedge = 1'b1; //IC_n negedge detector
wire            phi1_init = ic_n_negedge;

generate
if(FULLY_SYNCHRONOUS == 0) begin : FULLY_SYNCHRONOUS_0_reset_syncchain
    //2 stage SR for synchronization
    reg     [2:0]   ic_n_internal = 3'b111;
    always @(posedge i_EMUCLK) if(!i_phiM_PCEN_n) begin 
        ic_n_internal[0] <= i_IC_n; 
        ic_n_internal[2:1] <= ic_n_internal[1:0]; //shift
    end

    //ICn rising edge detector for phi1 phase initialization
    always @(posedge i_EMUCLK) if(!i_phiM_PCEN_n) begin
        ic_n_negedge <= ic_n_internal[0] & ~ic_n_internal[2];
    end

    assign  ic_n_zzzz = ic_n_internal[1];
    assign  o_RST_n = ic_n_internal[2];
end
else begin : FULLY_SYNCHRONOUS_1_reset_syncchain
    //add two stage SR

    //4 stage SR for synchronization
    reg     [4:0]   ic_n_internal = 5'b11111;
    always @(posedge i_EMUCLK) if(!i_phiM_PCEN_n) begin 
        ic_n_internal[0] <= i_IC_n; 
        ic_n_internal[4:1] <= ic_n_internal[3:0]; //shift
    end

    //ICn rising edge detector for phi1 phase initialization
    always @(posedge i_EMUCLK) if(!i_phiM_PCEN_n) begin
        ic_n_negedge <= ic_n_internal[2] & ~ic_n_internal[4];
    end

    assign  ic_n_zzzz = ic_n_internal[3];
    assign  o_RST_n = ic_n_internal[4];
end
endgenerate



///////////////////////////////////////////////////////////
//////  phi1 and clock enables generator
////

/*
    CLOCKING INFORMATION(ORIGINAL CHIP)
    
    phiM        |¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯|
    ICn         ¯¯¯¯¯¯¯¯¯¯¯¯|___________________________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
    IC          ____________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|________________________________________________________________
    ICn_Z       ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_______________________________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
    ICn_ZZ      ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_______________________________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
    IC neg det  ________________________________________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|________________________________________
    phi1        ¯¯¯¯¯¯¯|_______________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_______________________________________________________|¯¯¯¯¯¯¯¯
*/


//actual phi1 output is phi1p(positive), and the inverted phi1 is phi1n(negative)
reg     [3:0]   phisr;
wire            phi1p = phisr[1];
wire            phi1n = phisr[3];
assign          o_DAC_EN = phisr[0];

generate
if(FAST_RESET == 0) begin : FAST_RESET_0_phi1gen
    always @(posedge i_EMUCLK) if(!i_phiM_PCEN_n) begin
        if(phi1_init)   phisr <= 4'b1111; //reset
        else      begin phisr[3:1] <= phisr[2:0]; phisr[0] <= ~&{phisr} & phisr[3]; end //shift
    end
end
else begin : FAST_RESET_1_phi1gen
    always @(posedge i_EMUCLK) if(!(i_phiM_PCEN_n & ic_n_zzzz)) begin
        if(phi1_init)   phisr <= 4'b1111; //reset
        else      begin phisr[3:1] <= phisr[2:0]; phisr[0] <= ~&{phisr} & phisr[3]; end //shift
    end
end
endgenerate

generate
if(FAST_RESET == 0) begin : FAST_RESET_0_cenout
    //phi1 cen(internal)
    assign  o_phi1_PCEN_n = phi1p | i_phiM_PCEN_n; //ORed signal
    assign  o_phi1_NCEN_n = phi1n | i_phiM_PCEN_n;
end
else begin : FAST_RESET_1_cenout
    //phi1 cen(internal)
    assign  o_phi1_PCEN_n = (phi1p | i_phiM_PCEN_n | ic_n_negedge) & ic_n_zzzz; //ORed signal
    assign  o_phi1_NCEN_n = (phi1n | i_phiM_PCEN_n | ic_n_negedge) & ic_n_zzzz;
end
endgenerate



///////////////////////////////////////////////////////////
//////  Timing Generator
////

//master cycle counter
/*
     0  1  2  3  4  5  <-subcycles
     8  9 10 11 12 13
    16 17 18 19 20 21
*/

reg     [2:0]   mcyccntr_lo = 3'd0;
reg     [1:0]   mcyccntr_hi = 2'd0;
wire    [4:0]   mc = {mcyccntr_hi, mcyccntr_lo};
always @(posedge i_EMUCLK) if(!phi1ncen_n) begin
    if(phi1_init) begin
        mcyccntr_lo <= 3'd0;
        mcyccntr_hi <= 2'd0;
    end
    else begin
        mcyccntr_lo <= (mcyccntr_lo == 3'd5) ? 3'd0 : mcyccntr_lo + 3'd1;
        if(mcyccntr_lo == 3'd5) mcyccntr_hi <= (mcyccntr_hi == 2'd2) ? 2'd0 : mcyccntr_hi + 2'd1;
    end
end

//simple cycles
assign  o_CYCLE_21 = mc == 5'd21;
assign  o_CYCLE_20 = mc == 5'd20;
assign  o_CYCLE_17 = mc == 5'd17;
assign  o_CYCLE_12 = mc == 5'd12;
assign  o_CYCLE_00 = mc == 5'd0;

//delayed counter bits
reg     [1:0]   mc_d4_dly, mc_d3_dly;
assign  o_CYCLE_D4 = mc[4];
assign  o_CYCLE_D4_ZZ = mc_d4_dly[1];
assign  o_CYCLE_D3_ZZ = mc_d3_dly[1];
always @(posedge i_EMUCLK) if(!phi1ncen_n) begin
    mc_d4_dly[1] <= mc_d4_dly[0];
    mc_d4_dly[0] <= mc[4];
    mc_d3_dly[1] <= mc_d3_dly[0];
    mc_d3_dly[0] <= mc[3];
end

//composite timings
assign  o_MnC_SEL       =  &{(~mc[2] | mc[0]), (mc[2] | ~mc[1])}; //de morgan
assign  o_INHIBIT_FDBK  = ~|{o_MnC_SEL, ((mc == 5'd20) & i_RHYTHM_EN), ((mc == 5'd19) & i_RHYTHM_EN)};
assign  o_MO_CTRL       = ~|{(i_RHYTHM_EN & o_CYCLE_D4_ZZ), ~o_MnC_SEL};
assign  o_RO_CTRL       =  &{(~o_MnC_SEL | o_CYCLE_D4_ZZ), ~(mc == 5'd18), ~(mc == 5'd12), i_RHYTHM_EN}; //de morgan
always @(posedge i_EMUCLK) if(!phi1ncen_n) o_HH_TT_SEL <= &{o_MnC_SEL, ~((mc[4:1] == 4'b1000) & i_RHYTHM_EN)};

endmodule