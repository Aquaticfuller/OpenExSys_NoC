module v_receiver
import rvh_noc_pkg::*;
import v_noc_pkg::*;
#(
  parameter type flit_payload_t = logic[256-1:0]
)
(
  // intf with dut
    // input from one of dut router's outports // N,S,E,W,L
  input  logic                                  rx_flit_pend_i,
  input  logic                                  rx_flit_v_i,
  input  flit_payload_t                         rx_flit_i,
  input  logic          [VC_ID_NUM_MAX_W-1:0]   rx_flit_vc_id_i,
  input  io_port_t                              rx_flit_look_ahead_routing_i,

    // free vc credit from dut
  output logic                                  rx_lcrd_v_o,
  output logic          [VC_ID_NUM_MAX_W-1:0]   rx_lcrd_id_o,

  // intf with scoreboard
  output logic                                  check_scoreboard_vld_o,
  output receiver_info_t                        check_scoreboard_o,
  input  logic                                  check_scoreboard_rdy_i,

  // node id
  input  node_id_t                              node_id_i,

  input  logic clk,
  input  logic rstn
);

flit_dec_t flit_ctrl_info;

input_port_flit_decoder
#(
  .flit_payload_t   (flit_payload_t)
)
receiver_flit_decoder_u
(
  .flit_v_i     (rx_flit_v_i    ),
  .flit_i       (rx_flit_i      ),
  .flit_look_ahead_routing_i(rx_flit_look_ahead_routing_i),

  .flit_dec_o   (flit_ctrl_info )
);

assign check_scoreboard_vld_o         = rx_flit_v_i;
assign check_scoreboard_o.rec_id      = node_id_i;
assign check_scoreboard_o.src_id      = flit_ctrl_info.src_id;
assign check_scoreboard_o.txn_id      = flit_ctrl_info.txn_id;
assign check_scoreboard_o.flit_data   = rx_flit_i[FLIT_LENGTH-1-:FLIT_DATA_LENGTH];

assign rx_lcrd_v_o  = rx_flit_v_i;
assign rx_lcrd_id_o = rx_flit_vc_id_i;

endmodule
