module IKAOPLL_srlatch (
    input   wire            i_S,
    input   wire            i_R,
    output  reg             o_Q
);

always @(*) begin
    case({i_S, i_R})
        2'b00: o_Q = o_Q;
        2'b01: o_Q = 1'b0;
        2'b10: o_Q = 1'b1;
        2'b11: o_Q = 1'b0; //invalid
    endcase
end

endmodule

module IKAOPLL_dlatch #(parameter WIDTH = 8) (
    input   wire                    i_EN,
    input   wire    [WIDTH-1:0]     i_D,
    output  reg     [WIDTH-1:0]     o_Q
);

always @(*) begin
    if(i_EN) o_Q = i_D;
    else o_Q = o_Q;
end

endmodule

module IKAOPLL_sr #(parameter WIDTH = 1, parameter LENGTH = 9, parameter TAP0 = LENGTH, parameter TAP1 = LENGTH, parameter TAP2 = LENGTH) (
    input   wire                    i_EMUCLK,
    input   wire                    i_CEN_n,

    input   wire    [WIDTH-1:0]     i_D,
    output  wire    [WIDTH-1:0]     o_Q_TAP0,
    output  wire    [WIDTH-1:0]     o_Q_TAP1,
    output  wire    [WIDTH-1:0]     o_Q_TAP2,
    output  wire    [WIDTH-1:0]     o_Q_LAST
);

reg     [WIDTH-1:0]     sr[0:LENGTH-1];

//first stage
always @(posedge i_EMUCLK) if(!i_CEN_n) begin
    sr[0] <= i_D;
end

//the other stages
genvar stage;
generate
for(stage = 0; stage < LENGTH-1; stage = stage + 1) begin : primitive_sr
always @(posedge i_EMUCLK) if(!i_CEN_n) begin
    sr[stage + 1] <= sr[stage];
end
end
endgenerate

assign  o_Q_LAST = sr[LENGTH-1];
assign  o_Q_TAP0 = (TAP0 == 0) ? i_D : sr[TAP0-1];
assign  o_Q_TAP1 = (TAP1 == 0) ? i_D : sr[TAP1-1];
assign  o_Q_TAP2 = (TAP2 == 0) ? i_D : sr[TAP2-1];

endmodule