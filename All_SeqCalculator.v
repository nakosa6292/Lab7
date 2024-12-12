module All_SeqCalculator
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
	
	assign ClkHz = clock_num[23];
	
	
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



// DONE
// Clocking
// Clock Divider by Powers of 2 (Table of frequencies and periods at EOF)
module Clock_Div
	#(parameter SIZE = 36)	// divides by 2^i for i = 0 to i = 36
	(
		input CLK_in,
		output [SIZE:0] CLKS_out
	);
	
	reg [SIZE:1] Counter;
	initial Counter = 'd0;
	
	always @(posedge CLK_in)
		Counter <= Counter + 1;

	assign CLKS_out = {Counter, CLK_in};
endmodule // Clock_Div

/* Clock fequency and period
   at various taps of CLKS_OUT

	              Frequency		   Period
_________________________________________
CLOCK_50[0]     50.00	MHz	  20.00	ns
CLKS_out[1]     25.00	MHz     40.00	ns
CLKS_out[2]	    12.50	MHz     80.00	ns
CLKS_out[3]      6.25	MHz    160.00	ns
CLKS_out[4]      3.13	MHz    320.00	ns
CLKS_out[5]	     1.56	MHz	 640.00	ns
CLKS_out[6]	   781.25	KHz	   1.28	us
CLKS_out[7]	   390.63	KHz	   2.56	us
CLKS_out[8]	   195.31	KHz	   5.12	us
CLKS_out[9]	    97.66	KHz	  10.24	us
CLKS_out[10]    48.83	KHz	  20.48	us
CLKS_out[11]	  24.41	KHz	   40.96	us
CLKS_out[12]	  12.21	KHz	   81.92	us
CLKS_out[13]	   6.10	KHz	  163.84	us
CLKS_out[14]	   3.05	KHz	  327.68	us
CLKS_out[15]	   1.53	KHz	  655.36	us
CLKS_out[16]   762.94	Hz	     	 1.31	ms
CLKS_out[17]	 381.47	Hz	       2.62	ms
CLKS_out[18]	 190.73	Hz	       5.24	ms
CLKS_out[19]	  95.37	Hz	      10.49	ms
CLKS_out[20]	  47.68	Hz	      20.97	ms
CLKS_out[21]	  23.84	Hz       41.94	ms
CLKS_out[22]	  11.92	Hz	      83.89	ms
CLKS_out[23]	   5.96	Hz	     167.77	ms
CLKS_out[24]	   2.98	Hz	     335.54	ms
CLKS_out[25]	   1.49	Hz      671.09	ms
CLKS_out[26]   745.06	milliHz	 1.34	sec
CLKS_out[27]	 372.53	milliHz	 2.68	sec
CLKS_out[28]	 186.26	milliHz	 5.37	sec
CLKS_out[29]	  93.13	milliHz	10.74	sec
CLKS_out[30]	  46.57	milliHz	21.47	sec
CLKS_out[31]	  23.28	milliHz	42.95	sec
CLKS_out[32]	  11.64	milliHz	 1.43	min
CLKS_out[33]	  5.82	milliHz	 2.86	min
CLKS_out[34]	  2.91	milliHz	 5.73	min
CLKS_out[35]	  1.46	milliHz	11.45	min
CLKS_out[36]	  0.73  milliHz	22.91	min
*/





// DONE
// W-Bit signed-magnitude binary number to 4-Digit 7-Segment Display
module Binary_to_7SEG
	#(parameter W = 11)				// Default bit width
	(input [W-1:0] N,							// W-bit "signed" number			
	 input Encoding,								// Signed-Magnitude: 0, Two's Complement: 1
	 output [6:0] Sign,							// 7SEG display for sign
	 output [6:0] D2, D1, D0,		// 7SEG display for the three digits
	 output TooLarge							// N too large to display
	);

// Named HEX Outputs
	localparam ZERO 	= 7'b1000000;	// 64
	localparam ONE		= 7'b1111001; 	// 121
	localparam TWO		= 7'b0100100; 	// 36
	localparam THREE	= 7'b0110000; 	// 48
	localparam FOUR	= 7'b0011001; 	// 25
	localparam FIVE	= 7'b0010010; 	// 18
	localparam SIX		= 7'b0000010; 	// 2
	localparam SEVEN	= 7'b1111000; 	// 120
	localparam EIGHT	= 7'b0000000; 	// 0
	localparam NINE	= 7'b0010000; 	// 16
	localparam MINUS	= 7'b0111111;	// 63
	localparam OFF		= 7'b1111111; 	// 127

// Load the look-up table
	reg [6:0] LUT[0:9];					// Magnitude Look-up Table
	initial begin
		LUT[0] = ZERO;
		LUT[1] = ONE;
		LUT[2] = TWO;
		LUT[3] = THREE;
		LUT[4] = FOUR;
		LUT[5] = FIVE;
		LUT[6] = SIX;
		LUT[7] = SEVEN;
		LUT[8] = EIGHT;
		LUT[9] = NINE;
	end

	
// Find Magnitude
	wire [W-1:0] Magnitude;
	assign Magnitude = Encoding? (N[W-1] ? -N : N) : N[W-2:0];

// Check if N can be displayed
	assign TooLarge = (Magnitude > 'd999);


// Get digits of N
	wire [W-1:0] Quotient0, Quotient1, Digit0, Digit1, Digit2;
	assign Quotient0 = Magnitude / 4'b1010;
	assign Quotient1 = Quotient0 / 4'b1010;
	assign Digit0 = Magnitude % 4'b1010;
	assign Digit1 = Quotient0 % 4'b1010;
	assign Digit2 = Quotient1 % 4'b1010;
	
// Display: indicate out-of-range with "dashes"
		assign Sign = TooLarge? MINUS : (N[W-1]? MINUS : OFF);	// - if negative, blank if positive
		assign D2 = TooLarge? MINUS : ((Digit2 == 'd0) ? OFF : LUT[Digit2]);
		assign D1 = TooLarge? MINUS : ((Digit2 == 'd0) & (Digit1 == 'd0) ? OFF : LUT[Digit1]);
		assign D0	= TooLarge? MINUS : LUT[Digit0];
endmodule // Binary_to_7SEG





/*
`timescale 1ns/1ns
module Binary_to_7SEG_TestBench;
	parameter W = 11;
	reg signed [W-1:0] TC;				// W-bit two's complement number
	wire [6:0] TCSign;						// 7-segment for sign
	wire [6:0] TCD2, TCD1, TCD0;	// 7-segment for magnitude digits
	wire TCTooLarge;							// TC too large

	reg [W-1:0] SM;								// W-bit signed-magnitude number
	wire [6:0] SMSign;						// 7-segment for sign
	wire [6:0] SMD2, SMD1, SMD0;	// 7-segment for magnitude digits
	wire SMTooLarge;							// SM too large


	Binary_to_7SEG #(.W(W)) TCDisplay(TC, 1, TCSign, TCD2, TCD1, TCD0, TCTooLarge);
	Binary_to_7SEG #(.W(W)) SMDisplay(SM, 0, SMSign, SMD2, SMD1, SMD0, SMTooLarge);
	
	initial
	begin
		TC = 'd725; SM = 'd725;
		#1;
//
		TC = - 'd3;  SM = 'b10000000011;
		#1;
		TC = 'd1000; SM = 'd1000;
		#TC;
//
	end
endmodule
*/








module FourFuncCalc
  #(parameter W = 11)             // Default bit width
  (
    input Clock,
    input Clear,                   // C button
    input Equals,                  // = button: displays result so far
    input Add,                     // + button
    input Subtract,                // - button
    input Multiply,                // x button (times)
    input Divide,                  // / button (division quotient)
    input [W-1:0] Number,          // Must be entered in signed-magnitude on SW[W-1:0]
    output signed [W-1:0] Result,  // Calculation result in two's complement
    output Overflow                // Indicates result can't be represented in W bits 
  );
  localparam WW = 2 * W;           // Double width for Booth multiplier
  localparam BoothIter = $clog2(W);// Width of Booth Counter

  
//****************************************************************************************************
// Datapath Components
//****************************************************************************************************


//----------------------------------------------------------------------------------------------------
// Registers
// For each register, declare it along with the controller commands that
// are used to update its state following the example for register A
//----------------------------------------------------------------------------------------------------
	
	reg signed [W-1:0] A;			// Accumulator
	// wire CLR_A, LD_A;			// CLR_A: A <= 0; LD_A: A <= Q
	
	reg signed [W-1:0] N_TC;
	// wire LD_N;
	
	
	// registers for multiplication:
	reg [WW:0] PM;
	wire LD_P, SHFT_P;		// load and shift for product
	
	
	// reg [BoothIter:0] MCounter;	// counter for iterations
	// wire DEC_M, CLR_M;
	
	
	/*
	reg [W-1:0] N_SM;			// signed-magnitude version of the number
	wire LD_N_SM;
	*/
	
	
	
	// registers for division:
	reg signed [W-1:0] Dividend, Divisor, Q;
	// wire LD_Div, LD_Divsr, LD_Q, SUB, INC_Q;
  
//----------------------------------------------------------------------------------------------------
// Number Converters
// Instantiate the three number converters following the example of SM2TC1
//----------------------------------------------------------------------------------------------------

	wire signed [W-1:0] NumberTC;	// Two's complement of Number
	SM2TC #(.width(W)) SM2TC1(Number, NumberTC);


//----------------------------------------------------------------------------------------------------
// MUXes
// Use conditional assignments to create the various MUXes
// following the example for MUX Y1
//----------------------------------------------------------------------------------------------------
	
	
	
	//wire SEL_P;
	wire signed [W-1:0] Y1, Y2;
	wire SEL_P;
	
	assign Y1 = ((X == XMulAdd) || (X == XMulSub)) ? PM[WW:W+1] : (X == XDivLoop) ? Dividend : A;
	
	assign Y2 = ((X == XMulAdd) || (X == XMulSub)) ? A : (X == XDivLoop) ? Divisor : N_TC;

  
//----------------------------------------------------------------------------------------------------
// Adder/Subtractor 
//----------------------------------------------------------------------------------------------------

	wire c0;					// 0: Add, 1: Subtract
	wire ovf;					// Overflow
	wire signed [W-1:0] R;
	AddSub #(.W(W)) AddSub1(Y1, Y2, c0, R, ovf);
	
	wire PSgn = R[W-1] ^ ovf;		// Corrected P Sign on Adder/Subtractor overflow


//****************************************************************************************************
/* Datapath Controller
   Suggested Naming Convention for Controller States:
     All names start with X (since the tradtional Q connotes quotient in this project)
     XAdd, XSub, XMul, and XDiv label the start of these operations
     XA: Prefix for addition states (that follow XAdd)
     XS: Prefix for subtraction states (that follow XSub)
     XM: Prefix for multiplication states (that follow XMul)
     XD: Prefix for division states (that follow XDiv)
*/
//****************************************************************************************************


//----------------------------------------------------------------------------------------------------
// Controller State and State Labels
// Replace ? with the size of the state registers X and X_Next after
// you know how many controller states are needed.
// Use localparam declarations to assign labels to numeric states.
// Here are a few "common" states to get you started.
//----------------------------------------------------------------------------------------------------

	reg [4:0] X, X_Next;

	localparam XInit		= 5'd0;	// Power-on state (A == 0)
	localparam XLoadA		= 5'd1;
	localparam XResult	= 5'd2;
	
	
	
	// Might no need anymore:
	/* 
	localparam XAdd		= 5'd3;
	localparam XA1			= 5'd4;
	localparam XSub		= 5'd5;
	localparam XS1			= 5'd6;
	*/
	
	
	
	// states for multiplication:
	localparam XMulInit			= 5'd3;
	localparam XMulLoad			= 5'd4;
	localparam XMulCheck			= 5'd5;
	localparam XMulAdd			= 5'd6;
	localparam XMulSub			= 5'd7;
	localparam XMulNext			= 5'd8;
	localparam XMulMore			= 5'd9;
	localparam XMulDone			= 5'd10;
	
	
	// states for division:
	localparam XDivInit			= 5'd11;
	localparam XDivSetup			= 5'd12;
	localparam XDivLoop			= 5'd13;
	localparam XDivDone			= 5'd14;

	// localparam XWait		= 5'd15;		// waits for equals
	
	
	
	// Operatios different method:
	localparam OP_NONE 	= 3'd0;
	localparam OP_ADD 	= 3'd1;
	localparam OP_SUB 	= 3'd2;
	localparam OP_MUL 	= 3'd3;
	localparam OP_DIV 	= 3'd4;
	
	
	reg [2:0] last_op;
	
	reg [BoothIter-1:0] CTR;
	
	wire op_select = (Add || Subtract || Multiply || Divide);
	

//----------------------------------------------------------------------------------------------------
// Controller State Transitions
// This is the part of the project that you need to figure out.
// It's best to use ModelSim to simulate and debug the design as it evolves.
// Check the hints in the lab write-up about good practices for using
// ModelSim to make this "chore" manageable.
// The transitions from XInit are given to get you started.
//----------------------------------------------------------------------------------------------------


// Might need <= instead of = in this block
	always @(*) begin
	
		X_Next = XInit;
		
		case (X)
			XInit: begin
				if (Clear)
					X_Next = XInit;
				else if (Equals)
					X_Next = XLoadA;
				else if (op_select)
					X_Next = XResult;
				else
					X_Next = XInit;
			end
					
					
			XLoadA: begin
				if (last_op == OP_MUL)
					X_Next = XMulInit;
				else if(last_op == OP_DIV)
					X_Next = XDivInit;
				else
					X_Next = XResult;
			end
			
			
			XResult: begin
				if(Clear)
					X_Next = XInit;
				else if(Equals)
					X_Next = XLoadA;
				else if(op_select)
					X_Next = XResult;
				else
					X_Next = XResult;
			end
					
		
		
			// Multiplication states from Booth code
			XMulInit:	X_Next = XMulLoad;
			XMulLoad:	X_Next = XMulCheck;
			XMulCheck: begin
				if(~PM[1]&PM[0]) X_Next = XMulAdd;
				else if(PM[1]&~PM[0]) X_Next = XMulSub;
				else X_Next = XMulNext;
			end
			
			XMulAdd:		X_Next = XMulNext;
			XMulSub:		X_Next = XMulNext;
			XMulNext:	X_Next = XMulMore;
			
			XMulMore: begin
				if(CTR == 0) X_Next = XMulDone;
				else X_Next = XMulCheck;
			end
			
			XMulDone: X_Next = XResult;
			
			
			
			
			// Division states
			XDivInit: X_Next = XDivSetup;
			
			XDivSetup: begin
				if(Divisor == 0)
					X_Next = XDivDone;
				else
					X_Next = XDivLoop;
			end
			
			
			XDivLoop: begin
				if(Dividend >= Divisor)
					X_Next = XDivLoop;
				else
					X_Next = XDivDone;
			end
			
			XDivDone: X_Next = XResult;
		
		
		
		
		
		
		// Old code:
		/*
			XInit:
				if (Clear)
					X_Next <= XInit;
				else if (Equals)
					X_Next <= XLoadA;
				else if (Add)
					X_Next <= XAdd;
				else if (Subtract)
					X_Next <= XSub;
				else if (Multiply)
					X_Next <= XMul;
				else if (Divide)
					X_Next <= XDiv;
				else
					X_Next <= XInit;
			
			XLoadA: 	X_Next <= XResult;
			XAdd: 	X_Next <= XA1;
			XA1: 		X_Next <= XResult;
			XSub: 	X_Next <= XS1;
			XS1:		X_Next <= XResult;
			
			// Multiplication
			XMul:		X_Next <= XM1;
			XM1:		X_Next <= XM2;
			XM2:
				if(MCounter == 0)
					X_Next <= XM3;
				else
					X_Next <= XM2;
					
			XM3:		X_Next <= XResult;
			
			// Division
			XDiv:		X_Next <= XD1;
			XD1:		X_Next <= XD2;
			XD2:
				if(Dividend >= Divisor)
					X_Next <= XD2;
				else
					X_Next <= XD3;
			XD3:		X_Next <= XResult;
			XResult:
				if(Clear)
					X_Next <= XInit;
				else if(Equals)
					X_Next <= XLoadA;
				else if(Add)
					X_Next <= XAdd;
				else if(Subtract)
					X_Next <= XSub;
				else if(Multiply)
					X_Next <= XMul;
				else if(Divide)
					X_Next <= XDiv;
				else
					X_Next <= XResult;
					
			
			*/
			default: X_Next = XInit;
		endcase
	end
  
  
//----------------------------------------------------------------------------------------------------
// Initial state on power-on
// Here's a freebie!
//----------------------------------------------------------------------------------------------------


// Pretty sure I dont need this anymore:
/*
	initial begin
		X <= XInit;
		A <= 'd0;
		N_TC <= 'd0;
		MCounter <= W;						// Initialize MCounter to the Booth Iterator 
												// for the right amount of loops
		PM <= 'd0;      
		
		// add division states
		Dividend		<= 'd0;
		Divisor		<= 'd0;
		Q				<= 'd0;
		
		last_op <= OP_NONE; // no operation selected to start
	end
*/


//----------------------------------------------------------------------------------------------------
// Controller Commands to Datapath
// No freebies here!
// Using assign statements, you need to figure when the various controller
// commands are asserted in order to properly implement the datapath
// operations.
//----------------------------------------------------------------------------------------------------
	
	
	// Control commands for Add/Sub:
	// assign CLR_A 	= (X == XInit);
	// assign LD_A 	= (X == XLoadA); // || (X == XA1) || (X == XS1) || (X == XM3) || (X == XD3);
	// assign LD_N 	= (X == XLoadA); // || (X == XAdd) || (X == XSub) || (X == XMul) || (X == XDiv); 
	// ^^ might be too many conditions
	
	
	// assign c0 = ((X == XMulSub) || ((X == XDivLoop) && (Dividend <= Divisor)) || (X == XSub)) ? 1 : 0;
	assign c0 = ((X == XMulSub) || ((X == XDivLoop) && (Dividend >= Divisor)) || ((X == XLoadA) && (last_op == OP_SUB))) ? 1 : 0;
	
	
	
	// Control Commands for Multiplication:
	// assign LD_P 	= (X == XM1);
	// assign SHFT_P	= (X == XM2);
	// assign DEC_M 	= (X == XM2);
	// assign CLR_M 	= (X == XM1);
	// assign SEL_P 	= (X == XM2);
	
	
	// Control commands for Division:
	// assign LD_Div 		= (X == XD1);
	// assign LD_Divsr 	= (X == XD1);
	// assign LD_Q 		= (X == XD1);
	// assign SUB		 	= ((X == XD2) && Dividend >= Divisor);
	// assign INC_Q		= SUB;
	

	
	
//----------------------------------------------------------------------------------------------------  
// Controller State Update
//----------------------------------------------------------------------------------------------------

// might not need this can probably add this too the next always block
/*
	always @(posedge Clock)
		if (Clear)
			X <= XInit;
		else
			X <= X_Next;
*/

      
//----------------------------------------------------------------------------------------------------
// Datapath State Update
// This part too is your responsibility to figure out.
// But there is a hint to get you started.
//----------------------------------------------------------------------------------------------------

	always @(posedge Clock) begin
			//N_TC <= LD_N ? NumberTC : N_TC;
		
		if(Clear) begin
			X <= XInit;
			last_op <= OP_NONE;
			A <= 'd0;
		end
		else begin
			X <= X_Next;
		end
		
		
		// Only load N_TC on =
		if(X == XLoadA)
			N_TC <= NumberTC;
			
			
		// Select op when in XInit or XResult
		if(((X == XInit) || (X == XResult)) && op_select) begin
			if(Add)
				last_op <= OP_ADD;
			else if(Subtract)
				last_op <= OP_SUB;
			else if(Multiply)
				last_op <= OP_MUL;
			else if(Divide)
				last_op <= OP_DIV;
		end
		
		
		// After =
		if((X == XLoadA) && (last_op == OP_ADD))
			A <= R;
		else if((X == XLoadA) && (last_op == OP_SUB))
			A <= R;
		else if((X == XLoadA) && (last_op == OP_NONE)) begin
			// Maybe load R instead
			A <= N_TC;
		end
		
		
		// Multiplication:
		if(X == XMulLoad) begin
			PM <= $signed({{(W + 1){N_TC[W - 1]}}, N_TC, 1'b0});
			CTR <= W;
		end
		
		else if(X == XMulAdd) begin
			PM <= $signed({PSgn, R, PM[W:0]});
		end
		
		else if(X == XMulNext) begin
			PM <= PM >>> 1;
			CTR <= CTR - 1;
		end
		
		else if(X == XMulDone) begin
			A <= PM[W-1:0];
		end
		
		
		
		
		// Division:
		if(X == XDivInit) begin
			Dividend <= A;
			Divisor <= N_TC;
			Q <= 0;
		end
		
		else if(X == XDivSetup) begin
			// Do nothing
		end
		
		else if((X == XDivLoop) && (Dividend >= Divisor)) begin
			Dividend <= R;
			Q <= Q + 1;
		end
		
		else if(X == XDivDone) begin
			A <= Q;
		end
		
		
		// If XInit, clea A
		if(X == XInit)
			A <= 0;
	end
		
		
		
		
		
		
		// Old code
		/*
		// Clear or load A
		if(CLR_A) begin
			X <= Xinit;
			last_op <= OP_NONE;
			A <= 'd0;
		end
		else if(LD_A) begin
			if(X == XM3)
				A <= PM[W:1];
			else if(X == XD3)
				A <= Q;
			else
				A <= R;
		end
		
		
		// Load N_TC
		if(LD_N)
			N_TC <= NumberTC;
		
		
		// Multiplication loops
		if(LD_P)
			PM <= { {(W+1){1'b0}}, A, 1'b0}; // Use Concatenation operator to create PM
		else if (SHFT_P)
			PM <= {PSgn, R, PM[W:1]};			// Shift PM
			
			
		
		// Update Counter
		if (CLR_M)
			MCounter <= W;		// Reset
		else if (DEC_M)
			MCounter <= MCounter - 1;			// Decrement
			
			
		// Division loops
		if(LD_Div)
			Dividend <= A;
		if(LD_Divsr)
			Divisor <= N_TC;
		if(LD_Q)
			Q <= 0;					// Start at 0
		if(SUB)
			Dividend <= R;
		if(INC_Q)
			Q <= Q + 1;				// Increment Q
		

	end

 
//---------------------------------------------------------------------------------------------------- 
// Calculator Outputs
// The two outputs are Result and Overflow, get it?
//----------------------------------------------------------------------------------------------------
	*/

	assign Result = A;
	
	// ovf checks
	wire Div0 		= (X == XDivSetup) && (Divisor == 0);
	wire mul_ovf 	= (X == XMulDone) && (|PM[WW:W+1]);		// use reduction or operator to check if there 
																		// is an overflow at the final multiplication state
	
	assign Overflow = ovf || Div0 || mul_ovf;

endmodule // FourFuncCalc









// DONE
// Number Conversion from signed-magnitude to two's complement
module SM2TC
	#(parameter width = 11)
	(input [width-1:0] SM,
	 output [width-1:0] TC
	);

	wire [width-2:0] Magnitude;														// Magnitude
	assign Magnitude = ~(SM[width-2:0]) + 'b1; 		// Flip bits and add 1
 	assign TC =
		SM[width-1] ?																							// If SM is negative
		(Magnitude == 0 ?																			//   And is negative zero
			'd0 :																												//     Convert it to "positive" zero          
			{1'b1, Magnitude}																		//     Else prepend negative sign
		) :         
		SM;                     																			// Else TC = SM since number is positive
endmodule // SM2TC







// Number Conversion from two's complement to signed-magnitude
module TC2SM
	#(parameter width = 11)
	(
		input [width-1:0] TC, 
		output [width-1:0] SM,
		output Overflow
	);

	wire [width-1:0] Magnitude;
	assign Magnitude =
		TC[width-1] ?																											// If TC is negative
			~(TC[width-1:0]) + 1'b1 : 																	//   Flip bits and add 1
         TC; 																															//   Else SM is positive and SM = TC
				 
	assign SM = {TC[width-1], Magnitude[width-2:0]};		// Prepend sign
  assign Overflow = TC[width-1] & ~TC[width-2:0];		// Most negative TC number
																																						// Alternatively, Overflow = Magnitude[width-1]
endmodule // TC2SM






// DONE
module AddSub
	#(parameter W = 16)			// Default width
	(
		input [W-1:0] A, B,				// W-bit unsigned inputs
		input c0,											// Carry-in
		output [W-1:0] S,					// W-bit unsigned output
		output ovf										// Overflow signal
	);
	
	wire [W:0] c;									// Carry signals
	assign c[0] = c0;

// Instantiate and "chain" W full adders 
	genvar i;
	generate
		for (i = 0; i < W; i = i + 1)
			begin: RCAddSub
				FullAdder FA(A[i], B[i] ^ c[0], c[i], S[i], c[i+1]);
			end
	endgenerate

// Overflow
		assign ovf = c[W-1] ^ c[W];
endmodule // AddSub




// DONE
// Full Adder
module FullAdder(a, b, cin, s, cout);
	input a, b, cin;
	output s, cout;
	assign s = a ^ b ^ cin;
	assign cout = a & b | cin & (a ^ b);
endmodule // FullAdder







