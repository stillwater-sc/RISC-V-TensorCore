\m4_TLV_version 1d: tl-x.org
\SV

   // =========================================
   // TensorCore Module definition
   // =========================================
   
\SV
// ------------------------
// SystemVerilog data types

typedef logic [39:0] address_t;
typedef logic [31:0] operand_t;
typedef logic [5:0]  burst_t;   // burst length of the data request
typedef logic        bool_t;

typedef logic [31:0] vinstr_t;


// --------------
// TensorCore

module tensorcore
(
    input logic      reset,
    input logic      clk,
    input vinstr_t   vecop,  // RISC-V V instruction
    output bool_t    rw,     // read/write request indicator
    output address_t addr,   // Load/Store Unit request address
    output burst_t   size,   // Load request length
    output operand_t out
);

always_comb
begin
    out = 42;
end

endmodule : tensorcore 
