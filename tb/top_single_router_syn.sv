module top_single_router_syn
import rvh_noc_pkg::*;
// import v_noc_pkg::*;
#(
  // mesh parameters
  parameter  NODE_NUM_X_DIMESION = 3,
  parameter  NODE_NUM_Y_DIMESION = 3,

  // router parameters
  parameter  INPUT_PORT_NUM = INPUT_PORT_NUMBER,
  parameter  OUTPUT_PORT_NUM = OUTPUT_PORT_NUMBER,
  parameter  LOCAL_PORT_NUM  = INPUT_PORT_NUM-4,
  parameter type flit_payload_t = logic[FLIT_LENGTH-1:0],
  parameter  VC_NUM_INPUT_N = 1+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter  VC_NUM_INPUT_S = 1+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter  VC_NUM_INPUT_E = 3+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter  VC_NUM_INPUT_W = 3+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
`ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER
  parameter  VC_NUM_INPUT_L = 4+LOCAL_PORT_NUM-1+QOS_VC_NUM_PER_INPUT,
`else
  parameter  VC_NUM_INPUT_L = 4+QOS_VC_NUM_PER_INPUT,
`endif
  parameter  SA_GLOBAL_INPUT_NUM_N = 3+LOCAL_PORT_NUM,
  parameter  SA_GLOBAL_INPUT_NUM_S = 3+LOCAL_PORT_NUM,
  parameter  SA_GLOBAL_INPUT_NUM_E = 1+LOCAL_PORT_NUM,
  parameter  SA_GLOBAL_INPUT_NUM_W = 1+LOCAL_PORT_NUM,
`ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER
  parameter  SA_GLOBAL_INPUT_NUM_L = 4+LOCAL_PORT_NUM-1,
`else
  parameter  SA_GLOBAL_INPUT_NUM_L = 4,
`endif
  parameter  VC_NUM_OUTPUT_N = 1+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter  VC_NUM_OUTPUT_S = 1+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter  VC_NUM_OUTPUT_E = 3+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter  VC_NUM_OUTPUT_W = 3+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter  VC_NUM_OUTPUT_L = 1,
  parameter  VC_DEPTH_INPUT_N = VC_DEPTH_MAX,
  parameter  VC_DEPTH_INPUT_S = VC_DEPTH_MAX,
  parameter  VC_DEPTH_INPUT_E = VC_DEPTH_MAX,
  parameter  VC_DEPTH_INPUT_W = VC_DEPTH_MAX,
  parameter  VC_DEPTH_INPUT_L = VC_DEPTH_MAX
)
(
  output logic           [OUTPUT_PORT_NUM-1:0]                      tx_flit_pend_o,
  output logic           [OUTPUT_PORT_NUM-1:0]                      tx_flit_v_o,
  output flit_payload_t  [OUTPUT_PORT_NUM-1:0]                      tx_flit_o,
  output logic           [OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0] tx_flit_vc_id_o,
  output io_port_t       [OUTPUT_PORT_NUM-1:0]                      tx_flit_look_ahead_routing_o,

  input  logic           [INPUT_PORT_NUM-1:0]                       rx_flit_pend_i,
  input  logic           [INPUT_PORT_NUM-1:0]                       rx_flit_v_i,
  input  flit_payload_t  [INPUT_PORT_NUM-1:0]                       rx_flit_i,
  input  logic           [INPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]  rx_flit_vc_id_i,
  input  io_port_t       [INPUT_PORT_NUM-1:0]                       rx_flit_look_ahead_routing_i,

  input  logic           [OUTPUT_PORT_NUM-1:0]                      tx_lcrd_v_i,
  input  logic           [OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0] tx_lcrd_id_i,

  output logic           [INPUT_PORT_NUM-1:0]                       rx_lcrd_v_o,
  output logic           [INPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]  rx_lcrd_id_o,

  input  logic  clk,
  input  logic  rst

);

  // router
  vnet_router
  #(
    .INPUT_PORT_NUM(INPUT_PORT_NUM ),
    .OUTPUT_PORT_NUM(OUTPUT_PORT_NUM ),
    .flit_payload_t(flit_payload_t),
    .QOS_VC_NUM_PER_INPUT(QOS_VC_NUM_PER_INPUT),
    .VC_NUM_INPUT_N(VC_NUM_INPUT_N ),
    .VC_NUM_INPUT_S(VC_NUM_INPUT_S ),
    .VC_NUM_INPUT_E(VC_NUM_INPUT_E ),
    .VC_NUM_INPUT_W(VC_NUM_INPUT_W ),
    .VC_NUM_INPUT_L(VC_NUM_INPUT_L ),
    .SA_GLOBAL_INPUT_NUM_N(SA_GLOBAL_INPUT_NUM_N ),
    .SA_GLOBAL_INPUT_NUM_S(SA_GLOBAL_INPUT_NUM_S ),
    .SA_GLOBAL_INPUT_NUM_E(SA_GLOBAL_INPUT_NUM_E ),
    .SA_GLOBAL_INPUT_NUM_W(SA_GLOBAL_INPUT_NUM_W ),
    .SA_GLOBAL_INPUT_NUM_L(SA_GLOBAL_INPUT_NUM_L ),
    .VC_NUM_OUTPUT_N(VC_NUM_OUTPUT_N ),
    .VC_NUM_OUTPUT_S(VC_NUM_OUTPUT_S ),
    .VC_NUM_OUTPUT_E(VC_NUM_OUTPUT_E ),
    .VC_NUM_OUTPUT_W(VC_NUM_OUTPUT_W ),
    .VC_NUM_OUTPUT_L(VC_NUM_OUTPUT_L ),
    .VC_DEPTH_INPUT_N(VC_DEPTH_INPUT_N ),
    .VC_DEPTH_INPUT_S(VC_DEPTH_INPUT_S ),
    .VC_DEPTH_INPUT_E(VC_DEPTH_INPUT_E ),
    .VC_DEPTH_INPUT_W(VC_DEPTH_INPUT_W ),
    .VC_DEPTH_INPUT_L(VC_DEPTH_INPUT_L )
  )
  vnet_router_dut (
    .rx_flit_pend_i               (rx_flit_pend_i                ),
    .rx_flit_v_i                  (rx_flit_v_i                   ),
    .rx_flit_i                    (rx_flit_i                     ),
    .rx_flit_vc_id_i              (rx_flit_vc_id_i               ),
    .rx_flit_look_ahead_routing_i (rx_flit_look_ahead_routing_i  ),

    .tx_flit_pend_o               (tx_flit_pend_o                ),
    .tx_flit_v_o                  (tx_flit_v_o                   ),
    .tx_flit_o                    (tx_flit_o                     ),
    .tx_flit_vc_id_o              (tx_flit_vc_id_o               ),
    .tx_flit_look_ahead_routing_o (tx_flit_look_ahead_routing_o  ),

    .rx_lcrd_v_o                  (rx_lcrd_v_o                   ),
    .rx_lcrd_id_o                 (rx_lcrd_id_o                  ),

    .tx_lcrd_v_i                  (tx_lcrd_v_i                   ),
    .tx_lcrd_id_i                 (tx_lcrd_id_i                  ),

    .node_id_x_ths_hop_i          ('0                   ),
    .node_id_y_ths_hop_i          ('0                   ),

    .clk    (clk ),
    .rstn   (rst)
  );

endmodule
