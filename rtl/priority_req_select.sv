// select req(s) with the highest priority from the req input vector 
module priority_req_select
  import rvh_noc_pkg::*;
#(
  parameter INPUT_NUM        = 4,
  parameter INPUT_NUM_IDX_W  = INPUT_NUM > 1 ? $clog2(INPUT_NUM) : 1,
  parameter INPUT_PRIORITY_W = 4
)
(
  input  logic [INPUT_NUM-1:0]                        req_vld_i,
  input  logic [INPUT_NUM-1:0][INPUT_PRIORITY_W-1:0]  req_priority_i,

  output logic [INPUT_NUM-1:0]                        req_vld_o
);
genvar i,j;

// x >= y -> 1 else 0
//  req_vld_i  pri  3  9  2  8   &   req_vld_o
//      1       3   1  1  1  0   0      0
//      0       9   0  0  0  0   0      0
//      1       2   0  1  1  0   0      0
//      1       8   1  1  1  1   1      1

logic [INPUT_NUM-1:0][INPUT_NUM-1:0] priority_compare_vector;
generate
  for(i = 0; i < INPUT_NUM; i++) begin: gen_priority_compare_vector_i
    for(j = 0; j < INPUT_NUM; j++) begin: gen_priority_compare_vector_j
      if (i == j) begin: gen_diagonal
        assign priority_compare_vector[i][j] = req_vld_i[i];
      end else begin: gen_others
        assign priority_compare_vector[i][j] = ~req_vld_i[j] | (req_priority_i[i] >= req_priority_i[j]);
      end
    end
  end
endgenerate

generate
  for(i = 0; i < INPUT_NUM; i++) begin: gen_req_vld_o
    assign req_vld_o[i] = &(priority_compare_vector[i]);
  end
endgenerate

endmodule
