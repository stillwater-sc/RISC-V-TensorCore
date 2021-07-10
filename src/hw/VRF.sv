// Code your design here
// 
// 

// Author: Nitin Mishra

// Description: Functional module of a generic SRAM
//
// Parameters:
// - NumWords:    	Total number of elements in the memory = No. of VRs x No. of elements per VR
// - DataWidth:   	Width of the ports `wdata_i` and `rdata_o`.
//                	ceiling division `ceil(DataWidth, ByteWidth)`.
// - Numbanks:    	Number of memory banks. The elements of Vector Registers are sprea across these  banks.
// - WordsPerbank : Total No. of elements stored in each bank. Each bank stores multiple elements from every VR 
// Ports:
// - `clk`:   	Clock
// - `nrst`:  	Asynchronous reset, active low
// - `re`:   	Request, active high
// - `we`:    	Write request, active high
// - `w_addr`:  Write Request address
// - `wdata`: 	Write data, has to be valid on request
// - `r_addr`:  Read Request address
// - `rdata`: 	Read data, valid on re.
//
// Behaviour:
// - Address collision:  When Ports are making a write access onto the same address,
//                       the write operation will start at the port with the lowest address
//                       index, each port will overwrite the changes made by the previous ports
//                       according how the respective `be_i` signal is set.
// - Read data on write: This implementation will not produce a read data output on the signal
//                       `rdata_o` when `req_i` and `we_i` are asserted. The output data is stable
//                        on write requests.

module tc_sram #(
  parameter int unsigned NumWords		= 1024, // Total  elements - (VRs * elementperVR)
  parameter int unsigned NumBanks		= 4,		// banks
  parameter int unsigned WordsPerBank	= NumWords/NumBanks, // 32
  parameter int unsigned DataWidth    	= 32,  // Data signal width
 
 // DEPENDENT PARAMETERS, DO NOT OVERWRITE!
  
  parameter int unsigned AddrWidth 	= (NumWords > 32'd1) ? $clog2(WordsPerBank) : 32'd1,
  parameter int unsigned BankSel	= $clog2(NumBanks)
  //parameter int unsigned BeWidth  = (DataWidth + ByteWidth - 32'd1) / ByteWidth, // ceil_div - no - floor
  //parameter type         addr_t	    = logic [AddrWidth-1:0],
  //parameter type         data_t    	= logic [DataWidth-1:0]
  //parameter type         be_t      	= logic [BeWidth-1:0]
) (
  input  logic	clk,      // Clock
  input  logic  nrst,     // Asynchronous reset active low
  // input ports
  //input  logic  req[BankSel-1:0],      // request
 // input  logic  we[BankSel-1:0],       // write enable
 // input  logic  re[BankSel-1:0],
  input  logic  [NumBanks-1:0]re,   
  input  logic  [NumBanks-1:0]we,
  input  logic[NumBanks-1:0][AddrWidth-1:0]w_addr,    // request address
  input  logic[NumBanks-1:0][AddrWidth-1:0]r_addr,
  input  logic[NumBanks-1:0][DataWidth-1:0]wdata,    // write data
 
  output logic[NumBanks-1:0][DataWidth-1:0]rdata   // read data
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
  

  // write memory array with default values on reset
  always_ff @(posedge clk, negedge nrst) begin
    if (!nrst) begin
      for (int i = 0; i < NumBanks; i++) begin
        for(int j = 0; j < WordsPerBank; j++) begin
          sram[j][i] = 32'd0;
        end
      end
    end
    
      else begin
        // read value latch happens before new data is written to the sram
        for (int i = 0; i < NumBanks; i++) begin
          //for(int j = 0; j < WordsPerBank; j++) begin
            
            if (!re[i] && we[i]) begin
              sram[w_addr[i]][i] <= wdata[i];
            end
          
            else if(re[i] && !we[i]) begin
              rdata[i] <= sram[r_addr[i]][i];
            end
           
            else if(re[i] && we[i]) begin
              sram[w_addr[i]][i] <= wdata[i];
              rdata[i] <= sram[r_addr[i]][i];
            end
          
            else begin
              sram[w_addr[i]][i] <= sram[w_addr[i]][i];
              rdata[i] <= 32'd0;
            end
          //end
        end
      end
  end
     
  
endmodule
    
/*
// Validate parameters.
// pragma translate_off
`ifndef VERILATOR
`ifndef TARGET_SYNTHESYS
  initial begin: p_assertions
    assert ($bits(addr_i)  == NumPorts * AddrWidth) else $fatal(1, "AddrWidth problem on `addr_i`");
    assert ($bits(wdata_i) == NumPorts * DataWidth) else $fatal(1, "DataWidth problem on `wdata_i`");
    assert ($bits(be_i)    == NumPorts * BeWidth)   else $fatal(1, "BeWidth   problem on `be_i`"   );
    assert ($bits(rdata_o) == NumPorts * DataWidth) else $fatal(1, "DataWidth problem on `rdata_o`");
    assert (NumWords  >= 32'd1) else $fatal(1, "NumWords has to be > 0");
    assert (DataWidth >= 32'd1) else $fatal(1, "DataWidth has to be > 0");
    assert (ByteWidth >= 32'd1) else $fatal(1, "ByteWidth has to be > 0");
    assert (NumPorts  >= 32'd1) else $fatal(1, "The number of ports must be at least 1!");
  end
  initial begin: p_sim_hello
    if (PrintSimCfg) begin
      $display("#################################################################################");
      $display("tc_sram functional instantiated with the configuration:"                          );
      $display("Instance: %m"                                                                     );
      $display("Number of ports   (dec): %0d", NumPorts                                           );
      $display("Number of words   (dec): %0d", NumWords                                           );
      $display("Address width     (dec): %0d", AddrWidth                                          );
      $display("Data width        (dec): %0d", DataWidth                                          );
      $display("Byte width        (dec): %0d", ByteWidth                                          );
      $display("Byte enable width (dec): %0d", BeWidth                                            );
      $display("Latency Cycles    (dec): %0d", Latency                                            );
      $display("Simulation init   (str): %0s", SimInit                                            );
      $display("#################################################################################");
    end
  end
  for (genvar i = 0; i < NumPorts; i++) begin : gen_assertions
    assert property ( @(posedge clk_i) disable iff (!rst_ni)
        (req_i[i] |-> (addr_i[i] < NumWords))) else
      $warning("Request address %0h not mapped, port %0d, expect random write or read behavior!",
          addr_i[i], i);
  end
`endif
`endif
// pragma translate_on
endmodule
*/
