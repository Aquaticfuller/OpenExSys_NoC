// this module records many perforance counters
module performance_monitor
import rvh_noc_pkg::*;
#(
  parameter INPUT_PORT_NUM  = 5,
  parameter OUTPUT_PORT_NUM = 5,
  parameter LOCAL_PORT_NUM  = INPUT_PORT_NUM-4,

  parameter VC_NUM_INPUT_N = 1+LOCAL_PORT_NUM,
  parameter VC_NUM_INPUT_S = 1+LOCAL_PORT_NUM,
  parameter VC_NUM_INPUT_E = 3+LOCAL_PORT_NUM,
  parameter VC_NUM_INPUT_W = 3+LOCAL_PORT_NUM,
  parameter VC_NUM_INPUT_L = 4,

  parameter VC_DEPTH_INPUT_N = 2,
  parameter VC_DEPTH_INPUT_S = 2,
  parameter VC_DEPTH_INPUT_E = 2,
  parameter VC_DEPTH_INPUT_W = 2,
  parameter VC_DEPTH_INPUT_L = 2,
  parameter VC_DEPTH_INPUT_N_COUNTER_W = $clog2(VC_DEPTH_INPUT_N + 1),
  parameter VC_DEPTH_INPUT_S_COUNTER_W = $clog2(VC_DEPTH_INPUT_S + 1),
  parameter VC_DEPTH_INPUT_E_COUNTER_W = $clog2(VC_DEPTH_INPUT_E + 1),
  parameter VC_DEPTH_INPUT_W_COUNTER_W = $clog2(VC_DEPTH_INPUT_W + 1),
  parameter VC_DEPTH_INPUT_L_COUNTER_W = $clog2(VC_DEPTH_INPUT_L + 1)

)
(
  // 1. sa global util
    // input from sa local
  input  logic  [INPUT_PORT_NUM-1:0]  sa_local_vld_i,
    // input from sa global
  input  logic  [INPUT_PORT_NUM-1:0]  sa_global_inport_read_vld_i,

  // 2. outport credit util
  input  logic [VC_NUM_INPUT_N-1:0][VC_DEPTH_INPUT_N_COUNTER_W-1:0] vc_credit_counter_toN_i,
  input  logic [VC_NUM_INPUT_S-1:0][VC_DEPTH_INPUT_S_COUNTER_W-1:0] vc_credit_counter_toS_i,
  input  logic [VC_NUM_INPUT_E-1:0][VC_DEPTH_INPUT_E_COUNTER_W-1:0] vc_credit_counter_toE_i,
  input  logic [VC_NUM_INPUT_W-1:0][VC_DEPTH_INPUT_W_COUNTER_W-1:0] vc_credit_counter_toW_i,
`ifdef HAVE_LOCAL_PORT
  input  logic [LOCAL_PORT_NUM-1:0][VC_NUM_INPUT_L-1:0][VC_DEPTH_INPUT_L_COUNTER_W-1:0] vc_credit_counter_toL_i,
`endif

  // router addr
  input  logic [NodeID_X_Width-1:0] node_id_x_ths_hop_i,
  input  logic [NodeID_Y_Width-1:0] node_id_y_ths_hop_i,

  input  logic clk,
  input  logic rstn
);

genvar i;

// global sa efficiency
logic [INPUT_PORT_NUM-1:0][64-1:0] sa_local_vld_counter_d, sa_local_vld_counter_q;
logic [INPUT_PORT_NUM-1:0]         sa_local_vld_counter_ena;
logic [INPUT_PORT_NUM-1:0][64-1:0] sa_global_inport_read_vld_counter_d, sa_global_inport_read_vld_counter_q;
logic [INPUT_PORT_NUM-1:0]         sa_global_inport_read_vld_counter_ena;

always_comb begin
  sa_local_vld_counter_d                = sa_local_vld_counter_q;
  sa_local_vld_counter_ena              = '0;
  sa_global_inport_read_vld_counter_d   = sa_global_inport_read_vld_counter_q;
  sa_global_inport_read_vld_counter_ena = '0;

  for(int i = 0; i < INPUT_PORT_NUM; i++) begin
    if(sa_local_vld_i[i]) begin
      sa_local_vld_counter_d[i]   = sa_local_vld_counter_d[i] + 1;
      sa_local_vld_counter_ena[i] = 1'b1;
    end
    if(sa_global_inport_read_vld_i[i]) begin
      sa_global_inport_read_vld_counter_d   [i] = sa_global_inport_read_vld_counter_d[i] + 1;
      sa_global_inport_read_vld_counter_ena [i] = 1'b1;
    end
  end
end

generate
  for(i = 0; i < INPUT_PORT_NUM; i++) begin
    std_dffre
    #(.WIDTH(64))
    U_DAT_SA_LOCAL_VLD_COUNTER
    (
      .clk(clk),
      .rstn(rstn),
      .en(sa_local_vld_counter_ena[i]),
      .d(sa_local_vld_counter_d[i]),
      .q(sa_local_vld_counter_q[i])
    );

    std_dffre
    #(.WIDTH(64))
    U_DAT_SA_GLOBAL_INPORT_READ_VLD_COUNTER
    (
      .clk(clk),
      .rstn(rstn),
      .en(sa_global_inport_read_vld_counter_ena[i]),
      .d(sa_global_inport_read_vld_counter_d[i]),
      .q(sa_global_inport_read_vld_counter_q[i])
    );
  end
endgenerate

`ifdef V_ROUTER_PM_PRINT_EN
// display 
  // 1. sa global util
real sa_local_vld_counter             [INPUT_PORT_NUM-1:0];
real sa_global_inport_read_vld_counter[INPUT_PORT_NUM-1:0];
real sa_local_vld_counter_all;
real sa_global_inport_read_vld_counter_all;

always_ff @(posedge clk) begin
  if(~rstn) begin
    
  end else begin
    sa_local_vld_counter_all = 0;
    sa_global_inport_read_vld_counter_all = 0;
    for(int i = 0; i < INPUT_PORT_NUM; i++) begin
      sa_local_vld_counter[i]              = sa_local_vld_counter_q[i];
      sa_global_inport_read_vld_counter[i] = sa_global_inport_read_vld_counter_q[i];
      sa_local_vld_counter_all = sa_local_vld_counter_all + sa_local_vld_counter_q[i];
      sa_global_inport_read_vld_counter_all = sa_global_inport_read_vld_counter_all + sa_global_inport_read_vld_counter_q[i];

      $display("[%16d] info: (router %d,%d inport %2d) pm global sa efficiency (sa_global/sa_local): (%16d/%16d) = %f", 
                $time(), node_id_x_ths_hop_i, node_id_y_ths_hop_i, i,
                sa_global_inport_read_vld_counter[i], sa_local_vld_counter[i],
                sa_global_inport_read_vld_counter[i]/sa_local_vld_counter[i]);
    end
    $display("[%16d] info: pm (inportall) global sa efficiency (sa_global/sa_local): (%16d/%16d) = %f", 
                $time(),
                sa_global_inport_read_vld_counter_all, sa_local_vld_counter_all, 
                sa_global_inport_read_vld_counter_all/sa_local_vld_counter_all);

  end
end

  // 2. outport credit util
  always_ff @(posedge clk) begin
    if(~rstn) begin
    
    end else begin
      for(int i = 0; i < VC_NUM_INPUT_N; i++) begin
        $display("[%16d] info: (router %d,%d outport N  vc id %d) pm  credit count: %d", 
                $time(), node_id_x_ths_hop_i, node_id_y_ths_hop_i, i,
                vc_credit_counter_toN_i[i]);
      end
      for(int i = 0; i < VC_NUM_INPUT_S; i++) begin
        $display("[%16d] info: (router %d,%d outport S  vc id %d) pm  credit count: %d", 
                $time(), node_id_x_ths_hop_i, node_id_y_ths_hop_i, i,
                vc_credit_counter_toS_i[i]);
      end
      for(int i = 0; i < VC_NUM_INPUT_E; i++) begin
        $display("[%16d] info: (router %d,%d outport E  vc id %d) pm  credit count: %d", 
                $time(), node_id_x_ths_hop_i, node_id_y_ths_hop_i, i,
                vc_credit_counter_toE_i[i]);
      end
      for(int i = 0; i < VC_NUM_INPUT_W; i++) begin
        $display("[%16d] info: (router %d,%d outport W  vc id %d) pm  credit count: %d", 
                $time(), node_id_x_ths_hop_i, node_id_y_ths_hop_i, i,
                vc_credit_counter_toW_i[i]);
      end
`ifdef HAVE_LOCAL_PORT
      for(int i = 0; i < LOCAL_PORT_NUM; i++) begin
        for(int j = 0; j < VC_NUM_INPUT_L; j++) begin
          $display("[%16d] info: (router %d,%d outport L%1d vc id %d) pm  credit count: %d", 
                  $time(), node_id_x_ths_hop_i, node_id_y_ths_hop_i, i, j,
                  vc_credit_counter_toL_i[i][j]);
        end
      end
`endif
    end
  end

  `endif

endmodule
