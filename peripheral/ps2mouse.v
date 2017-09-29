
module ps2mouse
(
	input            clk,
	input            reset,

	input            strobe,
	output reg [5:0] data,

	input            ps2_mouse_clk,
	input            ps2_mouse_data
);

reg  [32:0] q;
wire [11:0] mdx = {{4{q[5]}},q[19:12]};
wire [11:0] mdy = {{4{q[6]}},q[30:23]};

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

	if(~&timer) timer <= timer + 1'b1;
	old_strobe <= strobe;

	if(reset) begin
		dx     <= 0;
		dy     <= 0;
		count  <= 0;
		data   <= 'b110000;
		state  <= 0;
	end else begin
		old_clk <= ps2_mouse_clk;
		if(old_clk & ~ps2_mouse_clk) begin
			q[count]  <= ps2_mouse_data;
		end else if(~old_clk & ps2_mouse_clk) begin
			count <= count + 1'b1;
			if(count == 32) begin
				count <= 0;
				if((~q[0] & q[10] & ~q[11] & q[21] & ~q[22] & q[32])
					& (q[9] == ~^q[8:1]) & (q[20] == ~^q[19:12]) & (q[31] == ~^q[30:23]))
				begin
					data[5:4] <= ~q[2:1];
					dx <= dx - mdx;
					dy <= dy + mdy;
				end
			end
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
