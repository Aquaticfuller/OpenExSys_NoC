// vc assignment per output port: assign the final allocated vc to the flit from global sa, use the vc selected at vc selection
module output_port_vc_assignment
import rvh_noc_pkg::*;
#(
parameter OUTPUT_VC_NUM         = 4,
parameter OUTPUT_VC_NUM_IDX_W   = OUTPUT_VC_NUM > 1 ? $clog2(OUTPUT_VC_NUM) : 1,

parameter SA_GLOBAL_INPUT_NUM = 4,
parameter SA_GLOBAL_INPUT_NUM_IDX_W = SA_GLOBAL_INPUT_NUM > 1 ? $clog2(SA_GLOBAL_INPUT_NUM) : 1,

parameter OUTPUT_TO_N = 0,
parameter OUTPUT_TO_S = 0,
parameter OUTPUT_TO_E = 0,
parameter OUTPUT_TO_W = 0,
parameter OUTPUT_TO_L = 0
)
(
// input from global sa
input  logic                                              sa_global_vld_i,
// input  logic [SA_GLOBAL_INPUT_NUM_IDX_W-1:0]              sa_global_inport_id_i,
`ifdef COMMON_QOS_EXTRA_RT_VC
input  logic [QoS_Value_Width-1:0]                        sa_global_qos_value_i,
`endif
input  logic [SA_GLOBAL_INPUT_NUM-1:0]                    sa_global_inport_id_oh_i,

// input from look-ahead-routing
input  io_port_t [SA_GLOBAL_INPUT_NUM-1:0]                look_ahead_routing_i, // NOTICE: not all routing results, only the ones connected to this global sa

// input from vc selection
input  vc_select_vld_t    [OUTPUT_VC_NUM-1:0]             vc_select_vld_i,
input  vc_select_vc_id_t  [OUTPUT_VC_NUM-1:0]             vc_select_vc_id_i,

// output
output logic                                              vc_assignment_vld_o,
output logic [VC_ID_NUM_MAX_W-1:0]                        vc_assignment_vc_id_o,
output io_port_t                                          look_ahead_routing_sel_o
);

genvar i;

// select the look-ahead routing of the flit which wins the global sa
io_port_t look_ahead_routing_sel;
// assign look_ahead_routing_sel   = look_ahead_routing_i[sa_global_inport_id_i];
onehot_mux 
#(
  .SOURCE_COUNT(SA_GLOBAL_INPUT_NUM ),
  .DATA_WIDTH  ($bits(io_port_t) )
)
onehot_mux_look_ahead_routing_sel_u (
  .sel_i    (sa_global_inport_id_oh_i ),
  .data_i   (look_ahead_routing_i ),
  .data_o   (look_ahead_routing_sel)
);
assign look_ahead_routing_sel_o = look_ahead_routing_sel;


logic                                          sa_global_sel_rt_vc_flit_en;
logic [OUTPUT_VC_NUM-QOS_VC_NUM_PER_INPUT-1:0]                      vc_select_vld;   // if local port as outport, doesn't take rt vc into consideration
logic [OUTPUT_VC_NUM-QOS_VC_NUM_PER_INPUT-1:0][VC_ID_NUM_MAX_W-1:0] vc_select_vc_id; // if local port as outport, doesn't take rt vc into consideration

`ifdef COMMON_QOS_EXTRA_RT_VC
assign sa_global_sel_rt_vc_flit_en = &sa_global_qos_value_i; // rt vc has highest QoS value
`else
assign sa_global_sel_rt_vc_flit_en = '0;
`endif


// vc_select_vld
// for vc_select_vld_i, the [0:QOS_VC_NUM_PER_INPUT-1] is rt vc, [QOS_VC_NUM_PER_INPUT:OUTPUT_VC_NUM-1] is common vc
generate
  for(i = 0; i < OUTPUT_VC_NUM-QOS_VC_NUM_PER_INPUT; i++) begin: gen_vc_select_vld
    assign vc_select_vld[i] = sa_global_sel_rt_vc_flit_en ? vc_select_vld_i[0].rt_vld : vc_select_vld_i[i+QOS_VC_NUM_PER_INPUT].common_vld;
  end
endgenerate

// vc_select_vc_id
generate
  for(i = 0; i < OUTPUT_VC_NUM-QOS_VC_NUM_PER_INPUT; i++) begin: gen_vc_select_vc_id
    assign vc_select_vc_id[i] = sa_global_sel_rt_vc_flit_en ? vc_select_vc_id_i[0].rt_vc_id : vc_select_vc_id_i[i+QOS_VC_NUM_PER_INPUT].common_vc_id;
  end
endgenerate

// vc assignment for different output ports
// to N vc:
// vc0
generate

  if(OUTPUT_TO_N) begin: gen_output_to_n // output to N, next hop input is S
    always_comb begin
      vc_assignment_vld_o   = 1'b0;
      vc_assignment_vc_id_o = '0;
      unique case(look_ahead_routing_sel)
        N: begin
          vc_assignment_vld_o   = vc_select_vld[0];
          vc_assignment_vc_id_o = vc_select_vc_id[0];
        end
        L0: begin
          vc_assignment_vld_o   = vc_select_vld[1];
          vc_assignment_vc_id_o = vc_select_vc_id[1];
        end
`ifdef LOCAL_PORT_NUM_2
        L1: begin
          vc_assignment_vld_o   = vc_select_vld[2];
          vc_assignment_vc_id_o = vc_select_vc_id[2];
        end
`endif
`ifdef LOCAL_PORT_NUM_3
        L2: begin
          vc_assignment_vld_o   = vc_select_vld[3];
          vc_assignment_vc_id_o = vc_select_vc_id[3];
        end
`endif
`ifdef LOCAL_PORT_NUM_4
        L3: begin
          vc_assignment_vld_o   = vc_select_vld[4];
          vc_assignment_vc_id_o = vc_select_vc_id[4];
        end
`endif
        default: begin
        end
      endcase
    end
  end

  if(OUTPUT_TO_S) begin: gen_output_to_s // output to S, next hop input is N
    always_comb begin
      vc_assignment_vld_o   = 1'b0;
      vc_assignment_vc_id_o = '0;
      unique case(look_ahead_routing_sel)
        S: begin
          vc_assignment_vld_o   = vc_select_vld[0];
          vc_assignment_vc_id_o = vc_select_vc_id[0];
        end
        L0: begin
          vc_assignment_vld_o   = vc_select_vld[1];
          vc_assignment_vc_id_o = vc_select_vc_id[1];
        end
`ifdef LOCAL_PORT_NUM_2
        L1: begin
          vc_assignment_vld_o   = vc_select_vld[2];
          vc_assignment_vc_id_o = vc_select_vc_id[2];
        end
`endif
`ifdef LOCAL_PORT_NUM_3
        L2: begin
          vc_assignment_vld_o   = vc_select_vld[3];
          vc_assignment_vc_id_o = vc_select_vc_id[3];
        end
`endif
`ifdef LOCAL_PORT_NUM_4
        L3: begin
          vc_assignment_vld_o   = vc_select_vld[4];
          vc_assignment_vc_id_o = vc_select_vc_id[4];
        end
`endif
        default: begin
        end
      endcase
    end
  end

  if(OUTPUT_TO_E) begin: gen_output_to_e // output to E, next hop input is W
    always_comb begin
      vc_assignment_vld_o   = 1'b0;
      vc_assignment_vc_id_o = '0;
      unique case(look_ahead_routing_sel)
        N: begin
          vc_assignment_vld_o   = vc_select_vld[0];
          vc_assignment_vc_id_o = vc_select_vc_id[0];
        end
        S: begin
          vc_assignment_vld_o   = vc_select_vld[1];
          vc_assignment_vc_id_o = vc_select_vc_id[1];
        end
        E: begin
          vc_assignment_vld_o   = vc_select_vld[2];
          vc_assignment_vc_id_o = vc_select_vc_id[2];
        end
        L0: begin
          vc_assignment_vld_o   = vc_select_vld[3];
          vc_assignment_vc_id_o = vc_select_vc_id[3];
        end
`ifdef LOCAL_PORT_NUM_2
        L1: begin
          vc_assignment_vld_o   = vc_select_vld[4];
          vc_assignment_vc_id_o = vc_select_vc_id[4];
        end
`endif
`ifdef LOCAL_PORT_NUM_3
        L2: begin
          vc_assignment_vld_o   = vc_select_vld[5];
          vc_assignment_vc_id_o = vc_select_vc_id[5];
        end
`endif
`ifdef LOCAL_PORT_NUM_4
        L3: begin
          vc_assignment_vld_o   = vc_select_vld[6];
          vc_assignment_vc_id_o = vc_select_vc_id[6];
        end
`endif
        default: begin
        end
      endcase
    end
  end

  if(OUTPUT_TO_W) begin: gen_output_to_w // output to W, next hop input is E
    always_comb begin
      vc_assignment_vld_o   = 1'b0;
      vc_assignment_vc_id_o = '0;
      unique case(look_ahead_routing_sel)
        N: begin
          vc_assignment_vld_o   = vc_select_vld[0];
          vc_assignment_vc_id_o = vc_select_vc_id[0];
        end
        S: begin
          vc_assignment_vld_o   = vc_select_vld[1];
          vc_assignment_vc_id_o = vc_select_vc_id[1];
        end
        W: begin
          vc_assignment_vld_o   = vc_select_vld[2];
          vc_assignment_vc_id_o = vc_select_vc_id[2];
        end
        L0: begin
          vc_assignment_vld_o   = vc_select_vld[3];
          vc_assignment_vc_id_o = vc_select_vc_id[3];
        end
`ifdef LOCAL_PORT_NUM_2
        L1: begin
          vc_assignment_vld_o   = vc_select_vld[4];
          vc_assignment_vc_id_o = vc_select_vc_id[4];
        end
`endif
`ifdef LOCAL_PORT_NUM_3
        L2: begin
          vc_assignment_vld_o   = vc_select_vld[5];
          vc_assignment_vc_id_o = vc_select_vc_id[5];
        end
`endif
`ifdef LOCAL_PORT_NUM_4
        L3: begin
          vc_assignment_vld_o   = vc_select_vld[6];
          vc_assignment_vc_id_o = vc_select_vc_id[6];
        end
`endif
        default: begin
        end
      endcase
    end
  end

  if(OUTPUT_TO_L) begin: gen_output_to_l // output to L, no next hop
    always_comb begin
      vc_assignment_vld_o   = 1'b0;
      vc_assignment_vc_id_o = '0;
      unique case(look_ahead_routing_sel) // assume all local port have 1 vc
        default: begin
          vc_assignment_vld_o   = vc_select_vld_i  [0].common_vld;
          vc_assignment_vc_id_o = vc_select_vc_id_i[0].common_vc_id;
        end
      endcase
    end
  end

endgenerate


endmodule
