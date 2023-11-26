module rn_router_sam
  import rvh_noc_pkg::*;
#(
  parameter type flit_payload_t = logic[256-1:0]
  // parameter VC_NUM_IDX_W = 1
)
(
  input  logic              flit_v_i,
  input  flit_payload_t     flit_i,
  input  io_port_t          flit_look_ahead_routing_i,

  input  logic [NodeID_X_Width-1:0] node_id_x_i,
  input  logic [NodeID_Y_Width-1:0] node_id_y_i,

  output flit_dec_t         flit_dec_o,
  output flit_payload_t     flit_o

);

`ifdef USE_QOS_VALUE
assign flit_dec_o.qos_value = flit_i.qos_value;
`endif

always_comb begin
  flit_o = flit_i;
  flit_o.tgt_id.x_position  = 1;
  flit_o.tgt_id.y_position  = 0;
  flit_o.tgt_id.device_port = 0;
  flit_o.tgt_id.device_id   = 0;
  flit_o.src_id.x_position   = node_id_x_i;
  flit_o.src_id.y_position   = node_id_y_i;
  flit_o.src_id.device_port  = 0;
  flit_o.src_id.device_id    = 0;
end

assign flit_dec_o.tgt_id.x_position   = 1;
assign flit_dec_o.tgt_id.y_position   = 0;
assign flit_dec_o.tgt_id.device_port  = 0;
assign flit_dec_o.tgt_id.device_id    = 0;
assign flit_dec_o.src_id.x_position   = node_id_x_i;
assign flit_dec_o.src_id.y_position   = node_id_y_i;
assign flit_dec_o.src_id.device_port  = 0;
assign flit_dec_o.src_id.device_id    = 0;

assign flit_dec_o.look_ahead_routing = flit_look_ahead_routing_i;

endmodule