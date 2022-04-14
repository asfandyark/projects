// ==============================================================================
//
//  File Name       :  stack_tb.v
//  Description     :  This file contains testbench for a Stack Module.
// 
// ==============================================================================

`timescale 1ns/1ps

module stack_tb;

  // -------------------------------------------------------------------
  // Parameters
  // -------------------------------------------------------------------
  parameter                     STACK_CLK_PERIOD = 10;
  parameter                     STACK_WIDTH      = 32;
  parameter                     STACK_DEPTH      = 32;



  // -------------------------------------------------------------------
  // Signals
  // -------------------------------------------------------------------

  // -----------------------------------------------------------
  // DUT I/O Signals
  // -----------------------------------------------------------

  // Clock/Reset Signals
  logic                         clock;
  logic                         reset;

  // Stack Write Port
  logic                         stack_wr_en;
  logic   [STACK_WIDTH-1:0]     stack_wr_data;
  logic                         stack_full;

  // Stack Read Port
  logic                         stack_rd_en;
  logic   [STACK_WIDTH-1:0]     stack_rd_data;
  logic                         stack_empty;


  // -----------------------------------------------------------
  // Testbench Signals
  // -----------------------------------------------------------

  // Control Signals
  logic                         stop_sim;

  // Counters
  logic                 [31:0]  data_count;
  integer                       err_cnt;
  
  // Misc Signals
  logic   [STACK_WIDTH-1:0]     stack_rdwr_en;
  logic   [STACK_WIDTH-1:0]     exp_data;
  logic   [STACK_WIDTH-1:0]     saved_data;
  
  

  // -------------------------------------------------------------------
  // Instantiations
  // -------------------------------------------------------------------

  // -----------------------------------------------------------
  // Design Under Test (DUT)
  // -----------------------------------------------------------

  // Stack Instance
  stack # (

    // Parametres
    .p_width        ( STACK_WIDTH   ),
    .p_depth        ( STACK_DEPTH   ),
    .p_early_flag_thresh ( 4       )
    

  ) dut (

    // Clock/Reset Signals
    .clock          ( clock        ),
    .reset          ( reset        ),

    // Stack Write Port
    .wr_req         ( stack_wr_en   ),
    .wr_data        ( stack_wr_data ),
    .full           ( stack_full    ),

    // Stack Read Port
    .rd_req         ( stack_rd_en   ),
    .rd_data        ( stack_rd_data ),
    .empty          ( stack_empty   )
  );



  // -------------------------------------------------------------------
  // Clock/Reset Generation
  // -------------------------------------------------------------------

  // -----------------------------------------------------------
  // Clock Generation
  // -----------------------------------------------------------
  
  initial clock = 1'b0;
  
  always  clock = #(STACK_CLK_PERIOD/2) ~clock;


  // -----------------------------------------------------------
  // Resetting Signals
  // -----------------------------------------------------------
  
  initial
  begin
  
    // Initializing Reset Signal
    reset    =  1'b0;
    
    @( posedge clock ); #1;
    
    // Asserting Reset
    $display ( ">>\n>> INFO: Resetting DUT..." );
    reset    =  1'b1;
    
    // Resetting DUT I/O Signals
    stack_wr_en    <= 1'b0;
    stack_wr_data  <=  'h0;
    stack_rd_en    <= 1'b0;  
    
    repeat ( 5 ) @( posedge clock );

    // De-asserting Reset
    reset    =  1'b0;
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
    @( negedge reset );
    
    repeat ( 10 ) @( posedge clock );


    fork

      // Writing Data into Stack
      begin

        data_count = 0;
        
        while ( !stop_sim )
        begin
          @( posedge clock ); #1;
          stack_wr_en   = ~stack_full | ( stack_full & stack_rd_en );
          stack_wr_data = data_count[STACK_WIDTH-1:0];
          data_count    = stack_wr_en ? data_count + 1 : data_count;
        end

        @( posedge clock ); #1;
        stack_wr_en = 1'b0;

      end


      // Reading Data from Stack
      begin

        repeat ( 40 ) @( posedge clock );

        while ( !(stop_sim && stack_empty) )
        begin
          @( posedge clock );
          if ( !(stack_wr_en && stack_rd_en) && stack_rdwr_en)
            exp_data = saved_data;
          else
            case ( {stack_rd_en, stack_wr_en} )
              2'b00  :  exp_data  =  stack_wr_data - 1;
              2'b01  :  exp_data  =  stack_wr_data - 1;  
              2'b10  :  exp_data  =  stack_rd_data - 1;
              2'b11  :  exp_data  =  stack_wr_data;   
            endcase

          if ( stack_wr_en && stack_rd_en && !stack_rdwr_en)
            saved_data = stack_rd_data - 1;

          stack_rdwr_en  = stack_wr_en & stack_rd_en;
          
          #1;
          stack_rd_en = ~stack_empty | ( stack_empty & stack_wr_en );

          @( negedge clock );
          if ( stack_rd_en && (stack_rd_data == exp_data) )
            $display ( ">>\n>> INFO: Data Read from Stack @ %0t: 0x%h", $time, stack_rd_data );
          else if ( stack_rd_en && !stack_empty )
          begin
            $display ( ">>\n>> ERROR: Data Mismatch @ %0t...", $time );
            $display ( ">> ERROR: Stack Read Data = 0x%h; Expected Data = 0x%h", 
                        stack_rd_data, exp_data );
            err_cnt = err_cnt + 1;
          end
          
        end

        @( posedge clock ); #1;
        stack_rd_en   = 1'b0;

      end


      // Ending Simulation 
      begin
        $display ( ">>\n>> INFO: Ending Simulation..." );
        repeat ( 100 ) @( posedge clock );
        stop_sim = 1'b1;
        repeat (  10 ) @( posedge clock );

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
    $dumpvars( 0, sync_stack_tb );
  end
  `endif

endmodule
