module rn_router_sam
  import rvh_noc_pkg::*;
#(
  parameter type flit_payload_t = logic[256-1:0],
  parameter int  sliced_llc = 0,
  parameter int  has_addr   = 0, // for req and evict, thsy have addr and need to do sam, for resp and data, only send to the correspond hn
  parameter int  interleave_granularity = 64, // should be (2 ** n) * 64byte, n is integer and >= 0
  parameter int  llc_slice_num = 9,

  parameter int  INTERLEAVE_BIT    = $clog2(interleave_granularity),
  parameter int  INTERLEAVE_LENGTH = $clog2(llc_slice_num)
  // parameter VC_NUM_IDX_W = 1
)
(
  input  logic              flit_v_i,
  input  flit_payload_t     flit_i,
  input  io_port_t          flit_look_ahead_routing_i,

  input  logic [NodeID_X_Width-1:0] node_id_x_i,
  input  logic [NodeID_Y_Width-1:0] node_id_y_i,

  output flit_dec_t         flit_dec_o,
  output flit_payload_t     flit_o

);

`ifdef USE_QOS_VALUE
assign flit_dec_o.qos_value = flit_i.qos_value;
`endif

logic [40-1:0] req_addr;
generate
  if(has_addr) begin
    assign req_addr = flit_i.addr;
  end
endgenerate

generate
  if(sliced_llc) begin
    if(has_addr) begin
      always_comb begin
        flit_o = flit_i;

        flit_o.tgt_id.x_position  = (req_addr[INTERLEAVE_BIT+INTERLEAVE_LENGTH-1:INTERLEAVE_BIT] % llc_slice_num) % NODE_NUM_X_DIMESION;
        flit_o.tgt_id.y_position  = (req_addr[INTERLEAVE_BIT+INTERLEAVE_LENGTH-1:INTERLEAVE_BIT] % llc_slice_num) / NODE_NUM_Y_DIMESION;
        flit_o.tgt_id.device_port = 1;

        flit_o.tgt_id.device_id   = 0;
        flit_o.src_id.x_position   = node_id_x_i;
        flit_o.src_id.y_position   = node_id_y_i;
        flit_o.src_id.device_port  = 0;
        flit_o.src_id.device_id    = 0;
      end
    end else begin
      always_comb begin
        flit_o = flit_i;
      
        flit_o.tgt_id.x_position  = flit_i.id.sid % NODE_NUM_X_DIMESION;
        flit_o.tgt_id.y_position  = flit_i.id.sid / NODE_NUM_Y_DIMESION;
        flit_o.tgt_id.device_port = 1;

        flit_o.tgt_id.device_id   = 0;
        flit_o.src_id.x_position   = node_id_x_i;
        flit_o.src_id.y_position   = node_id_y_i;
        flit_o.src_id.device_port  = 0;
        flit_o.src_id.device_id    = 0;
      end
    end 
  end else begin
    always_comb begin
      flit_o = flit_i;

      flit_o.tgt_id.x_position  = 1;
      flit_o.tgt_id.y_position  = 0;
      flit_o.tgt_id.device_port = 0;    

      flit_o.tgt_id.device_id   = 0;
      flit_o.src_id.x_position   = node_id_x_i;
      flit_o.src_id.y_position   = node_id_y_i;
      flit_o.src_id.device_port  = 0;
      flit_o.src_id.device_id    = 0;
    end
  end
endgenerate


generate
  if(sliced_llc) begin: gen_sliced_llc
    if(has_addr) begin: gen_has_addr
      assign flit_dec_o.tgt_id.x_position  = (req_addr[INTERLEAVE_BIT+INTERLEAVE_LENGTH-1:INTERLEAVE_BIT] % llc_slice_num) % NODE_NUM_X_DIMESION;
      assign flit_dec_o.tgt_id.y_position  = (req_addr[INTERLEAVE_BIT+INTERLEAVE_LENGTH-1:INTERLEAVE_BIT] % llc_slice_num) / NODE_NUM_Y_DIMESION;
      assign flit_dec_o.tgt_id.device_port = 1;
    end else begin: gen_no_addr
      assign flit_dec_o.tgt_id.x_position   = flit_i.id.sid % NODE_NUM_X_DIMESION;
      assign flit_dec_o.tgt_id.y_position   = flit_i.id.sid / NODE_NUM_Y_DIMESION;
      assign flit_dec_o.tgt_id.device_port  = 1;      
    end
  end else begin: gen_whole_llc // when the hn is at (1,0)
    assign flit_dec_o.tgt_id.x_position   = 1;
    assign flit_dec_o.tgt_id.y_position   = 0;
    assign flit_dec_o.tgt_id.device_port  = 0;
  end
endgenerate
assign flit_dec_o.tgt_id.device_id    = 0;
assign flit_dec_o.src_id.x_position   = node_id_x_i;
assign flit_dec_o.src_id.y_position   = node_id_y_i;
assign flit_dec_o.src_id.device_port  = 0;
assign flit_dec_o.src_id.device_id    = 0;

assign flit_dec_o.look_ahead_routing = flit_look_ahead_routing_i;

endmodule