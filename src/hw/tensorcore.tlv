\m4_TLV_version 1d: tl-x.org
\SV
   // This code can be found in: https://github.com/stevehoover/RISC-V_MYTH_Workshop
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/RISC-V_MYTH_Workshop/c1719d5b338896577b79ee76c2f443ca2a76e14f/tlv_lib/risc-v_shell_lib.tlv'])

\SV
     // URL include paths:
   //m4_define(['m4_TC_repo'], ['['https://raw.githubusercontent.com/olofk/serv/master/']']) 
   m4_define(['m4_TC_repo'], ['['https://github.com/nitinm694/Tensor_Core_RISCV_VP/']'])
   m4_define(['m4_TC_rtl'], ['m4_TC_repo['SV_Modules/']'])
   //m4_define(['m4_servant_rtl'], ['m4_serv_repo['servant/']'])
   //m4_define(['m4_serv_bench'], ['m4_serv_repo['bench/']'])
   //m4_define(['m4_serv_hex'], ['m4_serv_repo['sw/']'])

   //Bench RTL
   //m4_sv_get_url(m4_swerv_config_src['pic_map_auto.h'])
   //m4_sv_get_url(m4_serv_bench['servant_tb.v']) // CAN DEFINE THE TB
   //m4_sv_include_url(m4_serv_bench['uart_decoder.v'])

   
   // Modules:
   // Core RTL
   m4_sv_get_url(m4_TC_rtl['VRF.sv'])
                              
   /*
   // Hex files:
   m4_sv_get_url(m4_serv_hex['blinky.hex'])
   
   module servant_sim
   	(input wire  wb_clk,
   	input wire  wb_rst,
   	output wire q);
   	parameter memfile = "";
   	parameter memsize = 8192;
   	parameter with_csr = 1;
   	reg [1023:0] firmware_file;
   initial
   	begin
   	$display("Loading RAM from %0s", "./sv_url_inc/blinky.hex");
   	$readmemh("./sv_url_inc/blinky.hex", dut.ram.mem);
   	end
   servant #(.memfile  (memfile),
   	.memsize  (memsize),
   	.sim      (1),
   	.with_csr (with_csr))
   	dut(wb_clk, wb_rst, q);
   endmodule
   */
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV

   // /====================\
   // | SAXPY |
   // \====================/
   //
   // Program to compute  stripmined SAXPY loop using a FMA instruction & normal flow
   // Add 1,2,3,...,9 (in that order).
   //
   // Regs:
   //  r10 (a0): In: 0, Out: final sum
   //  r12 (a2): 10
   //  r13 (a3): 1..10
   //  r14 (a4): Sum
   // 
   // External to function:
   /*
   m4_asm(ADD, r10, r0, r0)             // Initialize r10 (a0) to 0.
   // Function:
   m4_asm(ADD, r14, r10, r0)            // Initialize sum register a4 with 0x0
   m4_asm(ADDI, r12, r10, 1010)         // Store count of 10 in register a2.
   m4_asm(ADD, r13, r10, r0)            // Initialize intermediate sum register a3 with 0
   // Loop:
   m4_asm(ADD, r14, r13, r14)           // Incremental addition
   m4_asm(ADDI, r13, r13, 1)            // Increment intermediate register by 1
   m4_asm(BLT, r13, r12, 1111111111000) // If a3 is less than a2, branch to label named <loop>
   m4_asm(ADD, r10, r14, r0)            // Store final result to register a0 so that it can be read by main program

   //Added by me - to check the Ld/Str functionality
   m4_asm(SW, r0, r10, 100)
   m4_asm(LW, r15, r0, 100)
   // Optional:
   // m4_asm(JAL, r7, 00000000000000000000) // Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
   m4_define_hier(['M4_IMEM'], M4_NUM_INSTRS)
   */
   |cpu
      //Type 1 - Using Stalls (NOPS) to ovrcome Hazards
      @0
         $reset = *reset;
         
      // YOUR CODE HERE         
      //For invalid instructions (-since we won't have a valid instruction every cycle now
      //because of dependency hazards and NOPS
      // Use the generated $valid signal to : - 
      // a. PC should not change during a NOP
      // b. Reg Write into RF should not occur during NOP
      // c. Update inter-instructiob dependency aligments by waiting for 3 cycles before starting new instruction
         
  
      // ...
      //PC logic
                  
         $imem_rd_en = $reset ? 0 : 1;
         $imem_rd_addr[M4_IMEM_INDEX_CNT-1:0] = $pc[M4_IMEM_INDEX_CNT+1:2]; 
        
      @1
         $instr[31:0] = $imem_rd_en ? $imem_rd_data[31:0] : 0;
         //$inc_pc[31:0] = $pc + 32'd4; //define $inc_pc to simplify $pc logic 
         //Decode Logic
         //A. Instruction type
         $is_vld_instr  = $instr[6:0] ==? 7'b0000111;
         $is_vstr_instr = $instr[6:0] ==? 7'b0100111;
         $is_vamo_instr = $instr[6:0] ==? 7'b0101111;
         $is_var_instr  = $instr[6:0] ==? 7'b1010111 && $instr[14:12] != 3'b111;
         $is_vcfg_instr = $instr[6:0] ==? 7'b1010111 && $instr[14:12] == 3'b111;
         
         //B.Flavours of above types
         //Vector Load
         $is_vl_instr =  $is_vld_instr && $instr[27:26] == 2'b00;
         $is_vls_instr = $is_vld_instr && ($instr[27:26] == 2'b01 || $instr[27:26]==2'b11);
         $is_vlx_instr = $is_vld_instr && $instr[27:26] == 2'b10;
         
         //Vector Store
         $is_vs_instr =  $is_vstr_instr && $instr[27:26] == 2'b00;
         $is_vss_instr = $is_vstr_instr && ($instr[27:26] == 2'b01 || $instr[27:26]==2'b11);
         $is_vsx_instr = $is_vstr_instr && $instr[27:26] == 2'b10;
         
         //Vector Arithmetic
         $is_ivv_instr = $is_var_instr && $instr[14:12] == 3'b000;
         $is_fvv_instr = $is_var_instr && $instr[14:12] == 3'b001;
         $is_mvv_instr = $is_var_instr && $instr[14:12] == 3'b010;
         
         $is_ivi_instr = $is_var_instr && $instr[14:12] == 3'b011;
         $is_ivx_instr = $is_var_instr && $instr[14:12] == 3'b100;
         $is_fvf_instr = $is_var_instr && $instr[14:12] == 3'b101;
         $is_mvx_instr = $is_var_instr && $instr[14:12] == 3'b110;
         
         //Config instructions - using 2 out of 3 defined
         $is_vsetvl = $is_vcfg_instr && $instr[31] == 1'b1;
         $is_vsetvli = $is_vcfg_instr && $instr[31] == 1'b0;
         
         //C. Immediate decode
         // VAR type doesn't have an immediate field - check
         // Only instructions used in this design have $imm field - define them here
         /*
         $imm[31:0] = $is_b_instr ? { {20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'b0} :
                      $is_u_instr ? { $instr[31], $instr[30:20], $instr[19:12], 12'b0} :
                      $is_j_instr ? { {12{$instr[31]}}, $instr[19:12], $instr[20], $instr[30:25], $instr[24:21], 1'b0} :
                      $is_i_instr ? { {21{$instr[31]}}, $instr[30:25], $instr[24:21], $instr[20]} :
                      $is_s_instr ? { {21{$instr[31]}}, $instr[30:25], $instr[11:8], $instr[7]} :
                      32'd0; //default - is this needed ?
         */
         
         //C. Create valids for other fields depending on instr type
         $vd_valid = !$is_vcfg_instr && !$is_vstr_instr;
         $rd_valid = $is_vcfg_instr || $is_fvv_instr || $is_mvv_instr || $is_mvx_instr;
         
         $vs1_valid = $is_ivv_instr || $is_fvv_instr || $is_mvv_instr;
         $rs1_valid = $is_ivx_instr || $is_fvf_instr || $is_mvx_instr || $is_vamo_instr || $is_vld_instr || $is_vstr_instr || $is_vcfg_instr; //vestvli not supported here; 
                                                                                                                                              //that has different encoding for rs1
         $vs2_valid = $is_var_instr || $is_vamo_instr || $is_vlx_instr || $is_vsx_instr;
         $rs2_valid = $is_vls_instr || $is_vss_instr || $is_vsetvl; // potential error; vsetvl not defined yet
         
         $funct3_valid = $is_var_instr || $is_vcfg_instr; //check
         $funct6_valid = $is_var_instr;
         
         //D. Other fields decode
         $opcode[6:0] = $instr[6:0];
         ?$rd_valid
            $rd[4:0]  = $instr[11:7];
         ?$vd_valid
            $vd[4:0]  = $instr[11:7];
         ?$vs1_valid
            $vs1[4:0] = $instr[19:15];
         ?$rs1_valid
            $rs1[4:0] = $instr[19:15];
         ?$vs2_valid
            $vs2[4:0] = $instr[24:20];
         ?$rs2_valid
            $rs2[4:0] = $instr[24:20];
         ?$funct3_valid
            $funct3[2:0] = $instr[14:12];
         ?$funct6_valid
            $funct6[5:0] = $instr[31:26];
         
         //E. Decode Individual instructions
         // Only a subset of RISCV spec - just what we need
         //A. Collect bits that are needed to specify an instruction
         $var_dec_bits[15:0] = {$funct6, $funct3, $opcode};
         $vls_dec_bits[12:0]  = {$instr[28:26], $instr[14:12], $opcode};
         
         //B. Now decode the VAR istructions
         //VV Type
         //integer
         $is_vadd_ivv = $var_dec_bits == 16'b000000_000_1010111;
         $is_vmul_ivv = $var_dec_bits == 16'b010111_000_1010111;
         // float
         $is_vadd_fvv = $var_dec_bits == 16'b000000_001_1010111;
         $is_vmul_fvv = $var_dec_bits == 16'b010111_001_1010111;
         //masked
         $is_vadd_mvv = $var_dec_bits == 16'b000000_000_1010111;
         $is_vmul_mvv = $var_dec_bits == 16'b010111_000_1010111;
         
         //VS type
         //integer
         $is_vadd_ivx = $var_dec_bits == 16'b000000_100_1010111;
         $is_vmul_ivx = $var_dec_bits == 16'b010111_100_1010111;
         // float
         $is_vadd_fvf = $var_dec_bits == 16'b000000_101_1010111;
         $is_vmul_fvf = $var_dec_bits == 16'b010111_101_1010111;
         //masked
         $is_vadd_mvx = $var_dec_bits == 16'b000000_110_1010111;
         $is_vmul_mvx = $var_dec_bits == 16'b010111_110_1010111;
         
         //VFMA type
         
         //B.4 Loads and Stores
         //Loads
         //Unit
         $is_vle8  = $vls_dec_bits ==? 13'b000_000_0000111;
         $is_vle16 = $vls_dec_bits ==? 13'b000_101_0000111; // Concatenate all loads into 1 instruction for our purposes
         $is_vle32 = $vls_dec_bits ==? 13'b000_110_0000111; // Concatenate all stores into 1 instruction for our purposes
         $is_vle64 = $vls_dec_bits ==? 13'b000_111_0000111;
         
         //Strided
         $is_vlse8  = $vls_dec_bits ==? 13'b010_000_0000111;
         $is_vlse16 = $vls_dec_bits ==? 13'b010_101_0000111; // Concatenate all loads into 1 instruction for our purposes
         $is_vlse32 = $vls_dec_bits ==? 13'b010_110_0000111; // Concatenate all stores into 1 instruction for our purposes
         $is_vlse64 = $vls_dec_bits ==? 13'b010_111_0000111;
         
         //Indexed
         //orderes
         $is_vloxei8  = $vls_dec_bits ==? 13'b011_000_0000111;
         $is_vloxei16 = $vls_dec_bits ==? 13'b011_101_0000111; // Concatenate all loads into 1 instruction for our purposes
         $is_vloxei32 = $vls_dec_bits ==? 13'b011_110_0000111; // Concatenate all stores into 1 instruction for our purposes
         $is_vloxei64 = $vls_dec_bits ==? 13'b011_111_0000111;
         
         
         //Stores
         //Unit
         $is_vse8  = $vls_dec_bits ==? 13'b000_000_0100111;
         $is_vse16 = $vls_dec_bits ==? 13'b000_101_0100111; // Concatenate all loads into 1 instruction for our purposes
         $is_vse32 = $vls_dec_bits ==? 13'b000_110_0100111; // Concatenate all stores into 1 instruction for our purposes
         $is_vse64 = $vls_dec_bits ==? 13'b000_111_0100111;
         
         //Strided
         $is_vsse8  = $vls_dec_bits ==? 13'b010_000_0100111;
         $is_vsse16 = $vls_dec_bits ==? 13'b010_101_0100111; // Concatenate all loads into 1 instruction for our purposes
         $is_vsse32 = $vls_dec_bits ==? 13'b010_110_0100111; // Concatenate all stores into 1 instruction for our purposes
         $is_vsse64 = $vls_dec_bits ==? 13'b010_111_0100111;
         
         //Indexed
         //orderes
         $is_vsoxei8  = $vls_dec_bits ==? 13'b011_000_0100111;
         $is_vsoxei16 = $vls_dec_bits ==? 13'b011_101_0100111; // Concatenate all loads into 1 instruction for our purposes
         $is_vsoxei32 = $vls_dec_bits ==? 13'b011_110_0100111; // Concatenate all stores into 1 instruction for our purposes
         $is_vsoxei64 = $vls_dec_bits ==? 13'b011_111_0100111;
         
         
      /*
      @3
         //ALU and output selection
         //first code partial results for sltu and sltiu instrs
         $sltu_rslt[31:0]  = $is_sltu  ? ($src1_value < $src2_value) : 0;
         $sltiu_rslt[31:0] = $is_sltiu ? ($src1_value < $imm) : 0; 
         
         //now code the final results based on intructions type (notice the diff for slt & slti)
         $result[31:0] = $is_addi ? $src1_value + $imm :
                         $is_add  ? $src1_value + $src2_value :
                         $is_andi ? $src1_value & $imm :
                         $is_ori  ? $src1_value | $imm :
                         $is_xori ? $src1_value ^ $imm :
                         $is_slli ? $src1_value << $imm[5:0] :
                         $is_srli ? $src1_value >> $imm[5:0] :
                         $is_and  ? $src1_value & $src2_value :
                         $is_or   ? $src1_value | $src2_value :
                         $is_xor  ? $src1_value ^ $src2_value :
                         $is_sub  ? $src1_value - $src2_value :
                         $is_sll  ? $src1_value << $src2_value[4:0] :
                         $is_srl  ? $src1_value >> $src2_value[4:0] : 
                         $is_sltu ? $sltu_rslt :
                         $is_sltiu ? $sltiu_rslt :
                         $is_lui ? {$imm[31:12], 12'd0} :
                         $is_auipc ? $pc + $imm :
                         $is_jal ? $pc + 32'd4 :
                         $is_jalr ? $pc + 32'd4 :
                         $is_sra ? { {32{$src1_value[31]}}, $src1_value} >> $src2_value[4:0] :
                         $is_srai ? { {32{$src1_value[31]}}, $src1_value} >> $imm[4:0] :
                         $is_slt ? ($src1_value[31] == $src2_value[31]) ? $sltu_rslt : {31'b0, $src1_value[31]} :
                         $is_slti ? ($src1_value[31] == $imm[31]) ? $sltiu_rslt : {31'b0, $src1_value[31]} :
                         //For loads and stores, compute the result(address)
                         ($is_load || $is_store) ? $src1_value + $imm : //this is same as addi and calculates the address of the load/store
                         32'b0; // default
                         
         //Change $valid logic to incorporate branches, loads and jumps
         //Nullify previously created $valid
         $valid = !(>>1$valid_taken_br || >>2$valid_taken_br || >>1$valid_load || >>2$valid_load);
         
         //Branch control 
         $taken_br = $is_beq ? $beq :
                     $is_bne ? $bne :
                     $is_bltu ? $bltu :
                     $is_bgeu ? $bgeu :
                     $is_blt ? $blt :
                     $is_bge ? $bge :
                     1'b0; //default
         
         $valid_taken_br = $taken_br && $valid; //added valid for NOPs
         
         //JALR PC calc - based on obtained $src1_value
         $jalr_tgt_pc[31:0] = $src1_value + $imm;
         //Check the flow of code - it seems sequential; could lead to potential problems           
         //Rf write
         // Dealing with RAW dependence through Forwarding
         //$rd_valid = $rd == 5'd0 ? 0 : 1;
         $rf_wr_en = (($rd_valid && $rd != 5'd0 && $valid) || >>2$valid_load); //$valid added for NOPS
                     
         //$rf_wr_index[4:0] = $rf_wr_en ? >>2$valid_load ? >>2$rd : $rd : 0; // previous incorrect logic
         $rf_wr_index[4:0] = $rf_wr_en ? !$valid ? >>2$rd : $rd : 0; // modified correct logic
         //modified to accomodate load instruction - defined the load address from when load instr occured (2 cycles earlier)
                  
         //$rf_wr_data[31:0] = $rf_wr_en ? >>2$result : 0; //my logic
         //$rf_wr_data[31:0] = $rf_wr_en ? $result : 0; //modified logic - this is correct if NO ld/str
         //New logic to accmodate load/store
         // Perform write of ld_data into RF after waiting for cycles after we go to mem to fetch ld_data
         // to wait for the ld_data to be returned from data cache 
         $rf_wr_data[31:0] = $rf_wr_en ? !$valid ? >>2$ld_data[31:0] : $result : 0;
         
         
         //Load control 
         $valid_load = $valid && $is_load;
         //$valid_store = $valid && $is_store; 
         $valid_store = $valid && $is_s_instr;
         
         $valid_jump = $valid && ($is_jal || $is_jalr);
      
      */
      
      /*
      @4
         //Load/Store data memory interface connections //Come back again to gain clairy
         //Dmem is only either 1R or 1W per cycle
         //Read
         $dmem_rd_en = $valid_load;
                       
                       
         //$dmem_addr[3:0] = $valid_load ? $result[5:2] : 0; //The output of result[31:0] on a valid_load
                                                           //generates the address of the data memory to be read
                                                   // In this case, only the lower 4 bits are needed, since the memory has only 16 entries
         $dmem_addr[3:0] = $result[5:2]; // modified
         //Write 
         //$dmem_wr_en = $valid_store; 
         $dmem_wr_en = $valid && $is_s_instr; // modified
                      
         $dmem_wr_data[31:0] = $src2_value[31:0]; //Store gets value from second operand
                       
          
      @5
         $ld_data[31:0] = $dmem_rd_data; 
        
       */  
      // Note: Because of the magic we are using for visualisation, if visualisation is enabled below,
      //       be sure to avoid having unassigned signals (which you might be using for random inputs)
      //       other than those specifically expected in the labs. You'll get strange errors for these.
      
   //BOGUS USE to suppress warnings
   /*
   `BOGUS_USE($rd $rd_valid $rs1 $rs1_valid $rs2 $rs2_valid $instr $is_r_instr
              $is_i_instr $is_s_instr $is_b_instr $is_u_instr $is_j_instr
              $funct3 $funct7 $funct3_valid $funct7_valid $imm_valid $result
              $is_bge $is_bltu $is_bgeu $is_beq $is_bne $is_blt $is_addi $is_add
              $src1_value $src2_value $result
              $beq $bne $blt $bge $bltu $bgeu
              $taken_br $br_tgt_pc);
   */   
   
   //TB to check pass/fail by monitoring value in x10(r10) at the end of simulation
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 40;
   //*passed = |cpu/xreg[15]>>5$value == (1+2+3+4+5+6+7+8+9);
   *failed = 1'b0;
   
   // Macro instantiations for:
   //  o instruction memory
   //  o register file
   //  o data memory
   //  o CPU visualization
   |cpu
      m4+imem(@1)    // Args: (read stage) //Instruction mem in @1
      
      //m4+rf(@2, @3)  // Args: (read stage, write stage) - if equal, no register bypass is required
      //m4+dmem(@4)    // Args: (read/write stage)
   
   m4+cpu_viz(@4)    // For visualisation, argument should be at least equal to the last stage of CPU logic. @4 would work for all labs.
\SV
   endmodule
