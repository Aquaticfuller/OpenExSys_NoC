module v_sender
import rvh_noc_pkg::*;
import v_noc_pkg::*;
#(
  parameter FLIT_BUFFER_DEPTH = 8,
  parameter type flit_payload_t = logic[256-1:0],

  parameter VC_NUM_OUTPORT   = 2,
  parameter VC_NUM_OUTPORT_IDX_W = VC_NUM_OUTPORT > 1 ? $clog2(VC_NUM_OUTPORT) : 1,
  parameter VC_DEPTH_OUTPORT = 2,
  parameter VC_DEPTH_OUTPORT_COUNTER_W = $clog2(VC_DEPTH_OUTPORT + 1),

  parameter SENDER_TIMEOUT_EN        = 1,
  parameter SENDER_TIMEOUT_THRESHOLD = 64,

  parameter OUTPUT_TO_N = 0,
  parameter OUTPUT_TO_S = 0,
  parameter OUTPUT_TO_E = 0,
  parameter OUTPUT_TO_W = 0,
  parameter OUTPUT_TO_L = 0
)
(
  // intf with dut
    // output to one of dut router's inports // N,S,E,W,L
  output logic                                  tx_flit_pend_o,
  output logic                                  tx_flit_v_o,
  output flit_payload_t                         tx_flit_o,
  output logic          [VC_ID_NUM_MAX_W-1:0]   tx_flit_vc_id_o,
  output io_port_t                              tx_flit_look_ahead_routing_o,

    // free vc credit from dut
  input  logic                                  tx_lcrd_v_i,
  input  logic          [VC_ID_NUM_MAX_W-1:0]   tx_lcrd_id_i,

  // intf with test generator
  input  logic                                  new_test_vld_i,
  input  test_case_t                            new_test_i,
  output logic                                  new_test_rdy_o,

  // intf with scoreboard
  output logic                                  new_scoreboard_entry_vld_o,
  output scoreboard_entry_t                     new_scoreboard_entry_o,
  input  logic                                  new_scoreboard_entry_rdy_i,

  // node id
  input  node_id_t                              node_id_i,

  // system cycle counter
  input  logic                       [64-1:0]   mcycle_i,


  input  logic clk,
  input  logic rstn
);

genvar i;


// to send flit buffer
logic       flit_buffer_head_vld;
test_case_t flit_buffer_head;

logic flit_buffer_dequeue_vld;

mp_fifo
#(
  .payload_t      (test_case_t),
  .ENQUEUE_WIDTH  (1),
  .DEQUEUE_WIDTH  (1),
  .DEPTH          (FLIT_BUFFER_DEPTH),
  .MUST_TAKEN_ALL (1)
)
FLIT_BUFFER_U
(
  // Enqueue
  .enqueue_vld_i          (new_test_vld_i  ),
  .enqueue_payload_i      (new_test_i      ),
  .enqueue_rdy_o          (new_test_rdy_o  ),
  // Dequeue
  .dequeue_vld_o          (flit_buffer_head_vld    ),
  .dequeue_payload_o      (flit_buffer_head        ),
  .dequeue_rdy_i          (flit_buffer_dequeue_vld ),

  .flush_i                (1'b0                 ),

  .clk                    (clk),
  .rst                    (~rstn)
);


// credit based flow control
io_port_t                         look_ahead_routing_test;
logic                             free_credit_vld;
logic [VC_NUM_OUTPORT_IDX_W-1:0]  free_credit_vc_id;
logic                             flit_vld;

assign flit_vld = flit_buffer_head_vld & new_scoreboard_entry_rdy_i;

local_port_couple_module
#(
  .VC_NUM_OUTPORT   (VC_NUM_OUTPORT ),
  .VC_DEPTH_OUTPORT (VC_DEPTH_OUTPORT ),

  .OUTPUT_TO_N      (OUTPUT_TO_N),
  .OUTPUT_TO_S      (OUTPUT_TO_S),
  .OUTPUT_TO_E      (OUTPUT_TO_E),
  .OUTPUT_TO_W      (OUTPUT_TO_W),
  .OUTPUT_TO_L      (OUTPUT_TO_L)
)
local_port_couple_module_u (
  // input vc head to calculate next routing
  .node_id_x_tgt_i        (flit_buffer_head.flit_head.tgt_id.x_position ),
  .node_id_y_tgt_i        (flit_buffer_head.flit_head.tgt_id.y_position ),
`ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER
  .device_port_tgt_i      (flit_buffer_head.flit_head.tgt_id.device_port),
`endif
  // input this hop xy addr
  .node_id_x_src_i        (flit_buffer_head.flit_head.src_id.x_position ),
  .node_id_y_src_i        (flit_buffer_head.flit_head.src_id.y_position ),
  // output look ahead routing result
  .look_ahead_routing_o   (look_ahead_routing_test ),

  // free credit in from router
  .tx_lcrd_v_i            (tx_lcrd_v_i ),
  .tx_lcrd_id_i           (tx_lcrd_id_i ),
  // consume credit
  .flit_vld_i             (flit_vld ),
  .flit_qos_value_i       (flit_buffer_head.qos_value ),
  .free_credit_vld_o      (free_credit_vld ),
  .free_credit_vc_id_o    (free_credit_vc_id),

  .clk                    (clk ),
  .rstn                   (rstn)
);

`ifndef SYNTHESIS
  assert property(@(posedge clk)disable iff(~rstn) ((flit_vld) |-> (look_ahead_routing_test == tx_flit_look_ahead_routing_o)))
    else $fatal("look_ahead_routing_test not equal");
`endif

assign flit_buffer_dequeue_vld = free_credit_vld & flit_vld;

// output to dut
assign tx_flit_pend_o                 = 1'b1;
assign tx_flit_v_o                    = flit_buffer_dequeue_vld;
assign tx_flit_o                      = {flit_buffer_head.flit_data, 
                                         flit_buffer_head.flit_head.txn_id, 
                                         flit_buffer_head.flit_head.src_id, 
                                         flit_buffer_head.flit_head.tgt_id, 
                                         flit_buffer_head.qos_value};
assign tx_flit_vc_id_o                = {{(VC_ID_NUM_MAX_W-VC_NUM_OUTPORT_IDX_W){1'b0}}, free_credit_vc_id};
assign tx_flit_look_ahead_routing_o   = flit_buffer_head.flit_head.look_ahead_routing;

// output to scoreboard
assign new_scoreboard_entry_vld_o                = tx_flit_v_o;
assign new_scoreboard_entry_o.tgt_id             = flit_buffer_head.flit_head.tgt_id;
assign new_scoreboard_entry_o.src_id             = flit_buffer_head.flit_head.src_id;
assign new_scoreboard_entry_o.txn_id             = flit_buffer_head.flit_head.txn_id;
assign new_scoreboard_entry_o.timeout_threshold  = flit_buffer_head.timeout_threshold;
assign new_scoreboard_entry_o.look_ahead_routing = flit_buffer_head.flit_head.look_ahead_routing;
assign new_scoreboard_entry_o.inport_vc_id       = tx_flit_vc_id_o;
assign new_scoreboard_entry_o.generated_mcycle   = flit_buffer_head.mcycle_when_generated;
assign new_scoreboard_entry_o.sent_mcycle        = mcycle_i;
assign new_scoreboard_entry_o.flit_data          = flit_buffer_head.flit_data;
assign new_scoreboard_entry_o.qos_value          = flit_buffer_head.qos_value;

// check for sender timeout
sender_timer_t sender_timer_d, sender_timer_q;
logic          sender_timer_ena;

always_ff @(posedge clk) begin
  if((sender_timer_q.timeout_counter >= SENDER_TIMEOUT_THRESHOLD) && SENDER_TIMEOUT_EN) begin
    $display("[%d] error: sender timeout, sender: (%d,%d), sender_local_device_port: %d, timeout_threshold: %d", 
                    $time(), 
                    node_id_i.x_position, node_id_i.y_position, node_id_i.device_port,
                    SENDER_TIMEOUT_THRESHOLD);
    $finish();
  end
end

assign sender_timer_d.timeout_counter = tx_flit_v_o ? '0 :
                                        sender_timer_q.timeout_counter + 1;

assign sender_timer_ena = 1'b1;

std_dffre
#(.WIDTH($bits(scoreboard_timer_t)))
U_DAT_SENDER_TIMER_REG
(
  .clk(clk),
  .rstn(rstn),
  .en(sender_timer_ena),
  .d (sender_timer_d  ),
  .q (sender_timer_q  )
);


endmodule
