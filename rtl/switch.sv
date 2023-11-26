module switch
import rvh_noc_pkg::*;
#(
  parameter INPUT_PORT_NUM = 5,
  parameter OUTPUT_PORT_NUM = 5,
  parameter LOCAL_PORT_NUM  = INPUT_PORT_NUM-4,

  parameter type flit_payload_t = logic[256-1:0],
 
  parameter VC_NUM_INPUT_N = 2,
  parameter VC_NUM_INPUT_S = 2,
  parameter VC_NUM_INPUT_E = 4,
  parameter VC_NUM_INPUT_W = 4,
  parameter VC_NUM_INPUT_L = 4,
  parameter VC_NUM_INPUT_N_IDX_W = VC_NUM_INPUT_N > 1 ? $clog2(VC_NUM_INPUT_N) : 1,
  parameter VC_NUM_INPUT_S_IDX_W = VC_NUM_INPUT_S > 1 ? $clog2(VC_NUM_INPUT_S) : 1,
  parameter VC_NUM_INPUT_E_IDX_W = VC_NUM_INPUT_E > 1 ? $clog2(VC_NUM_INPUT_E) : 1,
  parameter VC_NUM_INPUT_W_IDX_W = VC_NUM_INPUT_W > 1 ? $clog2(VC_NUM_INPUT_W) : 1,
  parameter VC_NUM_INPUT_L_IDX_W = VC_NUM_INPUT_L > 1 ? $clog2(VC_NUM_INPUT_L) : 1

)
(
  // input flit data from input port buffer
  input  flit_payload_t [VC_NUM_INPUT_N-1:0] vc_data_head_fromN_i,
  input  flit_payload_t [VC_NUM_INPUT_S-1:0] vc_data_head_fromS_i,
  input  flit_payload_t [VC_NUM_INPUT_E-1:0] vc_data_head_fromE_i,
  input  flit_payload_t [VC_NUM_INPUT_W-1:0] vc_data_head_fromW_i,
`ifdef HAVE_LOCAL_PORT
  input  flit_payload_t [LOCAL_PORT_NUM-1:0][VC_NUM_INPUT_L-1:0] vc_data_head_fromL_i,
`endif

  // input switch ctrl from SA to ST stage reg
  input  logic     [INPUT_PORT_NUM-1:0]                      inport_read_enable_st_stage_i,
  // input  io_port_t [INPUT_PORT_NUM-1:0]                      inport_read_outport_id_st_stage_i,
  input  logic     [INPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0] inport_read_vc_id_st_stage_i,
  // input  io_port_t [INPUT_PORT_NUM-1:0]                      inport_look_ahead_routing_st_stage_i,

  input  logic     [OUTPUT_PORT_NUM-1:0]                      outport_vld_st_stage_i,
  input  io_port_t [OUTPUT_PORT_NUM-1:0]                      outport_select_inport_id_st_stage_i,
  input  logic     [OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0] outport_vc_id_st_stage_i,
  input  io_port_t [OUTPUT_PORT_NUM-1:0]                      outport_look_ahead_routing_st_stage_i,

  // output flit data and look ahead routing to outport
  output logic          [OUTPUT_PORT_NUM-1:0]                      tx_flit_pend_o,
  output logic          [OUTPUT_PORT_NUM-1:0]                      tx_flit_v_o,
  output flit_payload_t [OUTPUT_PORT_NUM-1:0]                      tx_flit_o,
  output logic          [OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0] tx_flit_vc_id_o,
  output io_port_t      [OUTPUT_PORT_NUM-1:0]                      tx_flit_look_ahead_routing_o

);

genvar i;

// link flit clk gating
assign tx_flit_pend_o = '1; // TODO: by now receiver assuming always expecting a new flit

// select the output flit from per inport
flit_payload_t  [INPUT_PORT_NUM-1:0] vc_head_data;

`ifdef VC_DATA_USE_DUAL_PORT_RAM // for dpram, only one flit would be read from per input_port, and always assign it in slot 0
assign vc_head_data[0] = vc_data_head_fromN_i[0]; // from N
assign vc_head_data[1] = vc_data_head_fromS_i[0]; // from S
assign vc_head_data[2] = vc_data_head_fromE_i[0]; // from E
assign vc_head_data[3] = vc_data_head_fromW_i[0]; // from W
generate
  if(LOCAL_PORT_NUM > 0) begin: gen_have_vc_data_head_fromL_i
    for(i = 0; i < LOCAL_PORT_NUM; i++) begin: gen_vc_data_head_fromL_i
      assign vc_head_data[4+i] = vc_data_head_fromL_i[i][0]; // from L
    end
  end
endgenerate
`else
assign vc_head_data[0] = vc_data_head_fromN_i[inport_read_vc_id_st_stage_i[0][VC_NUM_INPUT_N_IDX_W-1:0]]; // from N
assign vc_head_data[1] = vc_data_head_fromS_i[inport_read_vc_id_st_stage_i[1][VC_NUM_INPUT_S_IDX_W-1:0]]; // from S
assign vc_head_data[2] = vc_data_head_fromE_i[inport_read_vc_id_st_stage_i[2][VC_NUM_INPUT_E_IDX_W-1:0]]; // from E
assign vc_head_data[3] = vc_data_head_fromW_i[inport_read_vc_id_st_stage_i[3][VC_NUM_INPUT_W_IDX_W-1:0]]; // from W
generate
  if(LOCAL_PORT_NUM > 0) begin: gen_have_vc_data_head_fromL_i
    for(i = 0; i < LOCAL_PORT_NUM; i++) begin: gen_vc_data_head_fromL_i
      assign vc_head_data[4+i] = vc_data_head_fromL_i[i][inport_read_vc_id_st_stage_i[4+i][VC_NUM_INPUT_L_IDX_W-1:0]]; // from L
    end
  end
endgenerate
`endif


// map per valid inport head flit to outport

  // map vld
assign tx_flit_v_o = outport_vld_st_stage_i;

  // map receiver vc id
assign tx_flit_vc_id_o = outport_vc_id_st_stage_i;

  // map look ahead routing
assign tx_flit_look_ahead_routing_o = outport_look_ahead_routing_st_stage_i;

  // map data
    // to N
always_comb begin
  unique case(outport_select_inport_id_st_stage_i[0])
    S: begin
      tx_flit_o[0] = vc_head_data[1];
    end
    E: begin
      tx_flit_o[0] = vc_head_data[2];
    end
    W: begin
      tx_flit_o[0] = vc_head_data[3];
    end
    L0: begin
      tx_flit_o[0] = vc_head_data[4];
    end
`ifdef LOCAL_PORT_NUM_2
    L1: begin
      tx_flit_o[0] = vc_head_data[5];
    end
`endif
`ifdef LOCAL_PORT_NUM_3
    L2: begin
      tx_flit_o[0] = vc_head_data[6];
    end
`endif
`ifdef LOCAL_PORT_NUM_4
    L3: begin
      tx_flit_o[0] = vc_head_data[7];
    end
`endif
    default: begin
      tx_flit_o[0] = vc_head_data[1];
    end
  endcase
end

    // to S
always_comb begin
  unique case(outport_select_inport_id_st_stage_i[1])
    N: begin
      tx_flit_o[1] = vc_head_data[0];
    end
    E: begin
      tx_flit_o[1] = vc_head_data[2];
    end
    W: begin
      tx_flit_o[1] = vc_head_data[3];
    end
    L0: begin
      tx_flit_o[1] = vc_head_data[4];
    end
`ifdef LOCAL_PORT_NUM_2
    L1: begin
      tx_flit_o[1] = vc_head_data[5];
    end
`endif
`ifdef LOCAL_PORT_NUM_3
    L2: begin
      tx_flit_o[1] = vc_head_data[6];
    end
`endif
`ifdef LOCAL_PORT_NUM_4
    L3: begin
      tx_flit_o[1] = vc_head_data[7];
    end
`endif
    default: begin
      tx_flit_o[1] = vc_head_data[0];
    end
  endcase
end

    // to E
always_comb begin
  unique case(outport_select_inport_id_st_stage_i[2])
    W: begin
      tx_flit_o[2] = vc_head_data[3];
    end
    L0: begin
      tx_flit_o[2] = vc_head_data[4];
    end
`ifdef LOCAL_PORT_NUM_2
    L1: begin
      tx_flit_o[2] = vc_head_data[5];
    end
`endif
`ifdef LOCAL_PORT_NUM_3
    L2: begin
      tx_flit_o[2] = vc_head_data[6];
    end
`endif
`ifdef LOCAL_PORT_NUM_4
    L3: begin
      tx_flit_o[2] = vc_head_data[7];
    end
`endif
    default: begin
      tx_flit_o[2] = vc_head_data[3];
    end
  endcase
end

    // to W
always_comb begin
  unique case(outport_select_inport_id_st_stage_i[3])
    E: begin
      tx_flit_o[3] = vc_head_data[2];
    end
    L0: begin
      tx_flit_o[3] = vc_head_data[4];
    end
`ifdef LOCAL_PORT_NUM_2
    L1: begin
      tx_flit_o[3] = vc_head_data[5];
    end
`endif
`ifdef LOCAL_PORT_NUM_3
    L2: begin
      tx_flit_o[3] = vc_head_data[6];
    end
`endif
`ifdef LOCAL_PORT_NUM_4
    L3: begin
      tx_flit_o[3] = vc_head_data[7];
    end
`endif
    default: begin
      tx_flit_o[3] = vc_head_data[2];
    end
  endcase
end

    // to L
generate
  if(LOCAL_PORT_NUM > 0) begin: gen_have_multi_local_port_in_switch
    for(i = 0; i < LOCAL_PORT_NUM; i++) begin: gen_multi_local_port_in_switch
      always_comb begin
        unique case(outport_select_inport_id_st_stage_i[4+i])
          N: begin
            tx_flit_o[4+i] = vc_head_data[0];
          end
          S: begin
            tx_flit_o[4+i] = vc_head_data[1];
          end
          E: begin
            tx_flit_o[4+i] = vc_head_data[2];
          end
          W: begin
            tx_flit_o[4+i] = vc_head_data[3];
          end
`ifdef HAVE_LOCAL_PORT
          L0: begin
            tx_flit_o[4+i] = vc_head_data[4];
          end
`endif
`ifdef LOCAL_PORT_NUM_2
          L1: begin
            tx_flit_o[4+i] = vc_head_data[5];
          end
`endif
`ifdef LOCAL_PORT_NUM_3
          L2: begin
            tx_flit_o[4+i] = vc_head_data[6];
          end
`endif
`ifdef LOCAL_PORT_NUM_4
          L3: begin
            tx_flit_o[4+i] = vc_head_data[7];
          end
`endif
          default: begin
            tx_flit_o[4+i] = vc_head_data[0];
          end
        endcase
      end
    end
  end
endgenerate


endmodule
