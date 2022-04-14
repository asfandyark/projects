// ==============================================================================
//
//  File Name       :  async_fifo.sv
//  Description     :  This file contains an Asynchornous FIFO.
// 
// ==============================================================================

`timescale 1ns/1ps

module async_fifo #(
  parameter                             FIFO_WIDTH   = 8,
  parameter                             FIFO_DEPTH   = 8,
  parameter                             FIFO_AWIDTH  = $clog2(FIFO_DEPTH),
  parameter                             READ_FALL_THROUH  = "TRUE",
  parameter                             EARLY_FLAG_THRESH = 1
) 
(
  // FIFO Write Port
  input   logic                         fifo_wclk,
  input   logic                         fifo_wrst,
  input   logic                         fifo_wen,
  input   logic   [ FIFO_WIDTH-1 : 0 ]  fifo_wdata,
  output  logic                         fifo_full,
  output  logic                         fifo_almost_full,
  output  logic   [ FIFO_AWIDTH  : 0 ]  fifo_wdata_count,

  // FIFO Read Port
  input   logic                         fifo_rclk,
  input   logic                         fifo_rrst,
  input   logic                         fifo_ren,
  output  logic   [ FIFO_WIDTH-1 : 0 ]  fifo_rdata,
  output  logic                         fifo_empty,
  output  logic                         fifo_almost_empty,
  output  logic   [ FIFO_AWIDTH  : 0 ]  fifo_rdata_count  
);



  // -------------------------------------------------------------------
  // Local Parameters
  // -------------------------------------------------------------------



  // -------------------------------------------------------------------
  // Local Signals
  // -------------------------------------------------------------------

  // FIFO Memory
  logic  [  FIFO_WIDTH-1 : 0 ]  fifo_mem  [ 0 : FIFO_DEPTH-1 ];

  // FIFO Write Signals
  logic                         fifo_write;
  logic  [ FIFO_AWIDTH   : 0 ]  fifo_wptr;
  logic  [ FIFO_AWIDTH-1 : 0 ]  fifo_waddr;
  logic  [ FIFO_AWIDTH   : 0 ]  fifo_wptr_gray_q0;
  logic  [ FIFO_AWIDTH   : 0 ]  fifo_wptr_gray_q1;
  logic  [ FIFO_AWIDTH   : 0 ]  fifo_wptr_sync;

  // FIFO Read Signals
  logic                         fifo_read;
  logic  [ FIFO_AWIDTH   : 0 ]  fifo_rptr;
  logic  [ FIFO_AWIDTH-1 : 0 ]  fifo_raddr;
  logic  [ FIFO_AWIDTH   : 0 ]  fifo_rptr_gray_q0;
  logic  [ FIFO_AWIDTH   : 0 ]  fifo_rptr_gray_q1;
  logic  [ FIFO_AWIDTH   : 0 ]  fifo_rptr_sync;



  // -------------------------------------------------------------------
  // Functions
  // -------------------------------------------------------------------
  
  // -----------------------------------------------------------
  // Function to convert Binary to Gray
  // -----------------------------------------------------------
  function [ FIFO_AWIDTH : 0 ] b2g;
    input  [ FIFO_AWIDTH : 0 ] bnum;
    integer fvar;
  begin
    b2g = bnum ^ ( bnum>>1 );
  end
  endfunction
  
  
  // -----------------------------------------------------------
  // Function to convert Gray to Binary
  // -----------------------------------------------------------
  function [ FIFO_AWIDTH : 0 ] g2b;
    input  [ FIFO_AWIDTH : 0 ] gnum;
    integer fvar;
  begin
    g2b[ FIFO_AWIDTH ] = gnum[ FIFO_AWIDTH ]; 
    for ( fvar = FIFO_AWIDTH-1; fvar >= 0; fvar = fvar-1 )
      g2b[ fvar ] = gnum[ fvar ] ^ g2b[ fvar+1 ];
  end
  endfunction



  // -------------------------------------------------------------------
  // Module Logic
  // -------------------------------------------------------------------

  // -----------------------------------------------------------
  // FIFO Write Operation
  // -----------------------------------------------------------

  // FIFO Write Pointer
  assign fifo_write = fifo_wen & ~fifo_full;
  
  always @( posedge fifo_wclk or posedge fifo_wrst )
  begin
    if ( fifo_wrst )
      fifo_wptr <= 'h0;
    else
      fifo_wptr <= fifo_write ? fifo_wptr + 'h1 : fifo_wptr;
  end 

  assign fifo_waddr = fifo_wptr[ FIFO_AWIDTH-1 : 0 ];
  
  
  // FIFO Write
  always @ ( posedge fifo_wclk)
  begin
    if ( fifo_write )
      fifo_mem[ fifo_waddr ] <= fifo_wdata;
  end


  // FIFO Read Pointer Synchronization
  always @ ( posedge fifo_wclk or posedge fifo_wrst )
  begin
    if ( fifo_wrst )
    begin
      fifo_rptr_gray_q0 <= 'h0;
      fifo_rptr_gray_q1 <= 'h0;      
    end
    else
    begin
      fifo_rptr_gray_q0 <= b2g( fifo_rptr );
      fifo_rptr_gray_q1 <= fifo_rptr_gray_q0;      
    end
  end
  
  assign fifo_rptr_sync = g2b( fifo_rptr_gray_q1 );
  

  // FIFO Write Status Signals
  assign fifo_full = ( fifo_waddr == fifo_rptr_sync[ FIFO_AWIDTH-1 : 0 ] ) &&
                     ( fifo_wptr[ FIFO_AWIDTH ] ^ fifo_rptr_sync[ FIFO_AWIDTH ] );

  assign fifo_almost_full = ( fifo_wdata_count >=  FIFO_DEPTH-EARLY_FLAG_THRESH );

  assign fifo_wdata_count = fifo_wptr - fifo_rptr_sync;



  // -----------------------------------------------------------
  // FIFO Read Operation
  // -----------------------------------------------------------
  
  // FIFO Read Pointer
   assign fifo_read = fifo_ren & ~fifo_empty;

  always @( posedge fifo_rclk or posedge fifo_rrst )
  begin
    if ( fifo_rrst )
      fifo_rptr <= 'h0;
    else
      fifo_rptr <= fifo_read ? fifo_rptr + 'h1 : fifo_rptr;
  end

  assign fifo_raddr = fifo_rptr[ FIFO_AWIDTH-1 : 0 ];


  // FIFO Read Data
  generate
    if ( READ_FALL_THROUH == "TRUE" )
      assign fifo_rdata = fifo_mem[ fifo_raddr ];
    else
      always @( posedge fifo_rclk)
        if ( fifo_read )
          fifo_rdata <= fifo_mem[ fifo_raddr ];
  endgenerate 


  // FIFO Write Pointer Synchronization
  always @ ( posedge fifo_rclk or posedge fifo_rrst )
  begin
    if ( fifo_rrst )
    begin
      fifo_wptr_gray_q0 <= 'h0;
      fifo_wptr_gray_q1 <= 'h0;      
    end
    else
    begin
      fifo_wptr_gray_q0 <= b2g( fifo_wptr );
      fifo_wptr_gray_q1 <= fifo_wptr_gray_q0;      
    end
  end
  
  assign fifo_wptr_sync = g2b( fifo_wptr_gray_q1 );

   
  // FIFO Read Status Signals
  assign fifo_empty = ( fifo_wptr_sync == fifo_rptr );

  assign fifo_almost_empty = ( fifo_rdata_count <=  EARLY_FLAG_THRESH);

  assign fifo_rdata_count = fifo_wptr_sync - fifo_rptr;


endmodule
