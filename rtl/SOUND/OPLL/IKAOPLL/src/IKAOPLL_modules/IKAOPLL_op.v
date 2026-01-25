module IKAOPLL_op (
    //master clock
    input   wire            i_EMUCLK, //emulator master clock

    //master reset
    input   wire            i_RST_n,

    //internal clock
    input   wire            i_phi1_PCEN_n, //positive edge clock enable for emulation
    input   wire            i_phi1_NCEN_n, //negative edge clock enable for emulation

    //timings
    input   wire            i_CYCLE_00, i_CYCLE_21, i_HH_TT_SEL, i_INHIBIT_FDBK,

    //parameter input
    input   wire    [3:0]   i_TEST,
    input   wire            i_DC, i_DM,
    input   wire    [2:0]   i_FB,

    //control input
    input   wire    [9:0]   i_OP_PHASE,
    input   wire    [6:0]   i_OP_ATTNLV,
    input   wire            i_OP_ATTNLV_MAX,

    //output
    output  wire    [8:0]   o_DAC_OPDATA
);


///////////////////////////////////////////////////////////
//////  Clock and reset
////

wire            emuclk = i_EMUCLK;
wire            phi1pcen_n = i_phi1_PCEN_n;
wire            phi1ncen_n = i_phi1_NCEN_n;



///////////////////////////////////////////////////////////
//////  Cycle 18: latch some parameters
////

reg             cyc18r_dc, cyc18r_dm;
reg     [2:0]   cyc18r_fb;
always @(posedge emuclk) if(!phi1ncen_n) begin
    cyc18r_dc <= i_DC;
    cyc18r_dm <= i_DM;
    cyc18r_fb <= i_FB;
end



///////////////////////////////////////////////////////////
//////  Cycle 19: look the logsin table up
////

//combinational part
reg     [9:0]   cyc19c_op_fdbk;
wire    [9:0]   cyc19c_phase_modded = i_OP_PHASE + cyc19c_op_fdbk;
wire    [7:0]   cyc19c_logsin_addr = cyc19c_phase_modded[8] ? ~cyc19c_phase_modded[7:0] : cyc19c_phase_modded[7:0]; //XOR(flip)

//treat as a combinational element
wire    [45:0]  cyc19c_logsin_data;
IKAOPLL_logsinrom u_cyc19c_logsinrom (.i_EMUCLK(emuclk), .i_CEN_n(phi1pcen_n), .i_ADDR(cyc19c_logsin_addr[5:1]), .o_DATA(cyc19c_logsin_data));

//output multiplexer
wire    [45:0]  ls = cyc19c_logsin_data;
reg     [10:0]  cyc19c_logsin_op0, cyc19c_logsin_op1;
always @(*) begin
    case(cyc19c_logsin_addr[7:6])
        /*    base                    D10      D9      D8      D7      D6      D5      D4      D3      D2      D1      D0  */
        2'd0: cyc19c_logsin_op0 = {ls[45], ls[44], ls[42], ls[40], ls[36], ls[32], ls[27], ls[22], ls[17], ls[11],  ls[4]};
        2'd1: cyc19c_logsin_op0 = {  1'b0,   1'b0, ls[43], ls[41], ls[37], ls[33], ls[28], ls[23], ls[18], ls[12],  ls[5]};
        2'd2: cyc19c_logsin_op0 = {  1'b0,   1'b0,   1'b0,   1'b0, ls[38], ls[34], ls[29], ls[24], ls[19], ls[13],  ls[6]};
        2'd3: cyc19c_logsin_op0 = {  1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0, ls[30], ls[25], ls[20], ls[14],  ls[7]};
    endcase

    case(cyc19c_logsin_addr[7:6])
        /*    delta                   D10      D9      D8      D7      D6      D5      D4      D3      D2      D1      D0  */
        2'd0: cyc19c_logsin_op1 = {  1'b0,   1'b0, ls[39], ls[39], ls[35], ls[31], ls[26], ls[21], ls[15],  ls[8],  ls[0]} & {10{~cyc19c_logsin_addr[0]}};
        2'd1: cyc19c_logsin_op1 = {  1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0, ls[16],  ls[9],  ls[1]} & {10{~cyc19c_logsin_addr[0]}};
        2'd2: cyc19c_logsin_op1 = {  1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0, ls[10],  ls[2]} & {10{~cyc19c_logsin_addr[0]}};
        2'd3: cyc19c_logsin_op1 = {  1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0,  ls[3]} & {10{~cyc19c_logsin_addr[0]}};
    endcase 
end

//register part
reg     [11:0]  cyc19r_lswave_raw;
reg             cyc19r_lswave_sign;
reg             cyc19r_dc, cyc19r_dm;
always @(posedge emuclk) if(!phi1ncen_n) begin
    cyc19r_lswave_raw <= cyc19c_logsin_op0 + cyc19c_logsin_op1;
    cyc19r_lswave_sign <= cyc19c_phase_modded[9];
    cyc19r_dc <= cyc18r_dc;
    cyc19r_dm <= cyc18r_dm;
end



///////////////////////////////////////////////////////////
//////  Cycle 20: apply attenuation level and exp func
////

wire    [12:0]  cyc20c_lswave_attenuated = cyc19r_lswave_raw + {i_OP_ATTNLV, 4'd0}; //apply envelope
wire    [11:0]  cyc20c_lswave_saturated = cyc20c_lswave_attenuated[12] ? 11'd0 : ~cyc20c_lswave_attenuated[11:0]; //saturation

//treat as a combinational element
wire    [47:0]  cyc20c_exp_data;
IKAOPLL_exprom u_cyc20c_exprom (.i_EMUCLK(emuclk), .i_CEN_n(phi1pcen_n), .i_ADDR(cyc20c_lswave_saturated[5:1]), .o_DATA(cyc20c_exp_data));

//output multiplexer
wire    [47:0]  e = cyc20c_exp_data;
reg     [9:0]   cyc20c_exp_op0, cyc20c_exp_op1;
always @(*) begin
    case(cyc20c_lswave_saturated[7:6])
        /*              base        D9      D8      D7      D6      D5      D4      D3      D2      D1      D0  */
        2'd0: cyc20c_exp_op0 = {  1'b0,   1'b0,  e[39],  e[35],  e[31],  e[27],  e[23],  e[15],   e[8],   e[0]};
        2'd1: cyc20c_exp_op0 = {  1'b0,  e[43],  e[40],  e[36],  e[32],  e[28],  e[24],  e[16],   e[9],   e[1]};
        2'd2: cyc20c_exp_op0 = { e[46],  e[44],  e[41],  e[37],  e[33],  e[29],  e[25],  e[17],  e[10],   e[2]};
        2'd3: cyc20c_exp_op0 = { e[47],  e[45],  e[42],  e[38],  e[34],  e[30],  e[26],  e[18],  e[11],   e[3]};
    endcase

    case(cyc20c_lswave_saturated[7:6])
        /*             delta        D9      D8      D7      D6      D5      D4      D3      D2      D1      D0  */
        2'd0: cyc20c_exp_op1 = {  1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0,  e[19],  e[12],   e[4]} & {7'b0000000, {3{cyc20c_lswave_saturated[0]}}};
        2'd1: cyc20c_exp_op1 = {  1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0,  e[20],  e[13],   e[5]} & {7'b0000000, {3{cyc20c_lswave_saturated[0]}}};
        2'd2: cyc20c_exp_op1 = {  1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0,  e[21],   1'b0,   e[6]} & {7'b0000000, {3{cyc20c_lswave_saturated[0]}}};
        2'd3: cyc20c_exp_op1 = {  1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0,   1'b0,  e[22],  e[14],   e[7]} & {7'b0000000, {3{cyc20c_lswave_saturated[0]}}};
    endcase 
end

//register part
reg     [9:0]   cyc20r_fpwave_mantissa;
reg     [3:0]   cyc20r_fpwave_exponent;
reg             cyc20r_fpwave_sign;
reg             cyc20r_dc, cyc20r_dm, cyc20r_attnlv_max;
always @(posedge emuclk) if(!phi1ncen_n) begin
    cyc20r_fpwave_mantissa <= cyc20c_exp_op0 + cyc20c_exp_op1; //discard carry
    cyc20r_fpwave_exponent <= cyc20c_lswave_saturated[11:8];
    cyc20r_fpwave_sign <= cyc19r_lswave_sign;
    
    cyc20r_dc <= cyc19r_dc;
    cyc20r_dm <= cyc19r_dm;
    cyc20r_attnlv_max <= i_OP_ATTNLV_MAX;
end



///////////////////////////////////////////////////////////
//////  Cycle 21: fp to int, select m/c output
////

//force the OP shifter output to zero
wire            cyc21c_fpwave_shifter_mute =  cyc20r_attnlv_max | 
                                             ( i_INHIBIT_FDBK & cyc20r_dm & cyc20r_fpwave_sign) | 
                                             (~i_INHIBIT_FDBK & cyc20r_dc & cyc20r_fpwave_sign);

//flip the int'd op wave
wire            cyc21c_intwave_flip = cyc20r_fpwave_sign & ~cyc20r_attnlv_max;

//shifter
reg     [10:0]  cyc21c_fpwave_shifter0, cyc21c_fpwave_shifter1;
always @(*) begin
    case(cyc20r_fpwave_exponent[1:0])
        2'd0: cyc21c_fpwave_shifter0 = {4'b0001, cyc20r_fpwave_mantissa[9:3]};
        2'd1: cyc21c_fpwave_shifter0 = {3'b001, cyc20r_fpwave_mantissa[9:2]};
        2'd2: cyc21c_fpwave_shifter0 = {2'b01, cyc20r_fpwave_mantissa[9:1]};
        2'd3: cyc21c_fpwave_shifter0 = {1'b1, cyc20r_fpwave_mantissa[9:0]};
    endcase

    if(cyc21c_fpwave_shifter_mute) cyc21c_fpwave_shifter1 = 11'd0;
    else begin
        case(cyc20r_fpwave_exponent[3:2])
            2'd0: cyc21c_fpwave_shifter1 = 11'd0;
            2'd1: cyc21c_fpwave_shifter1 = {8'b0, cyc21c_fpwave_shifter0[10:8]};
            2'd2: cyc21c_fpwave_shifter1 = {4'b0, cyc21c_fpwave_shifter0[10:4]};
            2'd3: cyc21c_fpwave_shifter1 = cyc21c_fpwave_shifter0;
        endcase
    end
end

//final integer wave
wire    [11:0]  cyc21c_intwave_flipped = cyc21c_intwave_flip ? {1'b1, ~cyc21c_fpwave_shifter1} : {1'b0, cyc21c_fpwave_shifter1};
assign  o_DAC_OPDATA = cyc21c_intwave_flipped[11:3];

//register output wires
wire    [11:0]  cyc21c_mod_z_tap6, cyc21c_mod_zz_tap6;
wire    [11:0]  cyc21c_mod_z_tap9, cyc21c_mod_zz_tap9;
wire    [12:0]  cyc21c_modsum = {cyc21c_mod_z_tap6[11], cyc21c_mod_z_tap6} + {cyc21c_mod_zz_tap6[11], cyc21c_mod_zz_tap6};

//register part, modulator_z, zz sr
wire    [11:0]  op_z_reg_d = i_RST_n ? (i_INHIBIT_FDBK ? cyc21c_intwave_flipped : cyc21c_mod_z_tap9) : 12'd0;
IKAOPLL_sr #(.WIDTH(12), .LENGTH(9), .TAP0(6)) u_op_z_reg
(.i_EMUCLK(i_EMUCLK), .i_CEN_n(phi1ncen_n), .i_D(op_z_reg_d), .o_Q_TAP0(cyc21c_mod_z_tap6), .o_Q_LAST(cyc21c_mod_z_tap9),
 .o_Q_TAP1(), .o_Q_TAP2());

wire    [11:0]  op_zz_reg_d = i_RST_n ? (i_INHIBIT_FDBK ? cyc21c_mod_z_tap9 : cyc21c_mod_zz_tap9) : 12'd0;
IKAOPLL_sr #(.WIDTH(12), .LENGTH(9), .TAP0(6)) u_op_zz_reg
(.i_EMUCLK(i_EMUCLK), .i_CEN_n(phi1ncen_n), .i_D(op_zz_reg_d), .o_Q_TAP0(cyc21c_mod_zz_tap6), .o_Q_LAST(cyc21c_mod_zz_tap9),
 .o_Q_TAP1(), .o_Q_TAP2());

reg     [8:0]   cyc21r_intwave;
reg     [11:0]  cyc21r_modsum;
reg             cyc21r_inhibit_fdbk;
always @(posedge emuclk) if(!phi1ncen_n) begin
    cyc21r_intwave <= cyc21c_intwave_flipped[8:0]; //discard upper 3 bits
    cyc21r_modsum <= cyc21c_modsum[12:1]; //discard lsb

    cyc21r_inhibit_fdbk <= i_INHIBIT_FDBK;
end



///////////////////////////////////////////////////////////
//////  Cycle 19C, make feedback
////

always @(*) begin
    case({i_HH_TT_SEL, cyc21r_inhibit_fdbk})
        2'b10: begin
            case(cyc18r_fb)
                3'd1: cyc19c_op_fdbk = {{4{cyc21r_modsum[11]}}, cyc21r_modsum[11:6]}; 
                3'd2: cyc19c_op_fdbk = {{3{cyc21r_modsum[11]}}, cyc21r_modsum[11:5]}; 
                3'd3: cyc19c_op_fdbk = {{2{cyc21r_modsum[11]}}, cyc21r_modsum[11:4]}; 
                3'd4: cyc19c_op_fdbk = {{1{cyc21r_modsum[11]}}, cyc21r_modsum[11:3]}; 
                3'd5: cyc19c_op_fdbk = cyc21r_modsum[11:2];
                3'd6: cyc19c_op_fdbk = cyc21r_modsum[10:1];
                3'd7: cyc19c_op_fdbk = cyc21r_modsum[9:0];
                3'd0: cyc19c_op_fdbk = 10'd0;
            endcase
        end
        2'b01: cyc19c_op_fdbk = {cyc21r_intwave, 1'b0};
        default: cyc19c_op_fdbk = 10'd0;
    endcase
end



///////////////////////////////////////////////////////////
//////  STATIC OPWAVE REGISTERS FOR DEBUGGING
////

reg     [4:0]   debug_cyccntr = 5'd0;
reg     [11:0]  debug_opwavereg_static[0:17];
always @(posedge emuclk) if(!phi1ncen_n) begin
    if(i_CYCLE_21) debug_cyccntr <= 5'd0;
    else debug_cyccntr <= debug_cyccntr + 5'd1;

    case(debug_cyccntr)
        5'd2 : debug_opwavereg_static[0]  <= cyc21c_intwave_flipped; //Ch.1 M
        5'd5 : debug_opwavereg_static[1]  <= cyc21c_intwave_flipped; //Ch.1 C
        5'd3 : debug_opwavereg_static[2]  <= cyc21c_intwave_flipped; //Ch.2 M
        5'd6 : debug_opwavereg_static[3]  <= cyc21c_intwave_flipped; //Ch.2 C
        5'd4 : debug_opwavereg_static[4]  <= cyc21c_intwave_flipped; //Ch.3 M
        5'd7 : debug_opwavereg_static[5]  <= cyc21c_intwave_flipped; //Ch.3 C
        5'd8 : debug_opwavereg_static[6]  <= cyc21c_intwave_flipped; //Ch.4 M
        5'd11: debug_opwavereg_static[7]  <= cyc21c_intwave_flipped; //Ch.4 C
        5'd9 : debug_opwavereg_static[8]  <= cyc21c_intwave_flipped; //Ch.5 M
        5'd12: debug_opwavereg_static[9]  <= cyc21c_intwave_flipped; //Ch.5 C
        5'd10: debug_opwavereg_static[10] <= cyc21c_intwave_flipped; //Ch.6 M
        5'd13: debug_opwavereg_static[11] <= cyc21c_intwave_flipped; //Ch.6 C
        5'd14: debug_opwavereg_static[12] <= cyc21c_intwave_flipped; //Ch.7 M | BD M
        5'd17: debug_opwavereg_static[13] <= cyc21c_intwave_flipped; //Ch.7 C | BD C
        5'd15: debug_opwavereg_static[14] <= cyc21c_intwave_flipped; //Ch.8 M | HH
        5'd0 : debug_opwavereg_static[15] <= cyc21c_intwave_flipped; //Ch.8 C | SD
        5'd16: debug_opwavereg_static[16] <= cyc21c_intwave_flipped; //Ch.9 M | TT
        5'd1 : debug_opwavereg_static[17] <= cyc21c_intwave_flipped; //Ch.9 C | TC
        default: ;
    endcase
end


endmodule


module IKAOPLL_logsinrom (
    input   wire            i_EMUCLK, //emulator master clock
    input   wire            i_CEN_n, //positive edge clock enable for emulation

    input   wire    [4:0]   i_ADDR,
    output  reg     [45:0]  o_DATA
);

always @(posedge i_EMUCLK) if(!i_CEN_n) begin
    case(i_ADDR)
        5'd0 : o_DATA <= 46'b11100111110100011101111_00110011001110101111010;
        5'd1 : o_DATA <= 46'b10110101101100111101110_11000011100110000011010;
        5'd2 : o_DATA <= 46'b10100101111101011000100_01011110001010100001010;
        5'd3 : o_DATA <= 46'b10100001010111111111001_00101011100010010010011;
        5'd4 : o_DATA <= 46'b10100001000110110110010_11110010001110010101001;
        5'd5 : o_DATA <= 46'b01110101010110110010011_00100010000110100110010;
        5'd6 : o_DATA <= 46'b01110101000110010011000_11010011100010000101001;
        5'd7 : o_DATA <= 46'b01110001010101010101001_01000110000010010010001;
        5'd8 : o_DATA <= 46'b01110001000001001011111_10111011101010010111011;
        5'd9 : o_DATA <= 46'b01110001000000001011110_00101010101010101111001;
        5'd10: o_DATA <= 46'b01001101110011001101101_10111110001010111110000;
        5'd11: o_DATA <= 46'b01001101110010001100101_11100101010001100010111;
        5'd12: o_DATA <= 46'b01001101100011000100110_11010111110110100011000;
        5'd13: o_DATA <= 46'b01001101100010000010111_01000001010111011111011;
        5'd14: o_DATA <= 46'b01001001110011000010110_11000001001011000011011;
        5'd15: o_DATA <= 46'b01001001110001000100001_01110001101001011111110;
        5'd16: o_DATA <= 46'b01001001110000000100000_11101000110101110010111;
        5'd17: o_DATA <= 46'b01001000100101001010011_01111110110100101100100;
        5'd18: o_DATA <= 46'b01001000100101001000010_01111000001111110100010;
        5'd19: o_DATA <= 46'b01001000100100001000010_11100100000111001111011;
        5'd20: o_DATA <= 46'b00011100010111001110001_11110100011001001110111;
        5'd21: o_DATA <= 46'b00011100010111001100000_11011100100001010100111;
        5'd22: o_DATA <= 46'b00011100010110001010001_11001100101011001101010;
        5'd23: o_DATA <= 46'b00011100010110000000011_10010101110001101110111;
        5'd24: o_DATA <= 46'b00011100000111000010010_10011101000101111001111;
        5'd25: o_DATA <= 46'b00011100000101000110011_00001001011001110100101;
        5'd26: o_DATA <= 46'b00011100000101000100011_00000001000101110100111;
        5'd27: o_DATA <= 46'b00011100000100000110000_00011101010001110010110;
        5'd28: o_DATA <= 46'b00011100000100000000001_10011001001001100100111;
        5'd29: o_DATA <= 46'b00011000010101000010001_10000101011001100000110;
        5'd30: o_DATA <= 46'b00011000010101000010000_00001001001001100010100;
        5'd31: o_DATA <= 46'b00011000010001001000010_00010101010101000100101;
    endcase
end

endmodule


module IKAOPLL_exprom (
    input   wire            i_EMUCLK, //emulator master clock
    input   wire            i_CEN_n, //positive edge clock enable for emulation

    input   wire    [4:0]   i_ADDR,
    output  reg     [47:0]  o_DATA
);

always @(posedge i_EMUCLK) if(!i_CEN_n) begin
    case(i_ADDR)
        5'd0 : o_DATA <= 48'b1001011100010110010001100_11000000011101010110000;
        5'd1 : o_DATA <= 48'b1001011101010010001000010_11101001001000100000000;
        5'd2 : o_DATA <= 48'b1001011101010010001001111_11001010011001110111011;
        5'd3 : o_DATA <= 48'b1001011101110000010110000_11001010011101010110001;
        5'd4 : o_DATA <= 48'b1001011101110100000110110_11100011001000110010000;
        5'd5 : o_DATA <= 48'b1001011101110101001011001_11100001001001010011010;
        5'd6 : o_DATA <= 48'b1001011101110101111000110_11000000011101110111000;
        5'd7 : o_DATA <= 48'b1001011101110111110101001_11001000011000010101010;
        5'd8 : o_DATA <= 48'b1011001100110011100100111_11001001011100010110001;
        5'd9 : o_DATA <= 48'b1011001100110011111110010_11000010011001111110011;
        5'd10: o_DATA <= 48'b1011101000100010111011101_11000010011101010110101;
        5'd11: o_DATA <= 48'b1110100000000100100010011_11101011001000110010101;
        5'd12: o_DATA <= 48'b1110100000001100000101100_11001011011100011110101;
        5'd13: o_DATA <= 48'b1110100000001100011101011_11000000011011110110011;
        5'd14: o_DATA <= 48'b1110100001001001001010100_11000000011111010110001;
        5'd15: o_DATA <= 48'b1110100001001011000011010_11001001011010110110111;
        5'd16: o_DATA <= 48'b1110100001001011010110101_11101001001110011010101;
        5'd17: o_DATA <= 48'b1110100001001111101100000_11100110001001110010011;
        5'd18: o_DATA <= 48'b1110100001001111101101111_11100110101101001010001;
        5'd19: o_DATA <= 48'b1110100001111100110000001_11001111011001110111101;
        5'd20: o_DATA <= 48'b1110100001111100110011110_11101111001110010011011;
        5'd21: o_DATA <= 48'b1110110000111000101111001_11100110001110110010101;
        5'd22: o_DATA <= 48'b1110110010110000011100110_11101110001010111010100;
        5'd23: o_DATA <= 48'b1110110010110011010001101_11101000001101011011010;
        5'd24: o_DATA <= 48'b1110110010110111001001011_11100001001001111011110;
        5'd25: o_DATA <= 48'b1110110010110111011110100_11111001000011011000000;
        5'd26: o_DATA <= 48'b1110111010010101010111011_11101000001111111011101;
        5'd27: o_DATA <= 48'b1110111111000000100001100_11100100101000001011011;
        5'd28: o_DATA <= 48'b1110111111000000111000011_11101100101000001010110;
        5'd29: o_DATA <= 48'b1110111111000000111101101_11101101001110111011010;
        5'd30: o_DATA <= 48'b1110111111000110100111110_11000001011100010110011;
        5'd31: o_DATA <= 48'b1110111111000111111010001_11101000001000110011101;
    endcase
end

endmodule