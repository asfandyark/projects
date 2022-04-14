// ==============================================================================
//
//  File Name       :  stack.sv
//  Description     :  This file contains a Stack Module.
// 
// ==============================================================================

module stack #(
  parameter                 p_width   =  8,
  parameter                 p_depth   =  8,
  parameter                 p_awidth  =  $clog2(p_depth),
  parameter                 p_early_flag_thresh  =  4
) 
(
  // Clock/Reset Signals
  input                     clock,
  input                     reset,
  
  // Stack Write Port
  input                     wr_req,
  input     [p_width-1:0]   wr_data,
  output                    full,
  output                    almost_full,
  
  // Stack Read Port
  input                     rd_req,
  output    [p_width-1:0]   rd_data,
  output                    empty,
  output                    almost_empty,

  // Misc Signals
  output    [p_awidth :0]   data_count
);


  // -------------------------------------------------------------------
  // Stack Logic
  // -------------------------------------------------------------------
  
  // Local Signals
  reg   [p_width-1:0]  mem  [0:p_depth-1];
  reg   [p_awidth: 0]  stack_ptr  =  0;
  wire                 wr_en;
  wire                 rd_en;
  reg                  rd_sel  =  0;


  // Stack Write/Read Signals
  assign  wr_en  =  wr_req & ~full;  
  assign  rd_en  =  rd_req & ~empty;  


  // Stack Pointer
  always @( posedge clock)  begin
    if ( reset )
      stack_ptr  <=  0;
    else  begin
      case ( {rd_en, wr_en} )
        2'b01   :  stack_ptr  <=  stack_ptr + 1;
        2'b10   :  stack_ptr  <=  stack_ptr - 1;
        default :  stack_ptr  <=  stack_ptr;   
      endcase
    end
  end 


  // Stack Write Data
  always @( posedge clock )  begin
    if ( wr_en )
      mem[stack_ptr]  <=  wr_data;
  end


  // Stack Read Data
  always @( posedge clock )  begin
    if ( reset )
      rd_sel  <=  1'b0;
    else 
      rd_sel  <=  wr_en & rd_en;
  end 
  
  assign  rd_data  =  rd_sel ? mem[stack_ptr] : mem[stack_ptr-1];  


  // Stack Status Signals
  assign  full          =  ( stack_ptr == p_depth );
  assign  almost_full   =  ( stack_ptr >= p_depth-p_early_flag_thresh );

  assign  empty         =  ( stack_ptr == 0 );
  assign  almost_empty  =  ( stack_ptr <= p_early_flag_thresh );

  assign  data_count    =  stack_ptr;


endmodule
