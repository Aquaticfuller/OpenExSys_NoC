`ifndef __V_NOC_PKG_SV__
`define __V_NOC_PKG_SV__

// `define V_ROUTER_PM_PRINT_EN
`define V_INPORT_PRINT_EN

package v_noc_pkg;
  import rvh_noc_pkg::*;

  localparam  SCOREBOARD_TIMEOUT_W = 15;
  localparam  SENDER_TIMEOUT_W = 15;
  localparam  FLIT_DATA_LENGTH = FLIT_LENGTH-QoS_Value_Width-$bits(node_id_t)*2-TxnID_Width;
  
  typedef struct packed {
    logic [FLIT_DATA_LENGTH-1:0]     flit_data;
    flit_dec_t                       flit_head;
    logic [SCOREBOARD_TIMEOUT_W-1:0] timeout_threshold;
    logic [64-1:0]                   mcycle_when_generated; // the cycle when the test case is generated
    logic [QoS_Value_Width-1:0]      qos_value;
  } test_case_t;

  typedef struct packed {
    node_id_t                             tgt_id; // target id
    node_id_t                             src_id; // source id
    logic     [TxnID_Width-1:0]           txn_id; // transaction id
    logic     [SCOREBOARD_TIMEOUT_W-1:0]  timeout_threshold;
    io_port_t                             look_ahead_routing;
    logic     [VC_ID_NUM_MAX_W-1:0]       inport_vc_id;
    logic     [64-1:0]                    generated_mcycle; // when it geerated by test generate
    logic     [64-1:0]                    sent_mcycle;      // when it inject into noc
    logic     [FLIT_DATA_LENGTH-1:0]      flit_data;
    logic     [QoS_Value_Width-1:0]       qos_value;

  // TODO: routing path
  } scoreboard_entry_t;

  typedef struct packed {
    logic [SCOREBOARD_TIMEOUT_W-1:0] timeout_counter;
  } scoreboard_timer_t;

  typedef struct packed {
    logic [SENDER_TIMEOUT_W-1:0] timeout_counter;
  } sender_timer_t;

  typedef struct packed {
    node_id_t                         rec_id; // receiver id (should be the same as tgt_id)
    node_id_t                         src_id; // source id
    logic     [TxnID_Width-1:0]       txn_id; // transaction id
    logic     [FLIT_DATA_LENGTH-1:0]  flit_data;
  } receiver_info_t;

endpackage
`endif
