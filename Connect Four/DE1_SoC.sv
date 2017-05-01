module DE1_SoC(CLOCK_50, SW, KEY, LEDR, GPIO_0, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);
	input CLOCK_50;
	input [9:0] SW;
	input [3:0] KEY;
	output [9:0] LEDR;
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	
	inout [35:0] GPIO_0;	

	wire [31:0] divided_clocks;
	clock_divider clk_div (CLOCK_50, divided_clocks);
	
	
	
	wire reset, reset_active_low;
	assign reset = ~KEY[0];
	assign reset_active_low = ~reset;
	
	/*
	wire transfer_data;
	wire transfer_data_ready; // Every time this is changed from high to low, or low to high, the processor should read from transfer_data
	
	assign transfer_data = SW[1];
	assign transfer_data_ready = SW[0];*/
	
	wire TX_data, TX_ready, RX_data, RX_ready;
	
	wire transfer_clock;
	assign transfer_clock = GPIO_0[35];
	assign GPIO_0[35] = is_start_player ? divided_clocks[18] : 1'bz;
		
	assign LEDR[8] = transfer_clock;
	assign LEDR[7] = TX_ready;
	assign LEDR[6] = RX_ready;

	assign GPIO_0[34] = TX_data;
	assign GPIO_0[33] = TX_ready;
	assign RX_data = GPIO_0[32];
	assign RX_ready = GPIO_0[31];
	
	wire is_start_player;
	assign is_start_player = SW[9];
	
	
	wire [3:0] their_last_move;
	
	wire [3:0] our_last_move;
	wire submit_our_last_move;
	
	long_binary_to_short bts (SW[7:0], our_move_input);
	wire[3:0] our_move_input;
	
	wire[6:0] their_last_move_column;
	
	wire [7:0][7:0] red_board;
	wire [7:0][7:0] green_board;
	
	wire [7:0] wins, losses, ties;
	
	wire transfer_data_clock; // transfer_data_clock will change everytime a 4 bit value should be sent to the nios processor
	wire our_turn; // when 1, it is our turn to move. When 0, it is the other players turn to move
	
	first_nios2_system u0 (
		.clk_clk                                            	(CLOCK_50),
		.green_led_0_external_connection_export 					({green_board[3], green_board[2], green_board[1], green_board[0]}),
		.green_led_1_external_connection_export					({green_board[7], green_board[6], green_board[5], green_board[4]}),
		.losses_external_connection_export                   	(losses),
		.our_board_move_input_pio_external_connection_export	(our_move_input),
		.our_board_move_submit_external_connection_export   	(!KEY[3]),
		.our_last_move_pio_external_connection_export       	(our_last_move),
		.our_turn_pio_external_connection_export            	(our_turn),
		.red_led_0_external_connection_export						({red_board[3], red_board[2], red_board[1], red_board[0]}), 
		.red_led_1_external_connection_export						({red_board[7], red_board[6], red_board[5], red_board[4]}),
		.reset_reset_n                                      	(reset_active_low),
		.submit_our_last_move_external_connection_export    	(submit_our_last_move),
		.ties_external_connection_export                     	(ties),
		.transfer_data_pio_external_connection_export       	(their_last_move),
		.transfer_data_ready_pio_external_connection_export 	(transfer_data_clock),		
		.we_are_p1_pio_external_connection_export           	(is_start_player),
		.wins_external_connection_export                     	(wins)    
	);
	
	assign LEDR[5] = our_turn;
	
	io_handler io (transfer_clock, reset,
						our_turn,
						RX_data, RX_ready,
						TX_data, TX_ready,
						their_last_move, transfer_data_clock,
						our_last_move, submit_our_last_move);
	
	led_matrix_driver matrix(divided_clocks[6], red_board, green_board, GPIO_0[15:8], GPIO_0[23:16], GPIO_0[7:0]);
	
	HEXdisplay wins_count(CLOCK_50, reset, wins, HEX1, HEX0);
	HEXdisplay losses_count(CLOCK_50, reset, losses, HEX3, HEX2);
	HEXdisplay ties_count(CLOCK_50, reset, ties, HEX5, HEX4);
endmodule


module io_handler(clock, reset,
						our_turn,
						RX_data, RX_ready,
						TX_data, TX_ready,
						their_last_move, transfer_data_clock,
						our_last_move, submit_move_clock);
	input clock, reset;
	input our_turn;
	input RX_data, RX_ready;
	output TX_data, TX_ready;
	output reg [3:0] their_last_move;
	output reg transfer_data_clock = 0; // Change this from 0->1, or from 1->0 to indicate that we have received input from the other board
	input [3:0] our_last_move;
	
	
	reg submit_move_clock_prev_val;
	input submit_move_clock; // Changing this from 0->1, or from 1->0 to indicate that we should send data to the other board
	
	reg [2:0] bits_to_send;
	reg data_sent = 0;
	reg [3:0] send_buffer;

	reg [2:0] bits_received;
	reg [3:0] receive_buffer;	

	
	
	assign TX_ready = bits_to_send > 0;
	assign TX_data = send_buffer[3];
	always @(posedge clock or posedge reset) begin
		if (reset) begin
			submit_move_clock_prev_val <= submit_move_clock;
			
			bits_to_send <= 3'b0;
			send_buffer <= 4'b0;
			
			bits_received <= 3'b0;
			receive_buffer <= 4'b0;
			
			transfer_data_clock <= 0;
		end else begin
			// SENDING LOGIC
			submit_move_clock_prev_val <= submit_move_clock;
			if (bits_to_send > 0) begin
				bits_to_send <= bits_to_send - 1;
				send_buffer <= send_buffer << 1;
			end else begin
				if (submit_move_clock_prev_val != submit_move_clock) begin
					send_buffer <= our_last_move;
					bits_to_send <= 3'd4;
				end
			end
		
			// RECEIVING LOGIC
			if (!our_turn && bits_received < 4) begin
				if (RX_ready) begin
					receive_buffer <= (receive_buffer << 1) | RX_data;
					bits_received <= bits_received + 1;
					if (bits_received == 3) begin
						their_last_move <= (receive_buffer << 1) | RX_data;
						transfer_data_clock <= !transfer_data_clock;
						bits_received <= 0;
					end
				end 
			end
			
		end
	end
	
endmodule

// Turns the switch input into a 4 bit value
// For example turns 0000100 into 4'd2, 1000000 into 4'd6, ...
module long_binary_to_short(column_input, value_out);
	input [7:0] column_input;
	output reg [3:0] value_out;
	always @(*) begin
		case(column_input)
			8'b00000001: begin
				value_out = 4'd0;
			end
			8'b00000010: begin
				value_out = 4'd1;
			end
			8'b00000100: begin
				value_out = 4'd2;
			end
			8'b00001000: begin
				value_out = 4'd3;
			end
			8'b00010000: begin
				value_out = 4'd4;
			end
			8'b00100000: begin
				value_out = 4'd5;
			end
			8'b01000000: begin
				value_out = 4'd6;
			end
			8'b10000000: begin
				value_out = 4'd7;
			end
			default: begin
				value_out = 4'd15;
			end
		endcase
	end
endmodule


module led_matrix_driver (clock, red_array, green_array, red_driver, green_driver, row_sink);
	input clock;
	input [7:0][7:0] red_array, green_array;
	output reg [7:0] red_driver, green_driver, row_sink;
	reg [2:0] count;
	always @(posedge clock)
		count <= count + 3'b001;
	always @(*)
		case (count)
			3'b000: row_sink = 8'b11111110;
			3'b001: row_sink = 8'b11111101;
			3'b010: row_sink = 8'b11111011;
			3'b011: row_sink = 8'b11110111;
			3'b100: row_sink = 8'b11101111;
			3'b101: row_sink = 8'b11011111;
			3'b110: row_sink = 8'b10111111;
			3'b111: row_sink = 8'b01111111;
		endcase
	
	assign red_driver = red_array[count];
	assign green_driver = green_array[count];
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

module HEXdisplay (clk, rst, data, D2, D1);
	input clk, rst;
	input [7:0] data;
	output [6:0] D2, D1;
	wire [3:0] digit0, digit1, digit2;
	
	assign digit0 = data % 10;
	assign digit1 = data / 10 % 10;
	
	HEXdisplay_sub d1(clk, rst, digit0, D1);
	HEXdisplay_sub d2(clk, rst, digit1, D2);
	
endmodule

module HEXdisplay_sub (clk, rst, digit, display);
	input clk, rst;
	input [3:0] digit;
	output reg [6:0] display;
	
	parameter zero = 4'b0000, one = 4'b0001, two = 4'b0010, three = 4'b0011, four = 4'b0100, five = 4'b0101, six = 4'b0110, seven = 4'b0111, eight = 4'b1000, nine = 4'b1001;
	parameter hex_UNDECIDED = 7'b1111111, hex_ZERO = 7'b1000000, hex_ONE = 7'b1111001, hex_TWO = 7'b0100100, hex_THREE= 7'b0110000, hex_FOUR = 7'b0011001, hex_FIVE = 7'b0010010, hex_SIX  = 7'b0000010, hex_SEVEN= 7'b1111000, hex_EIGHT= 7'b0000000, hex_NINE = 7'b0010000;

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
