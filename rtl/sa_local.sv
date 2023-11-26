module sa_local
  import rvh_noc_pkg::*;
#(
  parameter INPUT_NUM = 4,
  parameter INPUT_NUM_IDX_W = INPUT_NUM > 1 ? $clog2(INPUT_NUM) : 1
)
(
  // input to allocate
  input  logic      [INPUT_NUM-1:0]   vc_ctrl_head_vld_i,
  input  flit_dec_t [INPUT_NUM-1:0]   vc_ctrl_head_i,

  // output to global allocate
  output logic      [OUTPUT_PORT_NUMBER-1:0]    sa_local_vld_to_sa_global_o,
  output logic                                  sa_local_vld_o,
  output logic      [INPUT_NUM_IDX_W-1:0]       sa_local_vc_id_o,
  output logic      [INPUT_NUM-1:0]             sa_local_vc_id_oh_o,
`ifdef USE_QOS_VALUE
  output logic      [QoS_Value_Width-1:0]       sa_local_qos_value_o,
`endif
`ifdef VC_DATA_USE_DUAL_PORT_RAM
  output dpram_used_idx_t                       sa_local_dpram_idx_o,
`endif


  // input pop flit ctrl fifo (comes from SA stage), use to update rr arbiter pointer
  input logic                           inport_read_enable_sa_stage_i,

  input  logic clk,
  input  logic rstn
);
genvar i,j;
logic [INPUT_NUM-1:0]       sa_local_grt_oh;
logic [INPUT_NUM_IDX_W-1:0] sa_local_grt_idx;

logic [INPUT_NUM-1:0]   vc_ctrl_head_vld_join_arb; // for qos, if no qos, it is same as vc_ctrl_head_vld_i


io_port_t [INPUT_NUM-1:0]                         vc_ctrl_head_i_look_ahead_routing;
logic     [INPUT_NUM-1:0][OUTPUT_PORT_NUMBER-1:0] vc_ctrl_head_i_look_ahead_routing_match;

`ifdef USE_QOS_VALUE
logic                    [QoS_Value_Width-1:0] vc_ctrl_head_i_qos_value_sel;
`endif

flit_dec_t  vc_ctrl_head_sel;


`ifdef USE_QOS_VALUE

  logic [INPUT_NUM-1:0][QoS_Value_Width-1:0] vc_ctrl_head_qos_value;
  generate
    for(i = 0; i < INPUT_NUM; i++) begin: gen_vc_ctrl_head_qos_value
      assign vc_ctrl_head_qos_value [i] = vc_ctrl_head_i[i].qos_value;
    end
  endgenerate

  priority_req_select
  #(
    .INPUT_NUM        ( INPUT_NUM  ),
    .INPUT_PRIORITY_W ( QoS_Value_Width )
  )
  sa_local_priority_req_select_u (
    .req_vld_i      (vc_ctrl_head_vld_i         ),
    .req_priority_i (vc_ctrl_head_qos_value     ),
    .req_vld_o      (vc_ctrl_head_vld_join_arb  )
  );

`else

  assign vc_ctrl_head_vld_join_arb = vc_ctrl_head_vld_i;

`endif


one_hot_rr_arb #(
  .N_INPUT  (INPUT_NUM),

  .TIMEOUT_UPDATE_EN    (1 ),
  .TIMEOUT_UPDATE_CYCLE (10)
)
sa_local_rr_arb_u
(
  .req_i        (vc_ctrl_head_vld_join_arb ),
  .update_i     (inport_read_enable_sa_stage_i), // use global arbiter result to update: if win the global arbiter update local rr arbiter, or may be no fair
  .grt_o        (sa_local_grt_oh    ),
  .grt_idx_o    (sa_local_grt_idx   ),

  .rstn         (rstn ),
  .clk          (clk  )
);



assign sa_local_vc_id_o     = sa_local_grt_idx;
assign sa_local_vc_id_oh_o  = sa_local_grt_oh;
`ifdef USE_QOS_VALUE
assign sa_local_qos_value_o = vc_ctrl_head_sel.qos_value;
`endif
`ifdef VC_DATA_USE_DUAL_PORT_RAM
assign sa_local_dpram_idx_o.dpram_idx   = vc_ctrl_head_sel.dpram_used_idx.dpram_idx;
assign sa_local_dpram_idx_o.per_vc_idx  = vc_ctrl_head_sel.dpram_used_idx.per_vc_idx;
`endif
assign sa_local_vld_o   = |vc_ctrl_head_vld_join_arb;
generate
  for(i = 0; i < OUTPUT_PORT_NUMBER; i++) begin
    assign sa_local_vld_to_sa_global_o[i] = vc_ctrl_head_vld_join_arb[sa_local_grt_idx] &
                                            vc_ctrl_head_i_look_ahead_routing_match[sa_local_grt_idx][i];
  end
endgenerate



generate
  for(i = 0; i < INPUT_NUM; i++) begin
    assign vc_ctrl_head_i_look_ahead_routing[i] = vc_ctrl_head_i[i].look_ahead_routing;
  end
endgenerate


generate
  for(i = 0; i < INPUT_NUM; i++) begin: gen_vc_ctrl_head_i_look_ahead_routing_match_i
    for(j = 0; j < OUTPUT_PORT_NUMBER; j++) begin: gen_vc_ctrl_head_i_look_ahead_routing_match_j
      assign vc_ctrl_head_i_look_ahead_routing_match[i][j] = vc_ctrl_head_i_look_ahead_routing[i] == j[$bits(io_port_t)-1:0];
    end
  end
endgenerate


onehot_mux 
#(
  .SOURCE_COUNT(INPUT_NUM ),
  .DATA_WIDTH  ($bits(flit_dec_t))
)
onehot_mux_qos_value_sel_u (
  .sel_i    (sa_local_grt_oh ),
  .data_i   (vc_ctrl_head_i ),
  .data_o   (vc_ctrl_head_sel)
);



endmodule
