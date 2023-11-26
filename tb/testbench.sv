module testbench
import rvh_noc_pkg::*;
#(
  // Parameters
  parameter  INPUT_PORT_NUM = 5,
  parameter  OUTPUT_PORT_NUM = 5,
  parameter type flit_payload_t = logic[FLIT_LENGTH-1:0],
  parameter  VC_NUM_INPUT_N = 2,
  parameter  VC_NUM_INPUT_S = 2,
  parameter  VC_NUM_INPUT_E = 4,
  parameter  VC_NUM_INPUT_W = 4,
  parameter  VC_NUM_INPUT_L = 4,
  parameter  SA_GLOBAL_INPUT_NUM_N = 4,
  parameter  SA_GLOBAL_INPUT_NUM_S = 4,
  parameter  SA_GLOBAL_INPUT_NUM_E = 2,
  parameter  SA_GLOBAL_INPUT_NUM_W = 2,
  parameter  SA_GLOBAL_INPUT_NUM_L = 4,
  parameter  VC_NUM_OUTPUT_N = 2,
  parameter  VC_NUM_OUTPUT_S = 2,
  parameter  VC_NUM_OUTPUT_E = 4,
  parameter  VC_NUM_OUTPUT_W = 4,
  parameter  VC_NUM_OUTPUT_L = 1,
  parameter  VC_DEPTH_INPUT_N = 2,
  parameter  VC_DEPTH_INPUT_S = 2,
  parameter  VC_DEPTH_INPUT_E = 2,
  parameter  VC_DEPTH_INPUT_W = 2,
  parameter  VC_DEPTH_INPUT_L = 2
)
(

);

  // Ports
  logic           [INPUT_PORT_NUM-1:0]                        rx_flit_pend_i;
  logic           [INPUT_PORT_NUM-1:0]                        rx_flit_v_i;
  flit_payload_t  [INPUT_PORT_NUM-1:0]                        rx_flit_i;
  io_port_t       [INPUT_PORT_NUM-1:0]                        rx_flit_vc_id_i;
  io_port_t       [INPUT_PORT_NUM-1:0]                        rx_flit_look_ahead_routing_i;

  logic           [OUTPUT_PORT_NUM-1:0]                       tx_flit_pend_o;
  logic           [OUTPUT_PORT_NUM-1:0]                       tx_flit_v_o;
  flit_payload_t  [OUTPUT_PORT_NUM-1:0]                       tx_flit_o;
  io_port_t       [OUTPUT_PORT_NUM-1:0]                       tx_flit_vc_id_o;
  io_port_t       [OUTPUT_PORT_NUM-1:0]                       tx_flit_look_ahead_routing_o;

  logic           [INPUT_PORT_NUM-1:0]                        rx_lcrd_v_o;
  logic           [INPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]   rx_lcrd_id_o;
  
  logic           [OUTPUT_PORT_NUM-1:0]                       tx_lcrd_v_i;
  logic           [OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]  tx_lcrd_id_i;
  
  logic           [NodeID_X_Width-1:0]                        node_id_x_ths_hop_i;
  logic           [NodeID_Y_Width-1:0]                        node_id_y_ths_hop_i;
  
  logic clk;
  logic rstn;

  vnet_router
  #(
    .INPUT_PORT_NUM(INPUT_PORT_NUM ),
    .OUTPUT_PORT_NUM(OUTPUT_PORT_NUM ),
    .flit_payload_t(flit_payload_t),
    .VC_NUM_INPUT_N(VC_NUM_INPUT_N ),
    .VC_NUM_INPUT_S(VC_NUM_INPUT_S ),
    .VC_NUM_INPUT_E(VC_NUM_INPUT_E ),
    .VC_NUM_INPUT_W(VC_NUM_INPUT_W ),
    .VC_NUM_INPUT_L(VC_NUM_INPUT_L ),
    .SA_GLOBAL_INPUT_NUM_N(SA_GLOBAL_INPUT_NUM_N ),
    .SA_GLOBAL_INPUT_NUM_S(SA_GLOBAL_INPUT_NUM_S ),
    .SA_GLOBAL_INPUT_NUM_E(SA_GLOBAL_INPUT_NUM_E ),
    .SA_GLOBAL_INPUT_NUM_W(SA_GLOBAL_INPUT_NUM_W ),
    .SA_GLOBAL_INPUT_NUM_L(SA_GLOBAL_INPUT_NUM_L ),
    .VC_NUM_OUTPUT_N(VC_NUM_OUTPUT_N ),
    .VC_NUM_OUTPUT_S(VC_NUM_OUTPUT_S ),
    .VC_NUM_OUTPUT_E(VC_NUM_OUTPUT_E ),
    .VC_NUM_OUTPUT_W(VC_NUM_OUTPUT_W ),
    .VC_NUM_OUTPUT_L(VC_NUM_OUTPUT_L ),
    .VC_DEPTH_INPUT_N(VC_DEPTH_INPUT_N ),
    .VC_DEPTH_INPUT_S(VC_DEPTH_INPUT_S ),
    .VC_DEPTH_INPUT_E(VC_DEPTH_INPUT_E ),
    .VC_DEPTH_INPUT_W(VC_DEPTH_INPUT_W ),
    .VC_DEPTH_INPUT_L(VC_DEPTH_INPUT_L )
  )
  vnet_router_dut (
    .rx_flit_pend_i (rx_flit_pend_i ),
    .rx_flit_v_i (rx_flit_v_i ),
    .rx_flit_i (rx_flit_i ),
    .rx_flit_vc_id_i (rx_flit_vc_id_i ),
    .rx_flit_look_ahead_routing_i (rx_flit_look_ahead_routing_i ),
    .tx_flit_pend_o (tx_flit_pend_o ),
    .tx_flit_v_o (tx_flit_v_o ),
    .tx_flit_o (tx_flit_o ),
    .tx_flit_vc_id_o (tx_flit_vc_id_o ),
    .tx_flit_look_ahead_routing_o (tx_flit_look_ahead_routing_o ),
    .rx_lcrd_v_o (rx_lcrd_v_o ),
    .rx_lcrd_id_o (rx_lcrd_id_o ),
    .tx_lcrd_v_i (tx_lcrd_v_i ),
    .tx_lcrd_id_i (tx_lcrd_id_i ),
    .node_id_x_ths_hop_i (node_id_x_ths_hop_i ),
    .node_id_y_ths_hop_i (node_id_y_ths_hop_i ),
    .clk    (clk ),
    .rstn   (rstn)
  );

  // test generate
  flit_payload_t counter;
  node_id_t target_node;
  always_ff @(posedge clk or negedge rstn) begin
    if(~rstn) begin
      counter <= '0;
    end else begin
      counter <= counter + 1;
      if(counter == 'd1000) begin
        $finish();
      end
    end
  end

  assign node_id_x_ths_hop_i = 2'b01;
  assign node_id_y_ths_hop_i = 2'b01;

  assign target_node.x_position   = 1;
  assign target_node.y_position   = 2;
  assign target_node.device_port  = 0;
  assign target_node.device_id    = 0;

  always_comb begin
    rx_flit_pend_i                = '1;
    rx_flit_v_i                   = '0;
    rx_flit_i                     = '0;
    rx_flit_vc_id_i               = '0;
    rx_flit_look_ahead_routing_i  = '0;
    if(counter[5:0] == '1) begin
      rx_flit_v_i                 [2]       = 1'b1;
      rx_flit_i                   [2]       = {{(128-7-4){1'b0}}, target_node, {4'b0}}; // x=1,y=2
      rx_flit_vc_id_i             [2][1:0]  = counter[7:6] ^ counter[9:8];
      rx_flit_look_ahead_routing_i[2]       = N;
    end
  end



  //clock generate
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  //reset generate
  initial begin
    rstn = 1'b0;
    #30;
    rstn = 1'b1;
  end

  initial begin
    int dumpon = 1;
    int vcdplus = 0;
    $value$plusargs("dumpon=%d", dumpon);
    $value$plusargs("vcdplus=%d", vcdplus);

    if (dumpon > 0) begin
      $fsdbDumpvars(0, testbench);
      $fsdbDumpvars("+struct");
      $fsdbDumpvars("+mda");
      $fsdbDumpvars("+all");
      $fsdbDumpon;
    end
    if (vcdplus > 0) begin
      $vcdpluson();
    end
  end

endmodule
