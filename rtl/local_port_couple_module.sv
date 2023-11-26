// this module is at local device side, use to handle local device credit based flow control
module local_port_couple_module
import rvh_noc_pkg::*;
#(
  parameter VC_NUM_OUTPORT   = 2,
  parameter VC_NUM_OUTPORT_IDX_W = VC_NUM_OUTPORT > 1 ? $clog2(VC_NUM_OUTPORT) : 1,
  parameter VC_DEPTH_OUTPORT = 2,
  parameter VC_DEPTH_OUTPORT_COUNTER_W = $clog2(VC_DEPTH_OUTPORT + 1),

  // for local ports, always OUTPUT_TO_L
  parameter OUTPUT_TO_N = 0,
  parameter OUTPUT_TO_S = 0,
  parameter OUTPUT_TO_E = 0,
  parameter OUTPUT_TO_W = 0,
  parameter OUTPUT_TO_L = 1
)
(
  // input vc head to calculate next routing
  input  logic [NodeID_X_Width-1:0]       node_id_x_tgt_i,
  input  logic [NodeID_Y_Width-1:0]       node_id_y_tgt_i,
`ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER
  input  logic [NodeID_Device_Port_Width-1:0] device_port_tgt_i,
`endif

  // input this hop xy addr
  input  logic [NodeID_X_Width-1:0]       node_id_x_src_i,
  input  logic [NodeID_Y_Width-1:0]       node_id_y_src_i,

  // output look ahead routing result
  output io_port_t                        look_ahead_routing_o,

  // free credit in from router
  input  logic                            tx_lcrd_v_i,
  input  logic  [VC_ID_NUM_MAX_W-1:0]     tx_lcrd_id_i,

  // consume credit
  input  logic                            flit_vld_i,
  input  logic [QoS_Value_Width-1:0]      flit_qos_value_i,
  output logic                            free_credit_vld_o,
  output logic [VC_NUM_OUTPORT_IDX_W-1:0] free_credit_vc_id_o,

  input  logic clk,
  input  logic rstn
);

logic [VC_NUM_OUTPORT-1:0][VC_DEPTH_OUTPORT_COUNTER_W-1:0] vc_credit_counter;
logic [VC_NUM_OUTPORT-1:0]                                 vc_credit_counter_non_zero;
logic [VC_NUM_OUTPORT-QOS_VC_NUM_PER_INPUT-1:0]         vc_allocate_common_vc_grt_oh;
logic [$clog2(VC_NUM_OUTPORT-QOS_VC_NUM_PER_INPUT)-1:0] vc_allocate_common_vc_grt_idx;
`ifdef COMMON_QOS_EXTRA_RT_VC
logic [QOS_VC_NUM_PER_INPUT-1:0]                        vc_allocate_rt_vc_grt_oh;
logic [$clog2(QOS_VC_NUM_PER_INPUT)-1:0]                vc_allocate_rt_vc_grt_idx;
`else
logic [1-1:0]                                           vc_allocate_rt_vc_grt_oh;
logic [$clog2(1)-1:0]                                   vc_allocate_rt_vc_grt_idx;
`endif

logic [VC_NUM_OUTPORT_IDX_W-1:0] preferred_vc_id;

// to send flit buffer
logic       flit_buffer_head_rt_vc_en;

logic free_credit_vld;
logic flit_buffer_dequeue_vld;

logic                            consume_vc_credit_vld;
logic [VC_NUM_OUTPORT_IDX_W-1:0] consume_vc_credit_vc_id;


// 1st phase: calculate look ahead routing
local_port_look_adead_routing 
local_port_look_adead_routing_u 
(
  .node_id_x_tgt_i      (node_id_x_tgt_i ),
  .node_id_y_tgt_i      (node_id_y_tgt_i ),
`ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER
  .device_port_tgt_i    (device_port_tgt_i),
`endif
  .node_id_x_src_i      (node_id_x_src_i ),
  .node_id_y_src_i      (node_id_y_src_i ),
  .look_ahead_routing_o ( look_ahead_routing_o)
);

// 2nd phase: choose input vc

assign flit_buffer_head_rt_vc_en = QOS_VC_NUM_PER_INPUT && (flit_qos_value_i == '1);

assign free_credit_vld = (
`ifdef COMMON_QOS_EXTRA_RT_VC
                                  (flit_buffer_head_rt_vc_en  & (|(vc_credit_counter_non_zero[QOS_VC_NUM_PER_INPUT-1:0]))) |
`endif
                                  (~flit_buffer_head_rt_vc_en & (|(vc_credit_counter_non_zero[VC_NUM_OUTPORT-1:QOS_VC_NUM_PER_INPUT])))
                              );

assign free_credit_vld_o    = free_credit_vld;
assign free_credit_vc_id_o  = consume_vc_credit_vc_id;

assign flit_buffer_dequeue_vld = flit_vld_i &  // head valid
                                 free_credit_vld; // vc not empty

// rr for vc allocation
generate
  for(genvar i = 0; i < VC_NUM_OUTPORT; i++) begin: gen_vc_credit_counter_non_zero
    assign vc_credit_counter_non_zero[i] = ~(vc_credit_counter[i] == '0);
  end
endgenerate

one_hot_rr_arb #(
  .N_INPUT  (VC_NUM_OUTPORT-QOS_VC_NUM_PER_INPUT)
)
vc_allocate_common_vc_rr_arb_u
(
  .req_i        (vc_credit_counter_non_zero[VC_NUM_OUTPORT-1:QOS_VC_NUM_PER_INPUT] ),
  .update_i     (|(vc_credit_counter_non_zero[VC_NUM_OUTPORT-1:QOS_VC_NUM_PER_INPUT])),
  .grt_o        (vc_allocate_common_vc_grt_oh    ),
  .grt_idx_o    (vc_allocate_common_vc_grt_idx   ),

  .rstn         (rstn ),
  .clk          (clk  )
);

`ifdef COMMON_QOS_EXTRA_RT_VC
  generate
    if(QOS_VC_NUM_PER_INPUT > 1) begin: gen_vc_allocate_rt_vc_rr_arb_u
      one_hot_rr_arb #(
        .N_INPUT  (QOS_VC_NUM_PER_INPUT)
      )
      vc_allocate_rt_vc_rr_arb_u
      (
        .req_i        (vc_credit_counter_non_zero[QOS_VC_NUM_PER_INPUT-1:0] ),
        .update_i     (|(vc_credit_counter_non_zero[QOS_VC_NUM_PER_INPUT-1:0])),
        .grt_o        (vc_allocate_rt_vc_grt_oh    ),
        .grt_idx_o    (vc_allocate_rt_vc_grt_idx   ),
      
        .rstn         (rstn ),
        .clk          (clk  )
      );
    end else begin
      assign vc_allocate_rt_vc_grt_oh  = vc_credit_counter_non_zero[0];
      assign vc_allocate_rt_vc_grt_idx = '0;
    end
  endgenerate
`else
assign vc_allocate_rt_vc_grt_oh  = '0;
assign vc_allocate_rt_vc_grt_idx = '0;
`endif

// credit counter
assign consume_vc_credit_vld    = flit_buffer_dequeue_vld;
assign consume_vc_credit_vc_id  = flit_buffer_head_rt_vc_en ? vc_allocate_rt_vc_grt_idx :
                                  vc_credit_counter_non_zero[preferred_vc_id] ? preferred_vc_id :
                                                                                vc_allocate_common_vc_grt_idx+QOS_VC_NUM_PER_INPUT;

output_port_vc_credit_counter
#(
  .VC_NUM   (VC_NUM_OUTPORT   ),
  .VC_DEPTH (VC_DEPTH_OUTPORT )
)
output_port_vc_credit_counter_u (
  .free_vc_credit_vld_i       (tx_lcrd_v_i             ),
  .free_vc_credit_vc_id_i     (tx_lcrd_id_i            ),
  .consume_vc_credit_vld_i    (consume_vc_credit_vld   ),
  .consume_vc_credit_vc_id_i  (consume_vc_credit_vc_id ),
  .vc_credit_counter_o        (vc_credit_counter       ),
  .clk                        (clk  ),
  .rstn                       (rstn )
);


// select preferred vc id for different output ports
// to N vc:
// vc0
generate

  if(OUTPUT_TO_N) begin: gen_output_to_n // output to N, next hop input is S
    always_comb begin
      preferred_vc_id = '0;
      unique case(look_ahead_routing_o)
        S: begin
          preferred_vc_id = 0;
        end
        L0: begin
          preferred_vc_id = 1;
        end
`ifdef LOCAL_PORT_NUM_2
        L1: begin
          preferred_vc_id = 2;
        end
`endif
`ifdef LOCAL_PORT_NUM_3
        L2: begin
          preferred_vc_id = 3;
        end
`endif
`ifdef LOCAL_PORT_NUM_4
        L3: begin
          preferred_vc_id = 4;
        end
`endif
        default: begin
        end
      endcase
      preferred_vc_id = preferred_vc_id + QOS_VC_NUM_PER_INPUT;
    end
  end

  if(OUTPUT_TO_S) begin: gen_output_to_s // output to S, next hop input is N
    always_comb begin
      preferred_vc_id = '0;
      unique case(look_ahead_routing_o)
        N: begin
          preferred_vc_id = 0;
        end
        L0: begin
          preferred_vc_id = 1;
        end
`ifdef LOCAL_PORT_NUM_2
        L1: begin
          preferred_vc_id = 2;
        end
`endif
`ifdef LOCAL_PORT_NUM_3
        L2: begin
          preferred_vc_id = 3;
        end
`endif
`ifdef LOCAL_PORT_NUM_4
        L3: begin
          preferred_vc_id = 4;
        end
`endif
        default: begin
        end
      endcase
      preferred_vc_id = preferred_vc_id + QOS_VC_NUM_PER_INPUT;
    end
  end

  if(OUTPUT_TO_E) begin: gen_output_to_e // output to E, next hop input is W
    always_comb begin
      preferred_vc_id = '0;
      unique case(look_ahead_routing_o)
        N: begin
          preferred_vc_id = 0;
        end
        S: begin
          preferred_vc_id = 1;
        end
        W: begin
          preferred_vc_id = 2;
        end
        L0: begin
          preferred_vc_id = 3;
        end
`ifdef LOCAL_PORT_NUM_2
        L1: begin
          preferred_vc_id = 4;
        end
`endif
`ifdef LOCAL_PORT_NUM_3
        L2: begin
          preferred_vc_id = 5;
        end
`endif
`ifdef LOCAL_PORT_NUM_4
        L3: begin
          preferred_vc_id = 6;
        end
`endif
        default: begin
        end
      endcase
      preferred_vc_id = preferred_vc_id + QOS_VC_NUM_PER_INPUT;
    end
  end

  if(OUTPUT_TO_W) begin: gen_output_to_w // output to W, next hop input is E
    always_comb begin
      preferred_vc_id = '0;
      unique case(look_ahead_routing_o)
        N: begin
          preferred_vc_id = 0;
        end
        S: begin
          preferred_vc_id = 1;
        end
        E: begin
          preferred_vc_id = 2;
        end
        L0: begin
          preferred_vc_id = 3;
        end
`ifdef LOCAL_PORT_NUM_2
        L1: begin
          preferred_vc_id = 4;
        end
`endif
`ifdef LOCAL_PORT_NUM_3
        L2: begin
          preferred_vc_id = 5;
        end
`endif
`ifdef LOCAL_PORT_NUM_4
        L3: begin
          preferred_vc_id = 6;
        end
`endif
        default: begin
        end
      endcase
      preferred_vc_id = preferred_vc_id + QOS_VC_NUM_PER_INPUT;
    end
  end

  if(OUTPUT_TO_L) begin: gen_output_to_l // output to L, no next hop
    always_comb begin
      preferred_vc_id = '0;
      unique case(look_ahead_routing_o) // assume all local port have 1 vc
        default: begin
          preferred_vc_id = '0;
        end
      endcase
      preferred_vc_id = preferred_vc_id + QOS_VC_NUM_PER_INPUT;
    end
  end

endgenerate

endmodule
