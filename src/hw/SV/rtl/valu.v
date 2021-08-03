module valu (
  input nrst,
  input valu_en,
  input logic[31:0] inA,
  input logic[31:0] inB,
  input logic[8:0] op,
  output logic[31:0] out_res
  );
  
  
  always_comb begin
    if(!nrst) 
      out_res = 32'hDEAD_DEAD;
    else begin
      if( op == 9'h000 || op == 9'h004) 
        out_res = inA + inB;
      else if(op == 9'h0B9 || op == 9'h0BC) 
        out_res = inA * inB;
    end
  end
  
endmodule


    
  