module vnet_router
import rvh_noc_pkg::*;
#(
  parameter INPUT_PORT_NUM  = 5,
  parameter OUTPUT_PORT_NUM = 5,
  parameter LOCAL_PORT_NUM  = INPUT_PORT_NUM-4,
  parameter type flit_payload_t = logic[256-1:0],

  parameter QOS_VC_NUM_PER_INPUT = 0,

  parameter VC_NUM_INPUT_N = 1+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter VC_NUM_INPUT_S = 1+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter VC_NUM_INPUT_E = 3+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter VC_NUM_INPUT_W = 3+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
`ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER
  parameter  VC_NUM_INPUT_L = 4+LOCAL_PORT_NUM-1+QOS_VC_NUM_PER_INPUT,
`else
  parameter  VC_NUM_INPUT_L = 4+QOS_VC_NUM_PER_INPUT,
`endif
  parameter VC_NUM_INPUT_N_IDX_W = VC_NUM_INPUT_N > 1 ? $clog2(VC_NUM_INPUT_N) : 1,
  parameter VC_NUM_INPUT_S_IDX_W = VC_NUM_INPUT_S > 1 ? $clog2(VC_NUM_INPUT_S) : 1,
  parameter VC_NUM_INPUT_E_IDX_W = VC_NUM_INPUT_E > 1 ? $clog2(VC_NUM_INPUT_E) : 1,
  parameter VC_NUM_INPUT_W_IDX_W = VC_NUM_INPUT_W > 1 ? $clog2(VC_NUM_INPUT_W) : 1,
  parameter VC_NUM_INPUT_L_IDX_W = VC_NUM_INPUT_L > 1 ? $clog2(VC_NUM_INPUT_L) : 1,

  parameter SA_GLOBAL_INPUT_NUM_N = 3+LOCAL_PORT_NUM,
  parameter SA_GLOBAL_INPUT_NUM_S = 3+LOCAL_PORT_NUM,
  parameter SA_GLOBAL_INPUT_NUM_E = 1+LOCAL_PORT_NUM,
  parameter SA_GLOBAL_INPUT_NUM_W = 1+LOCAL_PORT_NUM,
`ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER
  parameter  SA_GLOBAL_INPUT_NUM_L = 4+LOCAL_PORT_NUM-1,
`else
  parameter  SA_GLOBAL_INPUT_NUM_L = 4,
`endif
  parameter SA_GLOBAL_INPUT_NUM_N_IDX_W = SA_GLOBAL_INPUT_NUM_N > 1 ? $clog2(SA_GLOBAL_INPUT_NUM_N) : 1,
  parameter SA_GLOBAL_INPUT_NUM_S_IDX_W = SA_GLOBAL_INPUT_NUM_S > 1 ? $clog2(SA_GLOBAL_INPUT_NUM_S) : 1,
  parameter SA_GLOBAL_INPUT_NUM_E_IDX_W = SA_GLOBAL_INPUT_NUM_E > 1 ? $clog2(SA_GLOBAL_INPUT_NUM_E) : 1,
  parameter SA_GLOBAL_INPUT_NUM_W_IDX_W = SA_GLOBAL_INPUT_NUM_W > 1 ? $clog2(SA_GLOBAL_INPUT_NUM_W) : 1,
  parameter SA_GLOBAL_INPUT_NUM_L_IDX_W = SA_GLOBAL_INPUT_NUM_L > 1 ? $clog2(SA_GLOBAL_INPUT_NUM_L) : 1,

  parameter VC_NUM_OUTPUT_N = 1+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter VC_NUM_OUTPUT_S = 1+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter VC_NUM_OUTPUT_E = 3+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter VC_NUM_OUTPUT_W = 3+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter VC_NUM_OUTPUT_L = 1, // vc number in local node
  parameter VC_NUM_OUTPUT_N_IDX_W = VC_NUM_OUTPUT_N > 1 ? $clog2(VC_NUM_OUTPUT_N) : 1,
  parameter VC_NUM_OUTPUT_S_IDX_W = VC_NUM_OUTPUT_S > 1 ? $clog2(VC_NUM_OUTPUT_S) : 1,
  parameter VC_NUM_OUTPUT_E_IDX_W = VC_NUM_OUTPUT_E > 1 ? $clog2(VC_NUM_OUTPUT_E) : 1,
  parameter VC_NUM_OUTPUT_W_IDX_W = VC_NUM_OUTPUT_W > 1 ? $clog2(VC_NUM_OUTPUT_W) : 1,
  parameter VC_NUM_OUTPUT_L_IDX_W = VC_NUM_OUTPUT_L > 1 ? $clog2(VC_NUM_OUTPUT_L) : 1,

  parameter VC_DEPTH_INPUT_N = 2,
  parameter VC_DEPTH_INPUT_S = 2,
  parameter VC_DEPTH_INPUT_E = 2,
  parameter VC_DEPTH_INPUT_W = 2,
  parameter VC_DEPTH_INPUT_L = 2,

  parameter VC_DEPTH_OUTPUT_N = VC_DEPTH_INPUT_N,
  parameter VC_DEPTH_OUTPUT_S = VC_DEPTH_INPUT_S,
  parameter VC_DEPTH_OUTPUT_E = VC_DEPTH_INPUT_E,
  parameter VC_DEPTH_OUTPUT_W = VC_DEPTH_INPUT_W,
  parameter VC_DEPTH_OUTPUT_L = VC_DEPTH_INPUT_L,
  parameter VC_DEPTH_OUTPUT_N_COUNTER_W = $clog2(VC_DEPTH_OUTPUT_N + 1),
  parameter VC_DEPTH_OUTPUT_S_COUNTER_W = $clog2(VC_DEPTH_OUTPUT_S + 1),
  parameter VC_DEPTH_OUTPUT_E_COUNTER_W = $clog2(VC_DEPTH_OUTPUT_E + 1),
  parameter VC_DEPTH_OUTPUT_W_COUNTER_W = $clog2(VC_DEPTH_OUTPUT_W + 1),
  parameter VC_DEPTH_OUTPUT_L_COUNTER_W = $clog2(VC_DEPTH_OUTPUT_L + 1)
)
(
  // input from other router or local port // N,S,E,W,L
  input  logic          [INPUT_PORT_NUM-1:0]                        rx_flit_pend_i,
  input  logic          [INPUT_PORT_NUM-1:0]                        rx_flit_v_i,
  input  flit_payload_t [INPUT_PORT_NUM-1:0]                        rx_flit_i,
  input  logic          [INPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]   rx_flit_vc_id_i,
  input  io_port_t      [INPUT_PORT_NUM-1:0]                        rx_flit_look_ahead_routing_i,

  // output to other router or local port // N,S,E,W,L
  output logic          [OUTPUT_PORT_NUM-1:0]                       tx_flit_pend_o,
  output logic          [OUTPUT_PORT_NUM-1:0]                       tx_flit_v_o,
  output flit_payload_t [OUTPUT_PORT_NUM-1:0]                       tx_flit_o,
  output logic          [OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]  tx_flit_vc_id_o,
  output io_port_t      [OUTPUT_PORT_NUM-1:0]                       tx_flit_look_ahead_routing_o,

  // free vc credit sent to sender
  output logic          [INPUT_PORT_NUM-1:0]                        rx_lcrd_v_o,
  output logic          [INPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]   rx_lcrd_id_o,

  // free vc credit received from receiver
  input  logic          [OUTPUT_PORT_NUM-1:0]                       tx_lcrd_v_i,
  input  logic          [OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]  tx_lcrd_id_i,

  // router addr
  input  logic [NodeID_X_Width-1:0] node_id_x_ths_hop_i,
  input  logic [NodeID_Y_Width-1:0] node_id_y_ths_hop_i,

  input  logic clk,
  input  logic rstn
);

genvar i, j, k;

logic     [INPUT_PORT_NUM-1:0]                       inport_read_enable_sa_stage;
// io_port_t [INPUT_PORT_NUM-1:0]                       inport_read_outport_id_sa_stage;
logic     [INPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]  inport_read_vc_id_sa_stage;
// io_port_t [INPUT_PORT_NUM-1:0]                       inport_look_ahead_routing_sa_stage;

logic     [OUTPUT_PORT_NUM-1:0]                      outport_vld_sa_stage;
io_port_t [OUTPUT_PORT_NUM-1:0]                      outport_select_inport_id_sa_stage;
logic     [OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0] outport_vc_id_sa_stage;
io_port_t [OUTPUT_PORT_NUM-1:0]                      outport_look_ahead_routing_sa_stage;

logic     [OUTPUT_PORT_NUM-1:0]                      consume_vc_credit_vld;
logic     [OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0] consume_vc_credit_vc_id;

logic     [INPUT_PORT_NUM-1:0]                       inport_read_enable_st_stage;
// io_port_t [INPUT_PORT_NUM-1:0]                      inport_read_outport_id_st_stage;
logic     [INPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]  inport_read_vc_id_st_stage;
// io_port_t [INPUT_PORT_NUM-1:0]                      inport_look_ahead_routing_st_stage;

logic     [OUTPUT_PORT_NUM-1:0]                      outport_vld_st_stage;
io_port_t [OUTPUT_PORT_NUM-1:0]                      outport_select_inport_id_st_stage;
logic     [OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0] outport_vc_id_st_stage;
io_port_t [OUTPUT_PORT_NUM-1:0]                      outport_look_ahead_routing_st_stage;

logic     [OUTPUT_PORT_NUM-1:0]                      vc_assignment_vld;
logic     [OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0] vc_assignment_vc_id;
io_port_t [OUTPUT_PORT_NUM-1:0]                      look_ahead_routing_sel;

logic [INPUT_PORT_NUM-1:0][OUTPUT_PORT_NUMBER-1:0]   sa_local_vld_to_sa_global;
logic [INPUT_PORT_NUM-1:0]                           sa_local_vld;
logic [INPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]      sa_local_vc_id;
logic [INPUT_PORT_NUM-1:0][VC_ID_NUM_MAX-1:0]        sa_local_vc_id_oh;
`ifdef USE_QOS_VALUE
logic [INPUT_PORT_NUM-1:0][QoS_Value_Width-1:0]      sa_local_qos_value;
`endif
`ifdef VC_DATA_USE_DUAL_PORT_RAM
dpram_used_idx_t [INPUT_PORT_NUM-1:0]                sa_local_dpram_idx;
`endif

// =============
// 1 input port
// =============

logic      [VC_NUM_INPUT_N-1:0]   vc_ctrl_head_vld_N;
flit_dec_t [VC_NUM_INPUT_N-1:0]   vc_ctrl_head_N;
logic      [VC_NUM_INPUT_S-1:0]   vc_ctrl_head_vld_S;
flit_dec_t [VC_NUM_INPUT_S-1:0]   vc_ctrl_head_S;
logic      [VC_NUM_INPUT_E-1:0]   vc_ctrl_head_vld_E;
flit_dec_t [VC_NUM_INPUT_E-1:0]   vc_ctrl_head_E;
logic      [VC_NUM_INPUT_W-1:0]   vc_ctrl_head_vld_W;
flit_dec_t [VC_NUM_INPUT_W-1:0]   vc_ctrl_head_W;

flit_payload_t [VC_NUM_INPUT_N-1:0] vc_data_head_N;
flit_payload_t [VC_NUM_INPUT_S-1:0] vc_data_head_S;
flit_payload_t [VC_NUM_INPUT_E-1:0] vc_data_head_E;
flit_payload_t [VC_NUM_INPUT_W-1:0] vc_data_head_W;

`ifdef HAVE_LOCAL_PORT
logic           [LOCAL_PORT_NUM-1:0][VC_NUM_INPUT_L-1:0] vc_ctrl_head_vld_L;
flit_dec_t      [LOCAL_PORT_NUM-1:0][VC_NUM_INPUT_L-1:0] vc_ctrl_head_L;
flit_payload_t  [LOCAL_PORT_NUM-1:0][VC_NUM_INPUT_L-1:0] vc_data_head_L;
`endif



input_port
#(
  .flit_payload_t (flit_payload_t   ),
  .VC_NUM         (VC_NUM_INPUT_N   ),
  .VC_DEPTH       (VC_DEPTH_INPUT_N ),

  .INPUT_PORT_NO  (0)
)
input_port_fromN_u
(
  // input from other router or local port
  .rx_flit_pend_i               (rx_flit_pend_i               [0]),
  .rx_flit_v_i                  (rx_flit_v_i                  [0]),
  .rx_flit_i                    (rx_flit_i                    [0]),
  .rx_flit_vc_id_i              (rx_flit_vc_id_i              [0][VC_NUM_INPUT_N_IDX_W-1:0]),
  .rx_flit_look_ahead_routing_i (rx_flit_look_ahead_routing_i [0]),

  // free vc credit sent to sender
  .rx_lcrd_v_o                  (rx_lcrd_v_o                  [0]),
  .rx_lcrd_id_o                 (rx_lcrd_id_o                 [0]),

  // output head flit ctrl info to SA & RC unit
  .vc_ctrl_head_vld_o           (vc_ctrl_head_vld_N              ),
  .vc_ctrl_head_o               (vc_ctrl_head_N                  ),

  // output data to switch traversal
  .vc_data_head_o               (vc_data_head_N                  ),

  // input pop flit ctrl fifo (comes from SA stage)
  .inport_read_enable_sa_stage_i  (inport_read_enable_sa_stage [0]),
  .inport_read_vc_id_sa_stage_i   (sa_local_vc_id              [0][VC_NUM_INPUT_N_IDX_W-1:0]), // use sa_local_vc_id instead inport_read_vc_id_sa_stage to remove it from critical path
`ifdef VC_DATA_USE_DUAL_PORT_RAM
  .inport_read_dpram_idx_i        (sa_local_dpram_idx          [0]),
`endif

  // input pop flit ctrl fifo (comes from ST stage)
  .inport_read_enable_st_stage_i  (inport_read_enable_st_stage [0]),
  .inport_read_vc_id_st_stage_i   (inport_read_vc_id_st_stage  [0][VC_NUM_INPUT_N_IDX_W-1:0]),

`ifndef SYNTHESIS
  // router addr
  .node_id_x_ths_hop_i          (node_id_x_ths_hop_i              ),
  .node_id_y_ths_hop_i          (node_id_y_ths_hop_i              ),
`endif

  .clk      (clk  ),
  .rstn     (rstn )
);

input_port
#(
  .flit_payload_t (flit_payload_t   ),
  .VC_NUM         (VC_NUM_INPUT_S   ),
  .VC_DEPTH       (VC_DEPTH_INPUT_S ),

  .INPUT_PORT_NO  (1)
)
input_port_fromS_u
(
  // input from other router or local port
  .rx_flit_pend_i               (rx_flit_pend_i               [1]),
  .rx_flit_v_i                  (rx_flit_v_i                  [1]),
  .rx_flit_i                    (rx_flit_i                    [1]),
  .rx_flit_vc_id_i              (rx_flit_vc_id_i              [1][VC_NUM_INPUT_S_IDX_W-1:0]),
  .rx_flit_look_ahead_routing_i (rx_flit_look_ahead_routing_i [1]),

  // free vc credit sent to sender
  .rx_lcrd_v_o                  (rx_lcrd_v_o                  [1]),
  .rx_lcrd_id_o                 (rx_lcrd_id_o                 [1]),

  // output head flit ctrl info to SA & RC unit
  .vc_ctrl_head_vld_o           (vc_ctrl_head_vld_S              ),
  .vc_ctrl_head_o               (vc_ctrl_head_S                  ),

  // output data to switch traversal
  .vc_data_head_o               (vc_data_head_S                  ),

  // input pop flit ctrl fifo (comes from SA stage)
  .inport_read_enable_sa_stage_i  (inport_read_enable_sa_stage [1]),
  .inport_read_vc_id_sa_stage_i   (sa_local_vc_id              [1][VC_NUM_INPUT_S_IDX_W-1:0]), // use sa_local_vc_id instead inport_read_vc_id_sa_stage to remove it from critical path
`ifdef VC_DATA_USE_DUAL_PORT_RAM
  .inport_read_dpram_idx_i        (sa_local_dpram_idx          [1]),
`endif

  // input pop flit ctrl fifo (comes from ST stage)
  .inport_read_enable_st_stage_i  (inport_read_enable_st_stage [1]),
  .inport_read_vc_id_st_stage_i   (inport_read_vc_id_st_stage  [1][VC_NUM_INPUT_S_IDX_W-1:0]),

`ifndef SYNTHESIS
  // router addr
  .node_id_x_ths_hop_i          (node_id_x_ths_hop_i              ),
  .node_id_y_ths_hop_i          (node_id_y_ths_hop_i              ),
`endif

  .clk      (clk  ),
  .rstn     (rstn )
);

input_port
#(
  .flit_payload_t (flit_payload_t   ),
  .VC_NUM         (VC_NUM_INPUT_E   ),
  .VC_DEPTH       (VC_DEPTH_INPUT_E ),

  .INPUT_PORT_NO  (2)
)
input_port_fromE_u
(
  // input from other router or local port
  .rx_flit_pend_i               (rx_flit_pend_i               [2]),
  .rx_flit_v_i                  (rx_flit_v_i                  [2]),
  .rx_flit_i                    (rx_flit_i                    [2]),
  .rx_flit_vc_id_i              (rx_flit_vc_id_i              [2][VC_NUM_INPUT_E_IDX_W-1:0]),
  .rx_flit_look_ahead_routing_i (rx_flit_look_ahead_routing_i [2]),

  // free vc credit sent to sender
  .rx_lcrd_v_o                  (rx_lcrd_v_o                  [2]),
  .rx_lcrd_id_o                 (rx_lcrd_id_o                 [2]),

  // output head flit ctrl info to SA & RC unit
  .vc_ctrl_head_vld_o           (vc_ctrl_head_vld_E              ),
  .vc_ctrl_head_o               (vc_ctrl_head_E                  ),

  // output data to switch traversal
  .vc_data_head_o               (vc_data_head_E                  ),

  // input pop flit ctrl fifo (comes from SA stage)
  .inport_read_enable_sa_stage_i  (inport_read_enable_sa_stage [2]),
  .inport_read_vc_id_sa_stage_i   (sa_local_vc_id              [2][VC_NUM_INPUT_E_IDX_W-1:0]), // use sa_local_vc_id instead inport_read_vc_id_sa_stage to remove it from critical path
`ifdef VC_DATA_USE_DUAL_PORT_RAM
  .inport_read_dpram_idx_i        (sa_local_dpram_idx          [2]),
`endif

  // input pop flit ctrl fifo (comes from ST stage)
  .inport_read_enable_st_stage_i  (inport_read_enable_st_stage [2]),
  .inport_read_vc_id_st_stage_i   (inport_read_vc_id_st_stage  [2][VC_NUM_INPUT_E_IDX_W-1:0]),

`ifndef SYNTHESIS
  // router addr
  .node_id_x_ths_hop_i          (node_id_x_ths_hop_i              ),
  .node_id_y_ths_hop_i          (node_id_y_ths_hop_i              ),
`endif

  .clk      (clk  ),
  .rstn     (rstn )
);

input_port
#(
  .flit_payload_t (flit_payload_t   ),
  .VC_NUM         (VC_NUM_INPUT_W   ),
  .VC_DEPTH       (VC_DEPTH_INPUT_W ),

  .INPUT_PORT_NO  (3)
)
input_port_fromW_u
(
  // input from other router or local port
  .rx_flit_pend_i               (rx_flit_pend_i               [3]),
  .rx_flit_v_i                  (rx_flit_v_i                  [3]),
  .rx_flit_i                    (rx_flit_i                    [3]),
  .rx_flit_vc_id_i              (rx_flit_vc_id_i              [3][VC_NUM_INPUT_W_IDX_W-1:0]),
  .rx_flit_look_ahead_routing_i (rx_flit_look_ahead_routing_i [3]),

  // free vc credit sent to sender
  .rx_lcrd_v_o                  (rx_lcrd_v_o                  [3]),
  .rx_lcrd_id_o                 (rx_lcrd_id_o                 [3]),

  // output head flit ctrl info to SA & RC unit
  .vc_ctrl_head_vld_o           (vc_ctrl_head_vld_W              ),
  .vc_ctrl_head_o               (vc_ctrl_head_W                  ),

  // output data to switch traversal
  .vc_data_head_o               (vc_data_head_W                  ),

  // input pop flit ctrl fifo (comes from SA stage)
  .inport_read_enable_sa_stage_i  (inport_read_enable_sa_stage [3]),
  .inport_read_vc_id_sa_stage_i   (sa_local_vc_id              [3][VC_NUM_INPUT_W_IDX_W-1:0]), // use sa_local_vc_id instead inport_read_vc_id_sa_stage to remove it from critical path
`ifdef VC_DATA_USE_DUAL_PORT_RAM
  .inport_read_dpram_idx_i        (sa_local_dpram_idx          [3]),
`endif

  // input pop flit ctrl fifo (comes from ST stage)
  .inport_read_enable_st_stage_i  (inport_read_enable_st_stage [3]),
  .inport_read_vc_id_st_stage_i   (inport_read_vc_id_st_stage  [3][VC_NUM_INPUT_W_IDX_W-1:0]),

`ifndef SYNTHESIS
  // router addr
  .node_id_x_ths_hop_i          (node_id_x_ths_hop_i              ),
  .node_id_y_ths_hop_i          (node_id_y_ths_hop_i              ),
`endif

  .clk      (clk  ),
  .rstn     (rstn )
);

generate
  if(LOCAL_PORT_NUM > 0) begin: gen_have_input_port_fromL
    for(i = 0; i < LOCAL_PORT_NUM; i++) begin: gen_input_port_fromL
      input_port
      #(
        .flit_payload_t (flit_payload_t   ),
        .VC_NUM         (VC_NUM_INPUT_L   ),
        .VC_DEPTH       (VC_DEPTH_INPUT_L ),

        .INPUT_PORT_NO  (4+i)
      )
      input_port_fromL_u
      (
        // input from other router or local port
        .rx_flit_pend_i               (rx_flit_pend_i               [4+i] ),
        .rx_flit_v_i                  (rx_flit_v_i                  [4+i] ),
        .rx_flit_i                    (rx_flit_i                    [4+i] ),
        .rx_flit_vc_id_i              (rx_flit_vc_id_i              [4+i][VC_NUM_INPUT_L_IDX_W-1:0] ),
        .rx_flit_look_ahead_routing_i (rx_flit_look_ahead_routing_i [4+i] ),

        // free vc credit sent to sender
        .rx_lcrd_v_o                  (rx_lcrd_v_o                  [4+i] ),
        .rx_lcrd_id_o                 (rx_lcrd_id_o                 [4+i] ),

        // output head flit ctrl info to SA & RC unit
        .vc_ctrl_head_vld_o           (vc_ctrl_head_vld_L           [i]   ),
        .vc_ctrl_head_o               (vc_ctrl_head_L               [i]   ),

        // output data to switch traversal
        .vc_data_head_o               (vc_data_head_L               [i]   ),

        // input pop flit ctrl fifo (comes from SA stage)
        .inport_read_enable_sa_stage_i  (inport_read_enable_sa_stage [4+i]),
        .inport_read_vc_id_sa_stage_i   (sa_local_vc_id              [4+i][VC_NUM_INPUT_L_IDX_W-1:0]), // use sa_local_vc_id instead inport_read_vc_id_sa_stage to remove it from critical path
`ifdef VC_DATA_USE_DUAL_PORT_RAM
        .inport_read_dpram_idx_i        (sa_local_dpram_idx          [4+i]),
`endif

        // input pop flit ctrl fifo (comes from ST stage)
        .inport_read_enable_st_stage_i  (inport_read_enable_st_stage [4+i]),
        .inport_read_vc_id_st_stage_i   (inport_read_vc_id_st_stage  [4+i][VC_NUM_INPUT_L_IDX_W-1:0]),

`ifndef SYNTHESIS
        // router addr
        .node_id_x_ths_hop_i          (node_id_x_ths_hop_i              ),
        .node_id_y_ths_hop_i          (node_id_y_ths_hop_i              ),
`endif

        .clk      (clk  ),
        .rstn     (rstn )
      );
    end
  end
endgenerate

// =========
// local sa
// =========

sa_local
#(
  .INPUT_NUM(VC_NUM_INPUT_N )
)
sa_local_fromN_u (
  .vc_ctrl_head_vld_i             (vc_ctrl_head_vld_N ),
  .vc_ctrl_head_i                 (vc_ctrl_head_N     ),

  .sa_local_vld_to_sa_global_o    (sa_local_vld_to_sa_global    [0]),
  .sa_local_vld_o                 (sa_local_vld                 [0]),
  .sa_local_vc_id_o               (sa_local_vc_id               [0][VC_NUM_INPUT_N_IDX_W-1:0]),
  .sa_local_vc_id_oh_o            (sa_local_vc_id_oh            [0][VC_NUM_INPUT_N-1:0]),
`ifdef USE_QOS_VALUE
  .sa_local_qos_value_o           (sa_local_qos_value           [0]),
`endif
`ifdef VC_DATA_USE_DUAL_PORT_RAM
  .sa_local_dpram_idx_o           (sa_local_dpram_idx           [0]),
`endif


  .inport_read_enable_sa_stage_i  (inport_read_enable_sa_stage  [0]),

  .clk    (clk ),
  .rstn   (rstn)
);

generate
  if(VC_ID_NUM_MAX_W > VC_NUM_INPUT_N_IDX_W) begin
    assign sa_local_vc_id[0][VC_ID_NUM_MAX_W-1:VC_NUM_INPUT_N_IDX_W] = '0;
  end
endgenerate

sa_local
#(
  .INPUT_NUM(VC_NUM_INPUT_S )
)
sa_local_fromS_u (
  .vc_ctrl_head_vld_i             (vc_ctrl_head_vld_S ),
  .vc_ctrl_head_i                 (vc_ctrl_head_S     ),

  .sa_local_vld_to_sa_global_o    (sa_local_vld_to_sa_global    [1]),
  .sa_local_vld_o                 (sa_local_vld                 [1]),
  .sa_local_vc_id_o               (sa_local_vc_id               [1][VC_NUM_INPUT_S_IDX_W-1:0]),
  .sa_local_vc_id_oh_o            (sa_local_vc_id_oh            [1][VC_NUM_INPUT_S-1:0]),
`ifdef USE_QOS_VALUE
  .sa_local_qos_value_o           (sa_local_qos_value           [1]),
`endif
`ifdef VC_DATA_USE_DUAL_PORT_RAM
  .sa_local_dpram_idx_o           (sa_local_dpram_idx           [1]),
`endif

  .inport_read_enable_sa_stage_i  (inport_read_enable_sa_stage  [1]),

  .clk    (clk ),
  .rstn   (rstn)
);

generate
  if(VC_ID_NUM_MAX_W > VC_NUM_INPUT_S_IDX_W) begin
    assign sa_local_vc_id[1][VC_ID_NUM_MAX_W-1:VC_NUM_INPUT_S_IDX_W] = '0;
  end
endgenerate

sa_local
#(
  .INPUT_NUM(VC_NUM_INPUT_E )
)
sa_local_fromE_u (
  .vc_ctrl_head_vld_i             (vc_ctrl_head_vld_E ),
  .vc_ctrl_head_i                 (vc_ctrl_head_E     ),

  .sa_local_vld_to_sa_global_o    (sa_local_vld_to_sa_global    [2]),
  .sa_local_vld_o                 (sa_local_vld                 [2]),
  .sa_local_vc_id_o               (sa_local_vc_id               [2][VC_NUM_INPUT_E_IDX_W-1:0]),
  .sa_local_vc_id_oh_o            (sa_local_vc_id_oh            [2][VC_NUM_INPUT_E-1:0]),
`ifdef USE_QOS_VALUE
  .sa_local_qos_value_o           (sa_local_qos_value           [2]),
`endif
`ifdef VC_DATA_USE_DUAL_PORT_RAM
  .sa_local_dpram_idx_o           (sa_local_dpram_idx           [2]),
`endif

  .inport_read_enable_sa_stage_i  (inport_read_enable_sa_stage  [2]),

  .clk    (clk ),
  .rstn   (rstn)
);

generate
  if(VC_ID_NUM_MAX_W > VC_NUM_INPUT_E_IDX_W) begin
    assign sa_local_vc_id[2][VC_ID_NUM_MAX_W-1:VC_NUM_INPUT_E_IDX_W] = '0;
  end
endgenerate

sa_local
#(
  .INPUT_NUM(VC_NUM_INPUT_W )
)
sa_local_fromW_u (
  .vc_ctrl_head_vld_i             (vc_ctrl_head_vld_W ),
  .vc_ctrl_head_i                 (vc_ctrl_head_W     ),

  .sa_local_vld_to_sa_global_o    (sa_local_vld_to_sa_global    [3]),
  .sa_local_vld_o                 (sa_local_vld                 [3]),
  .sa_local_vc_id_o               (sa_local_vc_id               [3][VC_NUM_INPUT_W_IDX_W-1:0]),
  .sa_local_vc_id_oh_o            (sa_local_vc_id_oh            [3][VC_NUM_INPUT_W-1:0]),
`ifdef USE_QOS_VALUE
  .sa_local_qos_value_o           (sa_local_qos_value           [3]),
`endif
`ifdef VC_DATA_USE_DUAL_PORT_RAM
  .sa_local_dpram_idx_o           (sa_local_dpram_idx           [3]),
`endif

  .inport_read_enable_sa_stage_i  (inport_read_enable_sa_stage  [3]),

  .clk    (clk ),
  .rstn   (rstn)
);

generate
  if(VC_ID_NUM_MAX_W > VC_NUM_INPUT_W_IDX_W) begin
    assign sa_local_vc_id[3][VC_ID_NUM_MAX_W-1:VC_NUM_INPUT_W_IDX_W] = '0;
  end
endgenerate

generate
  if(LOCAL_PORT_NUM > 0) begin: gen_have_sa_local_fromL
    for(i = 0; i < LOCAL_PORT_NUM; i++) begin: gen_sa_local_fromL
      sa_local
      #(
        .INPUT_NUM(VC_NUM_INPUT_L )
      )
      sa_local_fromL_u (
        .vc_ctrl_head_vld_i             (vc_ctrl_head_vld_L [i]),
        .vc_ctrl_head_i                 (vc_ctrl_head_L     [i]),

        .sa_local_vld_to_sa_global_o    (sa_local_vld_to_sa_global    [4+i]),
        .sa_local_vld_o                 (sa_local_vld                 [4+i]),
        .sa_local_vc_id_o               (sa_local_vc_id               [4+i][VC_NUM_INPUT_L_IDX_W-1:0]),
        .sa_local_vc_id_oh_o            (sa_local_vc_id_oh            [4+i][VC_NUM_INPUT_L-1:0]),
      `ifdef USE_QOS_VALUE
        .sa_local_qos_value_o           (sa_local_qos_value           [4+i]),
      `endif
      `ifdef VC_DATA_USE_DUAL_PORT_RAM
        .sa_local_dpram_idx_o           (sa_local_dpram_idx           [4+i]),
      `endif

        .inport_read_enable_sa_stage_i  (inport_read_enable_sa_stage  [4+i]),

        .clk    (clk ),
        .rstn   (rstn)
      );

      if(VC_ID_NUM_MAX_W > VC_NUM_INPUT_L_IDX_W) begin
        assign sa_local_vc_id[4+i][VC_ID_NUM_MAX_W-1:VC_NUM_INPUT_L_IDX_W] = '0;
      end
    end
  end
endgenerate

// ==========
// global sa
// ==========

logic [OUTPUT_PORT_NUM-1:0]                                 sa_global_vld;
logic [OUTPUT_PORT_NUM-1:0][QoS_Value_Width-1:0]            sa_global_qos_value;
logic [OUTPUT_PORT_NUM-1:0][SA_GLOBAL_INPUT_NUM_MAX-1:0]    sa_global_inport_id_oh;
logic [OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]            sa_global_inport_vc_id;

logic [SA_GLOBAL_INPUT_NUM_N-1:0]                       sa_local_vld_to_sa_global_all_inport_toN;
logic [SA_GLOBAL_INPUT_NUM_N-1:0][VC_ID_NUM_MAX_W-1:0]  sa_local_vc_id_all_inport_toN;
logic [SA_GLOBAL_INPUT_NUM_S-1:0]                       sa_local_vld_to_sa_global_all_inport_toS;
logic [SA_GLOBAL_INPUT_NUM_S-1:0][VC_ID_NUM_MAX_W-1:0]  sa_local_vc_id_all_inport_toS;
logic [SA_GLOBAL_INPUT_NUM_E-1:0]                       sa_local_vld_to_sa_global_all_inport_toE;
logic [SA_GLOBAL_INPUT_NUM_E-1:0][VC_ID_NUM_MAX_W-1:0]  sa_local_vc_id_all_inport_toE;
logic [SA_GLOBAL_INPUT_NUM_W-1:0]                       sa_local_vld_to_sa_global_all_inport_toW;
logic [SA_GLOBAL_INPUT_NUM_W-1:0][VC_ID_NUM_MAX_W-1:0]  sa_local_vc_id_all_inport_toW;
`ifdef HAVE_LOCAL_PORT
logic [LOCAL_PORT_NUM-1:0][SA_GLOBAL_INPUT_NUM_L-1:0]                       sa_local_vld_to_sa_global_all_inport_toL;
logic [LOCAL_PORT_NUM-1:0][SA_GLOBAL_INPUT_NUM_L-1:0][VC_ID_NUM_MAX_W-1:0]  sa_local_vc_id_all_inport_toL;
  `ifdef USE_QOS_VALUE
logic [LOCAL_PORT_NUM-1:0][SA_GLOBAL_INPUT_NUM_L-1:0][QoS_Value_Width-1:0]  sa_local_qos_value_all_inport_toL;
  `endif
`endif

`ifdef USE_QOS_VALUE
logic [SA_GLOBAL_INPUT_NUM_N-1:0][QoS_Value_Width-1:0]  sa_local_qos_value_all_inport_toN;
logic [SA_GLOBAL_INPUT_NUM_S-1:0][QoS_Value_Width-1:0]  sa_local_qos_value_all_inport_toS;
logic [SA_GLOBAL_INPUT_NUM_E-1:0][QoS_Value_Width-1:0]  sa_local_qos_value_all_inport_toE;
logic [SA_GLOBAL_INPUT_NUM_W-1:0][QoS_Value_Width-1:0]  sa_local_qos_value_all_inport_toW;
`endif

assign sa_local_vld_to_sa_global_all_inport_toN[0] = sa_local_vld_to_sa_global[1][0];
assign sa_local_vld_to_sa_global_all_inport_toN[1] = sa_local_vld_to_sa_global[2][0];
assign sa_local_vld_to_sa_global_all_inport_toN[2] = sa_local_vld_to_sa_global[3][0];
assign sa_local_vc_id_all_inport_toN           [0] = sa_local_vc_id           [1];
assign sa_local_vc_id_all_inport_toN           [1] = sa_local_vc_id           [2];
assign sa_local_vc_id_all_inport_toN           [2] = sa_local_vc_id           [3];

`ifdef USE_QOS_VALUE
assign sa_local_qos_value_all_inport_toN       [0] = sa_local_qos_value       [1];
assign sa_local_qos_value_all_inport_toN       [1] = sa_local_qos_value       [2];
assign sa_local_qos_value_all_inport_toN       [2] = sa_local_qos_value       [3];
`endif

generate
  if(LOCAL_PORT_NUM > 0) begin: gen_sa_local_vld_to_sa_global_all_inport_toN_fromL_signal
    for(i = 0; i < LOCAL_PORT_NUM; i++) begin
      assign sa_local_vld_to_sa_global_all_inport_toN[3+i] = sa_local_vld_to_sa_global[4+i][0];
      assign sa_local_vc_id_all_inport_toN           [3+i] = sa_local_vc_id           [4+i];
    `ifdef USE_QOS_VALUE
      assign sa_local_qos_value_all_inport_toN       [3+i] = sa_local_qos_value [4+i];
    `endif
    end
  end
endgenerate



sa_global
#(
  .INPUT_NUM    (SA_GLOBAL_INPUT_NUM_N )
)
sa_global_toN_u (

  .sa_local_vld_i           (sa_local_vld_to_sa_global_all_inport_toN ),
  .sa_local_vc_id_i         (sa_local_vc_id_all_inport_toN            ),
`ifdef USE_QOS_VALUE
  .sa_local_qos_value_i     (sa_local_qos_value_all_inport_toN        ),
`endif

  .sa_global_vld_o          (sa_global_vld          [0]),
`ifdef COMMON_QOS_EXTRA_RT_VC
  .sa_global_qos_value_o    (sa_global_qos_value    [0]),
`endif
  .sa_global_inport_id_oh_o (sa_global_inport_id_oh [0][SA_GLOBAL_INPUT_NUM_N-1:0]),
  .sa_global_inport_vc_id_o (sa_global_inport_vc_id [0]),

  .vc_assignment_vld_i      (vc_assignment_vld      [0]),

  .clk    (clk ),
  .rstn   (rstn)
);

generate
  if(SA_GLOBAL_INPUT_NUM_MAX > SA_GLOBAL_INPUT_NUM_N) begin
    assign sa_global_inport_id_oh[0][SA_GLOBAL_INPUT_NUM_MAX-1:SA_GLOBAL_INPUT_NUM_N] = '0;
  end
endgenerate


assign sa_local_vld_to_sa_global_all_inport_toS[0] = sa_local_vld_to_sa_global[0][1];
assign sa_local_vld_to_sa_global_all_inport_toS[1] = sa_local_vld_to_sa_global[2][1];
assign sa_local_vld_to_sa_global_all_inport_toS[2] = sa_local_vld_to_sa_global[3][1];
assign sa_local_vc_id_all_inport_toS           [0] = sa_local_vc_id           [0];
assign sa_local_vc_id_all_inport_toS           [1] = sa_local_vc_id           [2];
assign sa_local_vc_id_all_inport_toS           [2] = sa_local_vc_id           [3];

`ifdef USE_QOS_VALUE
assign sa_local_qos_value_all_inport_toS       [0] = sa_local_qos_value       [0];
assign sa_local_qos_value_all_inport_toS       [1] = sa_local_qos_value       [2];
assign sa_local_qos_value_all_inport_toS       [2] = sa_local_qos_value       [3];
`endif

generate
  if(LOCAL_PORT_NUM > 0) begin: gen_sa_local_vld_to_sa_global_all_inport_toS_fromL_signal
    for(i = 0; i < LOCAL_PORT_NUM; i++) begin
      assign sa_local_vld_to_sa_global_all_inport_toS[3+i] = sa_local_vld_to_sa_global[4+i][1];
      assign sa_local_vc_id_all_inport_toS           [3+i] = sa_local_vc_id           [4+i];
    `ifdef USE_QOS_VALUE
      assign sa_local_qos_value_all_inport_toS       [3+i] = sa_local_qos_value       [4+i];
    `endif
    end
  end
endgenerate

sa_global
#(
  .INPUT_NUM    (SA_GLOBAL_INPUT_NUM_S )
)
sa_global_toS_u (

  .sa_local_vld_i           (sa_local_vld_to_sa_global_all_inport_toS ),
  .sa_local_vc_id_i         (sa_local_vc_id_all_inport_toS            ),
`ifdef USE_QOS_VALUE
  .sa_local_qos_value_i     (sa_local_qos_value_all_inport_toS        ),
`endif

  .sa_global_vld_o          (sa_global_vld          [1]),
`ifdef COMMON_QOS_EXTRA_RT_VC
  .sa_global_qos_value_o    (sa_global_qos_value    [1]),
`endif
  .sa_global_inport_id_oh_o (sa_global_inport_id_oh [1][SA_GLOBAL_INPUT_NUM_S-1:0]),
  .sa_global_inport_vc_id_o (sa_global_inport_vc_id [1]),

  .vc_assignment_vld_i      (vc_assignment_vld      [1]),

  .clk    (clk ),
  .rstn   (rstn)
);

generate
  if(SA_GLOBAL_INPUT_NUM_MAX > SA_GLOBAL_INPUT_NUM_S) begin
    assign sa_global_inport_id_oh[1][SA_GLOBAL_INPUT_NUM_MAX-1:SA_GLOBAL_INPUT_NUM_S] = '0;
  end
endgenerate


assign sa_local_vld_to_sa_global_all_inport_toE[0] = sa_local_vld_to_sa_global[3][2];
assign sa_local_vc_id_all_inport_toE           [0] = sa_local_vc_id           [3];

`ifdef USE_QOS_VALUE
assign sa_local_qos_value_all_inport_toE       [0] = sa_local_qos_value       [3];
`endif

generate
  if(LOCAL_PORT_NUM > 0) begin: gen_sa_local_vld_to_sa_global_all_inport_toE_fromL_signal
    for(i = 0; i < LOCAL_PORT_NUM; i++) begin
      assign sa_local_vld_to_sa_global_all_inport_toE[1+i] = sa_local_vld_to_sa_global[4+i][2];
      assign sa_local_vc_id_all_inport_toE           [1+i] = sa_local_vc_id           [4+i];
    `ifdef USE_QOS_VALUE
      assign sa_local_qos_value_all_inport_toE       [1+i] = sa_local_qos_value       [4+i];
    `endif
    end
  end
endgenerate

sa_global
#(
  .INPUT_NUM    (SA_GLOBAL_INPUT_NUM_E )
)
sa_global_toE_u (

  .sa_local_vld_i           (sa_local_vld_to_sa_global_all_inport_toE ),
  .sa_local_vc_id_i         (sa_local_vc_id_all_inport_toE            ),
`ifdef USE_QOS_VALUE
  .sa_local_qos_value_i     (sa_local_qos_value_all_inport_toE        ),
`endif

  .sa_global_vld_o          (sa_global_vld          [2]),
`ifdef COMMON_QOS_EXTRA_RT_VC
  .sa_global_qos_value_o    (sa_global_qos_value    [2]),
`endif
  .sa_global_inport_id_oh_o (sa_global_inport_id_oh [2][SA_GLOBAL_INPUT_NUM_E-1:0]),
  .sa_global_inport_vc_id_o (sa_global_inport_vc_id [2]),

  .vc_assignment_vld_i      (vc_assignment_vld      [2]),

  .clk    (clk ),
  .rstn   (rstn)
);

generate
  if(SA_GLOBAL_INPUT_NUM_MAX > SA_GLOBAL_INPUT_NUM_E) begin
    assign sa_global_inport_id_oh[2][SA_GLOBAL_INPUT_NUM_MAX-1:SA_GLOBAL_INPUT_NUM_E] = '0;
  end
endgenerate



assign sa_local_vld_to_sa_global_all_inport_toW[0] = sa_local_vld_to_sa_global[2][3];
assign sa_local_vc_id_all_inport_toW           [0] = sa_local_vc_id           [2];

`ifdef USE_QOS_VALUE
assign sa_local_qos_value_all_inport_toW       [0] = sa_local_qos_value       [2];
`endif

generate
  if(LOCAL_PORT_NUM > 0) begin: gen_sa_local_vld_to_sa_global_all_inport_toW_fromL_signal
    for(i = 0; i < LOCAL_PORT_NUM; i++) begin
      assign sa_local_vld_to_sa_global_all_inport_toW[1+i] = sa_local_vld_to_sa_global[4+i][3];
      assign sa_local_vc_id_all_inport_toW           [1+i] = sa_local_vc_id           [4+i];
    `ifdef USE_QOS_VALUE
      assign sa_local_qos_value_all_inport_toW       [1+i] = sa_local_qos_value       [4+i];
    `endif
    end
  end
endgenerate

sa_global
#(
  .INPUT_NUM    (SA_GLOBAL_INPUT_NUM_W )
)
sa_global_toW_u (

  .sa_local_vld_i           (sa_local_vld_to_sa_global_all_inport_toW ),
  .sa_local_vc_id_i         (sa_local_vc_id_all_inport_toW            ),
`ifdef USE_QOS_VALUE
  .sa_local_qos_value_i     (sa_local_qos_value_all_inport_toW        ),
`endif

  .sa_global_vld_o          (sa_global_vld          [3]),
`ifdef COMMON_QOS_EXTRA_RT_VC
  .sa_global_qos_value_o    (sa_global_qos_value    [3]),
`endif
  .sa_global_inport_id_oh_o (sa_global_inport_id_oh [3][SA_GLOBAL_INPUT_NUM_W-1:0]),
  .sa_global_inport_vc_id_o (sa_global_inport_vc_id [3]),

  .vc_assignment_vld_i      (vc_assignment_vld      [3]),

  .clk    (clk ),
  .rstn   (rstn)
);

generate
  if(SA_GLOBAL_INPUT_NUM_MAX > SA_GLOBAL_INPUT_NUM_W) begin
    assign sa_global_inport_id_oh[3][SA_GLOBAL_INPUT_NUM_MAX-1:SA_GLOBAL_INPUT_NUM_W] = '0;
  end
endgenerate



`ifdef HAVE_LOCAL_PORT

always_comb begin
  int k;
  for(int i = 0; i < LOCAL_PORT_NUM; i++) begin
    for(int j = 0; j < 4; j++) begin
      sa_local_vld_to_sa_global_all_inport_toL[i][j] = sa_local_vld_to_sa_global[j][4+i];
      sa_local_vc_id_all_inport_toL           [i][j] = sa_local_vc_id           [j];
    `ifdef USE_QOS_VALUE
      sa_local_qos_value_all_inport_toL       [i][j] = sa_local_qos_value       [j];
    `endif
    end
  `ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER
    k = 0;
    for(int j = 0; j < LOCAL_PORT_NUM; j++) begin
      if(i != j) begin
        sa_local_vld_to_sa_global_all_inport_toL[i][4+k] = sa_local_vld_to_sa_global[4+j][4+i];
        sa_local_vc_id_all_inport_toL           [i][4+k] = sa_local_vc_id           [4+j];
      `ifdef USE_QOS_VALUE
        sa_local_qos_value_all_inport_toL       [i][4+k] = sa_local_qos_value       [4+j];
      `endif
        k++;
      end
    end
  `endif
  end
end

generate
  if(LOCAL_PORT_NUM > 0) begin: gen_have_sa_global_toL
    for(i = 0; i < LOCAL_PORT_NUM; i++) begin: gen_sa_global_toL
      sa_global
      #(
        .INPUT_NUM    (SA_GLOBAL_INPUT_NUM_L )
      )
      sa_global_toL_u (

        .sa_local_vld_i           (sa_local_vld_to_sa_global_all_inport_toL [i] ),
        .sa_local_vc_id_i         (sa_local_vc_id_all_inport_toL            [i] ),
      `ifdef USE_QOS_VALUE
        .sa_local_qos_value_i     (sa_local_qos_value_all_inport_toL        [i] ),
      `endif

        .sa_global_vld_o          (sa_global_vld          [4+i]),
      `ifdef COMMON_QOS_EXTRA_RT_VC
        .sa_global_qos_value_o    (sa_global_qos_value    [4+i]),
      `endif
        .sa_global_inport_id_oh_o (sa_global_inport_id_oh [4+i][SA_GLOBAL_INPUT_NUM_L-1:0]),
        .sa_global_inport_vc_id_o (sa_global_inport_vc_id [4+i]),

        .vc_assignment_vld_i      (vc_assignment_vld      [4+i]),

        .clk    (clk ),
        .rstn   (rstn)
      );


      if(SA_GLOBAL_INPUT_NUM_MAX > SA_GLOBAL_INPUT_NUM_L) begin
        assign sa_global_inport_id_oh[4+i][SA_GLOBAL_INPUT_NUM_MAX-1:SA_GLOBAL_INPUT_NUM_L] = '0;
      end
    end
  end
endgenerate
`endif

// ===================
// look-ahead routing
// ===================
io_port_t  [INPUT_PORT_NUM-1:0] look_ahead_routing;
flit_dec_t [INPUT_PORT_NUM-1:0] vc_ctrl_head_sa_local_sel;


onehot_mux 
#(
  .SOURCE_COUNT(VC_NUM_INPUT_N ),
  .DATA_WIDTH  ($bits(flit_dec_t) )
)
onehot_mux_vc_ctrl_head_sa_local_sel_N_u (
  .sel_i    (sa_local_vc_id_oh[0][VC_NUM_INPUT_N-1:0] ),
  .data_i   (vc_ctrl_head_N ),
  .data_o   (vc_ctrl_head_sa_local_sel[0])
);

look_ahead_routing
#(
)
look_ahead_routing_fromN_u (
  .vc_ctrl_head_vld_i     (sa_local_vld [0] ),
  .vc_ctrl_head_i         (vc_ctrl_head_sa_local_sel[0] ),

  .node_id_x_ths_hop_i    (node_id_x_ths_hop_i    ),
  .node_id_y_ths_hop_i    (node_id_y_ths_hop_i    ),
  .look_ahead_routing_o   (look_ahead_routing   [0])
);


onehot_mux 
#(
  .SOURCE_COUNT(VC_NUM_INPUT_S ),
  .DATA_WIDTH  ($bits(flit_dec_t) )
)
onehot_mux_vc_ctrl_head_sa_local_sel_S_u (
  .sel_i    (sa_local_vc_id_oh[1][VC_NUM_INPUT_S-1:0] ),
  .data_i   (vc_ctrl_head_S ),
  .data_o   (vc_ctrl_head_sa_local_sel[1])
);

look_ahead_routing
#(
)
look_ahead_routing_fromS_u (
  .vc_ctrl_head_vld_i     (sa_local_vld [1] ),
  .vc_ctrl_head_i         (vc_ctrl_head_sa_local_sel[1] ),

  .node_id_x_ths_hop_i    (node_id_x_ths_hop_i    ),
  .node_id_y_ths_hop_i    (node_id_y_ths_hop_i    ),
  .look_ahead_routing_o   (look_ahead_routing   [1])
);


onehot_mux 
#(
  .SOURCE_COUNT(VC_NUM_INPUT_E ),
  .DATA_WIDTH  ($bits(flit_dec_t) )
)
onehot_mux_vc_ctrl_head_sa_local_sel_E_u (
  .sel_i    (sa_local_vc_id_oh[2][VC_NUM_INPUT_E-1:0] ),
  .data_i   (vc_ctrl_head_E ),
  .data_o   (vc_ctrl_head_sa_local_sel[2])
);

look_ahead_routing
#(
)
look_ahead_routing_fromE_u (
  .vc_ctrl_head_vld_i     (sa_local_vld [2] ),
  .vc_ctrl_head_i         (vc_ctrl_head_sa_local_sel[2] ),

  .node_id_x_ths_hop_i    (node_id_x_ths_hop_i    ),
  .node_id_y_ths_hop_i    (node_id_y_ths_hop_i    ),
  .look_ahead_routing_o   (look_ahead_routing   [2])
);


onehot_mux 
#(
  .SOURCE_COUNT(VC_NUM_INPUT_W ),
  .DATA_WIDTH  ($bits(flit_dec_t) )
)
onehot_mux_vc_ctrl_head_sa_local_sel_W_u (
  .sel_i    (sa_local_vc_id_oh[3][VC_NUM_INPUT_W-1:0] ),
  .data_i   (vc_ctrl_head_W ),
  .data_o   (vc_ctrl_head_sa_local_sel[3])
);

look_ahead_routing
#(
)
look_ahead_routing_fromW_u (
  .vc_ctrl_head_vld_i     (sa_local_vld [3] ),
  .vc_ctrl_head_i         (vc_ctrl_head_sa_local_sel[3] ),

  .node_id_x_ths_hop_i    (node_id_x_ths_hop_i    ),
  .node_id_y_ths_hop_i    (node_id_y_ths_hop_i    ),
  .look_ahead_routing_o   (look_ahead_routing   [3])
);

generate
  if(LOCAL_PORT_NUM > 0) begin: gen_have_look_ahead_routing_fromL
    for(i = 0; i < LOCAL_PORT_NUM; i++) begin: gen_look_ahead_routing_fromL
      onehot_mux 
      #(
        .SOURCE_COUNT(VC_NUM_INPUT_L ),
        .DATA_WIDTH  ($bits(flit_dec_t) )
      )
      onehot_mux_look_ahead_routing_sel_u (
        .sel_i    (sa_local_vc_id_oh[4+i][VC_NUM_INPUT_L-1:0] ),
        .data_i   (vc_ctrl_head_L[i] ),
        .data_o   (vc_ctrl_head_sa_local_sel[4+i])
      );

      look_ahead_routing
      #(
      )
      look_ahead_routing_fromL_u (
        .vc_ctrl_head_vld_i     (sa_local_vld [4+i] ),
        .vc_ctrl_head_i         (vc_ctrl_head_sa_local_sel[4+i] ),

        .node_id_x_ths_hop_i    (node_id_x_ths_hop_i    ),
        .node_id_y_ths_hop_i    (node_id_y_ths_hop_i    ),
        .look_ahead_routing_o   (look_ahead_routing   [4+i])
      );
    end
  end
endgenerate

// ==============================
// output port vc credit counter
// ==============================
logic [VC_NUM_OUTPUT_N-1:0][VC_DEPTH_OUTPUT_N_COUNTER_W-1:0] vc_credit_counter_toN;
logic [VC_NUM_OUTPUT_S-1:0][VC_DEPTH_OUTPUT_S_COUNTER_W-1:0] vc_credit_counter_toS;
logic [VC_NUM_OUTPUT_E-1:0][VC_DEPTH_OUTPUT_E_COUNTER_W-1:0] vc_credit_counter_toE;
logic [VC_NUM_OUTPUT_W-1:0][VC_DEPTH_OUTPUT_W_COUNTER_W-1:0] vc_credit_counter_toW;
`ifdef HAVE_LOCAL_PORT
logic [LOCAL_PORT_NUM-1:0][VC_NUM_OUTPUT_L-1:0][VC_DEPTH_OUTPUT_L_COUNTER_W-1:0] vc_credit_counter_toL;
`endif

output_port_vc_credit_counter
#(
  .VC_NUM   (VC_NUM_OUTPUT_N ),
  .VC_DEPTH (VC_DEPTH_OUTPUT_N )
)
output_port_vc_credit_counter_toN_u (
  .free_vc_credit_vld_i       (tx_lcrd_v_i            [0] ),
  .free_vc_credit_vc_id_i     (tx_lcrd_id_i           [0][VC_NUM_OUTPUT_N_IDX_W-1:0] ),
  .consume_vc_credit_vld_i    (consume_vc_credit_vld  [0] ),
  .consume_vc_credit_vc_id_i  (consume_vc_credit_vc_id[0][VC_NUM_OUTPUT_N_IDX_W-1:0] ),
  .vc_credit_counter_o        (vc_credit_counter_toN      ),
  .clk                        (clk  ),
  .rstn                       (rstn )
);

output_port_vc_credit_counter
#(
  .VC_NUM   (VC_NUM_OUTPUT_S ),
  .VC_DEPTH (VC_DEPTH_OUTPUT_S )
)
output_port_vc_credit_counter_toS_u (
  .free_vc_credit_vld_i       (tx_lcrd_v_i            [1] ),
  .free_vc_credit_vc_id_i     (tx_lcrd_id_i           [1][VC_NUM_OUTPUT_S_IDX_W-1:0] ),
  .consume_vc_credit_vld_i    (consume_vc_credit_vld  [1] ),
  .consume_vc_credit_vc_id_i  (consume_vc_credit_vc_id[1][VC_NUM_OUTPUT_S_IDX_W-1:0] ),
  .vc_credit_counter_o        (vc_credit_counter_toS      ),
  .clk                        (clk  ),
  .rstn                       (rstn )
);

output_port_vc_credit_counter
#(
  .VC_NUM   (VC_NUM_OUTPUT_E ),
  .VC_DEPTH (VC_DEPTH_OUTPUT_E )
)
output_port_vc_credit_counter_toE_u (
  .free_vc_credit_vld_i       (tx_lcrd_v_i            [2] ),
  .free_vc_credit_vc_id_i     (tx_lcrd_id_i           [2][VC_NUM_OUTPUT_E_IDX_W-1:0] ),
  .consume_vc_credit_vld_i    (consume_vc_credit_vld  [2] ),
  .consume_vc_credit_vc_id_i  (consume_vc_credit_vc_id[2][VC_NUM_OUTPUT_E_IDX_W-1:0] ),
  .vc_credit_counter_o        (vc_credit_counter_toE      ),
  .clk                        (clk  ),
  .rstn                       (rstn )
);

output_port_vc_credit_counter
#(
  .VC_NUM   (VC_NUM_OUTPUT_W ),
  .VC_DEPTH (VC_DEPTH_OUTPUT_W )
)
output_port_vc_credit_counter_toW_u (
  .free_vc_credit_vld_i       (tx_lcrd_v_i            [3] ),
  .free_vc_credit_vc_id_i     (tx_lcrd_id_i           [3][VC_NUM_OUTPUT_W_IDX_W-1:0] ),
  .consume_vc_credit_vld_i    (consume_vc_credit_vld  [3] ),
  .consume_vc_credit_vc_id_i  (consume_vc_credit_vc_id[3][VC_NUM_OUTPUT_W_IDX_W-1:0] ),
  .vc_credit_counter_o        (vc_credit_counter_toW      ),
  .clk                        (clk  ),
  .rstn                       (rstn )
);

generate
  if(LOCAL_PORT_NUM > 0) begin: gen_have_output_port_vc_credit_counter_toL
    for(i = 0; i < LOCAL_PORT_NUM; i++) begin: gen_output_port_vc_credit_counter_toL
      output_port_vc_credit_counter
      #(
        .VC_NUM   (VC_NUM_OUTPUT_L ),
        .VC_DEPTH (VC_DEPTH_OUTPUT_L )
      )
      output_port_vc_credit_counter_toL_u (
        .free_vc_credit_vld_i       (tx_lcrd_v_i            [4+i] ),
        .free_vc_credit_vc_id_i     (tx_lcrd_id_i           [4+i][VC_NUM_OUTPUT_L_IDX_W-1:0] ),
        .consume_vc_credit_vld_i    (consume_vc_credit_vld  [4+i] ),
        .consume_vc_credit_vc_id_i  (consume_vc_credit_vc_id[4+i][VC_NUM_OUTPUT_L_IDX_W-1:0] ),
        .vc_credit_counter_o        (vc_credit_counter_toL  [i]   ),
        .clk                        (clk  ),
        .rstn                       (rstn )
      );
    end
  end
endgenerate

// =============
// vc selection
// =============

vc_select_vld_t   [VC_NUM_OUTPUT_N-1:0] vc_select_vld_toN;
vc_select_vc_id_t [VC_NUM_OUTPUT_N-1:0] vc_select_vc_id_toN;
vc_select_vld_t   [VC_NUM_OUTPUT_S-1:0] vc_select_vld_toS;
vc_select_vc_id_t [VC_NUM_OUTPUT_S-1:0] vc_select_vc_id_toS;
vc_select_vld_t   [VC_NUM_OUTPUT_E-1:0] vc_select_vld_toE;
vc_select_vc_id_t [VC_NUM_OUTPUT_E-1:0] vc_select_vc_id_toE;
vc_select_vld_t   [VC_NUM_OUTPUT_W-1:0] vc_select_vld_toW;
vc_select_vc_id_t [VC_NUM_OUTPUT_W-1:0] vc_select_vc_id_toW;
`ifdef HAVE_LOCAL_PORT
vc_select_vld_t   [LOCAL_PORT_NUM-1:0][VC_NUM_OUTPUT_L-1:0] vc_select_vld_toL;
vc_select_vc_id_t [LOCAL_PORT_NUM-1:0][VC_NUM_OUTPUT_L-1:0] vc_select_vc_id_toL;
`endif

output_port_vc_selection
#(
  .OUTPUT_VC_NUM    (VC_NUM_OUTPUT_N  ),
  .OUTPUT_VC_DEPTH  (VC_DEPTH_OUTPUT_N )
)
output_port_vc_selection_toN_u (
  .vc_credit_counter_i  (vc_credit_counter_toN  ),
  .vc_select_vld_o      (vc_select_vld_toN      ),
  .vc_select_vc_id_o    (vc_select_vc_id_toN    )
);

output_port_vc_selection
#(
  .OUTPUT_VC_NUM    (VC_NUM_OUTPUT_S  ),
  .OUTPUT_VC_DEPTH  (VC_DEPTH_OUTPUT_S )
)
output_port_vc_selection_toS_u (
  .vc_credit_counter_i  (vc_credit_counter_toS  ),
  .vc_select_vld_o      (vc_select_vld_toS      ),
  .vc_select_vc_id_o    (vc_select_vc_id_toS    )
);

output_port_vc_selection
#(
  .OUTPUT_VC_NUM    (VC_NUM_OUTPUT_E  ),
  .OUTPUT_VC_DEPTH  (VC_DEPTH_OUTPUT_E )
)
output_port_vc_selection_toE_u (
  .vc_credit_counter_i  (vc_credit_counter_toE  ),
  .vc_select_vld_o      (vc_select_vld_toE      ),
  .vc_select_vc_id_o    (vc_select_vc_id_toE    )
);

output_port_vc_selection
#(
  .OUTPUT_VC_NUM    (VC_NUM_OUTPUT_W  ),
  .OUTPUT_VC_DEPTH  (VC_DEPTH_OUTPUT_W )
)
output_port_vc_selection_toW_u (
  .vc_credit_counter_i  (vc_credit_counter_toW  ),
  .vc_select_vld_o      (vc_select_vld_toW      ),
  .vc_select_vc_id_o    (vc_select_vc_id_toW    )
);

generate
  if(LOCAL_PORT_NUM > 0) begin: gen_have_output_port_vc_selection_toL
    for(i = 0; i < LOCAL_PORT_NUM; i++) begin: gen_output_port_vc_selection_toL
      output_port_vc_selection
      #(
        .OUTPUT_VC_NUM    (VC_NUM_OUTPUT_L  ),
        .OUTPUT_VC_DEPTH  (VC_DEPTH_OUTPUT_L ),

        .OUTPUT_TO_L      (1)
      )
      output_port_vc_selection_toL_u (
        .vc_credit_counter_i  (vc_credit_counter_toL [i] ),
        .vc_select_vld_o      (vc_select_vld_toL     [i] ),
        .vc_select_vc_id_o    (vc_select_vc_id_toL   [i] )
      );
    end
  end
endgenerate

// ==============
// vc assignment
// ==============

io_port_t [SA_GLOBAL_INPUT_NUM_N-1:0] look_ahead_routing_all_inport_toN;
io_port_t [SA_GLOBAL_INPUT_NUM_S-1:0] look_ahead_routing_all_inport_toS;
io_port_t [SA_GLOBAL_INPUT_NUM_E-1:0] look_ahead_routing_all_inport_toE;
io_port_t [SA_GLOBAL_INPUT_NUM_W-1:0] look_ahead_routing_all_inport_toW;


assign look_ahead_routing_all_inport_toN[0] = look_ahead_routing[1];
assign look_ahead_routing_all_inport_toN[1] = look_ahead_routing[2];
assign look_ahead_routing_all_inport_toN[2] = look_ahead_routing[3];
generate
  if(LOCAL_PORT_NUM > 0) begin: gen_have_look_ahead_routing_all_inport_toN
    for(i = 0; i < LOCAL_PORT_NUM; i++) begin: gen_look_ahead_routing_all_inport_toN
      assign look_ahead_routing_all_inport_toN[3+i] = look_ahead_routing[4+i];
    end
  end
endgenerate

output_port_vc_assignment
#(
  .OUTPUT_VC_NUM        (VC_NUM_OUTPUT_N ),
  .SA_GLOBAL_INPUT_NUM  (SA_GLOBAL_INPUT_NUM_N ),
  .OUTPUT_TO_N          (1 )
)
output_port_vc_assignment_toN_u (
  .sa_global_vld_i            (sa_global_vld        [0]),
`ifdef COMMON_QOS_EXTRA_RT_VC
  .sa_global_qos_value_i      (sa_global_qos_value  [0]),
`endif
  .sa_global_inport_id_oh_i   (sa_global_inport_id_oh  [0][SA_GLOBAL_INPUT_NUM_N-1:0]),
  .look_ahead_routing_i       (look_ahead_routing_all_inport_toN ),

  .vc_select_vld_i            (vc_select_vld_toN       ),
  .vc_select_vc_id_i          (vc_select_vc_id_toN     ),

  .vc_assignment_vld_o        (vc_assignment_vld    [0]),
  .vc_assignment_vc_id_o      (vc_assignment_vc_id  [0]),
  .look_ahead_routing_sel_o   (look_ahead_routing_sel[0])
);

assign look_ahead_routing_all_inport_toS[0] = look_ahead_routing[0];
assign look_ahead_routing_all_inport_toS[1] = look_ahead_routing[2];
assign look_ahead_routing_all_inport_toS[2] = look_ahead_routing[3];
generate
  if(LOCAL_PORT_NUM > 0) begin: gen_have_look_ahead_routing_all_inport_toS
    for(i = 0; i < LOCAL_PORT_NUM; i++) begin: gen_look_ahead_routing_all_inport_toS
      assign look_ahead_routing_all_inport_toS[3+i] = look_ahead_routing[4+i];
    end
  end
endgenerate

output_port_vc_assignment
#(
  .OUTPUT_VC_NUM        (VC_NUM_OUTPUT_S ),
  .SA_GLOBAL_INPUT_NUM  (SA_GLOBAL_INPUT_NUM_S ),
  .OUTPUT_TO_S          (1 )
)
output_port_vc_assignment_toS_u (
  .sa_global_vld_i            (sa_global_vld        [1]),
`ifdef COMMON_QOS_EXTRA_RT_VC
  .sa_global_qos_value_i      (sa_global_qos_value  [1]),
`endif
  .sa_global_inport_id_oh_i   (sa_global_inport_id_oh  [1][SA_GLOBAL_INPUT_NUM_S-1:0]),
  .look_ahead_routing_i       (look_ahead_routing_all_inport_toS ),

  .vc_select_vld_i            (vc_select_vld_toS       ),
  .vc_select_vc_id_i          (vc_select_vc_id_toS     ),

  .vc_assignment_vld_o        (vc_assignment_vld    [1]),
  .vc_assignment_vc_id_o      (vc_assignment_vc_id  [1]),
  .look_ahead_routing_sel_o   (look_ahead_routing_sel[1])
);

assign look_ahead_routing_all_inport_toE[0] = look_ahead_routing[3];
generate
  if(LOCAL_PORT_NUM > 0) begin: gen_have_look_ahead_routing_all_inport_toE
    for(i = 0; i < LOCAL_PORT_NUM; i++) begin: gen_look_ahead_routing_all_inport_toE
      assign look_ahead_routing_all_inport_toE[1+i] = look_ahead_routing[4+i];
    end
  end
endgenerate

output_port_vc_assignment
#(
  .OUTPUT_VC_NUM        (VC_NUM_OUTPUT_E ),
  .SA_GLOBAL_INPUT_NUM  (SA_GLOBAL_INPUT_NUM_E ),
  .OUTPUT_TO_E          (1 )
)
output_port_vc_assignment_toE_u (
  .sa_global_vld_i            (sa_global_vld        [2]),
`ifdef COMMON_QOS_EXTRA_RT_VC
  .sa_global_qos_value_i      (sa_global_qos_value  [2]),
`endif
  .sa_global_inport_id_oh_i   (sa_global_inport_id_oh  [2][SA_GLOBAL_INPUT_NUM_E-1:0]),
  .look_ahead_routing_i       (look_ahead_routing_all_inport_toE),

  .vc_select_vld_i            (vc_select_vld_toE       ),
  .vc_select_vc_id_i          (vc_select_vc_id_toE     ),

  .vc_assignment_vld_o        (vc_assignment_vld    [2]),
  .vc_assignment_vc_id_o      (vc_assignment_vc_id  [2]),
  .look_ahead_routing_sel_o   (look_ahead_routing_sel[2])
);

assign look_ahead_routing_all_inport_toW[0] = look_ahead_routing[2];
generate
  if(LOCAL_PORT_NUM > 0) begin: gen_have_look_ahead_routing_all_inport_toW
    for(i = 0; i < LOCAL_PORT_NUM; i++) begin: gen_look_ahead_routing_all_inport_toW
      assign look_ahead_routing_all_inport_toW[1+i] = look_ahead_routing[4+i];
    end
  end
endgenerate

output_port_vc_assignment
#(
  .OUTPUT_VC_NUM        (VC_NUM_OUTPUT_W ),
  .SA_GLOBAL_INPUT_NUM  (SA_GLOBAL_INPUT_NUM_W ),
  .OUTPUT_TO_W          (1 )
)
output_port_vc_assignment_toW_u (
  .sa_global_vld_i            (sa_global_vld        [3]),
`ifdef COMMON_QOS_EXTRA_RT_VC
  .sa_global_qos_value_i      (sa_global_qos_value  [3]),
`endif
  .sa_global_inport_id_oh_i   (sa_global_inport_id_oh  [3][SA_GLOBAL_INPUT_NUM_W-1:0]),
  .look_ahead_routing_i       (look_ahead_routing_all_inport_toW),

  .vc_select_vld_i            (vc_select_vld_toW       ),
  .vc_select_vc_id_i          (vc_select_vc_id_toW     ),

  .vc_assignment_vld_o        (vc_assignment_vld    [3]),
  .vc_assignment_vc_id_o      (vc_assignment_vc_id  [3]),
  .look_ahead_routing_sel_o   (look_ahead_routing_sel[3])
);

generate
  if(LOCAL_PORT_NUM > 0) begin: gen_have_output_port_vc_assignment_toL
    for(i = 0; i < LOCAL_PORT_NUM; i++) begin: gen_output_port_vc_assignment_toL
      output_port_vc_assignment
      #(
        .OUTPUT_VC_NUM        (VC_NUM_OUTPUT_L ),
        .SA_GLOBAL_INPUT_NUM  (SA_GLOBAL_INPUT_NUM_L ),
        .OUTPUT_TO_L          (1 )
      )
      output_port_vc_assignment_toL_u (
        .sa_global_vld_i            (sa_global_vld         [4+i]),
      `ifdef COMMON_QOS_EXTRA_RT_VC
        .sa_global_qos_value_i      (sa_global_qos_value   [4+i]),
      `endif
        .sa_global_inport_id_oh_i   (sa_global_inport_id_oh  [4+i][SA_GLOBAL_INPUT_NUM_L-1:0]),
        .look_ahead_routing_i       ({ {((SA_GLOBAL_INPUT_NUM_L-4)*$bits(io_port_t)){1'b0}}, // for flit to L port, the look ahead routing is meaningless
                                       look_ahead_routing[3],
                                       look_ahead_routing[2],
                                       look_ahead_routing[1],
                                       look_ahead_routing[0]} ),

        .vc_select_vld_i            (vc_select_vld_toL     [i]   ),
        .vc_select_vc_id_i          (vc_select_vc_id_toL   [i]   ),

        .vc_assignment_vld_o        (vc_assignment_vld     [4+i]),
        .vc_assignment_vc_id_o      (vc_assignment_vc_id   [4+i]),
        .look_ahead_routing_sel_o   (look_ahead_routing_sel[4+i])
      );
    end
  end
endgenerate

// ==================
// input buffer read // TODO: if change to sram as input buffer, the read should conduct right after local allocate
// ==================

input_to_output
#(
  .INPUT_PORT_NUM  (INPUT_PORT_NUM  ),
  .OUTPUT_PORT_NUM (OUTPUT_PORT_NUM ),

  .SA_GLOBAL_INPUT_NUM_N  (SA_GLOBAL_INPUT_NUM_N ),
  .SA_GLOBAL_INPUT_NUM_S  (SA_GLOBAL_INPUT_NUM_S ),
  .SA_GLOBAL_INPUT_NUM_E  (SA_GLOBAL_INPUT_NUM_E ),
  .SA_GLOBAL_INPUT_NUM_W  (SA_GLOBAL_INPUT_NUM_W ),
  .SA_GLOBAL_INPUT_NUM_L  (SA_GLOBAL_INPUT_NUM_L )
)
input_to_output_u
(
  // input from sa global allocation
  .sa_global_vld_i              (sa_global_vld              ),
  // .sa_global_inport_id_i        (sa_global_inport_id        ),
  .sa_global_inport_id_oh_i     (sa_global_inport_id_oh     ),
  .sa_global_inport_vc_id_i     (sa_global_inport_vc_id     ),

  // input from vc allocation
  .vc_assignment_vld_i          (vc_assignment_vld          ),
  .vc_assignment_vc_id_i        (vc_assignment_vc_id        ),
  .look_ahead_routing_sel_i     (look_ahead_routing_sel     ),

  // output to input port buffer to get selected flit
  .inport_read_enable_o         (inport_read_enable_sa_stage         ),
  // .inport_read_outport_id_o     (inport_read_outport_id_sa_stage     ),
  .inport_read_vc_id_o          (inport_read_vc_id_sa_stage          ),
  // .inport_look_ahead_routing_o  (inport_look_ahead_routing_sa_stage  ),

  // output to switch to let outport select inport
  .outport_vld_o                (outport_vld_sa_stage                ),
  .outport_select_inport_id_o   (outport_select_inport_id_sa_stage   ),
  .outport_vc_id_o              (outport_vc_id_sa_stage              ),
  .outport_look_ahead_routing_o (outport_look_ahead_routing_sa_stage ),

  // output to outport vc credit counter to consume one credit
  .consume_vc_credit_vld_o      (consume_vc_credit_vld      ),
  .consume_vc_credit_vc_id_o    (consume_vc_credit_vc_id    )
);

// ===================
// SA to ST stage reg
// ===================

generate
  for(i = 0; i < INPUT_PORT_NUM; i++) begin: gen_sa_to_st_reg_inport_angle
    std_dffr
    #(.WIDTH(1))
    U_STA_INPORT_READ_ENABLE_ST_STAGE
    (
      .clk(clk),
      .rstn(rstn),
      .d(inport_read_enable_sa_stage[i]),
      .q(inport_read_enable_st_stage[i])
    );

    // std_dffe
    // #(.WIDTH($bits(io_port_t)))
    // U_DAT_INPORT_READ_OUTPORT_ID_ST_STAGE
    // (
    //   .clk(clk),
    //   .en(inport_read_enable_sa_stage[i]),
    //   .d(inport_read_outport_id_sa_stage[i]),
    //   .q(inport_read_outport_id_st_stage[i])
    // );

    std_dffe
    #(.WIDTH(VC_ID_NUM_MAX_W))
    U_DAT_INPORT_READ_VC_ID_ST_STAGE
    (
      .clk(clk),
      .en(inport_read_enable_sa_stage[i]),
      .d(inport_read_vc_id_sa_stage[i]),
      .q(inport_read_vc_id_st_stage[i])
    );

    // std_dffe
    // #(.WIDTH($bits(io_port_t)))
    // U_DAT_INPORT_LOOK_AHEAD_ROUTING_ST_STAGE
    // (
    //   .clk(clk),
    //   .en(inport_read_enable_sa_stage[i]),
    //   .d(inport_look_ahead_routing_sa_stage[i]),
    //   .q(inport_look_ahead_routing_st_stage[i])
    // );
  end

  for(i = 0; i < OUTPUT_PORT_NUM; i++) begin: gen_sa_to_st_reg_outport_angle
    std_dffr
    #(.WIDTH(1))
    U_STA_OUTPORT_VLD_ST_STAGE
    (
      .clk(clk),
      .rstn(rstn),
      .d(outport_vld_sa_stage[i]),
      .q(outport_vld_st_stage[i])
    );

    std_dffe
    #(.WIDTH($bits(io_port_t)))
    U_DAT_OUTPORT_SELECT_INPORT_ID_ST_STAGE
    (
      .clk(clk),
      .en(outport_vld_sa_stage[i]),
      .d(outport_select_inport_id_sa_stage[i]),
      .q(outport_select_inport_id_st_stage[i])
    );

    std_dffe
    #(.WIDTH(VC_ID_NUM_MAX_W))
    U_DAT_OUTPORT_VC_ID_ST_STAGE
    (
      .clk(clk),
      .en(outport_vld_sa_stage[i]),
      .d(outport_vc_id_sa_stage[i]),
      .q(outport_vc_id_st_stage[i])
    );

    std_dffe
    #(.WIDTH($bits(io_port_t)))
    U_DAT_OUTPORT_LOOK_AHEAD_ROUTING_ST_STAGE
    (
      .clk(clk),
      .en(outport_vld_sa_stage[i]),
      .d(outport_look_ahead_routing_sa_stage[i]),
      .q(outport_look_ahead_routing_st_stage[i])
    );

  end
endgenerate


// ==================
// switch to outport
// ==================

switch
#(
  .INPUT_PORT_NUM     (INPUT_PORT_NUM   ),
  .OUTPUT_PORT_NUM    (OUTPUT_PORT_NUM  ),

  .flit_payload_t     (flit_payload_t   ),
 
  .VC_NUM_INPUT_N     (VC_NUM_INPUT_N   ),
  .VC_NUM_INPUT_S     (VC_NUM_INPUT_S   ),
  .VC_NUM_INPUT_E     (VC_NUM_INPUT_E   ),
  .VC_NUM_INPUT_W     (VC_NUM_INPUT_W   ),
  .VC_NUM_INPUT_L     (VC_NUM_INPUT_L   )

)
switch_u
(
  // input flit data from input port buffer
  .vc_data_head_fromN_i           (vc_data_head_N   ),
  .vc_data_head_fromS_i           (vc_data_head_S   ),
  .vc_data_head_fromE_i           (vc_data_head_E   ),
  .vc_data_head_fromW_i           (vc_data_head_W   ),
`ifdef HAVE_LOCAL_PORT
  .vc_data_head_fromL_i           (vc_data_head_L   ),
`endif

  // input switch ctrl from SA to ST stage reg
  .inport_read_enable_st_stage_i        (inport_read_enable_st_stage),
  .inport_read_vc_id_st_stage_i         (inport_read_vc_id_st_stage ),

  .outport_vld_st_stage_i               (outport_vld_st_stage               ),
  .outport_select_inport_id_st_stage_i  (outport_select_inport_id_st_stage  ),
  .outport_vc_id_st_stage_i             (outport_vc_id_st_stage             ),
  .outport_look_ahead_routing_st_stage_i(outport_look_ahead_routing_st_stage),

  // output flit data and look ahead routing to outport
  .tx_flit_pend_o                       (tx_flit_pend_o               ),
  .tx_flit_v_o                          (tx_flit_v_o                  ),
  .tx_flit_o                            (tx_flit_o                    ),
  .tx_flit_vc_id_o                      (tx_flit_vc_id_o              ),
  .tx_flit_look_ahead_routing_o         (tx_flit_look_ahead_routing_o )

);

// ===================
// performance_monitor
// ===================
`ifndef SYNTHESIS
performance_monitor 
#(
  .INPUT_PORT_NUM(INPUT_PORT_NUM ),
  .OUTPUT_PORT_NUM(OUTPUT_PORT_NUM ),

  .VC_NUM_INPUT_N   (VC_NUM_INPUT_N   ),
  .VC_NUM_INPUT_S   (VC_NUM_INPUT_S   ),
  .VC_NUM_INPUT_E   (VC_NUM_INPUT_E   ),
  .VC_NUM_INPUT_W   (VC_NUM_INPUT_W   ),
  .VC_NUM_INPUT_L   (VC_NUM_INPUT_L   ),

  .VC_DEPTH_INPUT_N (VC_DEPTH_INPUT_N ),
  .VC_DEPTH_INPUT_S (VC_DEPTH_INPUT_S ),
  .VC_DEPTH_INPUT_E (VC_DEPTH_INPUT_E ),
  .VC_DEPTH_INPUT_W (VC_DEPTH_INPUT_W ),
  .VC_DEPTH_INPUT_L (VC_DEPTH_INPUT_L )
)
v_performance_monitor_u (
  .sa_local_vld_i              (sa_local_vld ),
  .sa_global_inport_read_vld_i (inport_read_enable_sa_stage ),

  .vc_credit_counter_toN_i     (vc_credit_counter_toN ),
  .vc_credit_counter_toS_i     (vc_credit_counter_toS ),
  .vc_credit_counter_toE_i     (vc_credit_counter_toE ),
  .vc_credit_counter_toW_i     (vc_credit_counter_toW ),
  .vc_credit_counter_toL_i     (vc_credit_counter_toL ),

  .node_id_x_ths_hop_i         (node_id_x_ths_hop_i),
  .node_id_y_ths_hop_i         (node_id_y_ths_hop_i),
  .clk    (clk ),
  .rstn   (rstn)
);
`endif

endmodule
