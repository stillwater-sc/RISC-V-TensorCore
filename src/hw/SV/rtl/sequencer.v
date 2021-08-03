// Code your design here
`include "tc_sram.sv"
`include "fifo_queue.sv"
`include "valu.sv"

module sequencer (
  input logic clk,
  input logic nrst,
  
  //seq to decoder interface
  output logic vseq_busy, // busy if fetching data from VRF (i.e if VRF is also busy)
  //
  input logic[4:0] vs1,
  input logic[4:0] vs2,
  input logic[4:0] vd,
  input logic[2:0] lmul,
  input logic[2:0] vsew,
  input logic[31:0] vl, //Defined as lmul * VLEN/vsew
  input logic[15:0] var_dec_bits, //Defined as {$funct6, $funct3, $opcode};
  
  //input logic[31:0] ld_data, // to fill the sram with random values to test the sequencer
  input int ld_data,
  input bit rw_done,
  input bit w_done,
  //input logic[3:0] vwe // write en for sram
  output logic[2:0] vid
);
  
  //seq to VRF Interface
  logic[3:0][7:0] vrf_addr1; //logic[4:0] for 4 banks; next[4:0] for addr width
  logic[3:0][7:0] vrf_addr2;
  logic[3:0][7:0] vrfd_addr;
  logic [3:0][31:0] inData;
  logic [3:0][31:0] outDataA;
  logic [3:0][31:0] outDataB;
  logic[3:0]vre;
  logic[3:0]vwe;
  
  logic[31:0] srcA_ele; //output from VRF, input to VALU
  logic[31:0] srcB_ele;
  
  //VRF Write State Machine
  localparam	OS0 = 4'd0,
  				OS1 = 4'd1,
  				OS2 = 4'd2,
  				OS3 = 4'd3,
  				OS4 = 4'd4,
  				OS5	= 4'd5,
  				OS6 = 4'd6,
  				OS7 = 4'd7,
  				OS8 = 4'd8;
  
  localparam	IS0 = 4'd0,
  				IS1	= 4'd1,
  				IS2 = 4'd2,
  				IS3 = 4'd3,
  				IS4	= 4'd4;
  
  //VRF Read State Machine
  localparam	ROS0 = 4'd0,
  				ROS1 = 4'd1,
  				ROS2 = 4'd2,
  				ROS3 = 4'd3,
  				ROS4 = 4'd4,
  				ROS5 = 4'd5,
  				ROS6 = 4'd6,
  				ROS7 = 4'd7,
  				ROS8 = 4'd8;
  
  localparam	RIS0 = 4'd0,
  				RIS1 = 4'd1,
  				RIS2 = 4'd2,
  				RIS3 = 4'd3,
  				RIS4 = 4'd4;
  
  logic[3:0] OCS, ONS;
  logic[3:0] ICS, INS;
      
  logic[3:0] ROCS, RONS;
  logic[3:0] RICS, RINS;
  //bit hold, hold_q;
  //logic[4:0] saddr1, saddr2;			
  
  //Seq to VALU signals
  logic[2:0]  vfu_id;
  logic[8:0]  valu_op;
  
  //Sequencer to Queue to ALU
  logic[31:0] Vin_A;
  logic[31:0] Vin_B;
  logic[31:0] result; // to be put in output queue 
  
  logic[31:0] rq_out; // output of result queue
  
  //
  assign valu_op = !nrst ? 9'd0 : var_dec_bits[15:7]; // {funct6, funct3}
  assign vid = !nrst ? 'd0 : vfu_id; 
  
  /*
  logic[3:0]i_cntr; //use counters instead of loops // loops don't work as per expectation
  logic[7:0]j_cntr;
  logic[3:0] addr_iter;
  */
  
  //Decoder to VRF logic
  
  
  always_ff @(posedge clk, negedge nrst) begin
    if(!nrst) begin
      //vrf_addr1 <= '0;
      //vrf_addr2 <= '0;
      //vre		<= '0;
      //vwe		<= '0;
      vseq_busy	<= '0;
      OCS		<= OS0;
      ICS		<= IS0;
      ROCS		<= ROS0;
      RICS		<= RIS0;
      //hold_q	<= 0;
      //i_cntr	<= '0;
      //j_cntr	<= '0;
      //addr_iter	<= '0;
    end
    
    else begin
      if(vfu_id[2] == 1'b1) begin // need not enable vwe if not load // or a writeback (take care of this later)
        ROCS		<= RONS;
      	RICS		<= RINS;
      end
      
      
      // Load logic to test sequencer
      else if(vfu_id[0] == 1'b1) begin //enable to load into SRAM
       	OCS	<= ONS;
        ICS	<= INS;
        //hold_q	<= hold;
      end
                  
      else //code LD/STR logic here
        vseq_busy <= 1'b0;
    end
  end
 
  //VRF State Sequence
  //Write FSM
  always_comb begin
    ONS = OCS;
    //vwe = 3'd0;
    case(OCS)
      OS0	: begin
        INS = ICS;
        
        case(ICS)
          IS0	: begin
            vwe				= 4'd1;
            vrfd_addr[0] 	= vd + OS0;
            inData[0]	 	= ld_data + OS0;
            INS				= IS1;
          end
          
          IS1	: begin
            vwe 			= 4'd2;
            vrfd_addr[1]	= vd + OS0;
            inData[1]		= ld_data + OS0;
            INS				= IS2;
          end
          
          IS2	: begin
            vwe				= 4'd4;
            vrfd_addr[2]	= vd + OS0;
            inData[2]		= ld_data + OS0;
            INS				= IS3;
          end
          
          IS3 	: begin
            vwe				= 4'd8;
            vrfd_addr[3]	= vd + OS0;
            inData[3]		= ld_data + OS0;
            INS				= IS4;
            
          end
          
          IS4 : begin
            vwe				= 4'd0;
            vrfd_addr		= 'd0;
          end
          
        endcase
        if(ICS == IS4) begin
          ONS		=	OS1;
          INS		=   IS0;
          //vwe		= 	4'd0;
          //vrfd_addr	= 	'd0;
          //hold		= 	0;
        end        
        else
          ONS 		= 	ONS;
      end
      
      OS1	: begin
        INS = ICS;
        //vwe = 3'd0;
        vrfd_addr = 'd0;
        case(ICS)
          IS0	: begin
            vwe				= 4'd1;
            vrfd_addr[0] 	= vd + OS1;
            inData[0]	 	= ld_data;
            INS				= IS1;
          end
          
          IS1	: begin
            vwe 			= 4'd2;
            vrfd_addr[1]	= vd + OS1;
            inData[1]		= ld_data;
            INS				= IS2;
          end
          
          IS2	: begin
            vwe				= 4'd4;
            vrfd_addr[2]	= vd + OS1;
            inData[2]		= ld_data;
            INS				= IS3;
          end
          
          IS3 	: begin
            vwe				= 4'd8;
            vrfd_addr[3]	= vd + OS1;
            inData[3]		= ld_data;
            INS				= IS4;
          end
          
          IS4 : begin
            vwe				= 4'd0;
           	vrfd_addr		= 'd0;
          end
        endcase
        
        if(ICS == IS4) begin
          ONS		=	OS2;
          INS		=   IS0;
        end        
        else
          ONS 		= 	ONS;
      end
      
      OS2	: begin
        INS = ICS;
       // vwe = 3'd0;
       // vrfd_addr = 'd0;
        case(ICS)
          IS0	: begin
            vwe				= 4'd1;
            vrfd_addr[0] 	= vd + OS2;
            inData[0]	 	= ld_data ;
            INS				= IS1;
          end
          
          IS1	: begin
            vwe 			= 4'd2;
            vrfd_addr[1]	= vd + OS2;
            inData[1]		= ld_data ;
            INS				= IS2;
          end
          
          IS2	: begin
            vwe				= 4'd4;
            vrfd_addr[2]	= vd + OS2;
            inData[2]		= ld_data ;
            INS				= IS3;
          end
          
          IS3 	: begin
            vwe				= 4'd8;
            vrfd_addr[3]	= vd + OS2;
            inData[3]		= ld_data ;
            INS				= IS4;
          end
          IS4 : begin
            vwe				= 4'd0;
            vrfd_addr		= 'd0;
          end
        endcase
        if(ICS == IS4) begin
          ONS		=	OS3;
          INS		=   IS0;
        end        
        else
          ONS 		= 	ONS;
      end
      
      OS3	: begin
        INS = ICS;
       // vwe = 3'd0;
        //vrfd_addr = 'd0;
        case(ICS)
          IS0	: begin
            vwe				= 4'd1;
            vrfd_addr[0] 	= vd + OS3;
            inData[0]	 	= ld_data ;
            INS				= IS1;
          end
          
          IS1	: begin
            vwe 			= 4'd2;
            vrfd_addr[1]	= vd + OS3;
            inData[1]		= ld_data ;
            INS				= IS2;
          end
          
          IS2	: begin
            vwe				= 4'd4;
            vrfd_addr[2]	= vd + OS3;
            inData[2]		= ld_data ;
            INS				= IS3;
          end
          
          IS3 	: begin
            vwe				= 4'd8;
            vrfd_addr[3]	= vd + OS3;
            inData[3]		= ld_data ;
            INS				= IS4;
          end
          
          IS4 : begin
            vwe				= 4'd0;
            vrfd_addr		= 'd0;
            end
          
        endcase
        if(ICS == IS4) begin
          ONS		=	OS4;
          INS		=   IS0;
        end        
        else
          ONS 		= 	ONS;
      end
      
      OS4	: begin
        
        INS = ICS;
        //vwe = 3'd0;
        //vrfd_addr = 'd0;
        case(ICS)
          IS0	: begin
            vwe				= 4'd1;
            vrfd_addr[0] 	= vd + OS4;
            inData[0]	 	= ld_data ;
            INS				= IS1;
          end
          
          IS1	: begin
            vwe 			= 4'd2;
            vrfd_addr[1]	= vd + OS4;
            inData[1]		= ld_data ;
            INS				= IS2;
          end
          
          IS2	: begin
            vwe				= 4'd4;
            vrfd_addr[2]	= vd + OS4;
            inData[2]		= ld_data ;
            INS				= IS3;
          end
          
          IS3 	: begin
            vwe				= 4'd8;
            vrfd_addr[3]	= vd + OS4;
            inData[3]		= ld_data ;
            INS				= IS4;
          end
          
          IS4 : begin
            vwe				= 4'd0;
            vrfd_addr		= 'd0;
          end
        endcase
        if(ICS == IS4) begin
          ONS		=	OS5;
          INS		=   IS0;
        end        
        else
          ONS 		= 	ONS;
      end
      
      OS5	: begin
        
        INS = ICS;
        //vwe = 3'd0;
        //vrfd_addr = 'd0;
        case(ICS)
          IS0	: begin
            vwe				= 4'd1;
            vrfd_addr[0] 	= vd + OS5;
            inData[0]	 	= ld_data ;
            INS				= IS1;
          end
          
          IS1	: begin
            vwe 			= 4'd2;
            vrfd_addr[1]	= vd + OS5;
            inData[1]		= ld_data ;
            INS				= IS2;
          end
          
          IS2	: begin
            vwe				= 4'd4;
            vrfd_addr[2]	= vd + OS5;
            inData[2]		= ld_data ;
            INS				= IS3;
          end
          
          IS3 	: begin
            vwe				= 4'd8;
            vrfd_addr[3]	= vd + OS5;
            inData[3]		= ld_data ;
            INS				= IS4;
          end
          
          IS4 : begin
            vwe				= 4'd0;
            vrfd_addr		= 'd0;
          end
        endcase
        if(ICS == IS4) begin
          ONS		=	OS6;
          INS		=   IS0;
        end        
        else
          ONS 		= 	ONS;
      end
      
      OS6	: begin
        
        INS = ICS;
        //vwe = 3'd0;
        //vrfd_addr = 'd0;
        case(ICS)
          IS0	: begin
            vwe				= 4'd1;
            vrfd_addr[0] 	= vd + OS6;
            inData[0]	 	= ld_data ;
            INS				= IS1;
          end
          
          IS1	: begin
            vwe 			= 4'd2;
            vrfd_addr[1]	= vd + OS6;
            inData[1]		= ld_data ;
            INS				= IS2;
          end
          
          IS2	: begin
            vwe				= 4'd4;
            vrfd_addr[2]	= vd + OS6;
            inData[2]		= ld_data ;
            INS				= IS3;
          end
          
          IS3 	: begin
            vwe				= 4'd8;
            vrfd_addr[3]	= vd + OS6;
            inData[3]		= ld_data ;
            INS				= IS4;
          end
          
          IS4 : begin
            vwe				= 4'd0;
           	vrfd_addr		= 'd0;
          end
        endcase
        if(ICS == IS4) begin
          ONS		=	OS7;
          INS		=   IS0;
        end        
        else
          ONS 		= 	ONS;
      end
      
      OS7	: begin
        
        INS = ICS;
        //vwe = 3'd0;
       // vrfd_addr = 'd0;
        case(ICS)
          IS0	: begin
            vwe				= 4'd1;
            vrfd_addr[0] 	= vd + OS7;
            inData[0]	 	= ld_data ;
            INS				= IS1;
          end
          
          IS1	: begin
            vwe 			= 4'd2;
            vrfd_addr[1]	= vd + OS7;
            inData[1]		= ld_data ;
            INS				= IS2;
          end
          
          IS2	: begin
            vwe				= 4'd4;
            vrfd_addr[2]	= vd + OS7;
            inData[2]		= ld_data ;
            INS				= IS3;
          end
          
          IS3 	: begin
            vwe				= 4'd8;
            vrfd_addr[3]	= vd + OS7;
            inData[3]		= ld_data ;
            INS				= IS4;
          end
          
          IS4 : begin
            vwe				= 4'd0;
            vrfd_addr		= 'd0;
          end
        endcase
        
        
        if(ICS == IS4) begin
          ONS		=	OS8;
          INS		=   IS0;
        end        
        else
          ONS 		= 	ONS;
      end
      
      OS8	: 	begin
        //INS = ICS;
        if(rw_done == 0) begin
          ONS		=	OS0;
          INS		=   IS0;
        end   
        
        else begin
          ONS		=   ONS;
          INS		=   INS;
          vwe		=   'd0;
        end
      end  
    endcase
  end
  
  
  //READ FSM
  always_comb begin
    RONS = ROCS;
    //vwe = 3'd0;
    case(ROCS)
      ROS0	: begin
        RINS = RICS;
        
        case(RICS)
          RIS0	: begin
            vre				= 4'd1;
            vrf_addr1[0] 	= vs1 + ROS0;
            vrf_addr2[0] 	= vs2 + ROS0;
            srcA_ele		= outDataA[0];
	    	srcB_ele		= outDataB[0];
            RINS			= RIS1;
          end
          
          RIS1	: begin
            vre				= 4'd2;
            vrf_addr1[1] 	= vs1 + ROS0;
            vrf_addr2[1] 	= vs2 + ROS0;
            srcA_ele		= outDataA[1];
            srcB_ele		= outDataB[1];
            RINS				= RIS2;
          end
          
          RIS2	: begin
            vre			= 4'd4;
            vrf_addr1[2] 	= vs1 + ROS0;
            vrf_addr2[2] 	= vs2 + ROS0;
            srcA_ele		= outDataA[2];
            srcB_ele		= outDataB[2];
            RINS				= RIS3;
          end
          
          RIS3 	: begin
            vre			= 4'd8;
            vrf_addr1[3] 	= vs1 + ROS0;
            vrf_addr2[3] 	= vs2 + ROS0;
            srcA_ele		= outDataA[3];
            srcB_ele		= outDataB[3];
            RINS			= RIS4;
            
          end
          
          RIS4 : begin
            vre			= 4'd0;
            vrf_addr1	= 'd0;
            vrf_addr2	= 'd0;
          end
          
        endcase
        if(RICS == RIS4) begin
          RONS		=   ROS1;
          RINS		=   RIS0;
          //vwe		= 	4'd0;
          //vrfd_addr	= 	'd0;
          //hold		= 	0;
        end        
        else
          RONS 		= 	RONS;
      end
      
      ROS1	: begin
        RINS = RICS;
        //vwe = 3'd0;
        //vrfd_addr = 'd0;
                
        case(RICS)
          RIS0	: begin
            vre			= 4'd1;
            vrf_addr1[0] 	= vs1 + ROS1;
            vrf_addr2[0] 	= vs2 + ROS1;
            srcA_ele		= outDataA[0];
	    	srcB_ele		= outDataB[0];
            RINS				= RIS1;
          end
          
          RIS1	: begin
            vre			= 4'd2;
            vrf_addr1[1] 	= vs1 + ROS1;
            vrf_addr2[1] 	= vs2 + ROS1;
            srcA_ele		= outDataA[1];
            srcB_ele		= outDataB[1];
            RINS				= RIS2;
          end
          
          RIS2	: begin
            vre			= 4'd4;
            vrf_addr1[2] 	= vs1 + ROS1;
            vrf_addr2[2] 	= vs2 + ROS1;
            srcA_ele		= outDataA[2];
            srcB_ele		= outDataB[2];
            RINS				= RIS3;
          end
          
          RIS3 	: begin
            vre			= 4'd8;
            vrf_addr1[3] 	= vs1 + ROS1;
            vrf_addr2[3] 	= vs2 + ROS1;
            srcA_ele		= outDataA[3];
            srcB_ele		= outDataB[3];
            RINS			= RIS4;
            
          end
          
          RIS4 : begin
            vre			= 4'd0;
            vrf_addr1	= 'd0;
            vrf_addr2	= 'd0;
          end
                      
        endcase
        if(RICS == RIS4) begin
          RONS		=	ROS2;
          RINS		=   RIS0;
        end        
        else
          RONS 		= 	RONS;
      end
      
      ROS2	: begin
        RINS = RICS;
       // vwe = 3'd0;
       // vrfd_addr = 'd0;
        
        case(RICS)
          RIS0	: begin
            vre			= 4'd1;
            vrf_addr1[0] 	= vs1 + ROS2;
            vrf_addr2[0] 	= vs2 + ROS2;
            srcA_ele		= outDataA[0];
	    	srcB_ele		= outDataB[0];
            RINS				= RIS1;
          end
          
          RIS1	: begin
            vre			= 4'd2;
            vrf_addr1[1] 	= vs1 + ROS2;
            vrf_addr2[1] 	= vs2 + ROS2;
            srcA_ele		= outDataA[1];
            srcB_ele		= outDataB[1];
            RINS				= RIS2;
          end
          
          RIS2	: begin
            vre			= 4'd4;
            vrf_addr1[2] 	= vs1 + ROS2;
            vrf_addr2[2] 	= vs2 + ROS2;
            srcA_ele		= outDataA[2];
            srcB_ele		= outDataB[2];
            RINS				= RIS3;
          end
          
          RIS3 	: begin
            vre			= 4'd8;
            vrf_addr1[3] 	= vs1 + ROS2;
            vrf_addr2[3] 	= vs2 + ROS2;
            srcA_ele		= outDataA[3];
            srcB_ele		= outDataB[3];
            RINS			= RIS4;
            
          end
          
          RIS4 : begin
            vre			= 4'd0;
            vrf_addr1	= 'd0;
            vrf_addr2	= 'd0;
          end
                      
        endcase
        if(RICS == RIS4) begin
          RONS		=	ROS3;
          RINS		=   RIS0;
        end        
        else
          RONS 		= 	RONS;
      end
      
      ROS3	: begin
        RINS = RICS;
       // vwe = 3'd0;
        //vrfd_addr = 'd0;
        
        case(RICS)
          RIS0	: begin
            vre			= 4'd1;
            vrf_addr1[0] 	= vs1 + ROS3;
            vrf_addr2[0] 	= vs2 + ROS3;
            srcA_ele		= outDataA[0];
	    	srcB_ele		= outDataB[0];
            RINS				= RIS1;
          end
          
          RIS1	: begin
            vre			= 4'd2;
            vrf_addr1[1] 	= vs1 + ROS3;
            vrf_addr2[1] 	= vs2 + ROS3;
            srcA_ele		= outDataA[1];
            srcB_ele		= outDataB[1];
            RINS				= RIS2;
          end
          
          RIS2	: begin
            vre			= 4'd4;
            vrf_addr1[2] 	= vs1 + ROS3;
            vrf_addr2[2] 	= vs2 + ROS3;
            srcA_ele		= outDataA[2];
            srcB_ele		= outDataB[2];
            RINS				= RIS3;
          end
          
          RIS3 	: begin
            vre			= 4'd8;
            vrf_addr1[3] 	= vs1 + ROS3;
            vrf_addr2[3] 	= vs2 + ROS3;
            srcA_ele		= outDataA[3];
            srcB_ele		= outDataB[3];
            RINS			= RIS4;
            
          end
          
          RIS4 : begin
            vre			= 4'd0;
            vrf_addr1	= 'd0;
            vrf_addr2	= 'd0;
          end
                      
        endcase
        if(RICS == RIS4) begin
          RONS		=	ROS4;
          RINS		=   RIS0;
        end        
        else
          RONS 		= 	RONS;
      end
      
      ROS4	: begin
        
        RINS = RICS;
        //vwe = 3'd0;
        //vrfd_addr = 'd0;
        
        case(RICS)
          RIS0	: begin
            vre			= 4'd1;
            vrf_addr1[0] 	= vs1 + ROS4;
            vrf_addr2[0] 	= vs2 + ROS4;
            srcA_ele		= outDataA[0];
	    	srcB_ele		= outDataB[0];
            RINS				= RIS1;
          end
          
          RIS1	: begin
            vre			= 4'd2;
            vrf_addr1[1] 	= vs1 + ROS4;
            vrf_addr2[1] 	= vs2 + ROS4;
            srcA_ele		= outDataA[1];
            srcB_ele		= outDataB[1];
            RINS				= RIS2;
          end
          
          RIS2	: begin
            vre			= 4'd4;
            vrf_addr1[2] 	= vs1 + ROS4;
            vrf_addr2[2] 	= vs2 + ROS4;
            srcA_ele		= outDataA[2];
            srcB_ele		= outDataB[2];
            RINS				= RIS3;
          end
          
          RIS3 	: begin
            vre			= 4'd8;
            vrf_addr1[3] 	= vs1 + ROS4;
            vrf_addr2[3] 	= vs2 + ROS4;
            srcA_ele		= outDataA[3];
            srcB_ele		= outDataB[3];
            RINS			= RIS4;
            
          end
          
          RIS4 : begin
            vre			= 4'd0;
            vrf_addr1	= 'd0;
            vrf_addr2	= 'd0;
          end
                      
        endcase
        if(RICS == RIS4) begin
          RONS		=	ROS5;
          RINS		=   RIS0;
        end        
        else
          RONS 		= 	RONS;
      end
      
      ROS5	: begin
        
        RINS = RICS;
        //vwe = 3'd0;
        //vrfd_addr = 'd0;
        case(RICS)
          RIS0	: begin
            vre			= 4'd1;
            vrf_addr1[0] 	= vs1 + ROS5;
            vrf_addr2[0] 	= vs2 + ROS5;
            srcA_ele		= outDataA[0];
	    	srcB_ele		= outDataB[0];
            RINS				= RIS1;
          end
          
          RIS1	: begin
            vre			= 4'd2;
            vrf_addr1[1] 	= vs1 + ROS5;
            vrf_addr2[1] 	= vs2 + ROS5;
            srcA_ele		= outDataA[1];
            srcB_ele		= outDataB[1];
            RINS				= RIS2;
          end
          
          RIS2	: begin
            vre			= 4'd4;
            vrf_addr1[2] 	= vs1 + ROS5;
            vrf_addr2[2] 	= vs2 + ROS5;
            srcA_ele		= outDataA[2];
            srcB_ele		= outDataB[2];
            RINS				= RIS3;
          end
          
          RIS3 	: begin
            vre			= 4'd8;
            vrf_addr1[3] 	= vs1 + ROS5;
            vrf_addr2[3] 	= vs2 + ROS5;
            srcA_ele		= outDataA[3];
            srcB_ele		= outDataB[3];
            RINS			= RIS4;
            
          end
          
          RIS4 : begin
            vre			= 4'd0;
            vrf_addr1	= 'd0;
            vrf_addr2	= 'd0;
          end
                      
        endcase
        if(RICS == RIS4) begin
          RONS		=	ROS6;
          RINS		=   RIS0;
        end        
        else
          RONS 		= 	RONS;
      end
      
      ROS6	: begin
        
        RINS = RICS;
        //vwe = 3'd0;
        //vrfd_addr = 'd0;
        
        case(RICS)
          RIS0	: begin
            vre			= 4'd1;
            vrf_addr1[0] 	= vs1 + ROS6;
            vrf_addr2[0] 	= vs2 + ROS6;
            srcA_ele		= outDataA[0];
	    	srcB_ele		= outDataB[0];
            RINS				= RIS1;
          end
          
          RIS1	: begin
            vre			= 4'd2;
            vrf_addr1[1] 	= vs1 + ROS6;
            vrf_addr2[1] 	= vs2 + ROS6;
            srcA_ele		= outDataA[1];
            srcB_ele		= outDataB[1];
            RINS				= RIS2;
          end
          
          RIS2	: begin
            vre			= 4'd4;
            vrf_addr1[2] 	= vs1 + ROS6;
            vrf_addr2[2] 	= vs2 + ROS6;
            srcA_ele		= outDataA[2];
            srcB_ele		= outDataB[2];
            RINS				= RIS3;
          end
          
          RIS3 	: begin
            vre			= 4'd8;
            vrf_addr1[3] 	= vs1 + ROS6;
            vrf_addr2[3] 	= vs2 + ROS6;
            srcA_ele		= outDataA[3];
            srcB_ele		= outDataB[3];
            RINS			= RIS4;
            
          end
          
          RIS4 : begin
            vre			= 4'd0;
            vrf_addr1	= 'd0;
            vrf_addr2	= 'd0;
          end
                      
        endcase
        if(RICS == RIS4) begin
          RONS		=	ROS7;
          RINS		=   RIS0;
        end        
        else
          RONS 		= 	RONS;
      end
      
      ROS7	: begin
        
        RINS = RICS;
        //vwe = 3'd0;
       // vrfd_addr = 'd0;
        
        case(RICS)
          RIS0	: begin
            vre			= 4'd1;
            vrf_addr1[0] 	= vs1 + ROS7;
            vrf_addr2[0] 	= vs2 + ROS7;
            srcA_ele		= outDataA[0];
	    	srcB_ele		= outDataB[0];
            RINS				= RIS1;
          end
          
          RIS1	: begin
            vre			= 4'd2;
            vrf_addr1[1] 	= vs1 + ROS7;
            vrf_addr2[1] 	= vs2 + ROS7;
            srcA_ele		= outDataA[1];
            srcB_ele		= outDataB[1];
            RINS				= RIS2;
          end
          
          RIS2	: begin
            vre			= 4'd4;
            vrf_addr1[2] 	= vs1 + ROS7;
            vrf_addr2[2] 	= vs2 + ROS7;
            srcA_ele		= outDataA[2];
            srcB_ele		= outDataB[2];
            RINS				= RIS3;
          end
          
          RIS3 	: begin
            vre			= 4'd8;
            vrf_addr1[3] 	= vs1 + ROS7;
            vrf_addr2[3] 	= vs2 + ROS7;
            srcA_ele		= outDataA[3];
            srcB_ele		= outDataB[3];
            RINS			= RIS4;
            
          end
          
          RIS4 : begin
            vre			= 4'd0;
            vrf_addr1	= 'd0;
            vrf_addr2	= 'd0;
          end
                      
        endcase
        
        
        if(RICS == RIS4) begin
          RONS		=	ROS8;
          RINS		=   RIS0;
        end        
        else
          RONS 		= 	RONS;
      end
      
      ROS8	: 	begin
        RINS = RICS;
        if(w_done == 0) begin
          RONS		=	ROS0;
          RINS		=   RIS0;
        end   
        
        else begin
          RONS		=   RONS;
          RINS		=   RINS;
        end
      end  
    endcase
  end
  
  
 //SRAM DUT Connection     
    tc_sram #(
    .NumWords('d1024), // Total  elements - (VRs * elementperVR)
    .NumBanks('d4),	   // banks
    .WordsPerBank('d256), //NumWords/NumBanks
    .DataWidth('d32),  // Data signal width
    
    .AddrWidth('d8) //$clog2(WordsPerBank)
  )
  sram_dut0(
    .clk(clk),      // Clock
    .nrst(nrst),     // Asynchronous reset active low
    .re(vre),
    .we(vwe),
    .waddr(vrfd_addr),    // request address
    .raddr1(vrf_addr1),
    .raddr2(vrf_addr2),
    .wdata(inData),    // write data to be defined later
    .rdataA(outDataA),
    .rdataB(outDataB)
  );
  
  //Queue Connections
  fifo_queue fq1 (
    .clk(clk),
    .nrst(nrst),
    .write(1'b1), // always write if queue is not full 
    .read(1'b1), // always read new values from queue (to VALU)
    .rdata(Vin_A),
    .wdata(srcA_ele),
    .full(/* */),
    .empty(/* */)
  );
  
  fifo_queue fq2(
    .clk(clk), 
    .nrst(nrst),
    .write(1'b1),
    .read(1'b1),
    .rdata(Vin_B),
    .wdata(srcB_ele),
    .full(/* */),
    .empty(/* */)
  );
  
  
  //Decoding to VRF Logic
  
 // assign vl_cnt = vl;
 // assign s_cnt	= vl;
  
  //enabling the VFU
  always_ff @(posedge clk, negedge nrst) begin
    if(!nrst)
      vfu_id = 3'b000;
    else if(var_dec_bits[6:0] == 7'b0000111)
      vfu_id = 3'b001; //LD VFU enabled
    else if (var_dec_bits[6:0] == 7'b0100111)
      vfu_id = 3'b010; //ST VFU enabled
    else if (var_dec_bits[6:0] == 7'b1010111 && var_dec_bits[9:7] != 3'b111)
      vfu_id = 3'b100; // VALU enabled
    else
      vfu_id = 3'b000;
  end
  
  
  //VV vs VS input to ALU
  // Only fetch element 0 from VRF if the instruction is vector scalar operation
  // Pass that element to all 32 inB values to VALU to add/mul with each of 32 elements (inA values) in a VS operation
  //assign Vin_A 
  //Seq to Queue to VFU logic
  valu v_alu(
    .nrst(nrst),
    .valu_en(vfu_id[2]),
    .inA(Vin_A),
    .inB(Vin_B),
    .op(valu_op),
    .out_res(result)
  );
  
  //Output queue
  fifo_queue fq_out (
    .clk(clk),
    .nrst(nrst),
    .write(1'b1), // always write if queue is not full 
    .read(/* */), // always read new values from queue (to VALU)
    .rdata(rq_out),
    .wdata(result),
    .full(/* */),
    .empty(/* */)
  );
    
endmodule  

  
  //************ XTRA *************** //
  
  /*
        j_cntr <= 8'b1;
        if((j_cntr[0] ^ j_cntr[1] ^ j_cntr[2] ^ j_cntr[3] ^ j_cntr[4] ^ j_cntr[5] ^ j_cntr[6] ^ j_cntr[7])) begin 
          i_cntr <= 4'b0001;
          if((i_cntr[0] ^ i_cntr[1] ^ i_cntr[2] ^ i_cntr[3])) begin 
            vwe <= i_cntr;
            vrfd_addr[addr_iter] <= vd + addr_iter;
            vseq_busy	<= 1'b1; 
            i_cntr <= i_cntr << 1;
          end
          i_cntr <= 4'd0;
          j_cntr <= j_cntr << 1;
          addr_iter <= addr_iter + 1;
        end
        j_cntr <= 4'd0;
      end
      */
        /*
        for(int j = 0; j < 8; j++) begin
          for(int i = 0; i < 4; i++) begin
            vwe <= (1 << i);
            vrfd_addr[i][j] <= vd + addr_iter;
            vseq_busy <= 1'b1;
          end
          addr_iter <= addr_iter + 1;
          vwe <= '0;
        end
      */
      //end
  
  /*
        j_cntr <= 'd1;
        if(^j_cntr) begin // j = elements per bank = 32(no. of ele)/4 (no. of banks) in this case
          vre[i_cntr] <= 1'b1;
          if(^i_cntr) begin // i = no. of banks = 4 in this case
            //vre[i_cntr] <= 1'b1;
            vrf_addr1[addr_iter] <= vs1 + addr_iter; // for 1 vs1 value, we go through 8 vrf addresses in each of the 4 banks to access total 32 elements 
            vrf_addr2[addr_iter] <= vs2 + addr_iter;
            vseq_busy	<= 1'b1; //seq is busy can't accept new instructions from decoder until it is done with all 32 elements of previous instruction
            i_cntr <= i_cntr << 1;
          end
          i_cntr <= 3'd0;
          j_cntr <= j_cntr << 1;
        end
        j_cntr <= 4'd0;
        */
 

/*
  tc_sram #(
    .NumWords('d1024), // Total  elements - (VRs * elementperVR)
    .NumBanks('d4),	   // banks
    .WordsPerBank('d256), //NumWords/NumBanks
    .DataWidth('d32),  // Data signal width
    
    .AddrWidth('d8), //$clog2(WordsPerBank)
    .BankSel('d2) //	= $clog2(NumBanks)
  )
  sram_dut1(
    .clk(clk),      // Clock
    .nrst(nrst),     // Asynchronous reset active low
    .re[1](vre),
    .we[1](vwe),
    .waddr[1](vrfd_addr),    // request address
    .raddr1[1](vrf_addr1),
    .raddr2[1](vrf_addr2),
    .wdata[1](ld_data),    // write data to be defined later
    .rdataA[1](srcA_ele),
    .rdataB[1](srcB_ele)
  );
  
  tc_sram #(
    .NumWords('d1024), // Total  elements - (VRs * elementperVR)
    .NumBanks('d4),	   // banks
    .WordsPerBank('d256), //NumWords/NumBanks
    .DataWidth('d32),  // Data signal width
    
    .AddrWidth('d8), //$clog2(WordsPerBank)
    .BankSel('d2) //	= $clog2(NumBanks)
  )
  sram_dut2(
    .clk(clk),      // Clock
    .nrst(nrst),     // Asynchronous reset active low
    .re[2](vre),
    .we[2](vwe),
    .waddr[2](vrfd_addr),    // request address
    .raddr1[2](vrf_addr1),
    .raddr2[2](vrf_addr2),
    .wdata[2](ld_data),    // write data to be defined later
    .rdataA[2](srcA_ele),
    .rdataB[2](srcB_ele)
  );
  
  tc_sram #(
    .NumWords('d1024), // Total  elements - (VRs * elementperVR)
    .NumBanks('d4),	   // banks
    .WordsPerBank('d256), //NumWords/NumBanks
    .DataWidth('d32),  // Data signal width
    
    .AddrWidth('d8), //$clog2(WordsPerBank)
    .BankSel('d2) //	= $clog2(NumBanks)
  )
  sram_dut3(
    .clk(clk),      // Clock
    .nrst(nrst),     // Asynchronous reset active low
    .re[3](vre),
    .we[3](vwe),
    .waddr[3](vrfd_addr),    // request address
    .raddr1[3](vrf_addr1),
    .raddr2[3](vrf_addr2),
    .wdata[3](ld_data),    // write data to be defined later
    .rdataA[3](srcA_ele),
    .rdataB[3](srcB_ele)
  );
  
 */     
// *********************************************** //
