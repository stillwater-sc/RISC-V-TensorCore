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
  //input  logic[DataWidth-1:0]wdata,
 
  output logic[NumBanks-1:0][DataWidth-1:0]rdataA,   		// read data
  //output logic[DataWidth-1:0]rdataA,   
  output logic[NumBanks-1:0][DataWidth-1:0]rdataB
);

  // memory array
  
  logic[DataWidth-1:0] sram [WordsPerBank-1:0][NumBanks-1:0]; // 2D sram memory array
  
  // hold the read address when no read access is made
  //addr_t [NumPorts-1:0] r_addr_q;

  
  // set the read output if requested
  // The read data at the highest array index is set combinational.
  // It gets then delayed for a number of cycles until it gets available at the output at
  // array index 0.

  // read data output assignment
  
  //Generate 4 banks of base_sram to create a 4 bank top SRAM
  
  genvar i;
    generate 
      for (i = 0; i < 4; i = i + 1) begin //: MEM_Banks
        
          base_ram BSRAM
          /*
          #(
                .BW(BW),
              .FIFO_SIZE(IF_SIZE),
                .AW(AW)
            ) 
            */
        
        //sram_cell 
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

  
/*
  // write memory array with default values on reset
  always_ff @(posedge clk, negedge nrst) begin
    if (nrst) begin
      for (int i = 0; i < NumBanks; i++) begin
        for(int j = 0; j < WordsPerBank; j++) begin
          sram[j][i] <= 32'd0;
          rdataA 	 <= 32'd0;
          rdataB	 <= 32'd0;
        end
      end
    end
    
      else begin
        // read value latch happens before new data is written to the sram
        for (int i = 0; i < NumBanks; i++) begin
          //for(int j = 0; j < WordsPerBank; j++) begin
            
            if (!re[i] && we[i]) begin
              sram[w_addr[i]][i] <= wdata;
            end
          
            else if(re[i] && !we[i]) begin
              rdataA <= sram[r_addr1[i]][i];
              rdataB <= sram[r_addr2[i]][i];
            end
           
            else if(re[i] && we[i]) begin
              sram[w_addr[i]][i] <= wdata;
              rdataA <= sram[r_addr1[i]][i];
              rdataB <= sram[r_addr2[i]][i];
            end
          
            else begin
              sram[w_addr[i]][i] <= sram[w_addr[i]][i];
              rdataA <= 32'hDEAD_DEAD;
              rdataB <= 32'hDEAD_DEAD;
            end
          //end
        end
      end
  end
*/     
  
endmodule
