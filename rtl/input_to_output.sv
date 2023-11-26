// this module connects switch allocation stage to switch traversal stage
// NOTE: if change to sram as input buffer, the read should conduct right after local allocate
module input_to_output
import rvh_noc_pkg::*;
#(
  parameter INPUT_PORT_NUM  = 5,
  parameter OUTPUT_PORT_NUM = 5,
  parameter LOCAL_PORT_NUM  = INPUT_PORT_NUM-4,

  parameter SA_GLOBAL_INPUT_NUM_N = 4,
  parameter SA_GLOBAL_INPUT_NUM_S = 4,
  parameter SA_GLOBAL_INPUT_NUM_E = 2,
  parameter SA_GLOBAL_INPUT_NUM_W = 2,
  parameter SA_GLOBAL_INPUT_NUM_L = 4,
  parameter SA_GLOBAL_INPUT_NUM_N_W = SA_GLOBAL_INPUT_NUM_N > 1 ? $clog2(SA_GLOBAL_INPUT_NUM_N) : 1,
  parameter SA_GLOBAL_INPUT_NUM_S_W = SA_GLOBAL_INPUT_NUM_S > 1 ? $clog2(SA_GLOBAL_INPUT_NUM_S) : 1,
  parameter SA_GLOBAL_INPUT_NUM_E_W = SA_GLOBAL_INPUT_NUM_E > 1 ? $clog2(SA_GLOBAL_INPUT_NUM_E) : 1,
  parameter SA_GLOBAL_INPUT_NUM_W_W = SA_GLOBAL_INPUT_NUM_W > 1 ? $clog2(SA_GLOBAL_INPUT_NUM_W) : 1,
  parameter SA_GLOBAL_INPUT_NUM_L_W = SA_GLOBAL_INPUT_NUM_L > 1 ? $clog2(SA_GLOBAL_INPUT_NUM_L) : 1

)
(
  // input from sa global allocation
  input  logic [OUTPUT_PORT_NUM-1:0]                                  sa_global_vld_i,
  // input  logic [OUTPUT_PORT_NUM-1:0][SA_GLOBAL_INPUT_NUM_MAX_W-1:0]   sa_global_inport_id_i,
  input  logic [OUTPUT_PORT_NUM-1:0][SA_GLOBAL_INPUT_NUM_MAX-1:0]     sa_global_inport_id_oh_i,
  input  logic [OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]             sa_global_inport_vc_id_i,

  // input from vc allocation
  input  logic      [OUTPUT_PORT_NUM-1:0]                             vc_assignment_vld_i,
  input  logic      [OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]        vc_assignment_vc_id_i,
  input  io_port_t  [OUTPUT_PORT_NUM-1:0]                             look_ahead_routing_sel_i,

  // output to input port buffer to get selected flit
  output logic      [INPUT_PORT_NUM-1:0]                              inport_read_enable_o,
  // output io_port_t  [INPUT_PORT_NUM-1:0]                              inport_read_outport_id_o,
  output logic      [INPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]         inport_read_vc_id_o,
  // output io_port_t  [INPUT_PORT_NUM-1:0]                              inport_look_ahead_routing_o,

  // output to switch to let outport select inport
  output logic      [OUTPUT_PORT_NUM-1:0]                             outport_vld_o,
  output io_port_t  [OUTPUT_PORT_NUM-1:0]                             outport_select_inport_id_o,
  output logic      [OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]        outport_vc_id_o,
  output io_port_t  [OUTPUT_PORT_NUM-1:0]                             outport_look_ahead_routing_o,

  // output to outport vc credit counter to consume one credit
  output logic [OUTPUT_PORT_NUM-1:0]                                  consume_vc_credit_vld_o,
  output logic [OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]             consume_vc_credit_vc_id_o
);

genvar i, j, k;

io_port_t [OUTPUT_PORT_NUM-1:0] inport_id_per_outport;
logic [OUTPUT_PORT_NUM-1:0][INPUT_PORT_NUM-1:0] inport_id_oh_per_outport;
logic [INPUT_PORT_NUM-1:0][OUTPUT_PORT_NUM-1:0] outport_id_oh_per_inport;

// outports valid signal
generate
  for(i = 0; i < OUTPUT_PORT_NUM; i++) begin: gen_consume_vc_credit
    assign consume_vc_credit_vld_o  [i] = sa_global_vld_i[i] & vc_assignment_vld_i[i];
    assign consume_vc_credit_vc_id_o[i] = vc_assignment_vc_id_i[i];
  end
endgenerate

assign outport_vld_o                = consume_vc_credit_vld_o;
assign outport_select_inport_id_o   = inport_id_per_outport;
assign outport_vc_id_o              = vc_assignment_vc_id_i;
assign outport_look_ahead_routing_o = look_ahead_routing_sel_i;

// map outports to per inport
  // inport_read_enable_o
generate
  for(i = 0; i < INPUT_PORT_NUM; i++) begin
    for(j = 0; j < OUTPUT_PORT_NUM; j++) begin
      assign outport_id_oh_per_inport[i][j] = inport_id_oh_per_outport[j][i];
    end 
  end
endgenerate


generate
  for(i = 0; i < INPUT_PORT_NUM; i++) begin
    assign inport_read_enable_o[i] = |(outport_id_oh_per_inport[i] & vc_assignment_vld_i);
  end
endgenerate

  // inport_read_vc_id_o
logic [OUTPUT_PORT_NUM-1:0][INPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0] inport_vc_id_oh_per_outport;
logic [INPUT_PORT_NUM-1:0][OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0] outport_vc_id_oh_per_inport;
logic [INPUT_PORT_NUM*VC_ID_NUM_MAX_W-1:0][OUTPUT_PORT_NUM-1:0] outport_vc_id_oh_per_inport_mid1;
logic [INPUT_PORT_NUM*VC_ID_NUM_MAX_W-1:0]                      outport_vc_id_oh_per_inport_mid2;

generate
  for(i = 0; i < OUTPUT_PORT_NUM; i++) begin
    for(j = 0; j < INPUT_PORT_NUM; j++) begin
      assign inport_vc_id_oh_per_outport[i][j] = {VC_ID_NUM_MAX_W{inport_id_oh_per_outport[i][j]}} & sa_global_inport_vc_id_i[i];
    end
  end
endgenerate

generate
  for(i = 0; i < INPUT_PORT_NUM; i++) begin
    for(j = 0; j < OUTPUT_PORT_NUM; j++) begin
      assign outport_vc_id_oh_per_inport[i][j] = inport_vc_id_oh_per_outport[j][i];
    end 
  end
endgenerate

generate
  for(i = 0; i < INPUT_PORT_NUM; i++) begin
    for(j = 0; j < OUTPUT_PORT_NUM; j++) begin
      for(k = 0; k < VC_ID_NUM_MAX_W; k++) begin
        assign outport_vc_id_oh_per_inport_mid1[i*VC_ID_NUM_MAX_W+k][j] = outport_vc_id_oh_per_inport[i][j][k];
      end
    end 
  end
endgenerate

generate
  for(i = 0; i < INPUT_PORT_NUM*VC_ID_NUM_MAX_W; i++) begin
    assign outport_vc_id_oh_per_inport_mid2[i] = |(outport_vc_id_oh_per_inport_mid1[i]);
  end
endgenerate

generate
  for(i = 0; i < INPUT_PORT_NUM; i++) begin
    for(j = 0; j < VC_ID_NUM_MAX_W; j++) begin
      assign inport_read_vc_id_o[i][j] = outport_vc_id_oh_per_inport_mid2[i*VC_ID_NUM_MAX_W+j];
    end
  end
endgenerate




// always_comb begin
//   // inport_read_enable_o = '0;
//   inport_read_vc_id_o  = '0;
//   for(int i = 0; i < INPUT_PORT_NUM; i++) begin
//     for(int j = 0; j < OUTPUT_PORT_NUM; j++) begin
//       if((inport_id_per_outport[j] == i[$bits(io_port_t)-1:0]) & consume_vc_credit_vld_o[j]) begin
//         // inport_read_enable_o        [i] = 1'b1;
//         // inport_read_outport_id_o    [i] = inport_id_per_outport[j];
//         inport_read_vc_id_o         [i] = sa_global_inport_vc_id_i[j];
//         // inport_look_ahead_routing_o [i] = look_ahead_routing_sel_i[j];
//       end
//     end
//   end
// end

// map sa global input no. to router inport no.
  // to N
always_comb begin
  inport_id_per_outport[0] = S;
  inport_id_oh_per_outport[0] = '0;
  unique case(1'b1)
    sa_global_inport_id_oh_i[0][0]: begin
      inport_id_per_outport[0] = S;
      inport_id_oh_per_outport[0][1] = 1'b1;
    end
    sa_global_inport_id_oh_i[0][1]: begin
      inport_id_per_outport[0] = E;
      inport_id_oh_per_outport[0][2] = 1'b1;
    end
    sa_global_inport_id_oh_i[0][2]: begin
      inport_id_per_outport[0] = W;
      inport_id_oh_per_outport[0][3] = 1'b1;
    end
    sa_global_inport_id_oh_i[0][3]: begin
      inport_id_per_outport[0] = L0;
      inport_id_oh_per_outport[0][4] = 1'b1;
    end
`ifdef LOCAL_PORT_NUM_2
    sa_global_inport_id_oh_i[0][4]: begin
      inport_id_per_outport[0] = L1;
      inport_id_oh_per_outport[0][5] = 1'b1;
    end
`endif
`ifdef LOCAL_PORT_NUM_3
    sa_global_inport_id_oh_i[0][5]: begin
      inport_id_per_outport[0] = L2;
      inport_id_oh_per_outport[0][6] = 1'b1;
    end
`endif
`ifdef LOCAL_PORT_NUM_4
    sa_global_inport_id_oh_i[0][6]: begin
      inport_id_per_outport[0] = L3;
      inport_id_oh_per_outport[0][7] = 1'b1;
    end
`endif
    default: begin
    end
  endcase
end

  // to S
always_comb begin
  inport_id_per_outport[1] = N;
  inport_id_oh_per_outport[1] = '0;
  unique case(1'b1)
    sa_global_inport_id_oh_i[1][0]: begin
      inport_id_per_outport[1] = N;
      inport_id_oh_per_outport[1][0] = 1'b1;
    end
    sa_global_inport_id_oh_i[1][1]: begin
      inport_id_per_outport[1] = E;
      inport_id_oh_per_outport[1][2] = 1'b1;
    end
    sa_global_inport_id_oh_i[1][2]: begin
      inport_id_per_outport[1] = W;
      inport_id_oh_per_outport[1][3] = 1'b1;
    end
    sa_global_inport_id_oh_i[1][3]: begin
      inport_id_per_outport[1] = L0;
      inport_id_oh_per_outport[1][4] = 1'b1;
    end
`ifdef LOCAL_PORT_NUM_2
    sa_global_inport_id_oh_i[1][4]: begin
      inport_id_per_outport[1] = L1;
      inport_id_oh_per_outport[1][5] = 1'b1;
    end
`endif
`ifdef LOCAL_PORT_NUM_3
    sa_global_inport_id_oh_i[1][5]: begin
      inport_id_per_outport[1] = L2;
      inport_id_oh_per_outport[1][6] = 1'b1;
    end
`endif
`ifdef LOCAL_PORT_NUM_4
    sa_global_inport_id_oh_i[1][6]: begin
      inport_id_per_outport[1] = L3;
      inport_id_oh_per_outport[1][7] = 1'b1;
    end
`endif
    default: begin
    end
  endcase
end

  // to E
always_comb begin
  inport_id_per_outport[2] = W;
  inport_id_oh_per_outport[2] = '0;
  unique case(1'b1)
    sa_global_inport_id_oh_i[2][0]: begin
      inport_id_per_outport[2] = W;
      inport_id_oh_per_outport[2][3] = 1'b1;
    end
    sa_global_inport_id_oh_i[2][1]: begin
      inport_id_per_outport[2] = L0;
      inport_id_oh_per_outport[2][4] = 1'b1;
    end
`ifdef LOCAL_PORT_NUM_2
    sa_global_inport_id_oh_i[2][2]: begin
      inport_id_per_outport[2] = L1;
      inport_id_oh_per_outport[2][5] = 1'b1;
    end
`endif
`ifdef LOCAL_PORT_NUM_3
    sa_global_inport_id_oh_i[2][3]: begin
      inport_id_per_outport[2] = L2;
      inport_id_oh_per_outport[2][6] = 1'b1;
    end
`endif
`ifdef LOCAL_PORT_NUM_4
    sa_global_inport_id_oh_i[2][4]: begin
      inport_id_per_outport[2] = L3;
      inport_id_oh_per_outport[2][7] = 1'b1;
    end
`endif
    default: begin
    end
  endcase
end

  // to W
always_comb begin
  inport_id_per_outport[3] = E;
  inport_id_oh_per_outport[3] = '0;
  unique case(1'b1)
    sa_global_inport_id_oh_i[3][0]: begin
      inport_id_per_outport[3] = E;
      inport_id_oh_per_outport[3][2] = 1'b1;
    end
    sa_global_inport_id_oh_i[3][1]: begin
      inport_id_per_outport[3] = L0;
      inport_id_oh_per_outport[3][4] = 1'b1;
    end
`ifdef LOCAL_PORT_NUM_2
    sa_global_inport_id_oh_i[3][2]: begin
      inport_id_per_outport[3] = L1;
      inport_id_oh_per_outport[3][5] = 1'b1;
    end
`endif
`ifdef LOCAL_PORT_NUM_3
    sa_global_inport_id_oh_i[3][3]: begin
      inport_id_per_outport[3] = L2;
      inport_id_oh_per_outport[3][6] = 1'b1;
    end
`endif
`ifdef LOCAL_PORT_NUM_4
    sa_global_inport_id_oh_i[3][4]: begin
      inport_id_per_outport[3] = L3;
      inport_id_oh_per_outport[3][7] = 1'b1;
    end
`endif
    default: begin
    end
  endcase
end

  // to L
`ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER // allow local to local transfer, at least 2 local ports per router
    // to L0
always_comb begin
  inport_id_per_outport[4+0] = N;
  inport_id_oh_per_outport[4+0] = '0;
  unique case(1'b1)
    sa_global_inport_id_oh_i[4+0][0]: begin
      inport_id_per_outport[4+0] = N;
      inport_id_oh_per_outport[4+0][0] = 1'b1;
    end
    sa_global_inport_id_oh_i[4+0][1]: begin
      inport_id_per_outport[4+0] = S;
      inport_id_oh_per_outport[4+0][1] = 1'b1;
    end
    sa_global_inport_id_oh_i[4+0][2]: begin
      inport_id_per_outport[4+0] = E;
      inport_id_oh_per_outport[4+0][2] = 1'b1;
    end
    sa_global_inport_id_oh_i[4+0][3]: begin
      inport_id_per_outport[4+0] = W;
      inport_id_oh_per_outport[4+0][3] = 1'b1;
    end
    sa_global_inport_id_oh_i[4+0][4]: begin
      inport_id_per_outport[4+0] = L1;
      inport_id_oh_per_outport[4+0][5] = 1'b1;
    end
  `ifdef LOCAL_PORT_NUM_3
    sa_global_inport_id_oh_i[4+0][5]: begin
      inport_id_per_outport[4+0] = L2;
      inport_id_oh_per_outport[4+0][6] = 1'b1;
    end
  `endif
  `ifdef LOCAL_PORT_NUM_4
    sa_global_inport_id_oh_i[4+0][6]: begin
      inport_id_per_outport[4+0] = L3;
      inport_id_oh_per_outport[4+0][7] = 1'b1;
    end
  `endif
    default: begin
    end
  endcase
end

    // to L1
always_comb begin
  inport_id_per_outport[4+1] = N;
  inport_id_oh_per_outport[4+1] = '0;
  unique case(1'b1)
    sa_global_inport_id_oh_i[4+1][0]: begin
      inport_id_per_outport[4+1] = N;
      inport_id_oh_per_outport[4+1][0] = 1'b1;
    end
    sa_global_inport_id_oh_i[4+1][1]: begin
      inport_id_per_outport[4+1] = S;
      inport_id_oh_per_outport[4+1][1] = 1'b1;
    end
    sa_global_inport_id_oh_i[4+1][2]: begin
      inport_id_per_outport[4+1] = E;
      inport_id_oh_per_outport[4+1][2] = 1'b1;
    end
    sa_global_inport_id_oh_i[4+1][3]: begin
      inport_id_per_outport[4+1] = W;
      inport_id_oh_per_outport[4+1][3] = 1'b1;
    end
    sa_global_inport_id_oh_i[4+1][4]: begin
      inport_id_per_outport[4+1] = L0;
      inport_id_oh_per_outport[4+1][4] = 1'b1;
    end
  `ifdef LOCAL_PORT_NUM_3
    sa_global_inport_id_oh_i[4+1][5]: begin
      inport_id_per_outport[4+1] = L2;
      inport_id_oh_per_outport[4+1][6] = 1'b1;
    end
  `endif
  `ifdef LOCAL_PORT_NUM_4
    sa_global_inport_id_oh_i[4+1][6]: begin
      inport_id_per_outport[4+1] = L3;
      inport_id_oh_per_outport[4+1][7] = 1'b1;
    end
  `endif
    default: begin
    end
  endcase
end


  `ifdef LOCAL_PORT_NUM_3
    // to L2
  always_comb begin
    inport_id_per_outport[4+2] = N;
    inport_id_oh_per_outport[4+2] = '0;
    unique case(1'b1)
      sa_global_inport_id_oh_i[4+2][0]: begin
        inport_id_per_outport[4+2] = N;
        inport_id_oh_per_outport[4+2][0] = 1'b1;
      end
      sa_global_inport_id_oh_i[4+2][1]: begin
        inport_id_per_outport[4+2] = S;
        inport_id_oh_per_outport[4+2][1] = 1'b1;
      end
      sa_global_inport_id_oh_i[4+2][2]: begin
        inport_id_per_outport[4+2] = E;
        inport_id_oh_per_outport[4+2][2] = 1'b1;
      end
      sa_global_inport_id_oh_i[4+2][3]: begin
        inport_id_per_outport[4+2] = W;
        inport_id_oh_per_outport[4+2][3] = 1'b1;
      end
      sa_global_inport_id_oh_i[4+2][4]: begin
        inport_id_per_outport[4+2] = L0;
        inport_id_oh_per_outport[4+2][4] = 1'b1;
      end
      sa_global_inport_id_oh_i[4+2][5]: begin
        inport_id_per_outport[4+2] = L1;
        inport_id_oh_per_outport[4+2][5] = 1'b1;
      end
    `ifdef LOCAL_PORT_NUM_4
      sa_global_inport_id_oh_i[4+2][6]: begin
        inport_id_per_outport[4+2] = L3;
        inport_id_oh_per_outport[4+2][7] = 1'b1;
      end
    `endif
      default: begin
      end
    endcase
  end
  `endif

  `ifdef LOCAL_PORT_NUM_4
    // to L3
  always_comb begin
    inport_id_per_outport[4+3] = N;
    inport_id_oh_per_outport[4+3] = '0;
    unique case(1'b1)
      sa_global_inport_id_oh_i[4+3][0]: begin
        inport_id_per_outport[4+3] = N;
        inport_id_oh_per_outport[4+3][0] = 1'b1;
      end
      sa_global_inport_id_oh_i[4+3][1]: begin
        inport_id_per_outport[4+3] = S;
        inport_id_oh_per_outport[4+3][1] = 1'b1;
      end
      sa_global_inport_id_oh_i[4+3][2]: begin
        inport_id_per_outport[4+3] = E;
        inport_id_oh_per_outport[4+3][2] = 1'b1;
      end
      sa_global_inport_id_oh_i[4+3][3]: begin
        inport_id_per_outport[4+3] = W;
        inport_id_oh_per_outport[4+3][3] = 1'b1;
      end
      sa_global_inport_id_oh_i[4+3][4]: begin
        inport_id_per_outport[4+3] = L0;
        inport_id_oh_per_outport[4+3][4] = 1'b1;
      end
      sa_global_inport_id_oh_i[4+3][5]: begin
        inport_id_per_outport[4+3] = L1;
        inport_id_oh_per_outport[4+3][5] = 1'b1;
      end
      sa_global_inport_id_oh_i[4+3][6]: begin
        inport_id_per_outport[4+3] = L2;
        inport_id_oh_per_outport[4+3][6] = 1'b1;
      end
      default: begin
      end
    endcase
  end
  `endif


`else
generate
  if(LOCAL_PORT_NUM > 0) begin: gen_have_multi_local_port
    for(i = 0; i < LOCAL_PORT_NUM; i++) begin: gen_multi_local_port
      always_comb begin
        inport_id_per_outport[4+i] = N;
        inport_id_oh_per_outport[4+i] = '0;
        unique case(1'b1)
          sa_global_inport_id_oh_i[4+i][0]: begin
            inport_id_per_outport[4+i] = N;
            inport_id_oh_per_outport[4+i][0] = 1'b1;
          end
          sa_global_inport_id_oh_i[4+i][1]: begin
            inport_id_per_outport[4+i] = S;
            inport_id_oh_per_outport[4+i][1] = 1'b1;
          end
          sa_global_inport_id_oh_i[4+i][2]: begin
            inport_id_per_outport[4+i] = E;
            inport_id_oh_per_outport[4+i][2] = 1'b1;
          end
          sa_global_inport_id_oh_i[4+i][3]: begin
            inport_id_per_outport[4+i] = W;
            inport_id_oh_per_outport[4+i][3] = 1'b1;
          end
          default: begin
          end
        endcase
      end
    end
  end
endgenerate
`endif


endmodule
