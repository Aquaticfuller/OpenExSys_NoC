module input_port
import rvh_noc_pkg::*;
#(
  parameter type flit_payload_t = logic[256-1:0],
  parameter VC_NUM = 1,
  parameter VC_DEPTH  = 1,
  parameter VC_NUM_IDX_W =VC_NUM > 1 ? $clog2(VC_NUM) : 1,

  parameter INPUT_PORT_NO = 0
)
(
  // input from other router or local port
  input  logic                        rx_flit_pend_i,
  input  logic                        rx_flit_v_i,
  input  flit_payload_t               rx_flit_i,
  input  logic [VC_NUM_IDX_W-1:0]     rx_flit_vc_id_i,
  input  io_port_t                    rx_flit_look_ahead_routing_i,

  // free vc credit sent to sender
  output logic                        rx_lcrd_v_o,
  output logic [VC_ID_NUM_MAX_W-1:0]  rx_lcrd_id_o,

  // output head flit ctrl info to SA & RC unit
  output logic      [VC_NUM-1:0]      vc_ctrl_head_vld_o,
  output flit_dec_t [VC_NUM-1:0]      vc_ctrl_head_o,

  // output data to switch traversal
  output flit_payload_t [VC_NUM-1:0]  vc_data_head_o,

  // input pop flit ctrl fifo (comes from SA stage)
  input logic                         inport_read_enable_sa_stage_i,
  input logic [VC_NUM_IDX_W-1:0]      inport_read_vc_id_sa_stage_i,
`ifdef VC_DATA_USE_DUAL_PORT_RAM
  input dpram_used_idx_t              inport_read_dpram_idx_i,
`endif

  // input pop flit ctrl fifo (comes from ST stage)
  input logic                         inport_read_enable_st_stage_i,
  input logic [VC_NUM_IDX_W-1:0]      inport_read_vc_id_st_stage_i,

`ifndef SYNTHESIS
  // router addr
  input  logic [NodeID_X_Width-1:0] node_id_x_ths_hop_i,
  input  logic [NodeID_Y_Width-1:0] node_id_y_ths_hop_i,
`endif

  input  logic clk,
  input  logic rstn
);

flit_dec_t flit_ctrl_info;


// 1 decode flit, get input vc and routing info
input_port_flit_decoder
#(
  .flit_payload_t   (flit_payload_t)
  // .VC_NUM_IDX_W  (VC_NUM_IDX_W)
)
input_port_flit_decoder_u
(
  .flit_v_i     (rx_flit_v_i    ),
  .flit_i       (rx_flit_i      ),
  .flit_look_ahead_routing_i(rx_flit_look_ahead_routing_i),

  .flit_dec_o   (flit_ctrl_info )
);

// 2 input vc fifo
input_port_vc
#(
  .flit_payload_t (flit_payload_t ),
  .VC_NUM         (VC_NUM      ),
  .VC_DEPTH       (VC_DEPTH       )
)
input_port_vc_u
(
  // input from input port
  .flit_v_i     (rx_flit_v_i    ),
  .flit_i       (rx_flit_i      ),
  .flit_dec_i   (flit_ctrl_info ),
  .flit_vc_id_i (rx_flit_vc_id_i),

  // free vc credit sent to sender
  .lcrd_v_o     (rx_lcrd_v_o    ),
  .lcrd_id_o    (rx_lcrd_id_o   ),

  // output ctrl to local allocate
  .vc_ctrl_head_vld_o (vc_ctrl_head_vld_o),
  .vc_ctrl_head_o     (vc_ctrl_head_o    ),

  // output data to switch traversal
  .vc_data_head_o     (vc_data_head_o    ),

  // input pop flit ctrl fifo (comes from SA stage)
  .inport_read_enable_sa_stage_i  (inport_read_enable_sa_stage_i  ),
  .inport_read_vc_id_sa_stage_i   (inport_read_vc_id_sa_stage_i   ),
`ifdef VC_DATA_USE_DUAL_PORT_RAM
  .inport_read_dpram_idx_i        (inport_read_dpram_idx_i        ),
`endif

  // input pop flit ctrl fifo (comes from ST stage)
  .inport_read_enable_st_stage_i  (inport_read_enable_st_stage_i  ),
  .inport_read_vc_id_st_stage_i   (inport_read_vc_id_st_stage_i   ),


  .clk          (clk  ),
  .rstn         (rstn )
);


`ifndef SYNTHESIS
`ifdef V_INPORT_PRINT_EN
// debug print
always_ff @(posedge clk) begin
  if(rstn) begin
    if(rx_flit_v_i) begin
      $display("[%16d] info: receive flit: router:(%d,%d); inport: %1d(N0,S1,E2,W3,L4-7); vc_id: %1d; look_ahead_routing: %1d(N0,S1,E2,W3,L4-7), QoS = %d", 
                $time(),
                node_id_x_ths_hop_i, node_id_y_ths_hop_i,
                INPUT_PORT_NO,
                rx_flit_vc_id_i,
                flit_ctrl_info.look_ahead_routing,
                rx_flit_i[QoS_Value_Width-1:0]);
      $write("                         ");
      $display("txn_id: 0x%h, sender: (%d,%d), sender_local_port: %1d", 
                flit_ctrl_info.txn_id,
                flit_ctrl_info.src_id.x_position, flit_ctrl_info.src_id.y_position, 
                flit_ctrl_info.src_id.device_port);
      $write("                         ");
      $display("tgt_id: (%d,%d), tgt_local_port: %1d", 
                flit_ctrl_info.tgt_id.x_position, flit_ctrl_info.tgt_id.y_position, flit_ctrl_info.tgt_id.device_port);
    end
  end
end
`endif
`endif
endmodule
