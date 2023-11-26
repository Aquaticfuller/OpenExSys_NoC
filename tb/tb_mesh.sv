module tb_mesh
import rvh_noc_pkg::*;
import v_noc_pkg::*;
#(
  // mesh parameters
  parameter  NODE_NUM_X_DIMESION = 3,
  parameter  NODE_NUM_Y_DIMESION = 3,
  
  // router parameters
  parameter  INPUT_PORT_NUM = INPUT_PORT_NUMBER,
  parameter  OUTPUT_PORT_NUM = OUTPUT_PORT_NUMBER,
  parameter  LOCAL_PORT_NUM  = INPUT_PORT_NUM-4,
  parameter type flit_payload_t = logic[FLIT_LENGTH-1:0],

  // parameter  QOS_VC_NUM_PER_INPUT = QOS_VC_NUM_PER_INPUT,

  parameter VC_NUM_INPUT_N = 1+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter VC_NUM_INPUT_S = 1+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter VC_NUM_INPUT_E = 3+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter VC_NUM_INPUT_W = 3+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
`ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER
  parameter  VC_NUM_INPUT_L = 4+LOCAL_PORT_NUM-1+QOS_VC_NUM_PER_INPUT,
`else
  parameter  VC_NUM_INPUT_L = 4+QOS_VC_NUM_PER_INPUT,
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
  parameter  VC_NUM_OUTPUT_N = 1+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter  VC_NUM_OUTPUT_S = 1+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter  VC_NUM_OUTPUT_E = 3+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter  VC_NUM_OUTPUT_W = 3+LOCAL_PORT_NUM+QOS_VC_NUM_PER_INPUT,
  parameter  VC_NUM_OUTPUT_L = 1,
  parameter  VC_DEPTH_INPUT_N = VC_DEPTH_MAX,
  parameter  VC_DEPTH_INPUT_S = VC_DEPTH_MAX,
  parameter  VC_DEPTH_INPUT_E = VC_DEPTH_MAX,
  parameter  VC_DEPTH_INPUT_W = VC_DEPTH_MAX,
  parameter  VC_DEPTH_INPUT_L = VC_DEPTH_MAX,

  parameter int  V_CPU_DATA_REQ_NUM_PER_CORE_PER_CYCLE = 3,
  parameter int  V_CPU_INST_REQ_NUM_PER_CORE_PER_CYCLE = 1,
  parameter real V_L1D_MISS_RATE = 10, // %
  parameter real V_L1I_MISS_RATE = 10, // %
  parameter real V_L2_MISS_RATE  = 100, // %
  parameter int  V_CORE_NUM = NODE_NUM_X_DIMESION * NODE_NUM_Y_DIMESION * LOCAL_PORT_NUM,
  parameter int  V_CACHE_MISS_ALL_CORE_PER_CYCLE = V_CORE_NUM,
  // parameter int  V_CACHE_MISS_ALL_CORE_PER_CYCLE = ((V_CPU_DATA_REQ_NUM_PER_CORE_PER_CYCLE * V_CORE_NUM) * V_L1D_MISS_RATE +
  //                                                   (V_CPU_INST_REQ_NUM_PER_CORE_PER_CYCLE * V_CORE_NUM) * V_L1I_MISS_RATE) *
  //                                                   V_L2_MISS_RATE / 100 / 100,
  

  // test_generator parameters
  parameter TEST_CASE_MESH_RANDOM   = 1,                      // random sender and receiver
  parameter TEST_CASE_MESH_DIAGONAL = !TEST_CASE_MESH_RANDOM, // from (0,0) to (NODE_NUM_X_DIMESION-1, NODE_NUM_Y_DIMESION-1)
  
  parameter RANDOM_BIT_NUM          = 168, // 32,64,80,128,168
  
  parameter SCOREBOARD_TIMEOUT_EN        = !TEST_CASE_MESH_DIAGONAL,
  parameter SCOREBOARD_TIMEOUT_THRESHOLD = 16384,
  
  parameter TEST_CASE_NUM_PER_CYCLE = RANDOM_BIT_NUM/3,
  // parameter TEST_CASE_NUM_PER_CYCLE = V_CACHE_MISS_ALL_CORE_PER_CYCLE < 1                ? 1                : 
  //                                     V_CACHE_MISS_ALL_CORE_PER_CYCLE > RANDOM_BIT_NUM/3 ? RANDOM_BIT_NUM/3 : // no more than RANDOM_BIT_NUM/3
  //                                     V_CACHE_MISS_ALL_CORE_PER_CYCLE,

  // scoreboard parameters
  parameter SCOREBOARD_ENTRY_NUM_PER_SENDER = 64,

  // sender parameters
  parameter SENDER_NUM = NODE_NUM_X_DIMESION*NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM,
  parameter SENDER_FLIT_BUFFER_DEPTH = 512,

  parameter SENDER_TIMEOUT_EN        = !TEST_CASE_MESH_DIAGONAL,
  parameter SENDER_TIMEOUT_THRESHOLD = 16384,

  // receiver parameters
  parameter RECEIVER_NUM = SENDER_NUM,

  // overall longest test cycle
  parameter LONGEST_TEST_CYCLE = 100000
)
(

);

  genvar i, j, k;

  // Ports
  logic           [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][OUTPUT_PORT_NUM-1:0]                       tx_flit_pend;
  logic           [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][OUTPUT_PORT_NUM-1:0]                       tx_flit_v;
  flit_payload_t  [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][OUTPUT_PORT_NUM-1:0]                       tx_flit;
  logic           [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]  tx_flit_vc_id;
  io_port_t       [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][OUTPUT_PORT_NUM-1:0]                       tx_flit_look_ahead_routing;

  logic           [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][OUTPUT_PORT_NUM-1:0]                       rx_flit_pend;
  logic           [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][OUTPUT_PORT_NUM-1:0]                       rx_flit_v;
  flit_payload_t  [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][OUTPUT_PORT_NUM-1:0]                       rx_flit;
  logic           [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][OUTPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]  rx_flit_vc_id;
  io_port_t       [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][OUTPUT_PORT_NUM-1:0]                       rx_flit_look_ahead_routing;

  logic           [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][INPUT_PORT_NUM-1:0]                        tx_lcrd_v;
  logic           [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][INPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]   tx_lcrd_id;

  logic           [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][INPUT_PORT_NUM-1:0]                        rx_lcrd_v;
  logic           [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][INPUT_PORT_NUM-1:0][VC_ID_NUM_MAX_W-1:0]   rx_lcrd_id;


  logic           [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][NodeID_X_Width-1:0]                        node_id_x;
  logic           [NODE_NUM_X_DIMESION-1:0][NODE_NUM_Y_DIMESION-1:0][NodeID_Y_Width-1:0]                        node_id_y;

  logic clk;
  logic rstn;


  // generate mesh routers
  generate
    for(i = 0; i < NODE_NUM_X_DIMESION; i++) begin: gen_mesh_routers_x_dimesion
      for(j = 0; j < NODE_NUM_Y_DIMESION; j++) begin: gen_mesh_routers_y_dimesion
        vnet_router
        #(
          .INPUT_PORT_NUM(INPUT_PORT_NUM ),
          .OUTPUT_PORT_NUM(OUTPUT_PORT_NUM ),
          .flit_payload_t(flit_payload_t),
          .QOS_VC_NUM_PER_INPUT(QOS_VC_NUM_PER_INPUT),
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
          .rx_flit_pend_i               (rx_flit_pend               [i][j] ),
          .rx_flit_v_i                  (rx_flit_v                  [i][j] ),
          .rx_flit_i                    (rx_flit                    [i][j] ),
          .rx_flit_vc_id_i              (rx_flit_vc_id              [i][j] ),
          .rx_flit_look_ahead_routing_i (rx_flit_look_ahead_routing [i][j] ),

          .tx_flit_pend_o               (tx_flit_pend               [i][j] ),
          .tx_flit_v_o                  (tx_flit_v                  [i][j] ),
          .tx_flit_o                    (tx_flit                    [i][j] ),
          .tx_flit_vc_id_o              (tx_flit_vc_id              [i][j] ),
          .tx_flit_look_ahead_routing_o (tx_flit_look_ahead_routing [i][j] ),

          .rx_lcrd_v_o                  (rx_lcrd_v                  [i][j] ),
          .rx_lcrd_id_o                 (rx_lcrd_id                 [i][j] ),

          .tx_lcrd_v_i                  (tx_lcrd_v                  [i][j] ),
          .tx_lcrd_id_i                 (tx_lcrd_id                 [i][j] ),

          .node_id_x_ths_hop_i          (node_id_x                  [i][j] ),
          .node_id_y_ths_hop_i          (node_id_y                  [i][j] ),

          .clk    (clk ),
          .rstn   (rstn)
        );
      end
    end
  endgenerate

  // assign node id to each router
  generate
    for(i = 0; i < NODE_NUM_X_DIMESION; i++) begin: gen_node_id_x_x_dimesion
      for(j = 0; j < NODE_NUM_Y_DIMESION; j++) begin: gen_node_id_x_y_dimesion
        assign node_id_x [i][j] = i;
      end
    end
    for(i = 0; i < NODE_NUM_Y_DIMESION; i++) begin: gen_node_id_y_y_dimesion
      for(j = 0; j < NODE_NUM_X_DIMESION; j++) begin: gen_node_id_y_x_dimesion
        assign node_id_y [j][i] = i;
      end
    end
  endgenerate

  // connect each router together
  generate
    for(i = 0; i < NODE_NUM_X_DIMESION; i++) begin: gen_connect_routers_ns_x_dimesion
      for(j = 0; j < NODE_NUM_Y_DIMESION-1; j++) begin: gen_connect_routers_ns_y_dimesion
        // connect N inport to S outport
        assign rx_flit_pend               [i][j][0]   = tx_flit_pend                [i][j+1][1];
        assign rx_flit_v                  [i][j][0]   = tx_flit_v                   [i][j+1][1];
        assign rx_flit                    [i][j][0]   = tx_flit                     [i][j+1][1];
        assign rx_flit_vc_id              [i][j][0]   = tx_flit_vc_id               [i][j+1][1];
        assign rx_flit_look_ahead_routing [i][j][0]   = tx_flit_look_ahead_routing  [i][j+1][1];

        assign tx_lcrd_v                  [i][j][0]   = rx_lcrd_v                   [i][j+1][1];
        assign tx_lcrd_id                 [i][j][0]   = rx_lcrd_id                  [i][j+1][1];

        // connect S inport to N outport
        assign rx_flit_pend               [i][j+1][1] = tx_flit_pend                [i][j][0];
        assign rx_flit_v                  [i][j+1][1] = tx_flit_v                   [i][j][0];
        assign rx_flit                    [i][j+1][1] = tx_flit                     [i][j][0];
        assign rx_flit_vc_id              [i][j+1][1] = tx_flit_vc_id               [i][j][0];
        assign rx_flit_look_ahead_routing [i][j+1][1] = tx_flit_look_ahead_routing  [i][j][0];

        assign tx_lcrd_v                  [i][j+1][1] = rx_lcrd_v                   [i][j][0];
        assign tx_lcrd_id                 [i][j+1][1] = rx_lcrd_id                  [i][j][0];
      end
    end
  endgenerate

  generate
    for(i = 0; i < NODE_NUM_Y_DIMESION; i++) begin: gen_connect_routers_ew_x_dimesion
      for(j = 0; j < NODE_NUM_X_DIMESION-1; j++) begin: gen_connect_routers_ew_y_dimesion
        // connect E inport to W outport
        assign rx_flit_pend               [j][i][2]   = tx_flit_pend                [j+1][i][3];
        assign rx_flit_v                  [j][i][2]   = tx_flit_v                   [j+1][i][3];
        assign rx_flit                    [j][i][2]   = tx_flit                     [j+1][i][3];
        assign rx_flit_vc_id              [j][i][2]   = tx_flit_vc_id               [j+1][i][3];
        assign rx_flit_look_ahead_routing [j][i][2]   = tx_flit_look_ahead_routing  [j+1][i][3];

        assign tx_lcrd_v                  [j][i][2]   = rx_lcrd_v                   [j+1][i][3];
        assign tx_lcrd_id                 [j][i][2]   = rx_lcrd_id                  [j+1][i][3];

        // connect W inport to E outport
        assign rx_flit_pend               [j+1][i][3] = tx_flit_pend                [j][i][2];
        assign rx_flit_v                  [j+1][i][3] = tx_flit_v                   [j][i][2];
        assign rx_flit                    [j+1][i][3] = tx_flit                     [j][i][2];
        assign rx_flit_vc_id              [j+1][i][3] = tx_flit_vc_id               [j][i][2];
        assign rx_flit_look_ahead_routing [j+1][i][3] = tx_flit_look_ahead_routing  [j][i][2];

        assign tx_lcrd_v                  [j+1][i][3] = rx_lcrd_v                   [j][i][2];
        assign tx_lcrd_id                 [j+1][i][3] = rx_lcrd_id                  [j][i][2];
      end
    end
  endgenerate

  // other unused non-local ports, assign router rx to 0
  generate
    for(i = 0; i < NODE_NUM_X_DIMESION; i++) begin: gen_unused_non_local_ports_x_dimesion
      assign rx_flit_pend               [i][NODE_NUM_Y_DIMESION-1][0]   = '0;
      assign rx_flit_v                  [i][NODE_NUM_Y_DIMESION-1][0]   = '0;
      assign rx_flit                    [i][NODE_NUM_Y_DIMESION-1][0]   = '0;
      assign rx_flit_vc_id              [i][NODE_NUM_Y_DIMESION-1][0]   = '0;
      assign rx_flit_look_ahead_routing [i][NODE_NUM_Y_DIMESION-1][0]   = '0;

      assign tx_lcrd_v                  [i][NODE_NUM_Y_DIMESION-1][0]   = '0;
      assign tx_lcrd_id                 [i][NODE_NUM_Y_DIMESION-1][0]   = '0;


      assign rx_flit_pend               [i][0][1]                       = '0;
      assign rx_flit_v                  [i][0][1]                       = '0;
      assign rx_flit                    [i][0][1]                       = '0;
      assign rx_flit_vc_id              [i][0][1]                       = '0;
      assign rx_flit_look_ahead_routing [i][0][1]                       = '0;

      assign tx_lcrd_v                  [i][0][1]                       = '0;
      assign tx_lcrd_id                 [i][0][1]                       = '0;
    end

    for(i = 0; i < NODE_NUM_Y_DIMESION; i++) begin: gen_unused_non_local_ports_y_dimesion
      // connect E inport to W outport
      assign rx_flit_pend               [NODE_NUM_X_DIMESION-1][i][2]   = '0;
      assign rx_flit_v                  [NODE_NUM_X_DIMESION-1][i][2]   = '0;
      assign rx_flit                    [NODE_NUM_X_DIMESION-1][i][2]   = '0;
      assign rx_flit_vc_id              [NODE_NUM_X_DIMESION-1][i][2]   = '0;
      assign rx_flit_look_ahead_routing [NODE_NUM_X_DIMESION-1][i][2]   = '0;

      assign tx_lcrd_v                  [NODE_NUM_X_DIMESION-1][i][2]   = '0;
      assign tx_lcrd_id                 [NODE_NUM_X_DIMESION-1][i][2]   = '0;

      // connect W inport to E outport
      assign rx_flit_pend               [0][i][3]                       = '0;
      assign rx_flit_v                  [0][i][3]                       = '0;
      assign rx_flit                    [0][i][3]                       = '0;
      assign rx_flit_vc_id              [0][i][3]                       = '0;
      assign rx_flit_look_ahead_routing [0][i][3]                       = '0;

      assign tx_lcrd_v                  [0][i][3]                       = '0;
      assign tx_lcrd_id                 [0][i][3]                       = '0;
    end
  endgenerate


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
  logic        [SENDER_NUM-1:0] new_test_vld;
  test_case_t  [SENDER_NUM-1:0] new_test;
  logic        [SENDER_NUM-1:0] new_test_rdy;

  assign src_id_lfsr_seed = 32'hdeadbeef;
  assign tgt_id_lfsr_seed = 32'hbaadf00d;

  v_test_generator
  #(
    .SENDER_NUM             (SENDER_NUM               ),
    .RANDOM_BIT_NUM         (RANDOM_BIT_NUM           ),
    .SCOREBOARD_TIMEOUT_EN  (SCOREBOARD_TIMEOUT_EN    ),
    .SCOREBOARD_TIMEOUT_THRESHOLD      (SCOREBOARD_TIMEOUT_THRESHOLD        ),
    .TEST_CASE_NUM_PER_CYCLE(TEST_CASE_NUM_PER_CYCLE  ),
    .TEST_CASE_MESH_RANDOM  (TEST_CASE_MESH_RANDOM    ),
    .TEST_CASE_MESH_DIAGONAL(TEST_CASE_MESH_DIAGONAL  ),
    .NODE_NUM_X_DIMESION    (NODE_NUM_X_DIMESION      ),
    .NODE_NUM_Y_DIMESION    (NODE_NUM_Y_DIMESION      ),
    .LOCAL_PORT_NUM         (LOCAL_PORT_NUM           ),

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

  logic              [SENDER_NUM-1:0]  new_scoreboard_entry_vld;
  scoreboard_entry_t [SENDER_NUM-1:0]  new_scoreboard_entry;
  logic              [SENDER_NUM-1:0]  new_scoreboard_entry_rdy;
  node_id_t          [SENDER_NUM-1:0]  sender_node_id;


// local port map to sender number
// sender id = x_posotion*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + y_posotion*LOCAL_PORT_NUM + local_port_id
//        7   8        17  16
//         \  |        |  /
//     6  - (0,2) -- (1,2) - 15
//       5    |        |   14
//         \  |        |  /
//     4  - (0,1) -- (1,1) - 13
//         /  |        |  \
//        3   |        |   12
//      2 - (0,0) -- (1,0) - 11
//         /  |        |  \
//        1   0        9   10

  generate
    for(i = 0; i < NODE_NUM_X_DIMESION; i++) begin: gen_sender_node_id_x_dimesion
      for(j = 0; j < NODE_NUM_Y_DIMESION; j++) begin: gen_sender_node_id_y_dimesion
        for(k = 0; k < LOCAL_PORT_NUM; k++) begin: gen_sender_node_id_device_port
          assign sender_node_id[i*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + j*LOCAL_PORT_NUM + k].x_position  = i;
          assign sender_node_id[i*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + j*LOCAL_PORT_NUM + k].y_position  = j;
          assign sender_node_id[i*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + j*LOCAL_PORT_NUM + k].device_port = k;
          assign sender_node_id[i*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + j*LOCAL_PORT_NUM + k].device_id   = '0;
        end
      end
    end
  endgenerate


generate
  for(i = 0; i < NODE_NUM_X_DIMESION; i++) begin: gen_v_sender_x_dimesion
    for(j = 0; j < NODE_NUM_Y_DIMESION; j++) begin: gen_v_sender_y_dimesion
      for(k = 0; k < LOCAL_PORT_NUM; k++) begin: gen_v_sender_device_port
        v_sender
        #(
          .FLIT_BUFFER_DEPTH    (SENDER_FLIT_BUFFER_DEPTH),
          .flit_payload_t       (flit_payload_t ),
          .VC_NUM_OUTPORT       (VC_NUM_INPUT_L),
          .VC_DEPTH_OUTPORT     (VC_DEPTH_INPUT_L ),

          .SENDER_TIMEOUT_EN        (SENDER_TIMEOUT_EN      ),
          .SENDER_TIMEOUT_THRESHOLD (SENDER_TIMEOUT_THRESHOLD),

          .OUTPUT_TO_L          (1)
        )
        v_sender_toL_u (
          .tx_flit_pend_o                 (rx_flit_pend                 [i][j][4+k] ),
          .tx_flit_v_o                    (rx_flit_v                    [i][j][4+k] ),
          .tx_flit_o                      (rx_flit                      [i][j][4+k] ),
          .tx_flit_vc_id_o                (rx_flit_vc_id                [i][j][4+k] ),
          .tx_flit_look_ahead_routing_o   (rx_flit_look_ahead_routing   [i][j][4+k] ),

          .tx_lcrd_v_i                    (rx_lcrd_v                    [i][j][4+k] ),
          .tx_lcrd_id_i                   (rx_lcrd_id                   [i][j][4+k] ),

          // sender id = x_posotion*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + y_posotion*LOCAL_PORT_NUM + local_port_id
          .new_test_vld_i                 (new_test_vld                 [i*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + j*LOCAL_PORT_NUM + k] ),
          .new_test_i                     (new_test                     [i*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + j*LOCAL_PORT_NUM + k] ),
          .new_test_rdy_o                 (new_test_rdy                 [i*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + j*LOCAL_PORT_NUM + k] ),

          .new_scoreboard_entry_vld_o     (new_scoreboard_entry_vld     [i*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + j*LOCAL_PORT_NUM + k] ),
          .new_scoreboard_entry_o         (new_scoreboard_entry         [i*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + j*LOCAL_PORT_NUM + k] ),
          .new_scoreboard_entry_rdy_i     (new_scoreboard_entry_rdy     [i*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + j*LOCAL_PORT_NUM + k] ),

          .node_id_i                      (sender_node_id               [i*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + j*LOCAL_PORT_NUM + k] ),

          .mcycle_i                       (mcycle),

          .clk  (clk ),
          .rstn (rstn)
        );
      end
    end
  end
endgenerate


  logic           [RECEIVER_NUM-1:0] check_scoreboard_vld;
  receiver_info_t [RECEIVER_NUM-1:0] check_scoreboard;
  logic           [RECEIVER_NUM-1:0] check_scoreboard_rdy;
  node_id_t       [RECEIVER_NUM-1:0] receiver_node_id;

// local port map to receiver number
// receiver id = x_posotion*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + y_posotion*LOCAL_PORT_NUM + local_port_id
//        7   8        17  16
//         \  |        |  /
//     6  - (0,2) -- (1,2) - 15
//       5    |        |   14
//         \  |        |  /
//     4  - (0,1) -- (1,1) - 13
//         /  |        |  \
//        3   |        |   12
//      2 - (0,0) -- (1,0) - 11
//         /  |        |  \
//        1   0        9   10

  generate
    for(i = 0; i < NODE_NUM_X_DIMESION; i++) begin: gen_receiver_node_id_x_dimesion
      for(j = 0; j < NODE_NUM_Y_DIMESION; j++) begin: gen_receiver_node_id_y_dimesion
        for(k = 0; k < LOCAL_PORT_NUM; k++) begin: gen_receiver_node_id_device_port
          assign receiver_node_id[i*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + j*LOCAL_PORT_NUM + k].x_position  = i;
          assign receiver_node_id[i*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + j*LOCAL_PORT_NUM + k].y_position  = j;
          assign receiver_node_id[i*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + j*LOCAL_PORT_NUM + k].device_port = k;
          assign receiver_node_id[i*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + j*LOCAL_PORT_NUM + k].device_id   = '0;
        end
      end
    end
  endgenerate

  generate
    for(i = 0; i < NODE_NUM_X_DIMESION; i++) begin: gen_v_receiver_x_dimesion
      for(j = 0; j < NODE_NUM_Y_DIMESION; j++) begin: gen_v_receiver_y_dimesion
        for(k = 0; k < LOCAL_PORT_NUM; k++) begin: gen_v_sender_device_port
          v_receiver
          #(
            .flit_payload_t       (flit_payload_t )
          )
          v_receiver_u (
            .rx_flit_pend_i               (tx_flit_pend                 [i][j][4+k] ),
            .rx_flit_v_i                  (tx_flit_v                    [i][j][4+k] ),
            .rx_flit_i                    (tx_flit                      [i][j][4+k] ),
            .rx_flit_vc_id_i              (tx_flit_vc_id                [i][j][4+k] ),
            .rx_flit_look_ahead_routing_i (tx_flit_look_ahead_routing   [i][j][4+k] ),

            .rx_lcrd_v_o                  (tx_lcrd_v                    [i][j][4+k] ),
            .rx_lcrd_id_o                 (tx_lcrd_id                   [i][j][4+k] ),

            // receiver id = x_posotion*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + y_posotion*LOCAL_PORT_NUM + local_port_id
            .check_scoreboard_vld_o       (check_scoreboard_vld         [i*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + j*LOCAL_PORT_NUM + k] ),
            .check_scoreboard_o           (check_scoreboard             [i*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + j*LOCAL_PORT_NUM + k] ),
            .check_scoreboard_rdy_i       (check_scoreboard_rdy         [i*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + j*LOCAL_PORT_NUM + k] ),

            .node_id_i                    (receiver_node_id             [i*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + j*LOCAL_PORT_NUM + k] ),

            .clk   (clk ),
            .rstn  (rstn)
          );
        end
      end
    end
  endgenerate


  v_scoreboard
  #(
    .SCOREBOARD_ENTRY_NUM_PER_SENDER (SCOREBOARD_ENTRY_NUM_PER_SENDER ),
    .SENDER_NUM                      (SENDER_NUM                   ),
    .RECEIVER_NUM                    (RECEIVER_NUM                 ),

    .NODE_NUM_X_DIMESION    (NODE_NUM_X_DIMESION      ),
    .NODE_NUM_Y_DIMESION    (NODE_NUM_Y_DIMESION      ),
    .LOCAL_PORT_NUM         (LOCAL_PORT_NUM           ),

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
      // $fsdbDumpvars(0, tb_mesh);
      // $fsdbDumpvars("+struct");
      // $fsdbDumpvars("+mda");
      // $fsdbDumpvars("+all");
      // $fsdbDumpon;
      $vcdpluson();
    end
    if (vcdplus > 0) begin
      $vcdpluson();
    end
  end

endmodule
