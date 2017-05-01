module HEXdisplay (clk, rst, data, D3, D2, D1);
	input clk, rst;
	input [7:0] data;
	output [6:0] D3, D2, D1;
	
	wire [3:0] digit0, digit1, digit2;
	
	assign digit0 = data % 10;
	assign digit1 = data / 10 % 10;
	assign digit2 = data / 100 % 10;
	
	
	HEXdisplay_sub d1(clk, rst, digit0, D1);
	HEXdisplay_sub d2(clk, rst, digit1, D2);
	HEXdisplay_sub d3(clk, rst, digit2, D3);
	
endmodule

module HEXdisplay_sub (clk, rst, digit, display);
	input clk, rst;
	input [3:0] digit;
	output reg [6:0] display;
	
	parameter zero = 4'b0000, one = 4'b0001, two = 4'b0010, three = 4'b0011, 
					four = 4'b0100, five = 4'b0101, six = 4'b0110, seven = 4'b0111,
					eight = 4'b1000, nine = 4'b1001;
	
	parameter hex_UNDECIDED = 7'b1111111, hex_ZERO = 7'b1000000, hex_ONE = 7'b1111001,
				hex_TWO = 7'b0100100, hex_THREE= 7'b0110000,
				hex_FOUR = 7'b0011001, hex_FIVE = 7'b0010010, hex_SIX  = 7'b0000010,
				hex_SEVEN= 7'b1111000, hex_EIGHT= 7'b0000000, hex_NINE = 7'b0010000;

	always @(posedge clk or posedge rst) begin
		if(rst) begin
			display = hex_UNDECIDED;
		end else begin
			case (digit)
				zero		: display = hex_ZERO;
				one		: display = hex_ONE;
				two    	: display = hex_TWO;
				three		: display = hex_THREE;
				four		: display = hex_FOUR;
				five		: display = hex_FIVE;
				six 	   : display = hex_SIX;
				seven		: display = hex_SEVEN;
				eight		: display = hex_EIGHT;
				nine		: display = hex_NINE;
				default	: display = hex_UNDECIDED;
			endcase
		end
	end
endmodule
