module SeqCalculator
	(
		input CLOCK_50,
		input [17:0] SW,	// SW[17]: operation control
								// SW[10:0]: signed-magnitude number
		input [3:0] KEY,			// Operations
		output [6:0] HEX7, HEX6, HEX5, HEX4,	// Number
		output [6:0] HEX3, HEX2, HEX1, HEX0,	// Result
		output [8:0] LEDG // ovf
	);
	
	
	// TODO CODE THIS MODULE
	
	wire clear, EQ, add, sub, mult, div, ovf1, ovf2, ovf3, ovf_final;
	wire [10:0] res;
	
	
	wire ClkHz;
	wire [26:0] clock_num;
	
	Clock_Div #(.SIZE(26)) c1(.CLK_in(CLOCK_50), .CLKS_out(clock_num));
	
	assign ClkHz = clock_num[26];
	
	
	assign clear = SW[17] & ~KEY[0];
	assign add = ~SW[17] & ~KEY[3];
	assign sub = ~SW[17] & ~KEY[2];
	assign mult = ~SW[17] & ~KEY[1];
	assign div = ~SW[17] & ~KEY[0];
	assign EQ = SW[17] & ~KEY[3];
	
	
	
	FourFuncCalc C1(.Clock(ClkHz), .Clear(clear), .Equals(EQ), .Add(add), 
						.Subtract(sub), .Multiply(mult), .Divide(div), .Number(SW[10:0]), 
						.Result(res), .Overflow(ovf3));
						
						
						
	// number entered
	Binary_to_7SEG B1(.N(SW[10:0]), .Encoding(1'b0), .Sign(HEX7), 
							.D2(HEX6), .D1(HEX5), .D0(HEX4), .TooLarge(ovf1));
	
	// result number
	Binary_to_7SEG B2(.N(res), .Encoding(1'b1), .Sign(HEX3), .D2(HEX2), 
							.D1(HEX1), .D0(HEX0), .TooLarge(ovf2));
	
	
	
	
	assign ovf_final = ovf1 || ovf2 || ovf3;
	
	assign LEDG[8] = ovf_final;
	
endmodule	// SeqCalculator