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

  

	reg signed [W-1:0] A;			// Accumulator
	// wire CLR_A, LD_A;			// CLR_A: A <= 0; LD_A: A <= Q
	
	reg signed [W-1:0] N_TC;
	// wire LD_N;
	
	
	// registers for multiplication:
	reg [WW:0] PM;
	wire LD_P, SHFT_P;		// load and shift for product
	
	
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




	reg [4:0] X, X_Next;

	localparam XInit		= 5'd0;	// Power-on state (A == 0)
	localparam XLoadA		= 5'd1;
	localparam XResult	= 5'd2;
	

	
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
		
			default: X_Next = XInit;
		endcase
	end
  
 
	assign c0 = ((X == XMulSub) || ((X == XDivLoop) && (Dividend >= Divisor)) || ((X == XLoadA) && (last_op == OP_SUB))) ? 1 : 0;
	

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
