module TransferStation(clk, rst, transfer_data, transfer_clock, transfer_ready, active, signal_50, signal_80, signal_90, signal_100, receiving_data, current_byte_value);
	input clk, rst;
	input transfer_data, transfer_clock;
	output transfer_ready;
	input active;
	
	assign transfer_ready = active;

	output receiving_data;
	output reg signal_50, signal_80, signal_90, signal_100;
	output reg [7:0] current_byte_value;

	reg [7:0] bytes_left;
	assign receiving_data = bytes_left > 0 && active;

	reg [2:0] current_bit;
	reg [7:0] current_byte;

	// read the next bit into current_byte
	always @(posedge transfer_clock or posedge rst) begin
		if (rst) begin
			current_bit <= 0;
			current_byte <= 0;
			
			signal_50 <= 0;
			signal_80 <= 0;
			signal_90 <= 0;
			signal_100 <= 0;
			current_byte_value <= 8'b0;
			bytes_left <= 0;
		end else if (active) begin
			current_byte <= (current_byte << 1) | transfer_data;
			current_bit <= current_bit + 1;
			
			if (current_bit == 3'b111) begin
				current_byte_value <= (current_byte << 1) | transfer_data;
				if (bytes_left > 0) begin
					bytes_left <= bytes_left - 1;
					if (bytes_left == 1) begin
						signal_50 <= 0;
						signal_80 <= 0;
						signal_90 <= 0;
						signal_100 <= 0;
					end
				end else begin
					if (((current_byte << 1) | transfer_data) == 8'd1)
						signal_50 <= 1;
					if (((current_byte << 1) | transfer_data) == 8'd2)
						signal_80 <= 1;
					if (((current_byte << 1) | transfer_data) == 8'd3)
						signal_90 <= 1;
					if (((current_byte << 1) | transfer_data) == 8'd4)
						signal_100 <= 1;
					if (((current_byte << 1) | transfer_data) == 8'd7) begin
						bytes_left <= 128;
					end
				end
			end
		end
	end
endmodule
