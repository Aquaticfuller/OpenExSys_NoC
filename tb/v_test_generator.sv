module v_test_generator
import rvh_noc_pkg::*;
import v_noc_pkg::*;
#(
  parameter SENDER_NUM = 1,
  parameter LOCAL_PORT_SENDER_NUM = SENDER_NUM-4,
  parameter RANDOM_BIT_NUM = 32, // 1 to 32, at least TEST_CASE_NUM_PER_CYCLE*3
  parameter SCOREBOARD_TIMEOUT_EN = 1,
  parameter SCOREBOARD_TIMEOUT_THRESHOLD = 64,

  parameter TEST_CASE_NUM_PER_CYCLE = 1,

  parameter TEST_CASE_SINGLE_ROUTER = 0, // assume the dut router posetion is (1,1)
                                         // its adjacent routers are:
                                         //                     sender0 (1,2)
                                         //                               |
                                         //             sender3 (0,1) - (1,1) - (2,1) sender2
                                         //                               |  \
                                         //                     sender1 (1,0) (local) sender4
  parameter TEST_CASE_MESH_RANDOM   = 0, // random sender and receiver
  parameter TEST_CASE_MESH_DIAGONAL = 0, // from (0,0) to (NODE_NUM_X_DIMESION-1, NODE_NUM_Y_DIMESION-1)
  parameter NODE_NUM_X_DIMESION     = 2, // only used in TEST_CASE_MESH_* mode
  parameter NODE_NUM_Y_DIMESION     = 3, // only used in TEST_CASE_MESH_* mode
  parameter LOCAL_PORT_NUM          = 1,  // only used in TEST_CASE_MESH_* mode

  parameter ASSUMED_SYSTEM_FREQUENCY = (1<<30) // 1GHz

)
(
  // intf with sender
  output logic        [SENDER_NUM-1:0] new_test_vld_o,
  output test_case_t  [SENDER_NUM-1:0] new_test_o,
  input  logic        [SENDER_NUM-1:0] new_test_rdy_i,

  // random seeds
  input  logic    [RANDOM_BIT_NUM-1:0] src_id_lfsr_seed_i,
  input  logic    [RANDOM_BIT_NUM-1:0] tgt_id_lfsr_seed_i,
  input  logic                         lfsr_update_en_i,

  input  logic                [64-1:0] mcycle_i,

  input  logic clk,
  input  logic rstn
);

genvar i;

logic [RANDOM_BIT_NUM-1:0] src_id_lfsr_data;
logic [RANDOM_BIT_NUM-1:0] tgt_id_lfsr_data;

logic [TxnID_Width-1:0] txn_counter;

logic       [TEST_CASE_NUM_PER_CYCLE-1:0] new_test_vld;
test_case_t [TEST_CASE_NUM_PER_CYCLE-1:0] new_test;

// map new test case to different sender
generate
  if(TEST_CASE_SINGLE_ROUTER) begin: gen_map_test_case_single_router
    always_comb begin
      new_test_vld_o = '0;
      new_test_o     = '0;
      for(int i = 0; i < TEST_CASE_NUM_PER_CYCLE; i++) begin
        unique case({new_test[i].flit_head.src_id.x_position, new_test[i].flit_head.src_id.y_position})
          4'b0110: begin // sender0 (1,2)
            new_test_vld_o[0] = new_test_vld[i];
            new_test_o    [0] = new_test[i];
          end
          4'b0100: begin // sender1 (1,0)
            new_test_vld_o[1] = new_test_vld[i];
            new_test_o    [1] = new_test[i];
          end
          4'b1001: begin // sender2 (2,1)
            new_test_vld_o[2] = new_test_vld[i];
            new_test_o    [2] = new_test[i];
          end
          4'b0001: begin // sender3 (0,1)
            new_test_vld_o[3] = new_test_vld[i];
            new_test_o    [3] = new_test[i];
          end
          4'b0101: begin // sender4 (1,1)
            new_test_vld_o[4+new_test[i].flit_head.src_id.device_port] = new_test_vld[i];
            new_test_o    [4+new_test[i].flit_head.src_id.device_port] = new_test[i];
          end
          default:begin
            $fatal("test generator source id error");
          end
        endcase
      end
    end
  end



  else if(TEST_CASE_MESH_RANDOM || TEST_CASE_MESH_DIAGONAL) begin: gen_map_test_case_mesh_x
    // sender id = x_posotion*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + y_posotion*LOCAL_PORT_NUM + local_port_id
    always_comb begin
      new_test_vld_o = '0;
      new_test_o     = '0;
      for(int i = 0; i < TEST_CASE_NUM_PER_CYCLE; i++) begin
        new_test_vld_o[new_test[i].flit_head.src_id.x_position*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + 
                       new_test[i].flit_head.src_id.y_position*LOCAL_PORT_NUM + 
                       new_test[i].flit_head.src_id.device_port] = new_test_vld[i];
        new_test_o    [new_test[i].flit_head.src_id.x_position*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + 
                       new_test[i].flit_head.src_id.y_position*LOCAL_PORT_NUM + 
                       new_test[i].flit_head.src_id.device_port] = new_test[i];

      end
    end
  end
endgenerate

// generate new test case
generate
  if(TEST_CASE_SINGLE_ROUTER) begin: gen_test_case_single_router
    for(i = 0; i < TEST_CASE_NUM_PER_CYCLE; i++) begin: gen_new_test
      always_comb begin
        unique case(src_id_lfsr_data[i*3+:3])
          3'b000: begin // from N
            new_test[i].flit_head.src_id.x_position = 1;
            new_test[i].flit_head.src_id.y_position = 2;
            unique case(tgt_id_lfsr_data[i])
              1'b0: begin // to S
                new_test[i].flit_head.tgt_id.x_position = 1;
                new_test[i].flit_head.tgt_id.y_position = 0;
              end
              default: begin // to L
                new_test[i].flit_head.tgt_id.x_position = 1;
                new_test[i].flit_head.tgt_id.y_position = 1;
              end
            endcase
          end
          3'b001: begin // from S
            new_test[i].flit_head.src_id.x_position = 1;
            new_test[i].flit_head.src_id.y_position = 0;
            unique case(tgt_id_lfsr_data[i])
              1'b0: begin // to N
                new_test[i].flit_head.tgt_id.x_position = 1;
                new_test[i].flit_head.tgt_id.y_position = 2;
              end
              default: begin // to L
                new_test[i].flit_head.tgt_id.x_position = 1;
                new_test[i].flit_head.tgt_id.y_position = 1;
              end
            endcase
          end
          3'b010: begin // from E
            new_test[i].flit_head.src_id.x_position = 2;
            new_test[i].flit_head.src_id.y_position = 1;
            unique case(tgt_id_lfsr_data[i*2+:2])
              2'b00: begin // to N
                new_test[i].flit_head.tgt_id.x_position = 1;
                new_test[i].flit_head.tgt_id.y_position = 2;
              end
              2'b01: begin // to S
                new_test[i].flit_head.tgt_id.x_position = 1;
                new_test[i].flit_head.tgt_id.y_position = 0;
              end
              2'b10: begin // to W
                new_test[i].flit_head.tgt_id.x_position = 0;
                new_test[i].flit_head.tgt_id.y_position = 1;
              end
              default: begin // to L
                new_test[i].flit_head.tgt_id.x_position = 1;
                new_test[i].flit_head.tgt_id.y_position = 1;
              end
            endcase
          end
          3'b011: begin // from W
            new_test[i].flit_head.src_id.x_position = 0;
            new_test[i].flit_head.src_id.y_position = 1;
            unique case(tgt_id_lfsr_data[i*2+:2])
              2'b00: begin // to N
                new_test[i].flit_head.tgt_id.x_position = 1;
                new_test[i].flit_head.tgt_id.y_position = 2;
              end
              2'b01: begin // to S
                new_test[i].flit_head.tgt_id.x_position = 1;
                new_test[i].flit_head.tgt_id.y_position = 0;
              end
              2'b10: begin // to E
                new_test[i].flit_head.tgt_id.x_position = 2;
                new_test[i].flit_head.tgt_id.y_position = 1;
              end
              default: begin // to L
                new_test[i].flit_head.tgt_id.x_position = 1;
                new_test[i].flit_head.tgt_id.y_position = 1;
              end
            endcase
          end
          default: begin // from L
            new_test[i].flit_head.src_id.x_position = 1;
            new_test[i].flit_head.src_id.y_position = 1;
            unique case(tgt_id_lfsr_data[i*2+:2])
              2'b00: begin // to N
                new_test[i].flit_head.tgt_id.x_position = 1;
                new_test[i].flit_head.tgt_id.y_position = 2;
              end
              2'b01: begin // to S
                new_test[i].flit_head.tgt_id.x_position = 1;
                new_test[i].flit_head.tgt_id.y_position = 0;
              end
              2'b10: begin // to E
                new_test[i].flit_head.tgt_id.x_position = 2;
                new_test[i].flit_head.tgt_id.y_position = 1;
              end
              default: begin // to W
                new_test[i].flit_head.tgt_id.x_position = 0;
                new_test[i].flit_head.tgt_id.y_position = 1;
              end
            endcase
          end
        endcase
      end

      logic [FLIT_DATA_LENGTH-1:0] flit_data_mask;
      always_comb begin
        flit_data_mask = ~({RANDOM_BIT_NUM{1'b1}} << tgt_id_lfsr_data[$clog2(FLIT_DATA_LENGTH-RANDOM_BIT_NUM)-1:0]);
        new_test[i].flit_data  = '1;
        new_test[i].flit_data  = ((src_id_lfsr_data[RANDOM_BIT_NUM-1:0] ^ i) << tgt_id_lfsr_data[$clog2(FLIT_DATA_LENGTH-RANDOM_BIT_NUM)-1:0]) | flit_data_mask;
      end

      assign new_test[i].flit_head.txn_id             = txn_counter + i;

      assign new_test[i].timeout_threshold            = SCOREBOARD_TIMEOUT_EN ? SCOREBOARD_TIMEOUT_THRESHOLD : '0; // 0 means no timeout error

      assign new_test[i].mcycle_when_generated        = mcycle_i;

      logic [TEST_CASE_NUM_PER_CYCLE-1:0][2-1:0] random_device_port;
      assign random_device_port[i] = src_id_lfsr_data[i*2+:2] ^ tgt_id_lfsr_data[i*2+:2];
      always_comb begin
        new_test[i].flit_head.src_id.device_port = '0;
        new_test[i].flit_head.src_id.device_id   = '0;
        new_test[i].flit_head.tgt_id.device_port = '0;
        new_test[i].flit_head.tgt_id.device_id   = '0;

        unique case(random_device_port[i]) // chooose which local port to route from/to(single router mode doesn't have local to local case)
          2'd0: begin
            new_test[i].flit_head.src_id.device_port = 0;
            new_test[i].flit_head.tgt_id.device_port = 0;
          end
`ifdef LOCAL_PORT_NUM_2
          2'd1: begin
            new_test[i].flit_head.src_id.device_port = 1;
            new_test[i].flit_head.tgt_id.device_port = 1;
          end
`endif
`ifdef LOCAL_PORT_NUM_3
          2'd2: begin
            if(LOCAL_PORT_SENDER_NUM >= 3) begin
              new_test[i].flit_head.src_id.device_port = 2;
              new_test[i].flit_head.tgt_id.device_port = 2;
            end else begin
              new_test[i].flit_head.src_id.device_port = 1;
              new_test[i].flit_head.tgt_id.device_port = 1;
            end
          end
`endif
`ifdef LOCAL_PORT_NUM_4
          2'd3: begin
            new_test[i].flit_head.src_id.device_port = 3;
            new_test[i].flit_head.tgt_id.device_port = 3;
          end
`endif
          default: begin
            new_test[i].flit_head.src_id.device_port = 0;
            new_test[i].flit_head.tgt_id.device_port = 0;
          end
        endcase
      end

    end
  end




  else if(TEST_CASE_MESH_RANDOM) begin: gen_test_case_mesh_random
    for(i = 0; i < TEST_CASE_NUM_PER_CYCLE; i++) begin: gen_new_test
      always_comb begin
        new_test[i].flit_head.src_id.x_position = src_id_lfsr_data[i*3+:3] % NODE_NUM_X_DIMESION;
        new_test[i].flit_head.src_id.y_position = src_id_lfsr_data[RANDOM_BIT_NUM-1-i*3-:3] % NODE_NUM_Y_DIMESION;

        new_test[i].flit_head.tgt_id.x_position = tgt_id_lfsr_data[i*3+:3] % NODE_NUM_X_DIMESION;
        new_test[i].flit_head.tgt_id.y_position = tgt_id_lfsr_data[RANDOM_BIT_NUM-1-i*3-:3] % NODE_NUM_Y_DIMESION;
      end


      logic [FLIT_DATA_LENGTH-1:0] flit_data_mask;
      always_comb begin
        flit_data_mask = ~({RANDOM_BIT_NUM{1'b1}} << tgt_id_lfsr_data[$clog2(FLIT_DATA_LENGTH-RANDOM_BIT_NUM)-1:0]);
        new_test[i].flit_data  = '1;
        new_test[i].flit_data  = ((src_id_lfsr_data[RANDOM_BIT_NUM-1:0] ^ i) << tgt_id_lfsr_data[$clog2(FLIT_DATA_LENGTH-RANDOM_BIT_NUM)-1:0]) | flit_data_mask;
      end

      assign new_test[i].flit_head.txn_id             = txn_counter + i;

`ifdef COMMON_QOS_EXTRA_RT_VC
      assign new_test[i].timeout_threshold            = (new_test[i].qos_value == '1) ? 2 * (NODE_NUM_X_DIMESION + NODE_NUM_Y_DIMESION - 1) :
                                                         SCOREBOARD_TIMEOUT_EN ? SCOREBOARD_TIMEOUT_THRESHOLD : '0;
`else
      assign new_test[i].timeout_threshold            = SCOREBOARD_TIMEOUT_EN ? SCOREBOARD_TIMEOUT_THRESHOLD : '0;
`endif

      assign new_test[i].mcycle_when_generated        = mcycle_i;

      assign new_test[i].flit_head.src_id.device_id   = '0;
      assign new_test[i].flit_head.tgt_id.device_id   = '0;

      assign new_test[i].flit_head.src_id.device_port = (src_id_lfsr_data[i*2+:2] ^ tgt_id_lfsr_data[RANDOM_BIT_NUM-1-i*2-:2]) % LOCAL_PORT_NUM;
      assign new_test[i].flit_head.tgt_id.device_port = (src_id_lfsr_data[RANDOM_BIT_NUM-1-i*2-:2] ^ tgt_id_lfsr_data[i*2+:2]) % LOCAL_PORT_NUM;
    end
  end

  else if(TEST_CASE_MESH_DIAGONAL) begin: gen_test_case_mesh_diagonal
    for(i = 0; i < TEST_CASE_NUM_PER_CYCLE; i++) begin: gen_new_test
      always_comb begin
        new_test[i].flit_head.src_id.x_position = 0;
        new_test[i].flit_head.src_id.y_position = 0;

        new_test[i].flit_head.tgt_id.x_position = NODE_NUM_X_DIMESION - 1;
        new_test[i].flit_head.tgt_id.y_position = NODE_NUM_Y_DIMESION - 1;
      end


      logic [FLIT_DATA_LENGTH-1:0] flit_data_mask;
      always_comb begin
        flit_data_mask = ~({RANDOM_BIT_NUM{1'b1}} << tgt_id_lfsr_data[$clog2(FLIT_DATA_LENGTH-RANDOM_BIT_NUM)-1:0]);
        new_test[i].flit_data  = '1;
        new_test[i].flit_data  = ((src_id_lfsr_data[RANDOM_BIT_NUM-1:0] ^ i) << tgt_id_lfsr_data[$clog2(FLIT_DATA_LENGTH-RANDOM_BIT_NUM)-1:0]) | flit_data_mask;
      end

      assign new_test[i].flit_head.txn_id             = txn_counter + i;

      assign new_test[i].timeout_threshold            = SCOREBOARD_TIMEOUT_EN ? SCOREBOARD_TIMEOUT_THRESHOLD : '0;

      assign new_test[i].mcycle_when_generated        = mcycle_i;

      assign new_test[i].flit_head.src_id.device_id   = '0;
      assign new_test[i].flit_head.tgt_id.device_id   = '0;

      assign new_test[i].flit_head.src_id.device_port = 0;
      assign new_test[i].flit_head.tgt_id.device_port = 0;
    end
  end
endgenerate


generate
  if(TEST_CASE_SINGLE_ROUTER) begin: gen_test_case_look_ahead_routing_single_router // the dut router is assume to be (1,1)
    for(i = 0; i < TEST_CASE_NUM_PER_CYCLE; i++) begin: gen_new_test_look_ahead_routing
      always_comb begin
        if(new_test[i].flit_head.tgt_id.x_position > 1) begin
          new_test[i].flit_head.look_ahead_routing = E;
        end else if(new_test[i].flit_head.tgt_id.x_position < 1) begin
          new_test[i].flit_head.look_ahead_routing = W;
        end else if(new_test[i].flit_head.tgt_id.y_position > 1) begin
          new_test[i].flit_head.look_ahead_routing = N;
        end else if(new_test[i].flit_head.tgt_id.y_position < 1) begin
          new_test[i].flit_head.look_ahead_routing = S;
        end else begin
          unique case(new_test[i].flit_head.tgt_id.device_port) // chooose which local port to route to
            0: begin
              new_test[i].flit_head.look_ahead_routing = L0;
            end
`ifdef LOCAL_PORT_NUM_2
            1: begin
              new_test[i].flit_head.look_ahead_routing = L1;
            end
`endif
`ifdef LOCAL_PORT_NUM_3
            2: begin
              new_test[i].flit_head.look_ahead_routing = L2;
            end
`endif
`ifdef LOCAL_PORT_NUM_4
            3: begin
              new_test[i].flit_head.look_ahead_routing = L3;
            end
`endif
            default: begin
              new_test[i].flit_head.look_ahead_routing = L0;
            end
          endcase
        end
      end
    end
  end




  else if(TEST_CASE_MESH_RANDOM || TEST_CASE_MESH_DIAGONAL) begin: gen_test_case_look_ahead_routing_mesh_x
    for(i = 0; i < TEST_CASE_NUM_PER_CYCLE; i++) begin: gen_new_test_look_ahead_routing
      always_comb begin
        if(new_test[i].flit_head.tgt_id.x_position > new_test[i].flit_head.src_id.x_position) begin
          new_test[i].flit_head.look_ahead_routing = E;
        end else if(new_test[i].flit_head.tgt_id.x_position < new_test[i].flit_head.src_id.x_position) begin
          new_test[i].flit_head.look_ahead_routing = W;
        end else if(new_test[i].flit_head.tgt_id.y_position > new_test[i].flit_head.src_id.y_position) begin
          new_test[i].flit_head.look_ahead_routing = N;
        end else if(new_test[i].flit_head.tgt_id.y_position < new_test[i].flit_head.src_id.y_position) begin
          new_test[i].flit_head.look_ahead_routing = S;
        end else begin
          unique case(new_test[i].flit_head.tgt_id.device_port) // chooose which local port to route to
            0: begin
              new_test[i].flit_head.look_ahead_routing = L0;
            end
`ifdef LOCAL_PORT_NUM_2
            1: begin
              new_test[i].flit_head.look_ahead_routing = L1;
            end
`endif
`ifdef LOCAL_PORT_NUM_3
            2: begin
              new_test[i].flit_head.look_ahead_routing = L2;
            end
`endif
`ifdef LOCAL_PORT_NUM_4
            3: begin
              new_test[i].flit_head.look_ahead_routing = L3;
            end
`endif
            default: begin
              new_test[i].flit_head.look_ahead_routing = L0;
            end
          endcase
        end
      end
    end
  end
endgenerate

logic [TEST_CASE_NUM_PER_CYCLE-1:0][3-1:0] random_qos;
generate
  for(i = 0; i < TEST_CASE_NUM_PER_CYCLE; i++) begin: gen_new_test_qos_value
    assign random_qos[i] = src_id_lfsr_data[i*3+:3] ^~ tgt_id_lfsr_data[i*3+:3];
`ifdef USE_QOS_VALUE
    always_comb begin
      unique case(random_qos[i])
        0, 1: begin
          new_test[i].qos_value = 4;
          new_test[i].flit_head.qos_value = 4;
        end
        2, 3: begin
          new_test[i].qos_value = 8;
          new_test[i].flit_head.qos_value = 8;
        end
        4: begin
          new_test[i].qos_value = 15;
          new_test[i].flit_head.qos_value = 15;
        end
        default: begin
          new_test[i].qos_value = '0;
          new_test[i].flit_head.qos_value = '0;
        end
      endcase

      // if((new_test[i].flit_head.src_id.x_position == 0) &&
      //    (new_test[i].flit_head.src_id.y_position == 0) &&
      //    (new_test[i].flit_head.src_id.device_port == 0)) begin
      //     new_test[i].qos_value = '1;
      //     new_test[i].flit_head.qos_value = '1;
      // end
    end
`else
    assign new_test[i].qos_value = '0;
`endif
  end
endgenerate



generate
  for(i = 0; i < TEST_CASE_NUM_PER_CYCLE; i++) begin: gen_new_test_vld
`ifdef ALLOW_SAME_ROUTER_L2L_TRANSFER
    assign new_test_vld[i] = ~((new_test[i].flit_head.src_id.x_position == new_test[i].flit_head.tgt_id.x_position) &&
                               (new_test[i].flit_head.src_id.y_position == new_test[i].flit_head.tgt_id.y_position) &&
                               (new_test[i].flit_head.src_id.device_port == new_test[i].flit_head.tgt_id.device_port)
                              );
`else
    assign new_test_vld[i] = (new_test[i].flit_head.src_id.x_position != new_test[i].flit_head.tgt_id.x_position) |
                             (new_test[i].flit_head.src_id.y_position != new_test[i].flit_head.tgt_id.y_position);
`endif
  end
endgenerate



LFSR #(.NUM_BITS(RANDOM_BIT_NUM)) src_id_gen_u (
    .i_Clk                      (clk),
    .i_Enable                   (rstn),
    .i_Seed_DV                  (lfsr_update_en_i  ),
    .i_Seed_Data                (src_id_lfsr_seed_i),
    .o_LFSR_Data                (src_id_lfsr_data),
    .o_LFSR_Done                ()
);

LFSR #(.NUM_BITS(RANDOM_BIT_NUM)) tgt_id_gen_u (
    .i_Clk                      (clk),
    .i_Enable                   (rstn),
    .i_Seed_DV                  (lfsr_update_en_i  ),
    .i_Seed_Data                (tgt_id_lfsr_seed_i),
    .o_LFSR_Data                (tgt_id_lfsr_data),
    .o_LFSR_Done                ()
);

always_ff @(posedge clk or negedge rstn ) begin
  if(~rstn) begin
    txn_counter <= '0;
  end else if(|new_test_vld) begin
    txn_counter <= txn_counter + TEST_CASE_NUM_PER_CYCLE;
  end
end






// display app throughput

logic [SENDER_NUM-1:0][64-1:0] flit_num_counter_d, flit_num_counter_q; // sent
logic [SENDER_NUM-1:0]         flit_num_counter_ena;
logic                 [64-1:0] flit_num_counter_all_d, flit_num_counter_all_q;
logic                          flit_num_counter_all_ena;

logic [SENDER_NUM-1:0][64-1:0] flit_num_gened_counter_d, flit_num_gened_counter_q; // generated, no matter whether it is sent
logic [SENDER_NUM-1:0]         flit_num_gened_counter_ena;
logic                 [64-1:0] flit_num_gened_counter_all_d, flit_num_gened_counter_all_q;
logic                          flit_num_gened_counter_all_ena;


generate
  for(i = 0; i < SENDER_NUM; i++) begin: gen_flit_num_counter_q
    std_dffre
    #(.WIDTH(64))
    U_DAT_FLIT_NUM_COUNTER
    (
      .clk(clk),
      .rstn(rstn),
      .en(flit_num_counter_ena[i]),
      .d (flit_num_counter_d  [i]),
      .q (flit_num_counter_q  [i])
    );
  end
endgenerate

std_dffre
#(.WIDTH(64))
U_DAT_FLIT_NUM_ALL_COUNTER
(
  .clk(clk),
  .rstn(rstn),
  .en(flit_num_counter_all_ena),
  .d (flit_num_counter_all_d  ),
  .q (flit_num_counter_all_q  )
);

generate
  for(i = 0; i < SENDER_NUM; i++) begin: gen_flit_gened_num_counter_q
    std_dffre
    #(.WIDTH(64))
    U_DAT_FLIT_GENED_NUM_COUNTER
    (
      .clk(clk),
      .rstn(rstn),
      .en(flit_num_gened_counter_ena[i]),
      .d (flit_num_gened_counter_d  [i]),
      .q (flit_num_gened_counter_q  [i])
    );
  end
endgenerate

std_dffre
#(.WIDTH(64))
U_DAT_FLIT_GENED_NUM_ALL_COUNTER
(
  .clk(clk),
  .rstn(rstn),
  .en(flit_num_gened_counter_all_ena),
  .d (flit_num_gened_counter_all_d  ),
  .q (flit_num_gened_counter_all_q  )
);

real flit_num_counter[SENDER_NUM-1:0];
real flit_num_counter_all;
real flit_num_gened_counter[SENDER_NUM-1:0];
real flit_num_gened_counter_all;
real mcycle;

always_ff @(posedge clk) begin
  flit_num_counter_all_d    = flit_num_counter_all_q;
  flit_num_counter_all_ena  = 1'b0;

  flit_num_gened_counter_all_d    = flit_num_gened_counter_all_q;
  flit_num_gened_counter_all_ena  = 1'b0;

  mcycle = mcycle_i;
  flit_num_counter_all        = flit_num_counter_all_q;
  flit_num_gened_counter_all  = flit_num_gened_counter_all_q;

  for(int i = 0; i < SENDER_NUM; i++) begin
    flit_num_counter_d  [i] = flit_num_counter_q[i];
    flit_num_counter_ena[i] = 1'b0;

    flit_num_gened_counter_d  [i] = flit_num_gened_counter_q[i];
    flit_num_gened_counter_ena[i] = 1'b0;

    flit_num_counter[i]       = flit_num_counter_q[i];
    flit_num_gened_counter[i] = flit_num_gened_counter_q[i];

    if(new_test_vld_o[i]) begin
      flit_num_gened_counter_d  [i] = flit_num_gened_counter_q[i] + 1;
      flit_num_gened_counter_ena[i] = 1'b1;

      flit_num_gened_counter_all_d   = flit_num_gened_counter_all_d + 1;
      flit_num_gened_counter_all_ena = 1'b1;

      if(new_test_rdy_i[i]) begin
        $display("[%16d] info: test_generator gen case to   sender: %2d, [average_app_gen_bandwidth: %fGBps], [average_app_bandwidth: %fGBps]", 
                    $time(), i,
                    ((flit_num_gened_counter[i] * FLIT_LENGTH /8/1024/1024/1024) / (mcycle / ASSUMED_SYSTEM_FREQUENCY)),
                    ((flit_num_counter[i] * FLIT_LENGTH /8/1024/1024/1024) / (mcycle / ASSUMED_SYSTEM_FREQUENCY)));

        flit_num_counter_d  [i] = flit_num_counter_q[i] + 1;
        flit_num_counter_ena[i] = 1'b1;

        flit_num_counter_all_d   = flit_num_counter_all_d + 1;
        flit_num_counter_all_ena = 1'b1;
      end
    end
  end
  if(|(new_test_vld_o & new_test_rdy_i)) begin
    $display("[%16d] info: test_generator gen case to   sender:all, [average_app_gen_bandwidth: %fGBps], [average_app_bandwidth: %fGBps]", 
                    $time(),
                    ((flit_num_gened_counter_all * FLIT_LENGTH /8/1024/1024/1024) / (mcycle / ASSUMED_SYSTEM_FREQUENCY)),
                    ((flit_num_counter_all * FLIT_LENGTH /8/1024/1024/1024) / (mcycle / ASSUMED_SYSTEM_FREQUENCY)));
  end
end


endmodule
