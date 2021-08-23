// Code your design here
`include "base_ram.sv"
// Author: Nitin Mishra

// Description: Functional module of a Tensor Core SRAM

module tc_sram #(
  parameter int unsigned NumWords		= 1024, 			// Total  elements - (VRs * elementperVR)
  parameter int unsigned NumBanks		= 4,				// banks
  parameter int unsigned WordsPerBank	= NumWords/NumBanks, // 32
  parameter int unsigned DataWidth    	= 32,  				// Data signal width
 
  
  parameter int unsigned AddrWidth 	= (NumWords > 32'd1) ? $clog2(WordsPerBank) : 32'd1
  
) (
  input  logic	clk,      									// Clock
  input  logic  nrst,     									// Asynchronous reset active low
  
  input  logic  [NumBanks-1:0]re,   
  input  logic  [NumBanks-1:0]we,
  input  logic[NumBanks-1:0][AddrWidth-1:0]waddr,    		// request address
  input  logic[NumBanks-1:0][AddrWidth-1:0]raddr1,
  input  logic[NumBanks-1:0][AddrWidth-1:0]raddr2,
  input  logic[NumBanks-1:0][DataWidth-1:0]wdata,    		// write data
  
  output logic[NumBanks-1:0][DataWidth-1:0]rdataA,   		// read data 
  output logic[NumBanks-1:0][DataWidth-1:0]rdataB
);

  // memory array
  
  logic[DataWidth-1:0] sram [WordsPerBank-1:0][NumBanks-1:0]; // 2D sram memory array
  
  //Generate 4 banks of base_sram to create a 4 bank top SRAM
  
  genvar i;
    generate 
      for (i = 0; i < 4; i = i + 1) begin //: MEM_Banks
        
          base_ram BSRAM
          	(
              .clk(clk),
              .nrst(nrst),
              
              .we (we[i]),
              .re(re[i]),
              
              .raddr1(raddr1[i]),
              .raddr2(raddr2[i]),
              .waddr(waddr[i]),
                             
              .wdata (wdata[i]),
              .rdataA(rdataA[i]),
              .rdataB(rdataB[i])
            );
			
      end 
    endgenerate  
  
endmodule
