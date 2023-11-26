// vc selection per output port to pre-allocate every possible next hop output port for vc assignment
module output_port_vc_selection
import rvh_noc_pkg::*;
#(
parameter OUTPUT_VC_NUM         = 4,
parameter OUTPUT_VC_NUM_IDX_W   = OUTPUT_VC_NUM > 1 ? $clog2(OUTPUT_VC_NUM) : 1,
parameter OUTPUT_VC_DEPTH       = 1,
parameter OUTPUT_VC_DEPTH_IDX_W = $clog2(OUTPUT_VC_DEPTH + 1),

parameter OUTPUT_TO_L = 0
)
(
// input from per output port vc credit counter
input  logic [OUTPUT_VC_NUM-1:0][OUTPUT_VC_DEPTH_IDX_W-1:0] vc_credit_counter_i,

// output to vc assignment
output vc_select_vld_t   [OUTPUT_VC_NUM-1:0] vc_select_vld_o,
output vc_select_vc_id_t [OUTPUT_VC_NUM-1:0] vc_select_vc_id_o

);

genvar i;

logic [OUTPUT_VC_NUM-1:0] vc_credit_counter_not_empty;

generate
  for(i = 0; i < OUTPUT_VC_NUM; i++) begin
    assign vc_credit_counter_not_empty[i] = |(vc_credit_counter_i[i]);
  end
endgenerate


generate
  if(!OUTPUT_TO_L) begin
    always_comb begin: comb_common_vc_id
      for(int i = QOS_VC_NUM_PER_INPUT; i < OUTPUT_VC_NUM; i++) begin
        vc_select_vld_o  [i].common_vld   = '0;
        vc_select_vc_id_o[i].common_vc_id = '0;
        vc_select_vld_o  [i].rt_vld   = '0;
        vc_select_vc_id_o[i].rt_vc_id = '0;
        if(vc_credit_counter_not_empty[i]) begin // the priority output port vc has free credit, assign it to the flit
          vc_select_vld_o   [i].common_vld    = 1'b1;
          vc_select_vc_id_o [i].common_vc_id  = i[VC_ID_NUM_MAX_W-1:0];
        end else begin // the priority output port vc has no free credit, try other vc
          for(int j = QOS_VC_NUM_PER_INPUT; j < OUTPUT_VC_NUM; j++) begin
            if(j != i) begin
              if(vc_credit_counter_not_empty[j]) begin
                vc_select_vld_o   [i].common_vld   = 1'b1;
                vc_select_vc_id_o [i].common_vc_id = j[VC_ID_NUM_MAX_W-1:0];
              end
            end
          end
        end
      end
    end

    `ifdef COMMON_QOS_EXTRA_RT_VC
    always_comb begin: comb_rt_vc_id
      for(int i = 0; i < QOS_VC_NUM_PER_INPUT; i++) begin
        vc_select_vld_o  [i].common_vld   = '0;
        vc_select_vc_id_o[i].common_vc_id = '0;
        vc_select_vld_o  [i].rt_vld   = '0;
        vc_select_vc_id_o[i].rt_vc_id = '0;
        if(vc_credit_counter_not_empty[i]) begin // the priority output port vc has free credit, assign it to the flit
          vc_select_vld_o   [i].rt_vld    = 1'b1;
          vc_select_vc_id_o [i].rt_vc_id  = i[VC_ID_NUM_MAX_W-1:0];
        end else begin // the priority output port vc has no free credit, try other vc
          for(int j = 0; j < QOS_VC_NUM_PER_INPUT; j++) begin
            if(j != i) begin
              if(vc_credit_counter_not_empty[j]) begin
                vc_select_vld_o   [i].rt_vld   = 1'b1;
                vc_select_vc_id_o [i].rt_vc_id = j[VC_ID_NUM_MAX_W-1:0];
              end
            end
          end
        end
      end
    end
    `endif

  end else begin // it is output to L, just common vc

    always_comb begin
      for(int i = 0; i < OUTPUT_VC_NUM; i++) begin
        vc_select_vld_o  [i].common_vld   = '0;
        vc_select_vc_id_o[i].common_vc_id = '0;
        vc_select_vld_o  [i].rt_vld   = '0;
        vc_select_vc_id_o[i].rt_vc_id = '0;
        if(vc_credit_counter_not_empty[i]) begin // the priority output port vc has free credit, assign it to the flit
          vc_select_vld_o   [i].common_vld    = 1'b1;
          vc_select_vc_id_o [i].common_vc_id  = i[VC_ID_NUM_MAX_W-1:0];
        end else begin // the priority output port vc has no free credit, try other vc
          for(int j = 0; j < OUTPUT_VC_NUM; j++) begin
            if(j != i) begin
              if(vc_credit_counter_not_empty[j]) begin
                vc_select_vld_o   [i].common_vld   = 1'b1;
                vc_select_vc_id_o [i].common_vc_id = j[VC_ID_NUM_MAX_W-1:0];
              end
            end
          end
        end
      end
    end

  end
endgenerate

endmodule
