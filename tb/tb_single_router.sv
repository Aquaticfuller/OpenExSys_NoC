module tb_single_router
import rvh_noc_pkg::*;
import v_noc_pkg::*;
#(
  // router parameters
  parameter  INPUT_PORT_NUM = INPUT_PORT_NUMBER,
  parameter  OUTPUT_PORT_NUM = OUTPUT_PORT_NUMBER,
  parameter  LOCAL_PORT_NUM  = INPUT_PORT_NUM-4,
  parameter type flit_payload_t = logic[FLIT_LENGTH-1:0],
  parameter  VC_NUM_INPUT_N = 1+LOCAL_PORT_NUM,
  parameter  VC_NUM_INPUT_S = 1+LOCAL_PORT_NUM,
  parameter  VC_NUM_INPUT_E = 3+LOCAL_PORT_NUM,
  parameter  VC_NUM_INPUT_W = 3+LOCAL_PORT_NUM,
`ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER
  parameter  VC_NUM_INPUT_L = 4+LOCAL_PORT_NUM-1,
`else
  parameter  VC_NUM_INPUT_L = 4,
`endif
  parameter  SA_GLOBAL_INPUT_NUM_N = 3+LOCAL_PORT_NUM,
  parameter  SA_GLOBAL_INPUT_NUM_S = 3+LOCAL_PORT_NUM,
  parameter  SA_GLOBAL_INPUT_NUM_E = 1+LOCAL_PORT_NUM,
  parameter  SA_GLOBAL_INPUT_NUM_W = 1+LOCAL_PORT_NUM,
`ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER
  parameter  SA_GLOBAL_INPUT_NUM_L = 4+LOCAL_PORT_NUM-1,
`else
  parameter  SA_GLOBAL_INPUT_NUM_L = 4,
`endif
  parameter  VC_NUM_OUTPUT_N = 1+LOCAL_PORT_NUM,
  parameter  VC_NUM_OUTPUT_S = 1+LOCAL_PORT_NUM,
  parameter  VC_NUM_OUTPUT_E = 3+LOCAL_PORT_NUM,
  parameter  VC_NUM_OUTPUT_W = 3+LOCAL_PORT_NUM,
  parameter  VC_NUM_OUTPUT_L = 1,
  parameter  VC_DEPTH_INPUT_N = VC_DEPTH_MAX,
  parameter  VC_DEPTH_INPUT_S = VC_DEPTH_MAX,
  parameter  VC_DEPTH_INPUT_E = VC_DEPTH_MAX,
  parameter  VC_DEPTH_INPUT_W = VC_DEPTH_MAX,
  parameter  VC_DEPTH_INPUT_L = VC_DEPTH_MAX,

  // test_generator parameters
  parameter RANDOM_BIT_NUM          = 32,

  parameter SCOREBOARD_TIMEOUT_EN         = 1,
  parameter SCOREBOARD_TIMEOUT_THRESHOLD  = 256,
  
  parameter TEST_CASE_NUM_PER_CYCLE = 10,

  // scoreboard parameters
  parameter SCOREBOARD_ENTRY_NUM_PER_SENDER = 64,

  // sender parameters
  parameter SENDER_TIMEOUT_EN        = 1,
  parameter SENDER_TIMEOUT_THRESHOLD = 256,

  // overall longest test cycle
  parameter LONGEST_TEST_CYCLE = 10000
)
(

);

  genvar i;

  // Ports
  logic           [INPUT_PORT_NUM-1:0]                        rx_flit_pend_i;
  logic           [INPUT_PORT_NUM-1:0]                        rx_flit_v_i;
  flit_payload_t  [INPUT_PORT_NUM-1:0]                        rx_flit_i;
  logic           [INPUT_PORT_NUM-1:0] [VC_ID_NUM_MAX_W-1:0]  rx_flit_vc_id_i;
  io_port_t       [INPUT_PORT_NUM-1:0]                        rx_flit_look_ahead_routing_i;

  logic           [OUTPUT_PORT_NUM-1:0]                       tx_flit_pend_o;
  logic           [OUTPUT_PORT_NUM-1:0]                       tx_flit_v_o;
  flit_payload_t  [OUTPUT_PORT_NUM-1:0]                       tx_flit_o;
  logic           [OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]  tx_flit_vc_id_o;
  io_port_t       [OUTPUT_PORT_NUM-1:0]                       tx_flit_look_ahead_routing_o;

  logic           [INPUT_PORT_NUM-1:0]                        rx_lcrd_v_o;
  logic           [INPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]   rx_lcrd_id_o;

  logic           [OUTPUT_PORT_NUM-1:0]                       tx_lcrd_v_i;
  logic           [OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]  tx_lcrd_id_i;

  logic           [NodeID_X_Width-1:0]                        node_id_x_ths_hop_i;
  logic           [NodeID_Y_Width-1:0]                        node_id_y_ths_hop_i;

  logic clk;
  logic rstn;

  assign node_id_x_ths_hop_i = 2'b01;
  assign node_id_y_ths_hop_i = 2'b01;

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
  logic [64-1:0] mcycle;
  node_id_t target_node;
  
  int longest_test_cycle = LONGEST_TEST_CYCLE;
  int self_finish        = 1;
  
  initial begin
    $value$plusargs("longest_test_cycle=%d", longest_test_cycle);
    $value$plusargs("self_finish=%d", self_finish);
  end

  always_ff @(posedge clk or negedge rstn) begin
    if(~rstn) begin
      mcycle <= '0;
    end else begin
      mcycle <= mcycle + 1;
      if(self_finish > 0) begin
        if(mcycle == longest_test_cycle) begin
          $finish();
        end
      end
    end
  end

  logic         [32-1:0]            src_id_lfsr_seed;
  logic         [32-1:0]            tgt_id_lfsr_seed;
  logic        [INPUT_PORT_NUM-1:0] new_test_vld;
  test_case_t  [INPUT_PORT_NUM-1:0] new_test;
  logic        [INPUT_PORT_NUM-1:0] new_test_rdy;

  assign src_id_lfsr_seed = 32'hdeadbeef;
  assign tgt_id_lfsr_seed = 32'hbaadf00d;

  v_test_generator
  #(
    .SENDER_NUM             (INPUT_PORT_NUM           ),
    .RANDOM_BIT_NUM         (RANDOM_BIT_NUM           ),
    .SCOREBOARD_TIMEOUT_EN  (SCOREBOARD_TIMEOUT_EN    ),
    .SCOREBOARD_TIMEOUT_THRESHOLD      (SCOREBOARD_TIMEOUT_THRESHOLD        ),
    .TEST_CASE_NUM_PER_CYCLE(TEST_CASE_NUM_PER_CYCLE  ),
    .TEST_CASE_SINGLE_ROUTER(1                        ),

    .ASSUMED_SYSTEM_FREQUENCY((1<<30) )
  )
  v_test_generator_u (
    .new_test_vld_o     (new_test_vld ),
    .new_test_o         (new_test ),
    .new_test_rdy_i     (new_test_rdy ),
    .src_id_lfsr_seed_i (src_id_lfsr_seed ^ mcycle[16+:32]),
    .tgt_id_lfsr_seed_i (tgt_id_lfsr_seed ^ mcycle[20+:32] ),
    .lfsr_update_en_i   (&mcycle[16-1:0]),
    .mcycle_i           (mcycle),
    .clk    (clk ),
    .rstn   (rstn)
  );

  logic              [INPUT_PORT_NUM-1:0]  new_scoreboard_entry_vld;
  scoreboard_entry_t [INPUT_PORT_NUM-1:0]  new_scoreboard_entry;
  logic              [INPUT_PORT_NUM-1:0]  new_scoreboard_entry_rdy;
  node_id_t          [OUTPUT_PORT_NUM-1:0] sender_node_id;

//                     sender0 (1,2)
//                               |
//             sender3 (0,1) - (1,1) - (2,1) sender2
//                               |  \
//                     sender1 (1,0) (local) sender4

  assign sender_node_id[0].x_position  = 1;
  assign sender_node_id[0].y_position  = 2;
  assign sender_node_id[0].device_port = '0;
  assign sender_node_id[0].device_id   = '0;
  assign sender_node_id[1].x_position  = 1;
  assign sender_node_id[1].y_position  = 0;
  assign sender_node_id[1].device_port = '0;
  assign sender_node_id[1].device_id   = '0;
  assign sender_node_id[2].x_position  = 2;
  assign sender_node_id[2].y_position  = 1;
  assign sender_node_id[2].device_port = '0;
  assign sender_node_id[2].device_id   = '0;
  assign sender_node_id[3].x_position  = 0;
  assign sender_node_id[3].y_position  = 1;
  assign sender_node_id[3].device_port = '0;
  assign sender_node_id[3].device_id   = '0;
  generate
    if(LOCAL_PORT_NUM > 0) begin: gen_have_local_sender_node_id
      for(i = 0; i < LOCAL_PORT_NUM; i++) begin: gen_local_sender_node_id
        assign sender_node_id[4+i].x_position  = 1;
        assign sender_node_id[4+i].y_position  = 1;
        assign sender_node_id[4+i].device_port = i;
        assign sender_node_id[4+i].device_id   = '0;
      end
    end
  endgenerate

  v_sender
  #(
    .FLIT_BUFFER_DEPTH    (8              ),
    .flit_payload_t       (flit_payload_t ),
    .VC_NUM_OUTPORT       (VC_NUM_INPUT_N),
    .VC_DEPTH_OUTPORT     (VC_DEPTH_INPUT_N ),
    
    .SENDER_TIMEOUT_EN        (SENDER_TIMEOUT_EN       ),
    .SENDER_TIMEOUT_THRESHOLD (SENDER_TIMEOUT_THRESHOLD),

    .OUTPUT_TO_N          (1)
  )
  v_sender_toN_u (
    .tx_flit_pend_o                 (rx_flit_pend_i               [0] ),
    .tx_flit_v_o                    (rx_flit_v_i                  [0] ),
    .tx_flit_o                      (rx_flit_i                    [0] ),
    .tx_flit_vc_id_o                (rx_flit_vc_id_i              [0] ),
    .tx_flit_look_ahead_routing_o   (rx_flit_look_ahead_routing_i [0] ),

    .tx_lcrd_v_i                    (rx_lcrd_v_o                  [0] ),
    .tx_lcrd_id_i                   (rx_lcrd_id_o                 [0] ),
    
    .new_test_vld_i                 (new_test_vld                 [0] ),
    .new_test_i                     (new_test                     [0] ),
    .new_test_rdy_o                 (new_test_rdy                 [0] ),
    
    .new_scoreboard_entry_vld_o     (new_scoreboard_entry_vld     [0] ),
    .new_scoreboard_entry_o         (new_scoreboard_entry         [0] ),
    .new_scoreboard_entry_rdy_i     (new_scoreboard_entry_rdy     [0] ),
    
    .node_id_i                      (sender_node_id               [0] ),

    .mcycle_i                       (mcycle),
    
    .clk  (clk ),
    .rstn (rstn)
  );

  v_sender
  #(
    .FLIT_BUFFER_DEPTH    (8              ),
    .flit_payload_t       (flit_payload_t ),
    .VC_NUM_OUTPORT       (VC_NUM_INPUT_S),
    .VC_DEPTH_OUTPORT     (VC_DEPTH_INPUT_S ),

    .SENDER_TIMEOUT_EN        (SENDER_TIMEOUT_EN       ),
    .SENDER_TIMEOUT_THRESHOLD (SENDER_TIMEOUT_THRESHOLD),

    .OUTPUT_TO_S          (1)
  )
  v_sender_toS_u (
    .tx_flit_pend_o                 (rx_flit_pend_i               [1] ),
    .tx_flit_v_o                    (rx_flit_v_i                  [1] ),
    .tx_flit_o                      (rx_flit_i                    [1] ),
    .tx_flit_vc_id_o                (rx_flit_vc_id_i              [1] ),
    .tx_flit_look_ahead_routing_o   (rx_flit_look_ahead_routing_i [1] ),

    .tx_lcrd_v_i                    (rx_lcrd_v_o                  [1] ),
    .tx_lcrd_id_i                   (rx_lcrd_id_o                 [1] ),
    
    .new_test_vld_i                 (new_test_vld                 [1] ),
    .new_test_i                     (new_test                     [1] ),
    .new_test_rdy_o                 (new_test_rdy                 [1] ),
    
    .new_scoreboard_entry_vld_o     (new_scoreboard_entry_vld     [1] ),
    .new_scoreboard_entry_o         (new_scoreboard_entry         [1] ),
    .new_scoreboard_entry_rdy_i     (new_scoreboard_entry_rdy     [1] ),
    
    .node_id_i                      (sender_node_id               [1] ),
    
    .mcycle_i                       (mcycle),
    
    .clk  (clk ),
    .rstn (rstn)
  );

  v_sender
  #(
    .FLIT_BUFFER_DEPTH    (8              ),
    .flit_payload_t       (flit_payload_t ),
    .VC_NUM_OUTPORT       (VC_NUM_INPUT_E),
    .VC_DEPTH_OUTPORT     (VC_DEPTH_INPUT_E ),

    .SENDER_TIMEOUT_EN        (SENDER_TIMEOUT_EN       ),
    .SENDER_TIMEOUT_THRESHOLD (SENDER_TIMEOUT_THRESHOLD),

    .OUTPUT_TO_E          (1)
  )
  v_sender_toE_u (
    .tx_flit_pend_o                 (rx_flit_pend_i               [2] ),
    .tx_flit_v_o                    (rx_flit_v_i                  [2] ),
    .tx_flit_o                      (rx_flit_i                    [2] ),
    .tx_flit_vc_id_o                (rx_flit_vc_id_i              [2] ),
    .tx_flit_look_ahead_routing_o   (rx_flit_look_ahead_routing_i [2] ),

    .tx_lcrd_v_i                    (rx_lcrd_v_o                  [2] ),
    .tx_lcrd_id_i                   (rx_lcrd_id_o                 [2] ),
    
    .new_test_vld_i                 (new_test_vld                 [2] ),
    .new_test_i                     (new_test                     [2] ),
    .new_test_rdy_o                 (new_test_rdy                 [2] ),
    
    .new_scoreboard_entry_vld_o     (new_scoreboard_entry_vld     [2] ),
    .new_scoreboard_entry_o         (new_scoreboard_entry         [2] ),
    .new_scoreboard_entry_rdy_i     (new_scoreboard_entry_rdy     [2] ),
    
    .node_id_i                      (sender_node_id               [2] ),
    
    .mcycle_i                       (mcycle),
    
    .clk  (clk ),
    .rstn (rstn)
  );

  v_sender
  #(
    .FLIT_BUFFER_DEPTH    (8              ),
    .flit_payload_t       (flit_payload_t ),
    .VC_NUM_OUTPORT       (VC_NUM_INPUT_W),
    .VC_DEPTH_OUTPORT     (VC_DEPTH_INPUT_W ),

    .SENDER_TIMEOUT_EN        (SENDER_TIMEOUT_EN       ),
    .SENDER_TIMEOUT_THRESHOLD (SENDER_TIMEOUT_THRESHOLD),

    .OUTPUT_TO_W          (1)
  )
  v_sender_toW_u (
    .tx_flit_pend_o                 (rx_flit_pend_i               [3] ),
    .tx_flit_v_o                    (rx_flit_v_i                  [3] ),
    .tx_flit_o                      (rx_flit_i                    [3] ),
    .tx_flit_vc_id_o                (rx_flit_vc_id_i              [3] ),
    .tx_flit_look_ahead_routing_o   (rx_flit_look_ahead_routing_i [3] ),

    .tx_lcrd_v_i                    (rx_lcrd_v_o                  [3] ),
    .tx_lcrd_id_i                   (rx_lcrd_id_o                 [3] ),
    
    .new_test_vld_i                 (new_test_vld                 [3] ),
    .new_test_i                     (new_test                     [3] ),
    .new_test_rdy_o                 (new_test_rdy                 [3] ),
    
    .new_scoreboard_entry_vld_o     (new_scoreboard_entry_vld     [3] ),
    .new_scoreboard_entry_o         (new_scoreboard_entry         [3] ),
    .new_scoreboard_entry_rdy_i     (new_scoreboard_entry_rdy     [3] ),
    
    .node_id_i                      (sender_node_id               [3] ),

    .mcycle_i                       (mcycle),
    
    .clk  (clk ),
    .rstn (rstn)
  );

generate
  for(i = 0; i < LOCAL_PORT_NUM; i++) begin
    v_sender
    #(
      .FLIT_BUFFER_DEPTH    (8              ),
      .flit_payload_t       (flit_payload_t ),
      .VC_NUM_OUTPORT       (VC_NUM_INPUT_L),
      .VC_DEPTH_OUTPORT     (VC_DEPTH_INPUT_L ),

      .SENDER_TIMEOUT_EN        (SENDER_TIMEOUT_EN       ),
      .SENDER_TIMEOUT_THRESHOLD (SENDER_TIMEOUT_THRESHOLD),

      .OUTPUT_TO_L          (1)
    )
    v_sender_toL_u (
      .tx_flit_pend_o                 (rx_flit_pend_i               [4+i] ),
      .tx_flit_v_o                    (rx_flit_v_i                  [4+i] ),
      .tx_flit_o                      (rx_flit_i                    [4+i] ),
      .tx_flit_vc_id_o                (rx_flit_vc_id_i              [4+i] ),
      .tx_flit_look_ahead_routing_o   (rx_flit_look_ahead_routing_i [4+i] ),

      .tx_lcrd_v_i                    (rx_lcrd_v_o                  [4+i] ),
      .tx_lcrd_id_i                   (rx_lcrd_id_o                 [4+i] ),

      .new_test_vld_i                 (new_test_vld                 [4+i] ),
      .new_test_i                     (new_test                     [4+i] ),
      .new_test_rdy_o                 (new_test_rdy                 [4+i] ),

      .new_scoreboard_entry_vld_o     (new_scoreboard_entry_vld     [4+i] ),
      .new_scoreboard_entry_o         (new_scoreboard_entry         [4+i] ),
      .new_scoreboard_entry_rdy_i     (new_scoreboard_entry_rdy     [4+i] ),

      .node_id_i                      (sender_node_id               [4+i] ),

      .mcycle_i                       (mcycle),

      .clk  (clk ),
      .rstn (rstn)
    );
  end
endgenerate


  logic           [OUTPUT_PORT_NUM-1:0] check_scoreboard_vld;
  receiver_info_t [OUTPUT_PORT_NUM-1:0] check_scoreboard;
  logic           [OUTPUT_PORT_NUM-1:0] check_scoreboard_rdy;
  node_id_t       [OUTPUT_PORT_NUM-1:0] receiver_node_id;

//                   receiver0 (1,2)
//                               |
//           receiver3 (0,1) - (1,1) - (2,1) receiver2
//                               |  \
//                   receiver1 (1,0) (local) receiver4

  assign receiver_node_id[0].x_position  = 1;
  assign receiver_node_id[0].y_position  = 2;
  assign receiver_node_id[0].device_port = '0;
  assign receiver_node_id[0].device_id   = '0;
  assign receiver_node_id[1].x_position  = 1;
  assign receiver_node_id[1].y_position  = 0;
  assign receiver_node_id[1].device_port = '0;
  assign receiver_node_id[1].device_id   = '0;
  assign receiver_node_id[2].x_position  = 2;
  assign receiver_node_id[2].y_position  = 1;
  assign receiver_node_id[2].device_port = '0;
  assign receiver_node_id[2].device_id   = '0;
  assign receiver_node_id[3].x_position  = 0;
  assign receiver_node_id[3].y_position  = 1;
  assign receiver_node_id[3].device_port = '0;
  assign receiver_node_id[3].device_id   = '0;
  generate
    if(LOCAL_PORT_NUM > 0) begin: gen_have_local_receiver_node_id
      for(i = 0; i < LOCAL_PORT_NUM; i++) begin: gen_local_receiver_node_id
        assign receiver_node_id[4+i].x_position  = 1;
        assign receiver_node_id[4+i].y_position  = 1;
        assign receiver_node_id[4+i].device_port = i;
        assign receiver_node_id[4+i].device_id   = '0;
      end
    end
  endgenerate

  generate
    for(i = 0; i < OUTPUT_PORT_NUM; i++) begin: gen_v_receiver
      v_receiver
      #(
        .flit_payload_t       (flit_payload_t )
      )
      v_receiver_u (
        .rx_flit_pend_i               (tx_flit_pend_o               [i] ),
        .rx_flit_v_i                  (tx_flit_v_o                  [i] ),
        .rx_flit_i                    (tx_flit_o                    [i] ),
        .rx_flit_vc_id_i              (tx_flit_vc_id_o              [i] ),
        .rx_flit_look_ahead_routing_i (tx_flit_look_ahead_routing_o [i] ),

        .rx_lcrd_v_o                  (tx_lcrd_v_i                  [i] ),
        .rx_lcrd_id_o                 (tx_lcrd_id_i                 [i] ),

        .check_scoreboard_vld_o       (check_scoreboard_vld         [i] ),
        .check_scoreboard_o           (check_scoreboard             [i] ),
        .check_scoreboard_rdy_i       (check_scoreboard_rdy         [i] ),

        .node_id_i                    (receiver_node_id             [i] ),

        .clk   (clk ),
        .rstn  (rstn)
      );
    end
  endgenerate


  v_scoreboard
  #(
    .SCOREBOARD_ENTRY_NUM_PER_SENDER (SCOREBOARD_ENTRY_NUM_PER_SENDER ),
    .SENDER_NUM                      (INPUT_PORT_NUM                  ),
    .RECEIVER_NUM                    (OUTPUT_PORT_NUM                 ),

    .NODE_NUM_X_DIMESION    (NODE_NUM_X_DIMESION      ),
    .NODE_NUM_Y_DIMESION    (NODE_NUM_Y_DIMESION      ),
    .LOCAL_PORT_NUM         (LOCAL_PORT_NUM           ),

    .TEST_CASE_SINGLE_ROUTER         (1),

    .ASSUMED_SYSTEM_FREQUENCY        ((1<<30) )
  )
  v_scoreboard_u (
    .new_scoreboard_entry_vld_i (new_scoreboard_entry_vld ),
    .new_scoreboard_entry_i     (new_scoreboard_entry     ),
    .new_scoreboard_entry_rdy_o (new_scoreboard_entry_rdy ),

    .check_scoreboard_vld_i     (check_scoreboard_vld ),
    .check_scoreboard_i         (check_scoreboard     ),
    .check_scoreboard_rdy_o     (check_scoreboard_rdy ),

    .mcycle_i                   (mcycle ),

    .clk    (clk ),
    .rstn   (rstn)
  );





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
      $fsdbDumpvars(0, tb_single_router);
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
