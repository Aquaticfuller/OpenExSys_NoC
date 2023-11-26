`ifndef __RVH_NOC_PKG_SV__
`define __RVH_NOC_PKG_SV__

// ----------
// local port configuration
// ----------
`define HAVE_LOCAL_PORT
// `define LOCAL_PORT_NUM_2 // local port num >= 2
// `define LOCAL_PORT_NUM_3 // local port num >= 3
// `define LOCAL_PORT_NUM_4      // local port num >= 4

`ifdef LOCAL_PORT_NUM_4
  `ifndef LOCAL_PORT_NUM_3
    `define LOCAL_PORT_NUM_3
  `endif
  `ifndef LOCAL_PORT_NUM_2
    `define LOCAL_PORT_NUM_2
  `endif
`endif

`ifdef LOCAL_PORT_NUM_3
  `ifndef LOCAL_PORT_NUM_2
    `define LOCAL_PORT_NUM_2
  `endif
`endif

// `define ENABLE_TXN_ID // for noc test, enable it

// ----------
// Single vc per input port
// ----------
// `define SINGLE_VC_PER_INPUT_PORT

// ----------
// use unified dual-port ram per input port vc data buffer (default: dff)
// ----------
// `define VC_DATA_USE_DUAL_PORT_RAM

// ----------
// reture credit to send at sa stage rather than st atage
// ----------
// `define RETURN_CREDIT_AT_SA_STAGE 

// ----------
// whether allow local ports in same router transfer flit, at least 2 local ports
// ----------
// `define ALLOW_SAME_ROUTER_L2L_TRANSFER 

// ----------
// insert a pipeline register between local sa and global sa, for better timing
// ----------
// `define INSERT_PIPELINE_REG_BETWEEN_SA

// ----------
// QoS, at most one of follow macros can be defined
// ----------

`define COMMON_QOS  // No special vc, all vc head flits ranked by QoS value.
// `define COMMON_QOS_EXTRA_RT_VC // Add special vc for highest priority flits, all vc head flits ranked by QoS value

// not implemented:
// `define RT_BYPASS_QOS_EXTRA_RT_VC // Add special vc for highest priority flits, other vc head flits have no QoS support


`ifdef COMMON_QOS
  `define USE_QOS_VALUE
`endif

`ifdef COMMON_QOS_EXTRA_RT_VC
  `define USE_QOS_VALUE
`endif


package rvh_noc_pkg;

localparam  CHANNEL_NUM = 5; // 5 channels: req, resp, evict, data, snp

// 4*4 nodes max
localparam  NodeID_X_Width = 2;
localparam  NodeID_Y_Width = 2;
localparam  NodeID_Device_Port_Width = 2;
localparam  NodeID_Device_Id_Width = 1;

localparam  NodeID_Width = NodeID_X_Width + NodeID_Y_Width + NodeID_Device_Port_Width + NodeID_Device_Id_Width; // 7
localparam  TxnID_Width = 12;
localparam  QoS_Value_Width = 4;


localparam  INPUT_PORT_NUMBER       = 5; // N,S,E,W,L
localparam  INPUT_PORT_NUMBER_IDX_W = INPUT_PORT_NUMBER > 1 ? $clog2(INPUT_PORT_NUMBER) : 1;
localparam  OUTPUT_PORT_NUMBER      = 5; // N,S,E,W,L
localparam  ROUTER_PORT_NUMBER      = 4;
localparam  LOCAL_PORT_NUMBER       = INPUT_PORT_NUMBER-ROUTER_PORT_NUMBER;

`ifdef COMMON_QOS_EXTRA_RT_VC
localparam  QOS_VC_NUM_PER_INPUT   = 1;
`else
localparam  QOS_VC_NUM_PER_INPUT   = 0;
`endif

`ifdef SINGLE_VC_PER_INPUT_PORT
localparam  VC_ID_NUM_MAX   = 1+QOS_VC_NUM_PER_INPUT;
`else
localparam  VC_ID_NUM_MAX   = (CHANNEL_NUM-1)+LOCAL_PORT_NUMBER+QOS_VC_NUM_PER_INPUT;
`endif

localparam  VC_ID_NUM_MAX_W = VC_ID_NUM_MAX > 1 ? $clog2(VC_ID_NUM_MAX) : 1;

localparam  SA_GLOBAL_INPUT_NUM_MAX   = (CHANNEL_NUM-1)+LOCAL_PORT_NUMBER;
localparam  SA_GLOBAL_INPUT_NUM_MAX_W = SA_GLOBAL_INPUT_NUM_MAX > 1 ? $clog2(SA_GLOBAL_INPUT_NUM_MAX) : 1;

localparam  VC_DEPTH_MAX = 2;
`ifdef VC_DATA_USE_DUAL_PORT_RAM
  `ifdef RETURN_CREDIT_AT_SA_STAGE
localparam VC_DPRAM_DEPTH_MAX     = VC_ID_NUM_MAX * (VC_DEPTH_MAX+1);
localparam VC_BUFFER_DEPTH_MAX_W  = (VC_DEPTH_MAX+1) > 1 ? $clog2(VC_DEPTH_MAX+1) : 1;
  `else
localparam VC_DPRAM_DEPTH_MAX     = VC_ID_NUM_MAX * VC_DEPTH_MAX;
localparam VC_BUFFER_DEPTH_MAX_W  = VC_DEPTH_MAX > 1 ? $clog2(VC_DEPTH_MAX) : 1;
  `endif
localparam VC_DPRAM_DEPTH_MAX_W = VC_DPRAM_DEPTH_MAX > 1 ? $clog2(VC_DPRAM_DEPTH_MAX) : 1;
`endif

typedef enum logic [2:0] {
  N  = 0,
  S  = 1,
  E  = 2,
  W  = 3,
  L0 = 4,
  L1 = 5,
  L2 = 6,
  L3 = 7
} io_port_t;

typedef struct packed {
  logic [NodeID_X_Width-1:0]            x_position;
  logic [NodeID_Y_Width-1:0]            y_position;
  logic [NodeID_Device_Port_Width-1:0]  device_port;
  logic [1-1:0]                         device_id;
} node_id_t;

`ifdef VC_DATA_USE_DUAL_PORT_RAM
typedef struct packed {
  logic [VC_DPRAM_DEPTH_MAX_W-1:0]  dpram_idx; // == VC_BUFFER_DEPTH * vc_id + per_vc_idx
  logic [VC_BUFFER_DEPTH_MAX_W-1:0] per_vc_idx;
} dpram_used_idx_t;
`endif

typedef struct packed {
  node_id_t                   tgt_id; // target id
  node_id_t                   src_id; // source id
`ifdef ENABLE_TXN_ID
  logic [TxnID_Width-1:0]     txn_id; // transaction id
`endif
  io_port_t                   look_ahead_routing;
`ifdef USE_QOS_VALUE
  logic [QoS_Value_Width-1:0] qos_value;
`endif
`ifdef VC_DATA_USE_DUAL_PORT_RAM
  dpram_used_idx_t            dpram_used_idx;
`endif
} flit_dec_t;

typedef struct packed {
  logic common_vld;
  logic rt_vld;
} vc_select_vld_t;

typedef struct packed {
  logic [VC_ID_NUM_MAX_W-1:0] common_vc_id;
  logic [VC_ID_NUM_MAX_W-1:0] rt_vc_id;
} vc_select_vc_id_t;





  // mesh parameters
  parameter  NODE_NUM_X_DIMESION = 3;
  parameter  NODE_NUM_Y_DIMESION = 3;
  
  // router parameters
  parameter  INPUT_PORT_NUM = INPUT_PORT_NUMBER;
  parameter  OUTPUT_PORT_NUM = OUTPUT_PORT_NUMBER;
  parameter  LOCAL_PORT_NUM  = INPUT_PORT_NUM-4;


  typedef struct packed {
    logic [256-1:0]             data;

    node_id_t                   tgt_id; // target id
    node_id_t                   src_id; // source id
`ifdef ENABLE_TXN_ID
    logic [TxnID_Width-1:0]     txn_id; // transaction id
`endif

`ifdef USE_QOS_VALUE
    logic [QoS_Value_Width-1:0] qos_value;
`endif
  } cache_scu_cc_test_t;

  parameter FLIT_LENGTH = $bits(cache_scu_cc_test_t);

  // parameter type flit_payload_t = logic[FLIT_LENGTH-1:0];
  parameter type flit_payload_t = cache_scu_cc_test_t;

  // parameter  QOS_VC_NUM_PER_INPUT = QOS_VC_NUM_PER_INPUT;
`ifdef SINGLE_VC_PER_INPUT_PORT
  parameter VC_NUM_INPUT_N = 1+QOS_VC_NUM_PER_INPUT;
  parameter VC_NUM_INPUT_S = 1+QOS_VC_NUM_PER_INPUT;
  parameter VC_NUM_INPUT_E = 1+QOS_VC_NUM_PER_INPUT;
  parameter VC_NUM_INPUT_W = 1+QOS_VC_NUM_PER_INPUT;
  `ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER
  parameter  VC_NUM_INPUT_L = 1+QOS_VC_NUM_PER_INPUT;
  `else
  parameter  VC_NUM_INPUT_L = 1+QOS_VC_NUM_PER_INPUT;
  `endif
`else
  parameter VC_NUM_INPUT_N = 1+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT;
  parameter VC_NUM_INPUT_S = 1+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT;
  parameter VC_NUM_INPUT_E = 3+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT;
  parameter VC_NUM_INPUT_W = 3+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT;
  `ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER
  parameter  VC_NUM_INPUT_L = 4+LOCAL_PORT_NUM-1+QOS_VC_NUM_PER_INPUT;
  `else
  parameter  VC_NUM_INPUT_L = 4+QOS_VC_NUM_PER_INPUT;
  `endif
`endif
  parameter  SA_GLOBAL_INPUT_NUM_N = 3+LOCAL_PORT_NUM;
  parameter  SA_GLOBAL_INPUT_NUM_S = 3+LOCAL_PORT_NUM;
  parameter  SA_GLOBAL_INPUT_NUM_E = 1+LOCAL_PORT_NUM;
  parameter  SA_GLOBAL_INPUT_NUM_W = 1+LOCAL_PORT_NUM;
`ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER
  parameter  SA_GLOBAL_INPUT_NUM_L = 4+LOCAL_PORT_NUM-1;
`else
  parameter  SA_GLOBAL_INPUT_NUM_L = 4;
`endif
`ifdef SINGLE_VC_PER_INPUT_PORT
  parameter  VC_NUM_OUTPUT_N = 1+QOS_VC_NUM_PER_INPUT;
  parameter  VC_NUM_OUTPUT_S = 1+QOS_VC_NUM_PER_INPUT;
  parameter  VC_NUM_OUTPUT_E = 1+QOS_VC_NUM_PER_INPUT;
  parameter  VC_NUM_OUTPUT_W = 1+QOS_VC_NUM_PER_INPUT;
`else
  parameter  VC_NUM_OUTPUT_N = 1+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT;
  parameter  VC_NUM_OUTPUT_S = 1+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT;
  parameter  VC_NUM_OUTPUT_E = 3+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT;
  parameter  VC_NUM_OUTPUT_W = 3+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT;
`endif
  parameter  VC_NUM_OUTPUT_L = 1;
  parameter  VC_DEPTH_INPUT_N = VC_DEPTH_MAX;
  parameter  VC_DEPTH_INPUT_S = VC_DEPTH_MAX;
  parameter  VC_DEPTH_INPUT_E = VC_DEPTH_MAX;
  parameter  VC_DEPTH_INPUT_W = VC_DEPTH_MAX;
  parameter  VC_DEPTH_INPUT_L = VC_DEPTH_MAX;


endpackage
`endif
