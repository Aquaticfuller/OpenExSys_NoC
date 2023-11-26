// vc credit counter per out port port
module output_port_vc_credit_counter
  import rvh_noc_pkg::*;
#(
  parameter VC_NUM         = 4,
  parameter VC_NUM_IDX_W   = VC_NUM > 1 ? $clog2(VC_NUM) : 1,
  parameter VC_DEPTH       = 1,
  parameter VC_DEPTH_COUNTER_W = $clog2(VC_DEPTH+1)
)
(
  // input new free vc credit
  input  logic                        free_vc_credit_vld_i,
  input  logic [VC_NUM_IDX_W-1:0]     free_vc_credit_vc_id_i,

  // input new consume vc credit
  input  logic                        consume_vc_credit_vld_i,
  input  logic [VC_NUM_IDX_W-1:0]     consume_vc_credit_vc_id_i,

  // output to vc selection
  output logic [VC_NUM-1:0][VC_DEPTH_COUNTER_W-1:0] vc_credit_counter_o,

  input  logic clk,
  input  logic rstn

);
genvar i;

// credit counter
logic [VC_NUM-1:0][VC_DEPTH_COUNTER_W-1:0] vc_credit_counter_d, vc_credit_counter_q;
logic [VC_NUM-1:0][VC_DEPTH_COUNTER_W-1:0] vc_credit_counter_q_plus1, vc_credit_counter_q_minus1;
logic [VC_NUM-1:0]                     vc_credit_counter_ena;

// credit counter nxt
logic [VC_NUM-1:0] free_vc_credit_vc_id_hit;
logic [VC_NUM-1:0] consume_vc_credit_vc_id_hit;
generate
  for(i = 0; i < VC_NUM; i++) begin: gen_vc_credit_vc_id_hit
    assign free_vc_credit_vc_id_hit   [i] = free_vc_credit_vld_i & (free_vc_credit_vc_id_i == i[VC_NUM_IDX_W-1:0]);
    assign consume_vc_credit_vc_id_hit[i] = consume_vc_credit_vld_i & (consume_vc_credit_vc_id_i == i[VC_NUM_IDX_W-1:0]);
  end
endgenerate

generate
  for(i = 0; i < VC_NUM; i++) begin: gen_vc_credit_counter_q_plus1
    assign vc_credit_counter_q_plus1[i]  = vc_credit_counter_q[i] + 1;
  end
endgenerate

generate
  for(i = 0; i < VC_NUM; i++) begin: gen_vc_credit_counter_q_minus1
    assign vc_credit_counter_q_minus1[i] = vc_credit_counter_q[i] - 1;
  end
endgenerate

generate
  for(i = 0; i < VC_NUM; i++) begin: gen_vc_credit_counter_d
    always_comb begin
      vc_credit_counter_d   [i] = vc_credit_counter_q[i];
      vc_credit_counter_ena [i] = 1'b0;
      if(free_vc_credit_vc_id_hit[i] & ~consume_vc_credit_vc_id_hit[i]) begin
        vc_credit_counter_d   [i] = vc_credit_counter_q_plus1[i];
        vc_credit_counter_ena [i] = 1'b1;
      end else if(~free_vc_credit_vc_id_hit[i] & consume_vc_credit_vc_id_hit[i]) begin
        vc_credit_counter_d   [i] = vc_credit_counter_q_minus1[i];
        vc_credit_counter_ena [i] = 1'b1;
      end
    end
  end
endgenerate

// dff vc_credit_counter_q
generate
  for(i = 0; i < VC_NUM; i++) begin: gen_vc_credit_counter_q
    std_dffrve
    #(.WIDTH(VC_DEPTH_COUNTER_W))
    U_DAT_VC_CREDIT_CONTER_REG
    (
      .clk(clk),
      .rstn(rstn),
      .rst_val(VC_DEPTH[VC_DEPTH_COUNTER_W-1:0]),
      .en(vc_credit_counter_ena[i]),
      .d(vc_credit_counter_d[i]),
      .q(vc_credit_counter_q[i])
    );

`ifndef SYNTHESIS
    assert property(@(posedge clk)disable iff(~rstn) ((vc_credit_counter_q[i]) <= VC_DEPTH))
      else $fatal("output_port_vc_credit_counter: vc credit counter overflow");
`endif
  end
endgenerate

// output to vc selection
assign vc_credit_counter_o = vc_credit_counter_q;


endmodule
