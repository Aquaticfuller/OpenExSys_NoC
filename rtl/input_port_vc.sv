module input_port_vc
  import rvh_noc_pkg::*;
#(
  parameter type flit_payload_t = logic[256-1:0],
  parameter VC_NUM = 1,
  parameter VC_NUM_IDX_W = VC_NUM > 1 ? $clog2(VC_NUM) : 1,
  parameter VC_DEPTH  = 1,
`ifdef RETURN_CREDIT_AT_SA_STAGE
  parameter VC_BUFFER_DEPTH  = VC_DEPTH + 1, // need one more slot to handle push and pop at the same cycle when the fifo is full
`else
  parameter VC_BUFFER_DEPTH  = VC_DEPTH,
`endif
  parameter VC_BUFFER_DEPTH_IDX_W = VC_BUFFER_DEPTH > 1 ? $clog2(VC_BUFFER_DEPTH) : 1

`ifdef VC_DATA_USE_DUAL_PORT_RAM
  ,
  parameter VC_DPRAM_DEPTH = VC_NUM * VC_BUFFER_DEPTH,
  parameter VC_DPRAM_DEPTH_IDX_W = VC_DPRAM_DEPTH > 1 ? $clog2(VC_DPRAM_DEPTH) : 1
`endif
)
(
  // input from input port
  input  logic                        flit_v_i,
  input  flit_payload_t               flit_i,
  input  flit_dec_t                   flit_dec_i,
  input  logic [VC_NUM_IDX_W-1:0]     flit_vc_id_i,

  // free vc credit sent to sender
  output logic                        lcrd_v_o,
  output logic [VC_ID_NUM_MAX_W-1:0]  lcrd_id_o,

  // output ctrl to local allocate
  output logic      [VC_NUM-1:0]      vc_ctrl_head_vld_o,
  output flit_dec_t [VC_NUM-1:0]      vc_ctrl_head_o,

  // output data to switch traversal
  output flit_payload_t [VC_NUM-1:0]  vc_data_head_o,

  // input pop flit ctrl fifo (comes from SA stage)
  input logic                         inport_read_enable_sa_stage_i,
  input logic [VC_NUM_IDX_W-1:0]      inport_read_vc_id_sa_stage_i, // use local sa result instead of vc assignment
`ifdef VC_DATA_USE_DUAL_PORT_RAM
  input dpram_used_idx_t              inport_read_dpram_idx_i,
`endif

  // input pop flit ctrl fifo (comes from ST stage)
  input logic                         inport_read_enable_st_stage_i,
  input logic [VC_NUM_IDX_W-1:0]      inport_read_vc_id_st_stage_i,

  input  logic clk,
  input  logic rstn
);

genvar i;

logic [VC_NUM-1:0] vc_data_tail_we;
flit_payload_t vc_data_din;
logic [VC_NUM-1:0] vc_data_enqueue_rdy;

logic [VC_NUM-1:0] vc_ctrl_tail_we;
flit_dec_t vc_ctrl_din;
logic [VC_NUM-1:0] vc_ctrl_enqueue_rdy;

logic           [VC_NUM-1:0] vc_data_head_vld;
flit_payload_t  [VC_NUM-1:0] vc_data_head;
logic           [VC_NUM-1:0] vc_data_head_dequeue_vld;

logic           [VC_NUM-1:0] vc_ctrl_head_vld;
flit_dec_t      [VC_NUM-1:0] vc_ctrl_head;
logic           [VC_NUM-1:0] vc_ctrl_head_dequeue_vld;

`ifdef VC_DATA_USE_DUAL_PORT_RAM
  logic [VC_NUM-1:0][VC_BUFFER_DEPTH_IDX_W-1:0] vc_data_freelist_deq_per_vc_idx;
  logic             [VC_BUFFER_DEPTH_IDX_W-1:0] vc_data_freelist_deq_per_vc_idx_sel;
  logic [VC_NUM-1:0]                            vc_data_freelist_deq_rdy;
  logic [VC_NUM-1:0][VC_DPRAM_DEPTH_IDX_W-1:0]  vc_data_freelist_deq_dpram_idx;
  logic             [VC_DPRAM_DEPTH_IDX_W-1:0]  vc_data_freelist_deq_dpram_idx_sel;
  logic [VC_NUM-1:0]                            vc_data_freelist_deq_vld;

  logic             [VC_BUFFER_DEPTH_IDX_W-1:0] vc_data_freelist_enq_per_vc_idx;
`endif

// enqueue
always_comb begin
  vc_data_tail_we = '0;
  vc_ctrl_tail_we = '0;
  if(flit_v_i) begin
    vc_data_tail_we[flit_vc_id_i] = 1'b1;
    vc_ctrl_tail_we[flit_vc_id_i] = 1'b1;
  end
end

assign vc_data_din = flit_i;
assign vc_ctrl_din.tgt_id             = flit_dec_i.tgt_id;
assign vc_ctrl_din.src_id             = flit_dec_i.src_id;
assign vc_ctrl_din.txn_id             = flit_dec_i.txn_id;
assign vc_ctrl_din.look_ahead_routing = flit_dec_i.look_ahead_routing;
`ifdef USE_QOS_VALUE
assign vc_ctrl_din.qos_value          = flit_dec_i.qos_value;
`endif
`ifdef VC_DATA_USE_DUAL_PORT_RAM
assign vc_ctrl_din.dpram_used_idx.dpram_idx   = {{(VC_DPRAM_DEPTH_MAX_W-VC_DPRAM_DEPTH_IDX_W){1'b0}}, vc_data_freelist_deq_dpram_idx_sel};
assign vc_ctrl_din.dpram_used_idx.per_vc_idx  = {{(VC_BUFFER_DEPTH_MAX_W-VC_BUFFER_DEPTH_IDX_W){1'b0}}, vc_data_freelist_deq_per_vc_idx_sel};
`endif

// dequeue
  // ctrl dequeue at SA stage
always_comb begin
  vc_ctrl_head_dequeue_vld = '0;
  vc_ctrl_head_dequeue_vld[inport_read_vc_id_sa_stage_i] = inport_read_enable_sa_stage_i;
end

  // data dequeue at ST stage
always_comb begin
  vc_data_head_dequeue_vld = '0;
  vc_data_head_dequeue_vld[inport_read_vc_id_st_stage_i] = inport_read_enable_st_stage_i;
end


// fifo module
`ifdef VC_DATA_USE_DUAL_PORT_RAM
  generate
    for(i = 0; i < VC_NUM; i++) begin: gen_vc_data_freelist_deq_dpram_idx
      assign vc_data_freelist_deq_dpram_idx[i] = VC_BUFFER_DEPTH * i + vc_data_freelist_deq_per_vc_idx[i];
    end
  endgenerate

  assign vc_data_freelist_deq_vld = vc_data_tail_we;
  onehot_mux
  #(
    .SOURCE_COUNT(VC_NUM ),
    .DATA_WIDTH  (VC_DPRAM_DEPTH_IDX_W )
  )
  onehot_mux_vc_data_freelist_deq_dpram_idx_sel_u (
    .sel_i    (vc_data_tail_we                ),
    .data_i   (vc_data_freelist_deq_dpram_idx     ),
    .data_o   (vc_data_freelist_deq_dpram_idx_sel )
  );

  onehot_mux
  #(
    .SOURCE_COUNT(VC_NUM ),
    .DATA_WIDTH  (VC_BUFFER_DEPTH_IDX_W )
  )
  onehot_mux_vc_data_freelist_deq_per_vc_idx_sel_u (
    .sel_i    (vc_data_tail_we                ),
    .data_i   (vc_data_freelist_deq_per_vc_idx     ),
    .data_o   (vc_data_freelist_deq_per_vc_idx_sel )
  );


  assign vc_data_freelist_enq_per_vc_idx = inport_read_dpram_idx_i.per_vc_idx[VC_BUFFER_DEPTH_IDX_W-1:0];

  // free list
  generate
    for(i = 0; i < VC_NUM; i++) begin: gen_vc_data_freelist
      freelist
      #(
        .ENTRY_COUNT  (VC_BUFFER_DEPTH)
      )
      VC_DATA_FREELIST_U (
        .enq_vld_i (vc_ctrl_head_dequeue_vld        [i] ),
        .enq_tag_i (vc_data_freelist_enq_per_vc_idx     ),
        .deq_vld_i (vc_data_freelist_deq_vld        [i] ),
        .deq_tag_o (vc_data_freelist_deq_per_vc_idx [i] ),
        .deq_rdy_o (vc_data_freelist_deq_rdy        [i] ),
        .flush_i   ('0        ),
        .clk       (clk       ),
        .rst       (~rstn     )
      );
    end
  endgenerate

  // dpram
  simple_dual_one_clock
  #(
    .ADDR_BITS  (VC_DPRAM_DEPTH_IDX_W),
    .DATA_BITS  ($bits(flit_payload_t))
  )
  VC_DATA_DPRAM_U (
    .clk    (clk                            ),
    .ena    (flit_v_i                       ), // in  flit write
    .enb    (inport_read_enable_sa_stage_i  ), // out flit read
    .wea    (flit_v_i                       ),
    .addra  (vc_data_freelist_deq_dpram_idx_sel ),
    .addrb  (inport_read_dpram_idx_i.dpram_idx[VC_DPRAM_DEPTH_IDX_W-1:0] ),
    .dia    (vc_data_din                    ),
    .dob    (vc_data_head_o [0]             )
  );

`else
  generate
    for(i = 0; i < VC_NUM; i++) begin: gen_vc_data_fifo
      mp_fifo
      #(
        .payload_t      (flit_payload_t),
        .ENQUEUE_WIDTH  (1),
        .DEQUEUE_WIDTH  (1),
        .DEPTH          (VC_BUFFER_DEPTH),
        .MUST_TAKEN_ALL (1)
      )
      VC_DATA_U
      (
        // Enqueue
        .enqueue_vld_i          (vc_data_tail_we          [i] ),
        .enqueue_payload_i      (vc_data_din                  ),
        .enqueue_rdy_o          (vc_data_enqueue_rdy      [i] ),
        // Dequeue
        .dequeue_vld_o          (vc_data_head_vld         [i] ),
        .dequeue_payload_o      (vc_data_head             [i] ),
        .dequeue_rdy_i          (vc_data_head_dequeue_vld [i] ),

        .flush_i                (1'b0                 ),

        .clk                    (clk),
        .rst                    (~rstn)
      );

      assign vc_data_head_o [i] = vc_data_head [i];
    end
  endgenerate
`endif



generate
  for(i = 0; i < VC_NUM; i++) begin: gen_vc_ctrl_fifo
    mp_fifo
    #(
      .payload_t      (flit_dec_t),
      .ENQUEUE_WIDTH  (1),
      .DEQUEUE_WIDTH  (1),
      .DEPTH          (VC_DEPTH),
      .MUST_TAKEN_ALL (1)
    )
    VC_CTRL_U
    (
      // Enqueue
      .enqueue_vld_i          (vc_ctrl_tail_we     [i] ),
      .enqueue_payload_i      (vc_ctrl_din             ),
      .enqueue_rdy_o          (vc_ctrl_enqueue_rdy [i] ),
      // Dequeue
      .dequeue_vld_o          (vc_ctrl_head_vld    [i] ),
      .dequeue_payload_o      (vc_ctrl_head        [i] ),
      .dequeue_rdy_i          (vc_ctrl_head_dequeue_vld [i] ),

      .flush_i                (1'b0                 ),

      .clk                    (clk),
      .rst                    (~rstn)
    );

    assign vc_ctrl_head_vld_o [i] = vc_ctrl_head_vld[i];
    assign vc_ctrl_head_o     [i] = vc_ctrl_head    [i];
  end
endgenerate

  // free vc credit sent to sender
`ifdef RETURN_CREDIT_AT_SA_STAGE
  assign lcrd_v_o   = inport_read_enable_sa_stage_i;
  assign lcrd_id_o  = {{(VC_ID_NUM_MAX_W-VC_NUM_IDX_W){1'b0}}, inport_read_vc_id_sa_stage_i};
`else
  assign lcrd_v_o   = inport_read_enable_st_stage_i;
  assign lcrd_id_o  = {{(VC_ID_NUM_MAX_W-VC_NUM_IDX_W){1'b0}}, inport_read_vc_id_st_stage_i};
`endif



`ifndef SYNTHESIS
`ifdef COMMON_QOS_EXTRA_RT_VC
// assert property(@(posedge clk)disable iff(~rstn) (flit_v_i == 1'b1) |-> (((flit_vc_id_i < QOS_VC_NUM_PER_INPUT) && (flit_dec_i.qos_value == 15))))
//       else $error("noc_input_port: flit with highest QoS value goes into common VC, txn_id: 0x%x, vc_id: %d,  flit_v_i=%d", flit_dec_i.txn_id, flit_vc_id_i, flit_v_i);
// assert property(@(posedge clk)disable iff(~rstn) (flit_v_i == 1'b1) |-> (((flit_vc_id_i >= QOS_VC_NUM_PER_INPUT) && (flit_dec_i.qos_value < 15))))
//       else begin $display("noc_input_port: flit with lower QoS value goes into rt VC, txn_id: 0x%x, vc_id: %d, flit_v_i=%d", flit_dec_i.txn_id, flit_vc_id_i, flit_v_i); $fatal(); end

generate
  for(i = 0; i < QOS_VC_NUM_PER_INPUT; i++) begin
    assert property(@(posedge clk)disable iff(~rstn) (vc_ctrl_head_vld[i]) |-> (vc_ctrl_head[i].qos_value == 15))
          else $fatal("noc_input_vc: rt VC has flit with lower QoS value, txn_id: 0x%x", vc_ctrl_head[i].txn_id);
  end
  for(i = QOS_VC_NUM_PER_INPUT; i < VC_NUM; i++) begin
    assert property(@(posedge clk)disable iff(~rstn) (vc_ctrl_head_vld[i]) |-> (vc_ctrl_head[i].qos_value != 15))
          else $fatal("noc_input_vc: common VC has flit with highest QoS value, txn_id: 0x%x", vc_ctrl_head[i].txn_id);
  end
endgenerate
`endif
`endif

endmodule
