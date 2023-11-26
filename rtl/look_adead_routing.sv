// implemented XY routing, for per local sa winnner flit
module look_ahead_routing
  import rvh_noc_pkg::*;
#(
)
(
  // input vc head to calculate next routing
  input  logic      vc_ctrl_head_vld_i,
  input  flit_dec_t vc_ctrl_head_i,

  // input this hop xy addr
  input  logic [NodeID_X_Width-1:0] node_id_x_ths_hop_i,
  input  logic [NodeID_Y_Width-1:0] node_id_y_ths_hop_i,

  // output look ahead routing result
  output io_port_t  look_ahead_routing_o
);

logic [NodeID_X_Width-1:0] node_id_x_nxt_hop, node_id_x_dst_hop;
logic [NodeID_Y_Width-1:0] node_id_y_nxt_hop, node_id_y_dst_hop;

assign node_id_x_dst_hop = vc_ctrl_head_i.tgt_id.x_position;
assign node_id_y_dst_hop = vc_ctrl_head_i.tgt_id.y_position;

// 1st phase: Assign next address
always_comb begin
  node_id_x_nxt_hop = node_id_x_ths_hop_i;
  node_id_y_nxt_hop = node_id_y_ths_hop_i;
  unique case(vc_ctrl_head_i.look_ahead_routing)
    N: begin
      node_id_y_nxt_hop = node_id_y_ths_hop_i + 1;
    end
    S: begin
      node_id_y_nxt_hop = node_id_y_ths_hop_i - 1;
    end
    E: begin
      node_id_x_nxt_hop = node_id_x_ths_hop_i + 1;
    end
    W: begin
      node_id_x_nxt_hop = node_id_x_ths_hop_i - 1;
    end
    default: begin
    end
  endcase
end

// 2nd phase: Define new Next-port
logic x_nxt_equal_x_dst;
logic x_nxt_less_x_dst;
logic y_nxt_equal_y_dst;
logic y_nxt_less_y_dst;

assign x_nxt_equal_x_dst = (node_id_x_nxt_hop == node_id_x_dst_hop);
assign x_nxt_less_x_dst  = (node_id_x_nxt_hop <  node_id_x_dst_hop);
assign y_nxt_equal_y_dst = (node_id_y_nxt_hop == node_id_y_dst_hop);
assign y_nxt_less_y_dst  = (node_id_y_nxt_hop <  node_id_y_dst_hop);

always_comb begin
  if(x_nxt_equal_x_dst) begin
    if(y_nxt_equal_y_dst) begin
      unique case(vc_ctrl_head_i.tgt_id.device_port) // chooose which local port to route to
        0: begin
          look_ahead_routing_o = L0;
        end
`ifdef LOCAL_PORT_NUM_2
        1: begin
          look_ahead_routing_o = L1;
        end
`endif
`ifdef LOCAL_PORT_NUM_3
        2: begin
          look_ahead_routing_o = L2;
        end
`endif
`ifdef LOCAL_PORT_NUM_4
        3: begin
          look_ahead_routing_o = L3;
        end
`endif
        default: begin
          look_ahead_routing_o = L0;
        end
      endcase
    end else if(y_nxt_less_y_dst) begin
      look_ahead_routing_o = N;
    end else begin
      look_ahead_routing_o = S;
    end
  end else if(x_nxt_less_x_dst) begin
    look_ahead_routing_o = E;
  end else begin
    look_ahead_routing_o = W;
  end
end

endmodule
