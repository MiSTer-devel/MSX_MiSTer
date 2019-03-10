
module ps2mouse
(
	input            clk,
	input            reset,

	input            strobe,
	output reg [5:0] data,

	input     [24:0] ps2_mouse
);

wire [11:0] mdx = {{4{ps2_mouse[4]}},ps2_mouse[15:8]};
wire [11:0] mdy = {{4{ps2_mouse[5]}},ps2_mouse[23:16]};

always @(posedge clk) begin
	reg  [5:0] count;
	reg        old_clk;
	reg        old_strobe;
	reg  [2:0] state = 0;
	reg [14:0] timer = 0; //MSX mouse timer
	reg  [7:0] mx;
	reg  [7:0] my;
	reg  [2:0] button;
	reg [11:0] dx;
	reg [11:0] dy;
	reg        old_stb;

	if(~&timer) timer <= timer + 1'b1;
	old_strobe <= strobe;
	
	old_stb <= ps2_mouse[24];

	if(reset) begin
		dx     <= 0;
		dy     <= 0;
		data   <= 'b110000;
		state  <= 0;
	end
	else begin
		if(old_stb ^ ps2_mouse[24]) begin
			data[5:4] <= ~ps2_mouse[1:0];
			dx <= dx - mdx;
			dy <= dy + mdy;
		end

		case(state)
			0: if(~old_strobe && strobe && &timer) begin
					state <= state + 1'd1;
					mx    <= dx[8:1];
					my    <= dy[8:1];
					dx    <= 0;
					dy    <= 0;
					timer <= 0;

					data[3:0] <= dx[7:4];
				end

			1: if(old_strobe && ~strobe) begin
					state <= state + 1'd1;
					data[3:0] <= mx[3:0];
				end

			2: if(~old_strobe && strobe) begin
					state <= state + 1'd1;
					data[3:0] <= my[7:4];
				end

			3: if(old_strobe && ~strobe) begin
					state <= state + 1'd1;
					data[3:0] <= my[3:0];
				end

			4: if(~old_strobe && strobe) begin
					state <= 0;
					data[3:0] <= 0;
				end
		endcase
	end
end

endmodule
