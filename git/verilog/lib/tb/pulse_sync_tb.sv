// ==============================================================================
//
//  File Name       :  pulse_sync_tb.v
//  Description     :  This file contains testbench for a Synchornous FIFO.
// 
// ==============================================================================

`timescale 1ns/1ps

module pulse_sync_tb;

  // -------------------------------------------------------------------
  // Parameters
  // -------------------------------------------------------------------
  parameter         CLK_0_PERIOD        = 10;
  parameter         CLK_1_PERIOD        = 20;
  parameter         NUM_TEST_PULSES     = 2;



  // -------------------------------------------------------------------
  // Signals
  // -------------------------------------------------------------------

  // -----------------------------------------------------------
  // DUT I/O Signals
  // -----------------------------------------------------------

  // Input Pulse Signals
  logic             i_clk;
  logic             i_rst_n;
  logic             i_pulse;

  // Output Pulse Signals
  logic             o_clk;
  logic             p_rst_n;
  logic             o_pulse;


  // -----------------------------------------------------------
  // Testbench Signals
  // -----------------------------------------------------------
  
  // Clock/Reset Signal
  logic             clk_0;
  logic             clk_1;
  logic             clk_sel;
  logic             rst_n;

  // Loop Variables
  integer           lvar;
  
  

  // -------------------------------------------------------------------
  // Instantiations
  // -------------------------------------------------------------------

  // -----------------------------------------------------------
  // Design Under Test (DUT)
  // -----------------------------------------------------------

  // Pulse Synchronizer
  pulse_sync dut (

    // Input Pulse Signals
    .i_clk          ( i_clk   ),
    .i_rst_n        ( i_rst_n ),
    .i_pulse        ( i_pulse ),

    // Output Pulse Signals
    .o_clk          ( o_clk   ),
    .o_rst_n        ( o_rst_n ),
    .o_pulse        ( o_pulse )
  );



  // -------------------------------------------------------------------
  // Clock/Reset Generation
  // -------------------------------------------------------------------

  // -----------------------------------------------------------
  // Clock Generation
  // -----------------------------------------------------------
  
  initial clk_0 = 1'b0;
  
  always  clk_0 = #(CLK_0_PERIOD/2) ~clk_0;

  initial clk_1 = 1'b0;
  
  always  clk_1 = #(CLK_1_PERIOD/2) ~clk_1;

  assign  i_clk = clk_sel ? clk_1 : clk_0;
  assign  o_clk = clk_sel ? clk_0 : clk_1;
  

  // -----------------------------------------------------------
  // Resetting Signals
  // -----------------------------------------------------------
  
  
  initial
  begin
  
    // Initializing Reset Signal
    rst_n  =  1'b1;
    
    #10;
        
    // Asserting Reset
    $display ( ">>\n>> INFO: Resetting DUT..." );
    rst_n  =  1'b0;

    #( ( CLK_0_PERIOD + CLK_1_PERIOD ) * 5 );
    
    // De-asserting Reset
    rst_n  =  1'b1; 
  end

  assign i_rst_n = rst_n;
  assign o_rst_n = rst_n;
  


  // -------------------------------------------------------------------
  // Test Sequence
  // -------------------------------------------------------------------
  initial
  begin

    // Time format
    $timeformat( -9, 1, " ns", 10 ); 

  
    // Initializing DUT Inputs
    i_pulse  = 0;
    clk_sel  = 0;
    

    // Waiting for Reset to be de-asserted
    @( posedge rst_n );
    
    
    for ( lvar = 0; lvar < NUM_TEST_PULSES; lvar = lvar + 1 )
    begin    
      // Generating Input Pluse
      @( negedge i_clk );
      @( negedge i_clk );
      i_pulse  = 1;   
      @( negedge i_clk );
      i_pulse  = 0;
    

      // Waiting for Synchronizer Output
      wait ( o_pulse );
      @( negedge o_clk );
      @( negedge o_clk );
    end


    // Swicth Clocks
    clk_sel  = 1;
        
    
    for ( lvar = 0; lvar < NUM_TEST_PULSES; lvar = lvar + 1 )
    begin    
      // Generating Input Pluse
      @( negedge i_clk );
      @( negedge i_clk );
      i_pulse  = 1;   
      @( negedge i_clk );
      i_pulse  = 0;
    

      // Waiting for Synchronizer Output
      wait ( o_pulse );
      @( negedge o_clk );
      @( negedge o_clk );
    end

    
    // Ending Simulation
    #( ( CLK_0_PERIOD + CLK_1_PERIOD ) * 5 );
    $finish;

  end



  // -------------------------------------------------------------------
  // Dump File Generation
  // -------------------------------------------------------------------
  initial
  begin
    $dumpfile( "pulse_sync.vcd" );
    $dumpvars( 0, pulse_sync_tb );
  end


endmodule
