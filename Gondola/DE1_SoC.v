module DE1_SoC(CLOCK_50, LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, SW, KEY, GPIO_0);
	input CLOCK_50;
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output [9:0] LEDR;
	input [9:0] SW;
	input [3:0] KEY;
	inout [35:0] GPIO_0; // GPIO_0[0]  is  the leftmost  connection  (AC18),
								// and  GPIO_0[35]  is  the rightmost connection (AJ21). 
	
	wire clk, rst;
	wire[31:0] divided_clocks;
	clock_divider clk_div(CLOCK_50, divided_clocks);
	assign clk = divided_clocks[17]; // Slower than needed
	assign rst = ~KEY[0];
	
	wire active, transfer_permit, flush, go_to_standby, start_scanning;
	
	// Transfer station output
	wire signal_50, signal_80, signal_90, signal_100, receiving_data;
	wire [7:0] current_byte_value; // The last byte received from the transfer station
	wire [10:0] bits_used;
	wire [2:0] state;
	wire transfer_permit_received;
	
	assign active = SW[0];
	assign transfer_permit = SW[1];
	assign flush = SW[2];
	assign go_to_standby = SW[3];
	assign start_scanning = SW[4];
		
	Scanner scanner(clk, rst, GPIO_0[33], GPIO_0[34], GPIO_0[35], active, transfer_permit, flush,
							go_to_standby, start_scanning, bits_used, state, transfer_permit_received);
	TransferStation transferStation(clk, rst, GPIO_0[32], GPIO_0[31], GPIO_0[30],
												active, signal_50, signal_80, signal_90, signal_100,
												receiving_data, current_byte_value);
	
	assign LEDR[9:5] = {signal_50, signal_80, signal_90, signal_100, receiving_data};
	assign LEDR[4] = transfer_permit_received;
	assign LEDR[2:0] = state;
	
	wire [7:0] bytes_used = bits_used / 8;
	
	HEXdisplay hexdisplay1(clk, rst, bytes_used, HEX2, HEX1, HEX0);
	HEXdisplay hexdisplay2(clk, rst, current_byte_value, HEX5, HEX4, HEX3);
	
	
		
endmodule

// divided_clocks[0] = 25MHz, [1] = 12.5Mhz, ... [16] = 762.9Hz ... [23] = 3Hz, [24] = 1.5Hz,[25] = 0.75Hz, ...
module clock_divider (clock, divided_clocks);
	input clock;
	output reg [31:0] divided_clocks;
	
	initial
		divided_clocks <= 0;
	
	always @(posedge clock)
		divided_clocks = divided_clocks + 1;
		
endmodule