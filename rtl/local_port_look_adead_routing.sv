// implemented XY routing, for per local sa winnner flit
module local_port_look_adead_routing
  import rvh_noc_pkg::*;
#(
)
(
  // input vc head to calculate next routing
  input  logic [NodeID_X_Width-1:0] node_id_x_tgt_i,
  input  logic [NodeID_Y_Width-1:0] node_id_y_tgt_i,
`ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER
  input  logic [NodeID_Device_Port_Width-1:0] device_port_tgt_i,
`endif

  // input this hop xy addr
  input  logic [NodeID_X_Width-1:0] node_id_x_src_i,
  input  logic [NodeID_Y_Width-1:0] node_id_y_src_i,

  // output look ahead routing result
  output io_port_t  look_ahead_routing_o
);

// 2nd phase: Define new Next-port
logic x_nxt_equal_x_dst;
logic x_nxt_less_x_dst;
`ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER
logic y_nxt_equal_y_dst;
`endif
logic y_nxt_less_y_dst;

assign x_nxt_equal_x_dst = (node_id_x_src_i == node_id_x_tgt_i);
assign x_nxt_less_x_dst  = (node_id_x_src_i <  node_id_x_tgt_i);
`ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER
assign y_nxt_equal_y_dst = (node_id_y_src_i == node_id_y_tgt_i);
`endif
assign y_nxt_less_y_dst  = (node_id_y_src_i <  node_id_y_tgt_i);


`ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER
always_comb begin
  if(x_nxt_equal_x_dst) begin
    if(y_nxt_equal_y_dst) begin
      unique case(device_port_tgt_i) // chooose which local port to route to
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

`else
always_comb begin
  if(x_nxt_equal_x_dst) begin
    if(y_nxt_less_y_dst) begin
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
`endif

endmodule
