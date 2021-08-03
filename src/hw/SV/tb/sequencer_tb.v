// Code your testbench here
// or browse Examples
`timescale 1ns/1ps

module top();
  logic clk, nrst;
  logic vseq_busy;
  logic[4:0] vs1, vs2, vd;
  logic[2:0] lmul, vsew;
  logic [31:0] vl;
  logic[15:0] var_dec_bits;
  //logic[31:0] ld_data;
  int ld_data;
  logic[2:0] vid;
  bit rw_done;
  bit w_done;
  
  //Connections
  sequencer seq(
    .clk(clk),
    .nrst(nrst),
    .vseq_busy(vseq_busy),
    .vs1(vs1),
    .vs2(vs2),
    .vd(vd),
    .lmul(lmul),
    .vsew(vsew),
    .vl(vl),
    .var_dec_bits(var_dec_bits),
    .ld_data(ld_data),
    .vid(vid),
    .rw_done(rw_done),
    .w_done(w_done)
  );
  
  logic[4:0] ele_cnt;
  logic[4:0] addr;
  
  
  initial begin
    clk = 1'b0;
    forever #5ns
    clk = !clk;
  end
  
  initial begin
    nrst = 1'b0;
    //ele_cnt = 32'd0;
    ld_data = 32'd0;
    //addr = 32'd0; 
    #10ns
    nrst = 1'b1;
    //#5ns
    //nrst = 1'b0;
  end
  
  //Stimulus 
  //1. Load SRAM with values
  //Make sure all addresses vs1, vs2, vd are multiples of 8
  //For 32 vector registers, possible values are - [4'd0, 4'd8, 4'd16, etc.)
  //This needs to be modified later

  initial begin
    @(posedge nrst);
    @(posedge clk);
    var_dec_bits = 15'b0000_0000_0000_0111;
    vd = 5'd8;
    
    for (int j = 0; j<8; j++) begin
      for (int i = 0; i< 5; i++)begin
        @(posedge clk);
        ld_data = ld_data + 1;
      end
      //vwe = 3'd0;
    end
    
    @(posedge clk);
    vd = 5'd16;
    ld_data = 0;
    
    for (int j = 0; j<8; j++) begin
      for (int i = 0; i< 5; i++)begin
        @(posedge clk);
        ld_data = ld_data -1;
      end
      //vwe = 3'd0;
    end
    //@(posedge clk);
    rw_done = 1;
    
    @(posedge clk);
    //rw_done = 0;
    var_dec_bits = 15'b0000_0000_0101_0111;
    vs1 = 5'd8;
    vs2 = 5'd16;
    
    for (int j = 0; j<8; j++) begin
      for (int i = 0; i< 5; i++)begin
        @(posedge clk);
        //ld_data = ld_data + 1;
      end
      //vwe = 3'd0;
    end
    //@(posedge clk);
    w_done = 1;
   // @(posedge clk);
    //w_done = 0;
  end
  
  initial begin
    #1500ns
    $finish;
  end
  
  initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars;
  end
 
 
  
endmodule


      
    
 