// ==============================================================================
//
//  File Name       :  async_fifo_tb.sv
//  Description     :  This file contains testbench for an Asynchornous FIFO.
// 
// ==============================================================================

`timescale 1ns/1ps

module async_fifo_tb;

  // -------------------------------------------------------------------
  // Parameters
  // -------------------------------------------------------------------
  parameter                     FIFO_WCLK_PERIOD = 25;
  parameter                     FIFO_RCLK_PERIOD = 10;
  parameter                     FIFO_WIDTH       = 8;
  parameter                     FIFO_DEPTH       = 8;



  // -------------------------------------------------------------------
  // Signals
  // -------------------------------------------------------------------

  // -----------------------------------------------------------
  // DUT I/O Signals
  // -----------------------------------------------------------

  // Reset Signal
  logic                         fifo_rst;

  // FIFO Write Port
  logic                         fifo_wclk;
  logic                         fifo_wen;
  logic   [ FIFO_WIDTH-1 : 0 ]  fifo_wdata;
  logic                         fifo_full;

  // FIFO Read Port
  logic                         fifo_rclk;
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
  async_fifo # (

    // Parametres
    .FIFO_WIDTH                 ( FIFO_WIDTH ),
    .FIFO_DEPTH                 ( FIFO_DEPTH )

  ) dut (

    // FIFO Write Port
    .fifo_wclk                  ( fifo_wclk  ),
    .fifo_wrst                  ( fifo_rst   ),
    .fifo_wen                   ( fifo_wen   ),
    .fifo_wdata                 ( fifo_wdata ),
    .fifo_full                  ( fifo_full  ),

    // FIFO Read Port
    .fifo_rclk                  ( fifo_rclk  ),
    .fifo_rrst                  ( fifo_rst   ),    
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
  
  initial fifo_wclk = 1'b0;
  always  fifo_wclk = #(FIFO_WCLK_PERIOD/2) ~fifo_wclk;

  initial fifo_rclk = 1'b0;
  always  fifo_rclk = #(FIFO_RCLK_PERIOD/2) ~fifo_rclk;


  // -----------------------------------------------------------
  // Resetting Signals
  // -----------------------------------------------------------
  
  initial
  begin
  
    // Initializing Reset Signal
    fifo_rst    =  1'b0;
    
    #10;

    // Asserting Reset
    $display ( ">>\n>> INFO: Resetting DUT..." );
    fifo_rst    =  1'b1;
    
    // Resetting DUT I/O Signals
    fifo_wen    <= 1'b0;
    fifo_wdata  <=  'h0;
    fifo_ren    <= 1'b0;  
    
    #100;

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
    
    #100;


    fork

      // Writing Data into FIFO
      begin

        fifo_wcnt = 0;
        
        while ( !stop_sim )
        begin
          @( negedge fifo_wclk );
          fifo_wen   = ~fifo_full;
          fifo_wdata = fifo_wcnt[ FIFO_WIDTH-1 : 0 ];
          fifo_wcnt  = fifo_wen ? fifo_wcnt + 1 : fifo_wcnt;
        end

        @( negedge fifo_wclk );
        fifo_wen = 1'b0;

      end


      // Reading Data from FIFO
      begin

        fifo_rcnt = 0;

        repeat ( 10 ) @( negedge fifo_rclk );

        while ( !(stop_sim && fifo_empty) )
        begin
          @( negedge fifo_rclk );
          fifo_ren  = ~fifo_empty;

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

        @( negedge fifo_rclk );
        fifo_ren   = 1'b0;

      end


      // Ending Simulation 
      begin
        $display ( ">>\n>> INFO: Ending Simulation..." );
        #1000;
        stop_sim = 1'b1;
        
        #100;
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
    $dumpfile( "async_fifo.vcd" );
    $dumpvars( 0, async_fifo_tb );
  end
  `endif

endmodule
