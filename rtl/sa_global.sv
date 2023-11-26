module sa_global
  import rvh_noc_pkg::*;
#(
  parameter INPUT_NUM       = 4,
  parameter INPUT_NUM_IDX_W = INPUT_NUM > 1 ? $clog2(INPUT_NUM) : 1
)
(
  // input to allocate
  input  logic [INPUT_NUM-1:0]                      sa_local_vld_i,
  input  logic [INPUT_NUM-1:0][VC_ID_NUM_MAX_W-1:0] sa_local_vc_id_i,
`ifdef USE_QOS_VALUE
  input  logic [INPUT_NUM-1:0][QoS_Value_Width-1:0] sa_local_qos_value_i,
`endif

  // output to VC assignment
  output logic                                  sa_global_vld_o,
`ifdef COMMON_QOS_EXTRA_RT_VC
  output logic [QoS_Value_Width-1:0]            sa_global_qos_value_o,
`endif
  output logic [INPUT_NUM-1:0]                  sa_global_inport_id_oh_o,
  output logic [VC_ID_NUM_MAX_W-1:0]            sa_global_inport_vc_id_o,

  // input from vc assignment for rr arbiter update
  input  logic                                  vc_assignment_vld_i,

  input  logic clk,
  input  logic rstn
);

logic [INPUT_NUM-1:0]       sa_global_grt_oh;
logic [INPUT_NUM_IDX_W-1:0] sa_global_grt_idx;

logic [INPUT_NUM-1:0]   sa_local_vld_join_arb; // for qos, if no qos, it is same as sa_local_vld_i


`ifdef USE_QOS_VALUE

  priority_req_select
  #(
    .INPUT_NUM        ( INPUT_NUM  ),
    .INPUT_PRIORITY_W ( QoS_Value_Width )
  )
  sa_local_priority_req_select_u (
    .req_vld_i      (sa_local_vld_i         ),
    .req_priority_i (sa_local_qos_value_i   ),
    .req_vld_o      (sa_local_vld_join_arb  )
  );

`else

  assign sa_local_vld_join_arb = sa_local_vld_i;

`endif


one_hot_rr_arb #(
  .N_INPUT  (INPUT_NUM),

  .TIMEOUT_UPDATE_EN    (1 ),
  .TIMEOUT_UPDATE_CYCLE (10)
)
sa_global_rr_arb_u
(
  .req_i        (sa_local_vld_join_arb ),
  .update_i     (vc_assignment_vld_i ),
  .grt_o        (sa_global_grt_oh    ),
  .grt_idx_o    (sa_global_grt_idx   ),

  .rstn         (rstn ),
  .clk          (clk  )
);

assign sa_global_vld_o          = |sa_local_vld_join_arb;
assign sa_global_inport_id_oh_o = sa_global_grt_oh;
// assign sa_global_inport_vc_id_o = sa_local_vc_id_i[sa_global_grt_idx];

onehot_mux
#(
  .SOURCE_COUNT(INPUT_NUM ),
  .DATA_WIDTH  (VC_ID_NUM_MAX_W )
)
onehot_mux_sa_global_inport_vc_id_o_u (
  .sel_i    (sa_global_grt_oh ),
  .data_i   (sa_local_vc_id_i ),
  .data_o   (sa_global_inport_vc_id_o)
);

`ifdef COMMON_QOS_EXTRA_RT_VC
onehot_mux
#(
  .SOURCE_COUNT(INPUT_NUM ),
  .DATA_WIDTH  (QoS_Value_Width )
)
onehot_mux_sa_global_qos_value_o_u (
  .sel_i    (sa_global_grt_oh ),
  .data_i   (sa_local_qos_value_i ),
  .data_o   (sa_global_qos_value_o)
);
`endif

endmodule
