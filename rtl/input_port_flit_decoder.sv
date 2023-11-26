module input_port_flit_decoder
  import rvh_noc_pkg::*;
#(
  parameter type flit_payload_t = logic[256-1:0]
  // parameter VC_NUM_IDX_W = 1
)
(
  input  logic              flit_v_i,
  input  flit_payload_t     flit_i,
  input  io_port_t          flit_look_ahead_routing_i,

  output flit_dec_t         flit_dec_o
);

`ifdef USE_QOS_VALUE
assign flit_dec_o.qos_value = flit_i.qos_value;
`endif
assign flit_dec_o.tgt_id    = flit_i.tgt_id;
assign flit_dec_o.src_id    = flit_i.src_id;
`ifdef ENABLE_TXN_ID
assign flit_dec_o.txn_id    = flit_i.txn_id;
`endif

assign flit_dec_o.look_ahead_routing = flit_look_ahead_routing_i;

endmodule