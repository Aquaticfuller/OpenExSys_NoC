module v_scoreboard
import rvh_noc_pkg::*;
import v_noc_pkg::*;
#(
  parameter SCOREBOARD_ENTRY_NUM_PER_SENDER = 8, // size of scoreboard per sender, should be able to hold all inflight transaction, or the verification coverage would be degraged
  parameter SCOREBOARD_ENTRY_NUM_PER_SENDER_IDX_W = SCOREBOARD_ENTRY_NUM_PER_SENDER > 1 ? $clog2(SCOREBOARD_ENTRY_NUM_PER_SENDER) : 1,
  parameter SENDER_NUM = 1,
  parameter RECEIVER_NUM = 1,

  parameter NODE_NUM_X_DIMESION     = 2, // only used in non TEST_CASE_SINGLE_ROUTER mode
  parameter NODE_NUM_Y_DIMESION     = 3, // only used in non TEST_CASE_SINGLE_ROUTER mode
  parameter LOCAL_PORT_NUM          = 1,  // only used in non TEST_CASE_SINGLE_ROUTER mode

  parameter TEST_CASE_SINGLE_ROUTER = 0,

  parameter ASSUMED_SYSTEM_FREQUENCY = (1<<30) // 1GHz
)
(
  // intf with sender
  input  logic              [SENDER_NUM-1:0]  new_scoreboard_entry_vld_i,
  input  scoreboard_entry_t [SENDER_NUM-1:0]  new_scoreboard_entry_i,
  output logic              [SENDER_NUM-1:0]  new_scoreboard_entry_rdy_o,

  // intf with receiver
  input  logic            [RECEIVER_NUM-1:0]  check_scoreboard_vld_i,
  input  receiver_info_t  [RECEIVER_NUM-1:0]  check_scoreboard_i,
  output logic            [RECEIVER_NUM-1:0]  check_scoreboard_rdy_o,

  // current system cycle
  input  logic            [64-1:0]            mcycle_i,

  input  logic clk,
  input  logic rstn
);

genvar i, j;

logic              [SENDER_NUM-1:0][SCOREBOARD_ENTRY_NUM_PER_SENDER-1:0] scoreboard_entry_vld_d, scoreboard_entry_vld_q;
logic              [SENDER_NUM-1:0][SCOREBOARD_ENTRY_NUM_PER_SENDER-1:0] scoreboard_entry_vld_ena;
logic              [SENDER_NUM-1:0][SCOREBOARD_ENTRY_NUM_PER_SENDER-1:0] scoreboard_entry_vld_set, scoreboard_entry_vld_clr;

scoreboard_entry_t [SENDER_NUM-1:0][SCOREBOARD_ENTRY_NUM_PER_SENDER-1:0] scoreboard_entry_d, scoreboard_entry_q;
logic              [SENDER_NUM-1:0][SCOREBOARD_ENTRY_NUM_PER_SENDER-1:0] scoreboard_entry_ena;

scoreboard_timer_t [SENDER_NUM-1:0][SCOREBOARD_ENTRY_NUM_PER_SENDER-1:0] scoreboard_timer_d, scoreboard_timer_q;
logic              [SENDER_NUM-1:0][SCOREBOARD_ENTRY_NUM_PER_SENDER-1:0] scoreboard_timer_ena;

// if at least one scoreboard entry is non valid, the new entry can find a slot to place
generate
  for(i = 0; i < SENDER_NUM; i++) begin: gen_new_scoreboard_entry_rdy_o
    assign new_scoreboard_entry_rdy_o[i] = ~(&(scoreboard_entry_vld_q[i]));
  end
endgenerate

// scoreboard allocate new entry
logic [SENDER_NUM-1:0][SCOREBOARD_ENTRY_NUM_PER_SENDER_IDX_W-1:0] sel_sb_ent_idx;
generate
  for(i = 0; i < SENDER_NUM; i++) begin: gen_set_scoreboard_entry
    always_comb begin
      sel_sb_ent_idx[i] = 0;
      scoreboard_entry_vld_set[i] = '0;
      scoreboard_entry_d      [i] = '0;
      if(new_scoreboard_entry_vld_i[i]) begin// new
        for(int j = SCOREBOARD_ENTRY_NUM_PER_SENDER-1; j >= 0; j--) begin
          if(~scoreboard_entry_vld_q[i][j] & ~scoreboard_entry_vld_set[i][j]) begin
            sel_sb_ent_idx[i] = j;
          end
        end

        scoreboard_entry_d[i][sel_sb_ent_idx[i]] = new_scoreboard_entry_i[i];

        if(~scoreboard_entry_vld_q[i][sel_sb_ent_idx[i]]) begin
          scoreboard_entry_vld_set[i][sel_sb_ent_idx[i]] = 1'b1;
        end
      end
    end
  end
endgenerate

// scoreboard deallocate old entry
always_comb begin
  scoreboard_entry_vld_clr = '0;
  for(int i = 0; i < RECEIVER_NUM; i++) begin: gen_clr_scoreboard_entry
    if(check_scoreboard_vld_i[i]) begin// new
      for(int j = 0; j < SENDER_NUM; j++) begin
        for(int k = 0; k < SCOREBOARD_ENTRY_NUM_PER_SENDER; k++) begin
          if(scoreboard_entry_vld_q[j][k]) begin
            if(
              (scoreboard_entry_q[j][k].txn_id == check_scoreboard_i[i].txn_id) &
              (scoreboard_entry_q[j][k].src_id == check_scoreboard_i[i].src_id) &
              (scoreboard_entry_q[j][k].tgt_id == check_scoreboard_i[i].rec_id) &
              (scoreboard_entry_q[j][k].flit_data == check_scoreboard_i[i].flit_data)
            ) begin
              scoreboard_entry_vld_clr[j][k] = 1'b1;
            end
          end
        end
      end
    end
  end
end

// scoreboard timer
generate
  for(i = 0; i < SENDER_NUM; i++) begin: gen_scoreboard_timer_d_i
    for(j = 0; j < SCOREBOARD_ENTRY_NUM_PER_SENDER; j++) begin:gen_scoreboard_timer_d_j
      assign scoreboard_timer_d  [i][j] = scoreboard_entry_vld_set[i][j] ? 0 : scoreboard_timer_q[i][j] + 1;
      assign scoreboard_timer_ena[i][j] = scoreboard_entry_vld_set[i][j] | (scoreboard_entry_vld_q[i][j] & ~scoreboard_entry_vld_clr[i][j]);
    end
  end
endgenerate

// scoreboard entry change
generate
  for(i = 0; i < SENDER_NUM; i++) begin: gen_scoreboard_entry_vld_d_i
    for(j = 0; j < SCOREBOARD_ENTRY_NUM_PER_SENDER; j++) begin:gen_scoreboard_entry_vld_d_j
      assign scoreboard_entry_vld_ena[i][j] = scoreboard_entry_vld_set[i][j] | scoreboard_entry_vld_clr[i][j];
      assign scoreboard_entry_vld_d  [i][j] = scoreboard_entry_vld_set[i][j] & ~scoreboard_entry_vld_clr[i][j];
      assign scoreboard_entry_ena    [i][j] = scoreboard_entry_vld_set[i][j];
    end
  end

endgenerate

`ifndef SYNTHESIS
  assert property(@(posedge clk)disable iff(~rstn) ((scoreboard_entry_vld_set & scoreboard_entry_vld_clr) == '0))
    else $fatal("v_scoreboard: set and clr scoreboard_entry_vld at the same cycle");
`endif

// registers
generate
  for(i = 0; i < SENDER_NUM; i++) begin: gen_scoreboard_entry_i
    for(j = 0; j < SCOREBOARD_ENTRY_NUM_PER_SENDER; j++) begin:gen_scoreboard_entry_j
      std_dffre
      #(.WIDTH(1))
      U_STA_SCOREBOARD_ENTRY_VLD_REG
      (
        .clk(clk),
        .rstn(rstn),
        .en(scoreboard_entry_vld_ena[i][j]),
        .d (scoreboard_entry_vld_d  [i][j]),
        .q (scoreboard_entry_vld_q  [i][j])
      );

      std_dffe
      #(.WIDTH($bits(scoreboard_entry_t)))
      U_DAT_SCOREBOARD_ENTRY_REG
      (
        .clk(clk),
        .en(scoreboard_entry_ena[i][j]),
        .d (scoreboard_entry_d  [i][j]),
        .q (scoreboard_entry_q  [i][j])
      );

      std_dffe
      #(.WIDTH($bits(scoreboard_timer_t)))
      U_DAT_SCOREBOARD_TIMER_REG
      (
        .clk(clk),
        .en(scoreboard_timer_ena[i][j]),
        .d (scoreboard_timer_d  [i][j]),
        .q (scoreboard_timer_q  [i][j])
      );
    end
  end
endgenerate

// check for receiver 1.target error; 2.data error
logic [RECEIVER_NUM-1:0] find_entry;
always_ff @(posedge clk) begin
  find_entry = '0;
  for(int i = 0; i < RECEIVER_NUM; i++) begin
    if(check_scoreboard_vld_i[i]) begin
      for(int j = 0; j < SENDER_NUM; j++) begin
        for(int k = 0; k < SCOREBOARD_ENTRY_NUM_PER_SENDER; k++) begin
          if(scoreboard_entry_vld_q[j][k]) begin
            if((scoreboard_entry_q[j][k].src_id == check_scoreboard_i[i].src_id) &&
               (scoreboard_entry_q[j][k].txn_id == check_scoreboard_i[i].txn_id) &&
               (TEST_CASE_SINGLE_ROUTER || 
                (scoreboard_entry_q[j][k].tgt_id == check_scoreboard_i[i].rec_id) &&
                (scoreboard_entry_q[j][k].flit_data == check_scoreboard_i[i].flit_data)
              )
            ) begin // found the entry
              find_entry[i] = 1'b1;
              // check target position
              if((scoreboard_entry_q[j][k].tgt_id.x_position != check_scoreboard_i[i].rec_id.x_position) |
                 (scoreboard_entry_q[j][k].tgt_id.y_position != check_scoreboard_i[i].rec_id.y_position)
              ) begin
                $display("[%16d] error: receiver position mismatch", $time());
                $display("txn_id: 0x%h, sender: %2d (%d,%d), receiver: %d (%d,%d)", 
                        check_scoreboard_i[i].txn_id, 
                        j, check_scoreboard_i[i].src_id.x_position, check_scoreboard_i[i].src_id.y_position, 
                        i, check_scoreboard_i[i].rec_id.x_position, check_scoreboard_i[i].rec_id.y_position);
                $display("tgt_id: (%d,%d), tgt_local_port: %d, look_ahead_routing: %d, send_time: %d", 
                        scoreboard_entry_q[j][k].tgt_id.x_position, scoreboard_entry_q[j][k].tgt_id.y_position, scoreboard_entry_q[j][k].tgt_id.device_port,
                        scoreboard_entry_q[j][k].look_ahead_routing, scoreboard_entry_q[j][k].sent_mcycle);
                $finish();
              end

              // check port id if tgt is (one of) the local port(s) of the dut router
              if(((check_scoreboard_i[i].rec_id.x_position == 1) &&
                  (check_scoreboard_i[i].rec_id.y_position == 1)) || // assume the dut is (1,1) for single router mode
                 !TEST_CASE_SINGLE_ROUTER                           // always check if is mesh mode
                 ) begin 
                  if(scoreboard_entry_q[j][k].tgt_id.device_port != check_scoreboard_i[i].rec_id.device_port) begin
                    $display("[%16d] error: receiver local_port_id mismatch", $time());
                    $display("txn_id: 0x%h, sender: %2d (%d,%d), sender_local_port: %d; receiver: %d (%d,%d), receiver_local_port: %d", 
                            check_scoreboard_i[i].txn_id,
                            j, check_scoreboard_i[i].src_id.x_position, check_scoreboard_i[i].src_id.y_position, 
                            check_scoreboard_i[i].src_id.device_port,
                            i, check_scoreboard_i[i].rec_id.x_position, check_scoreboard_i[i].rec_id.y_position,
                            check_scoreboard_i[i].rec_id.device_port);
                    $display("tgt_id: (%d,%d), tgt_local_port: %d, look_ahead_routing: %d, send_time: %d", 
                            scoreboard_entry_q[j][k].tgt_id.x_position, scoreboard_entry_q[j][k].tgt_id.y_position, scoreboard_entry_q[j][k].tgt_id.device_port,
                            scoreboard_entry_q[j][k].look_ahead_routing, scoreboard_entry_q[j][k].sent_mcycle);
                    $finish();
                  end
              end

              // check data
              if(scoreboard_entry_q[j][k].flit_data != check_scoreboard_i[i].flit_data) begin
                $display("[%16d] error: data mismatch", $time());
                $display("txn_id: 0x%h, sender: %2d (%d,%d), receiver: %d (%d,%d), received_data: %h", 
                        check_scoreboard_i[i].txn_id, 
                        j, check_scoreboard_i[i].src_id.x_position, check_scoreboard_i[i].src_id.y_position, 
                        i, check_scoreboard_i[i].rec_id.x_position, check_scoreboard_i[i].rec_id.y_position,
                        check_scoreboard_i[i].flit_data);
                $display("tgt_id: (%d,%d), tgt_local_port: %d, look_ahead_routing: %d, send_time: %d, sent_data: %h", 
                        scoreboard_entry_q[j][k].tgt_id.x_position, scoreboard_entry_q[j][k].tgt_id.y_position, scoreboard_entry_q[j][k].tgt_id.device_port,
                        scoreboard_entry_q[j][k].look_ahead_routing, scoreboard_entry_q[j][k].sent_mcycle,
                        scoreboard_entry_q[j][k].flit_data);
                $finish();
              end
            end
          end
        end
      end
      if(find_entry[i] == 1'b0) begin
        $display("[%16d] error: scoreboard failed to find the entry, txn_id: 0x%h, sender: (%d,%d), receiver: (%d,%d)", 
                        $time(), check_scoreboard_i[i].txn_id, 
                        check_scoreboard_i[i].src_id.x_position, check_scoreboard_i[i].src_id.y_position, 
                        check_scoreboard_i[i].rec_id.x_position, check_scoreboard_i[i].rec_id.y_position);
        $finish();
      end
    end
  end
end

// check for scoreboard timeout
always_ff @(posedge clk) begin
  for(int i = 0; i < SENDER_NUM; i++) begin
    for(int j = 0; j < SCOREBOARD_ENTRY_NUM_PER_SENDER; j++) begin
      if(scoreboard_entry_vld_q[i][j]) begin
        if((scoreboard_timer_q[i][j].timeout_counter >= scoreboard_entry_q[i][j].timeout_threshold) 
            && (scoreboard_entry_q[i][j].timeout_threshold != '0)) begin
          $display("[%16d] error: scoreboard entry timeout, timeout_threshold: %d", 
                          $time(), scoreboard_entry_q[i][j].timeout_threshold);
          $display("txn_id: 0x%h, sender: %2d (%d,%d), sender_local_port: %d, qos_value = %d", 
                  scoreboard_entry_q[i][j].txn_id,
                  i, scoreboard_entry_q[i][j].src_id.x_position, scoreboard_entry_q[i][j].src_id.y_position, 
                  scoreboard_entry_q[i][j].src_id.device_port,
                  scoreboard_entry_q[i][j].qos_value);
          $display("tgt_id: (%d,%d), tgt_local_port: %d, look_ahead_routing: %d, send_time: %d", 
                  scoreboard_entry_q[i][j].tgt_id.x_position, scoreboard_entry_q[i][j].tgt_id.y_position, scoreboard_entry_q[i][j].tgt_id.device_port,
                  scoreboard_entry_q[i][j].look_ahead_routing, scoreboard_entry_q[i][j].sent_mcycle);
          if(!((scoreboard_entry_q[i][j].qos_value == '1) && QOS_VC_NUM_PER_INPUT)) begin // if rt flit, don't finish, as its timeout_threshold is too tight
            $finish();
          end
        end
      end
    end
  end
end

// average cycle per flit
logic [64-1:0] flit_num_counter_d, flit_num_counter_q;
logic flit_num_counter_ena;
logic [64-1:0] flit_noc_latency_counter_d, flit_noc_latency_counter_q;
logic flit_noc_latency_counter_ena;
logic [64-1:0] flit_app_latency_counter_d, flit_app_latency_counter_q;
logic flit_app_latency_counter_ena;

// port usage counter
logic [64-1:0] allocate_port_counter_d, allocate_port_counter_q;
logic allocate_port_counter_ena;
logic [64-1:0] deallocate_port_counter_all_d, deallocate_port_counter_all_q;
logic deallocate_port_counter_all_ena;
logic [RECEIVER_NUM-1:0][64-1:0] deallocate_port_counter_d, deallocate_port_counter_q;
logic [RECEIVER_NUM-1:0]         deallocate_port_counter_ena;

std_dffre
#(.WIDTH(64))
U_DAT_FLIT_NUM_COUNTER
(
  .clk(clk),
  .rstn(rstn),
  .en(flit_num_counter_ena),
  .d(flit_num_counter_d),
  .q(flit_num_counter_q)
);

std_dffre
#(.WIDTH(64))
U_DAT_FLIT_NOC_LATENCY_COUNTER
(
  .clk(clk),
  .rstn(rstn),
  .en(flit_noc_latency_counter_ena),
  .d(flit_noc_latency_counter_d),
  .q(flit_noc_latency_counter_q)
);

std_dffre
#(.WIDTH(64))
U_DAT_FLIT_APP_LATENCY_COUNTER
(
  .clk(clk),
  .rstn(rstn),
  .en(flit_app_latency_counter_ena),
  .d(flit_app_latency_counter_d),
  .q(flit_app_latency_counter_q)
);

std_dffre
#(.WIDTH(64))
U_DAT_ALLOCATE_PORT_COUNTER
(
  .clk(clk),
  .rstn(rstn),
  .en(allocate_port_counter_ena),
  .d(allocate_port_counter_d),
  .q(allocate_port_counter_q)
);

std_dffre
#(.WIDTH(64))
U_DAT_DEALLOCATE_PORT_COUNTER_ALL
(
  .clk(clk),
  .rstn(rstn),
  .en(deallocate_port_counter_all_ena),
  .d(deallocate_port_counter_all_d),
  .q(deallocate_port_counter_all_q)
);

generate
  for(i = 0; i < RECEIVER_NUM; i++) begin
    std_dffre
    #(.WIDTH(64))
    U_DAT_DEALLOCATE_PORT_COUNTER
    (
      .clk(clk),
      .rstn(rstn),
      .en(deallocate_port_counter_ena[i]),
      .d (deallocate_port_counter_d  [i]),
      .q (deallocate_port_counter_q  [i])
    );
  end
endgenerate


// display allocate and deallocate scoreboard entry
real flit_noc_latency_counter;
real flit_app_latency_counter;
real flit_num_counter;

real allocate_port_counter;
real deallocate_port_counter_all;
real deallocate_port_counter[RECEIVER_NUM-1:0];

real mcycle;

always_ff @(posedge clk) begin
  flit_num_counter_d     = flit_num_counter_q;
  flit_num_counter_ena   = 1'b0;
  flit_noc_latency_counter_d   = flit_noc_latency_counter_q;
  flit_noc_latency_counter_ena = 1'b0;
  flit_app_latency_counter_d   = flit_app_latency_counter_q;
  flit_app_latency_counter_ena = 1'b0;
  mcycle                 = mcycle_i;

  allocate_port_counter_d     = allocate_port_counter_q;
  allocate_port_counter_ena   = 1'b0;
  deallocate_port_counter_all_d   = deallocate_port_counter_all_q;
  deallocate_port_counter_all_ena = 1'b0;

  flit_noc_latency_counter = flit_noc_latency_counter_q;
  flit_app_latency_counter = flit_app_latency_counter_q;
  flit_num_counter   = flit_num_counter_q;
  
  deallocate_port_counter_d   = deallocate_port_counter_q;
  deallocate_port_counter_ena = '0;

  allocate_port_counter       = allocate_port_counter_q;
  deallocate_port_counter_all = deallocate_port_counter_all_q;

  for(int i = 0; i < RECEIVER_NUM; i++) begin
    deallocate_port_counter[i] = deallocate_port_counter_q[i];
  end

  for(int i = 0; i < SENDER_NUM; i++) begin
    for(int j = 0; j < SCOREBOARD_ENTRY_NUM_PER_SENDER; j++) begin
      if(scoreboard_entry_vld_set[i][j]) begin
        $display("[%16d] info: scoreboard allocate   entry, sender: %2d (%d,%d), txn_id: 0x%h, QoS = %d, inport_vc_id:%d, tgt_id: (%d,%d), tgt_local_port: %d, look_ahead_routing: %d, send_data: %h", 
                    $time(), i, 
                    scoreboard_entry_d[i][j].src_id.x_position, scoreboard_entry_d[i][j].src_id.y_position, 
                    scoreboard_entry_d[i][j].txn_id, 
                    scoreboard_entry_d[i][j].qos_value, 
                    scoreboard_entry_d[i][j].inport_vc_id, 
                    scoreboard_entry_d[i][j].tgt_id.x_position, scoreboard_entry_d[i][j].tgt_id.y_position, scoreboard_entry_d[i][j].tgt_id.device_port,
                    scoreboard_entry_d[i][j].look_ahead_routing,
                    scoreboard_entry_d[i][j].flit_data);

        allocate_port_counter_d   = allocate_port_counter_d + 1;
        allocate_port_counter_ena = 1'b1;
      end

      if(scoreboard_entry_vld_clr[i][j]) begin
        $display("[%16d] info: scoreboard deallocate entry, sender: %2d (%d,%d), txn_id: 0x%h, QoS = %d, inport_vc_id:%d, tgt_id: (%d,%d), tgt_local_port: %d, send_data: %h, [noc_latency: %4d], [app_latency: %4d], [receiver (%d,%d) port %d average_noc_bandwidth: %fGBps])", 
                    $time(), i, 
                    scoreboard_entry_q[i][j].src_id.x_position, scoreboard_entry_q[i][j].src_id.y_position, 
                    scoreboard_entry_q[i][j].txn_id, 
                    scoreboard_entry_q[i][j].qos_value, 
                    scoreboard_entry_q[i][j].inport_vc_id, 
                    scoreboard_entry_q[i][j].tgt_id.x_position, scoreboard_entry_q[i][j].tgt_id.y_position, scoreboard_entry_q[i][j].tgt_id.device_port,
                    scoreboard_entry_q[i][j].flit_data,
                    mcycle_i - scoreboard_entry_q[i][j].sent_mcycle,
                    mcycle_i - scoreboard_entry_q[i][j].generated_mcycle,

                    scoreboard_entry_q[i][j].tgt_id.x_position, scoreboard_entry_q[i][j].tgt_id.y_position, scoreboard_entry_q[i][j].tgt_id.device_port,
                    ((deallocate_port_counter[scoreboard_entry_q[i][j].tgt_id.x_position*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + 
                                              scoreboard_entry_q[i][j].tgt_id.y_position*LOCAL_PORT_NUM + 
                                              scoreboard_entry_q[i][j].tgt_id.device_port] * 
                      FLIT_LENGTH /8/1024/1024/1024) / (mcycle / ASSUMED_SYSTEM_FREQUENCY))
                  );

        flit_num_counter_d  = flit_num_counter_d + 1;
        flit_num_counter_ena   = 1'b1;
        flit_noc_latency_counter_d = flit_noc_latency_counter_d + (mcycle_i - scoreboard_entry_q[i][j].sent_mcycle);
        flit_noc_latency_counter_ena = 1'b1;
        flit_app_latency_counter_d = flit_app_latency_counter_d + (mcycle_i - scoreboard_entry_q[i][j].generated_mcycle);
        flit_app_latency_counter_ena = 1'b1;

        deallocate_port_counter_all_d   = deallocate_port_counter_all_d + 1;
        deallocate_port_counter_all_ena = 1'b1;
    
        // receiver id = x_posotion*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + y_posotion*LOCAL_PORT_NUM + local_port_id
        deallocate_port_counter_d  [scoreboard_entry_q[i][j].tgt_id.x_position*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + 
                                    scoreboard_entry_q[i][j].tgt_id.y_position*LOCAL_PORT_NUM + 
                                    scoreboard_entry_q[i][j].tgt_id.device_port] += 1;
        deallocate_port_counter_ena[scoreboard_entry_q[i][j].tgt_id.x_position*(NODE_NUM_Y_DIMESION*LOCAL_PORT_NUM) + 
                                    scoreboard_entry_q[i][j].tgt_id.y_position*LOCAL_PORT_NUM + 
                                    scoreboard_entry_q[i][j].tgt_id.device_port] = 1'b1;
      end
    end
  end
  if(|scoreboard_entry_vld_clr) begin
    $display("[%16d] info: scoreboard deallocate entry, receiver:all, [average_noc_latency: %f], [average_app_latency: %f], [average_noc_bandwidth: %fGBps]", 
              $time(),
              (flit_noc_latency_counter)/(flit_num_counter),
              (flit_app_latency_counter)/(flit_num_counter),
              ((deallocate_port_counter_all * FLIT_LENGTH /8/1024/1024/1024) / (mcycle / ASSUMED_SYSTEM_FREQUENCY)));
  end
end


endmodule
