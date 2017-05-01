// transfer_data, transfer_clock, active described in the communications standard
// go_to_standby will trigger a transition from lowpower to standby
// start_scanning will trigger a transition from standby to active
// flush will trigger a transition from idle to flush
module Scanner(clk, rst,
				transfer_data, transfer_clock, transfer_ready, active, transfer_permit, flush,
				go_to_standby, start_scanning,
				bits_used, state, transfer_permit_received);
	input clk, rst;
	input active, transfer_permit, flush;
	input go_to_standby, start_scanning;
	
	output transfer_data, transfer_clock;
	input transfer_ready;
	assign transfer_clock = clk && bits_to_transfer > 0;
		
	output reg [10:0] bits_used;
	
	// Indicates the current state
	// 3'b000: Lowpower
	// 3'b001: Standby
	// 3'b010: Active
	// 3'b011: Idle
	// 3'b100: Transferring
	// 3'b101: Flush / Clearing buffer
	output reg [2:0] state;
	
	reg buffer_boolean;
	
	reg [7:0] transmit_buffer;
	reg [11:0] bits_to_transfer;
	assign transfer_data = transmit_buffer[7];
	
	wire last_bit_from_buffer;
	assign last_bit_from_buffer = ( ((bits_used - 1) / 8) >> (((bits_used - 1) % 8)) ) & 8'b00000001;
	
	output reg transfer_permit_received;
	
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			state <= 0;
			bits_used <= 0;
			buffer_boolean <= 0;
			
			transmit_buffer <= 0;
			bits_to_transfer <= 0;
			transfer_permit_received <= 0;
		end else begin
			buffer_boolean <= ~buffer_boolean;
				
			if (state == 3'b000 && go_to_standby) begin
				state <= 3'b001;
			end else if (state == 3'b001 && start_scanning) begin
				state <= 3'b010;
			end else if (state == 3'b010) begin
				if (transfer_permit && bits_used >= 11'd819)
					transfer_permit_received <= 1;
			
				if (active && buffer_boolean && bits_used <= 11'd1024)
					bits_used <= bits_used + 1;
				if (bits_used == 11'd512) begin // 50%
					transmit_buffer <= 1;
					bits_to_transfer <= 8;
				end else if (bits_used == 11'd819) begin // 80%
					transmit_buffer <= 2;
					bits_to_transfer <= 8;
				end else if (bits_used == 11'd921) begin // 90%
					transmit_buffer <= 3;
					bits_to_transfer <= 8;
				end else if (bits_used == 11'd1024) begin // 100%
					transmit_buffer <= 4;
					bits_to_transfer <= 8;
					state <= 3'b011;
				end
			end else if (state == 3'b011) begin
				if ((transfer_permit || transfer_permit_received) && active && bits_to_transfer == 0) begin
					state <= 3'b100;
					transmit_buffer <= 7;
					bits_to_transfer <= 8 + 1024;
					transfer_permit_received <= 0;
				end else if (flush && active) begin
					state <= 3'b101;
				end
			end else if (state == 3'b100 || state == 3'b101) begin
				if (active && bits_used > 11'd0)
					bits_used <= bits_used - 1;
				if (active && bits_used == 0)
					state <= 3'b000;
			end
				
			// Transmitting
			if (bits_to_transfer > 0 && active && transfer_ready) begin
				transmit_buffer <= (transmit_buffer << 1) | last_bit_from_buffer;
				bits_to_transfer <= bits_to_transfer - 1;
			end
		end
	end
endmodule

