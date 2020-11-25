// ==============================================================================
//
//  File Name       :  sync_fifo.sv
//  Description     :  This file contains a Synchornous FIFO.
// 
// ==============================================================================

`timescale 1ns/1ps

module sync_fifo #(
  parameter                             FIFO_WIDTH = 8,
  parameter                             FIFO_DEPTH = 8 
) 
(
  // Clock/Reset Signals
  input   logic                         fifo_clk,
  input   logic                         fifo_rst_n,
  
  // FIFO Write Port
  input   logic                         fifo_wen,
  input   logic   [ FIFO_WIDTH-1 : 0 ]  fifo_wdata,
  output  logic                         fifo_full,

  // FIFO Read Port
  input   logic                         fifo_ren,
  output  logic   [ FIFO_WIDTH-1 : 0 ]  fifo_rdata,
  output  logic                         fifo_empty
);



  // -------------------------------------------------------------------
  // Local Parameters
  // -------------------------------------------------------------------

  // FIFO Address Width
  localparam                    FIFO_AWIDTH = $clog2(FIFO_DEPTH);



  // -------------------------------------------------------------------
  // Local Signals
  // -------------------------------------------------------------------

  // FIFO Memory
  logic  [  FIFO_WIDTH-1 : 0 ]  fifo_mem  [ 0 : FIFO_DEPTH-1 ];


  // FIFO Write Signals
  logic  [   FIFO_AWIDTH : 0 ]  fifo_wptr;
  logic  [   FIFO_AWIDTH : 0 ]  fifo_waddr;
  logic                         fifo_write;


  // FIFO Read Signals
  logic  [   FIFO_AWIDTH : 0 ]  fifo_rptr;
  logic  [ FIFO_AWIDTH-1 : 0 ]  fifo_raddr;
  logic                         fifo_read;

  // Integers
  integer                       lvar;
  


  // -------------------------------------------------------------------
  // Module Logic
  // -------------------------------------------------------------------

  // -----------------------------------------------------------
  // FIFO Write Operation
  // -----------------------------------------------------------

  // FIFO Write Pointer
  assign fifo_write = fifo_wen & ( fifo_full ? fifo_ren : 1'b1 );  
  
  always @( posedge fifo_clk or negedge fifo_rst_n )
  begin
    if ( !fifo_rst_n )
      fifo_wptr <= 'h0;
    else
      fifo_wptr <= fifo_write ? fifo_wptr + 'h1 : fifo_wptr;
  end 

  assign fifo_waddr = fifo_wptr[ FIFO_AWIDTH-1 : 0 ];
  
  
  // FIFO Write
  always @ ( posedge fifo_clk or negedge fifo_rst_n )
  begin
    if ( !fifo_rst_n )
      for ( lvar = 0; lvar < FIFO_DEPTH ; lvar++)
        fifo_mem[ lvar ] <= 'h0;
    else
      if ( fifo_write )
        fifo_mem[ fifo_waddr ] <= fifo_wdata;
  end

  
  // FIFO Full Signals
  assign fifo_full = ( fifo_waddr == fifo_raddr ) &&
                     ( fifo_wptr[ FIFO_AWIDTH ] ^ fifo_rptr[ FIFO_AWIDTH ] );


  // -----------------------------------------------------------
  // FIFO Read Operation
  // -----------------------------------------------------------
  
  // FIFO Read Pointer
  assign fifo_read = fifo_ren & ( fifo_empty ? fifo_wen : 1'b1 );  
  
  always @( posedge fifo_clk or negedge fifo_rst_n )
  begin
    if ( !fifo_rst_n )
      fifo_rptr <= 'h0;
    else
      fifo_rptr <= fifo_read ? fifo_rptr + 'h1 : fifo_rptr;
  end

  assign fifo_raddr = fifo_rptr[ FIFO_AWIDTH-1 : 0 ];


  // FIFO Read Data
  assign fifo_rdata = fifo_mem[ fifo_raddr ];

  
  // FIFO Empty Signals
  assign fifo_empty = ( fifo_wptr == fifo_rptr );


endmodule
