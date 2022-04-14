// ==============================================================================
//
//  File Name       :  sync_fifo_tb.v
//  Description     :  This file contains testbench for a Synchornous FIFO.
// 
// ==============================================================================

`timescale 1ns/1ps

module sync_fifo_tb;

  // -------------------------------------------------------------------
  // Parameters
  // -------------------------------------------------------------------
  parameter                     FIFO_CLK_PERIOD = 10;
  parameter                     FIFO_WIDTH      = 8;
  parameter                     FIFO_DEPTH      = 8;



  // -------------------------------------------------------------------
  // Signals
  // -------------------------------------------------------------------

  // -----------------------------------------------------------
  // DUT I/O Signals
  // -----------------------------------------------------------

  // Clock/Reset Signals
  logic                         fifo_clk;
  logic                         fifo_rst;

  // FIFO Write Port
  logic                         fifo_wen;
  logic   [ FIFO_WIDTH-1 : 0 ]  fifo_wdata;
  logic                         fifo_full;

  // FIFO Read Port
  logic                         fifo_ren;
  logic   [ FIFO_WIDTH-1 : 0 ]  fifo_rdata;
  logic                         fifo_empty;


  // -----------------------------------------------------------
  // Testbench Signals
  // -----------------------------------------------------------

  // Control Signals
  logic                         stop_sim;

  // Counters
  logic             [ 31 : 0 ]  fifo_wcnt;
  logic             [ 31 : 0 ]  fifo_rcnt;
  integer                       err_cnt;
  
  

  // -------------------------------------------------------------------
  // Instantiations
  // -------------------------------------------------------------------

  // -----------------------------------------------------------
  // Design Under Test (DUT)
  // -----------------------------------------------------------

  // FIFO Instance
  sync_fifo # (

    // Parametres
    .FIFO_WIDTH                 ( FIFO_WIDTH ),
    .FIFO_DEPTH                 ( FIFO_DEPTH )

  ) dut (

    // Clock/Reset Signals
    .fifo_clk                   ( fifo_clk   ),
    .fifo_rst                   ( fifo_rst   ),

    // FIFO Write Port
    .fifo_wen                   ( fifo_wen   ),
    .fifo_wdata                 ( fifo_wdata ),
    .fifo_full                  ( fifo_full  ),

    // FIFO Read Port
    .fifo_ren                   ( fifo_ren   ),
    .fifo_rdata                 ( fifo_rdata ),
    .fifo_empty                 ( fifo_empty )
  );



  // -------------------------------------------------------------------
  // Clock/Reset Generation
  // -------------------------------------------------------------------

  // -----------------------------------------------------------
  // Clock Generation
  // -----------------------------------------------------------
  
  initial fifo_clk = 1'b0;
  
  always  fifo_clk = #(FIFO_CLK_PERIOD/2) ~fifo_clk;


  // -----------------------------------------------------------
  // Resetting Signals
  // -----------------------------------------------------------
  
  initial
  begin
  
    // Initializing Reset Signal
    fifo_rst    =  1'b0;
    
    @( negedge fifo_clk );
    
    // Asserting Reset
    $display ( ">>\n>> INFO: Resetting DUT..." );
    fifo_rst    =  1'b1;
    
    // Resetting DUT I/O Signals
    fifo_wen    <= 1'b0;
    fifo_wdata  <=  'h0;
    fifo_ren    <= 1'b0;  
    
    repeat ( 5 ) @( negedge fifo_clk );

    // De-asserting Reset
    fifo_rst    =  1'b0;
  end



  // -------------------------------------------------------------------
  // Test Sequence
  // -------------------------------------------------------------------
  initial
  begin

    $timeformat( -9, 1, " ns", 10 ); 

    err_cnt  = 0;
    stop_sim = 1'b0;


    // Waiting for Reset to be de-asserted
    @( negedge fifo_rst );
    
    repeat ( 10 ) @( negedge fifo_clk );


    fork

      // Writing Data into FIFO
      begin

        fifo_wcnt = 0;
        
        while ( !stop_sim )
        begin
          @( negedge fifo_clk );
          fifo_wen   = ~fifo_full | ( fifo_full & fifo_ren );
          fifo_wdata = fifo_wcnt[ FIFO_WIDTH-1 : 0 ];
          fifo_wcnt  = fifo_wen ? fifo_wcnt + 1 : fifo_wcnt;
        end

        @( negedge fifo_clk );
        fifo_wen = 1'b0;

      end


      // Reading Data from FIFO
      begin

        fifo_rcnt = 0;

        repeat ( 10 ) @( negedge fifo_clk );

        while ( !(stop_sim && fifo_empty) )
        begin
          @( negedge fifo_clk );
          fifo_ren  = ~fifo_empty | ( fifo_empty & fifo_wen );

          if ( fifo_rdata == fifo_rcnt[ FIFO_WIDTH-1 : 0 ] )
            $display ( ">>\n>> INFO: Data Read from FIFO @ %0t: 0x%h", $time, fifo_rdata );
          else if ( !fifo_empty )
          begin
            $display ( ">>\n>> ERROR: Data Mismatch @ %0t...", $time );
            $display ( ">> ERROR: FIFO Read Data = 0x%h; Expected Data = 0x%h", 
                        fifo_rdata, fifo_rcnt[ FIFO_WIDTH-1 : 0 ] );
            err_cnt = err_cnt + 1;
          end
          
          fifo_rcnt = fifo_ren ? fifo_rcnt + 1 : fifo_rcnt;
        end

        @( negedge fifo_clk );
        fifo_ren   = 1'b0;

      end

	
      // Ending Simulation 
      begin
        $display ( ">>\n>> INFO: Ending Simulation..." );
        repeat ( 100 ) @( negedge fifo_clk );
        stop_sim = 1'b1;
        repeat (  10 ) @( negedge fifo_clk );

        if ( err_cnt > 0 )
          $display ( ">>\n>> RESULT: Test Failed with %0d Errors...", err_cnt );
        else
          $display ( ">>\n>> RESULT: Test Passed..." );

        $finish;      
      end

    join


  end



  // -------------------------------------------------------------------
  // Dump File Generation
  // -------------------------------------------------------------------
  `ifdef DUMP_VCD
  initial
  begin
    $dumpfile( "sync_fifo.vcd" );
    $dumpvars( 0, sync_fifo_tb );
  end
  `endif

endmodule
