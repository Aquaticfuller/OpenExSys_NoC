// Simple Dual-Port Block RAM with One Clock
// reference: https://docs.xilinx.com/r/en-US/ug901-vivado-synthesis/Single-Port-Block-RAM-No-Change-Mode-Verilog
// File: simple_dual_one_clock.v

module simple_dual_one_clock 
#(
  parameter ADDR_BITS   = 4,
  parameter DATA_BITS   = 8
  // parameter RAM_LATENCY = 1,
  // parameter WE_SIZE     = 1,

)
(clk,ena,enb,wea,addra,addrb,dia,dob);

input clk,ena,enb,wea;

input [ADDR_BITS-1:0] addra,addrb;

input [DATA_BITS-1:0] dia;

output [DATA_BITS-1:0] dob;

reg [DATA_BITS-1:0] ram [(1'b1<<ADDR_BITS)-1:0];

reg [DATA_BITS-1:0] doa,dob;

always @(posedge clk) begin

if (ena) begin

if (wea)

ram[addra] <= dia;

end

end

always @(posedge clk) begin

if (enb)

dob <= ram[addrb];

end

endmodule