`timescale 1 ns / 1 ns  //time scale for simulation

module Testbench ();
  // Parameters
  parameter W = 11;

  // Inputs
  reg Clock;
  reg Clear;
  reg Equals;
  reg Add;
  reg Subtract;
  reg Multiply;
  reg Divide;
  reg [W-1:0] Number;

  // Outputs
  wire signed [W-1:0] Result;
  wire Overflow;

  // Instantiate the Unit Under Test (UUT)
  FourFuncCalc #(
      .W(W)
  ) uut (
      .Clock(Clock),
      .Clear(Clear),
      .Equals(Equals),
      .Add(Add),
      .Subtract(Subtract),
      .Multiply(Multiply),
      .Divide(Divide),
      .Number(Number),
      .Result(Result),
      .Overflow(Overflow)
  );

  // Clock generation
  always #5 Clock = ~Clock;  // 100 MHz clock (10ns period)

  // Task to apply signed magnitude number
  task apply_number(input sign, input [W-2:0] magnitude);
    begin
      Number[W-1]   = sign;
      Number[W-2:0] = magnitude;
    end
  endtask

  task apply_num(input sign, input [W-2:0] magnitude, output reg [W-1:0] num);
    begin
      num[W-1]   = sign;
      num[W-2:0] = magnitude;
    end
  endtask

  task sub(input [W-1:0] A, input [W-1:0] B);
    begin
      Equals = 0;
      Add = 0;
      Subtract = 0;
      Multiply = 0;
      Divide = 0;
      Number = A;
      Clear = 1;
      #30;
      Clear = 0;
      Subtract = 0;
      Equals = 1;
      #30;
      Equals   = 0;
      Subtract = 1;
      Number   = B;
      #30;
      Subtract = 0;
      Equals   = 1;
      #30;
    end
  endtask
  task sub2(input [W-1:0] A, input [W-1:0] B, input Begin);
    begin
      Equals = 0;
      #30;
      if (Begin) Number = A;
      Subtract = 0;
      if (Begin) Equals = 1;
      #30;
      Equals   = 0;
      Subtract = 1;
      Number   = B;
      #30;
      Subtract = 0;
      Equals   = 1;
      #30;
      Equals = 0;
      #5;
    end
  endtask


  task add(input [W-1:0] A, input [W-1:0] B);
    begin
      Equals = 0;
      Add = 0;
      Subtract = 0;
      Multiply = 0;
      Divide = 0;
      Number = A;
      Clear = 1;
      #30;
      Clear = 0;
      Add = 0;
      Equals = 1;
      #30;
      Equals = 0;
      Add = 1;
      Number = B;
      #30;
      Add = 0;
      Equals = 1;
      #30;
    end
  endtask
  task add2(input [W-1:0] A, input [W-1:0] B, input Begin);
    begin
      Equals = 0;
      #30;
      if (Begin) Number = A;
      Add = 0;
      if (Begin) Equals = 1;
      #30;
      Equals = 0;
      Add = 1;
      Number = B;
      #30;
      Add = 0;
      Equals = 1;
      #30;
      Equals = 0;
      #5;
    end
  endtask

  task mult(input [W-1:0] A, input [W-1:0] B);
    begin
      Equals = 0;
      Add = 0;
      Subtract = 0;
      Multiply = 0;
      Divide = 0;
      Number = A;
      Clear = 1;
      #30;
      Clear = 0;
      Multiply = 0;
      Equals = 1;
      #30;
      Equals   = 0;
      Multiply = 1;
      Number   = B;
      #30;
      Multiply = 0;
      Equals   = 1;
      #30;
    end
  endtask
  task mult2(input [W-1:0] A, input [W-1:0] B, input Begin);
    begin
      Equals = 0;
      #30;
      if (Begin) Number = A;
      Multiply = 0;
      if (Begin) Equals = 1;
      #30;
      Equals   = 0;
      Multiply = 1;
      Number   = B;
      #30;
      Multiply = 0;
      Equals   = 1;
      #30;
      Equals = 0;
      #5;
    end
  endtask

  task div(input [W-1:0] A, input [W-1:0] B);
    begin
      Equals = 0;
      Add = 0;
      Subtract = 0;
      Multiply = 0;
      Divide = 0;
      Number = A;
      Clear = 1;
      #30;
      Clear  = 0;
      Divide = 0;
      Equals = 1;
      #30;
      Equals = 0;
      Divide = 1;
      Number = B;
      #30;
      Divide = 0;
      Equals = 1;
      #30;
    end
  endtask

  task div2(input [W-1:0] A, input [W-1:0] B, input Begin);
    begin
      Equals = 0;
      #30;
      Divide = 0;
      if (Begin) Number = A;
      if (Begin) Equals = 1;
      #30;
      Equals = 0;
      Divide = 1;
      Number = B;
      #30;
      Divide = 0;
      Equals = 1;
      #30;
      Equals = 0;
      #5;
    end
  endtask

  task clear();
    begin
      Clear = 1;
      #30;
      Clear = 0;
      #30;
    end
  endtask


  reg [W-1:0] Number1, Number2;

  // Test Procedure
  initial begin
    // Initialize Inputs
    Clock = 0;
    Clear = 0;
    Equals = 0;
    Add = 0;
    Subtract = 0;
    Multiply = 0;
    Divide = 0;
    Number = 0;

    // Wait for global reset
    #100;

    // Test sequence
    Clear = 1;
    #30;
    Clear = 0;


    // Test: 3 + 4
    apply_num(0, 10'd3, Number1);
    apply_num(0, 10'd4, Number2);
    add(Number1, Number2);

    // apply_num(0, 10'd3, Number1);
    // apply_num(0, 10'd4, Number2);
    // sub(Number1, Number2);

    // apply_num(0, 10'd0, Number1);
    // apply_num(0, 10'd976, Number2);
    // sub(Number1, Number2);

    // apply_num(0, 10'd256, Number1);
    // apply_num(0, 10'd4, Number2);
    // mult(Number1, Number2);


    // apply_num(1, 10'd3, Number1);
    // apply_num(1, 10'd3, Number2);
    // mult2(Number1, Number2, 1);
    // #30;
    // Add = 1;
    // apply_num(0, 10'd3, Number1);
    // apply_num(0, 10'd3, Number2);
    // add2(Number, Number2, 0);

    // apply_num(1, 10'd15, Number1);
    // apply_num(1, 10'd17, Number2);
    // mult(Number1, Number2);

    // apply_num(1, 10'd10, Number1);
    // apply_num(0, 10'd9, Number2);
    // div2(Number1, Number2);
  end
endmodule
