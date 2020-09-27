// ==============================================================================
//
//  File Name       :  pulse_sync.sv
//  Description     :  This file contains a Pulse Synchronizer.
// 
// ==============================================================================

`timescale 1ns/1ps

module pulse_sync (

  // Input Pulse Signals
  input   logic     i_clk,
  input   logic     i_rst_n,
  input   logic     i_pulse,

  // Output Pulse Signals
  input   logic     o_clk,
  input   logic     o_rst_n,
  output  logic     o_pulse
);



  // -------------------------------------------------------------------
  // Local Signals
  // -------------------------------------------------------------------

  // Synchronizer Signals
  logic             i_pulse_q;
  logic   [ 2:0 ]   i_pulse_q_sync;  
  


  // -------------------------------------------------------------------
  // Module Logic
  // -------------------------------------------------------------------

  // Detecting Input Pulse  
  // This FF toggles whenever a pulse is detected
  always @( posedge i_clk or negedge i_rst_n )
  begin
    if ( !i_rst_n )
      i_pulse_q <= 1'b0;
    else
      i_pulse_q <= i_pulse_q ^ i_pulse;
  end 


  // Synchronizing Detected Input Pulse
  always @( posedge o_clk or negedge o_rst_n )
  begin
    if ( !o_rst_n )
      i_pulse_q_sync <= 3'b0;
    else
      i_pulse_q_sync <= { i_pulse_q_sync[ 1:0 ] , i_pulse_q };
  end 
  
  
  // Ouput Pulse
  assign o_pulse = ^i_pulse_q_sync[ 2:1 ];


endmodule
