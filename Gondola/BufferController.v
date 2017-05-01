// This buffer stores 1024 bits
// input_data is the value to store in the buffer
// output data is the value to transfer at this time
// bits_used is a 11 bit array representing how many bits are being used in the buffer
//
// When record_bits is 1, bits will be recorded
// 		bits will be added 8 at a time, in a counting order. 8 bits will be added every 4 clk cycles
//
// When output_bits is 1, bits will be outputted
//		At the posedge of clk, the output_data will change
//
// record_bits and output_bits should never be true at the same time
module BufferController(clk, rst, output_data, bits_used, record_bits, output_bits);
	input clk, rst;
	input record_bits, output_bits;
	output output_data;
	output reg [10:0] bits_used;
	
	reg boolean = 0;
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			bits_used <= 11'b0;
			boolean <= 0;
		end else begin
			if (record_bits == 1 && output_bits != 1 && bits_used < 11'd1024) begin
				if (boolean == 1) begin
					bits_used <= bits_used + 1;
				end
				boolean <= ~boolean;
			end else if (record_bits != 1 && output_bits == 1 && bits_used > 12'b0) begin
				bits_used <= bits_used - 1'b1;
			end
		end
	end
	assign output_data = ( ((bits_used - 1) / 8) >> (((bits_used - 1) % 8)) ) & 8'b00000001;
endmodule

