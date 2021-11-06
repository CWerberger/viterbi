module  pmu
      import viterbi_pkg::*; // wildcard import
    #(
        localparam tablelen = 60 
    ) 
    (
    input logic                  clk_i,
    input logic                  rst_ni,
    input logic                  flush,               

    input bm_array               bm0, 
    input bm_array               bm1,


    input logic 	         valid_i,  // trigger

    output logic [1:0]           valid_o,  
    output logic 	         data_out // 2 bmu needed for both states

                            
    );

    
    /*setup connections */

    pm_array                pm_ff,pm_next;
    temp_pm_array           pm_temp_wire;

    reg_ex_array            reg_ex_ff,reg_ex_next;

    pmMin_array             pm_min_ff,pm_min_next;
    integer                 count_input,pm_min_temp;

    logic [STATES_N-1:0]    min_idx_ff,min_idx_next;
    
    logic 	            valid_o_ff,valid_o_next;
    logic 		    output_bit;

    logic [0:31][11:0]      pmCand00,pmCand01,pmCand10,pmCand11;

    assign valid_o = valid_o_ff;

    // typedef logic [0 : STATES_N /   2 - 1] [PM_MAX_BITS - 1 : 0] stage_0;
    // typedef logic [0 : STATES_N /   4 - 1] [PM_MAX_BITS - 1 : 0] stage_1;
    // typedef logic [0 : STATES_N /   8 - 1] [PM_MAX_BITS - 1 : 0] stage_2;
    // typedef logic [0 : STATES_N /  16 - 1] [PM_MAX_BITS - 1 : 0] stage_3;
    // typedef logic [0 : STATES_N /  32 - 1] [PM_MAX_BITS - 1 : 0] stage_4;

    // stage_0 min_s0       ;
    // stage_0 idx_s0       ;
    // stage_1 min_s1       ;
    // stage_1 idx_s1       ;
    // stage_2 min_s2       ;
    // stage_2 idx_s2       ;
    // stage_3 min_s3       ;
    // stage_3 idx_s3       ;
    // stage_4 min_s4       ;
    // stage_4 idx_s4       ;

    
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (!rst_ni ) begin
            pm_ff       <= '{default : 12'd2048};
            pm_ff[0]    <=  0;
            reg_ex_ff   <= '{default : '0};
            pm_min_ff   <= '0;
            min_idx_ff  <= '0;
            valid_o_ff  <= '0;
            count_input <=  0;
	 

        end else begin

            pm_ff       <=  pm_next;
            reg_ex_ff   <=  reg_ex_next;
            pm_min_ff   <=  pm_min_next;
            min_idx_ff  <=  min_idx_next;
            valid_o_ff  <=  valid_o_next;
            if(valid_i)
            count_input <= count_input+1;
           
        end
    end

    for (genvar state = 0; state<STATES_N/2; state++) begin
            
       assign pmCand00[state] = pm_ff[2*state] 	- pm_min_ff +bm0[2*state];
       assign pmCand01[state] = pm_ff[2*state+1] 	- pm_min_ff +bm0[2*state+1];
       assign pmCand10[state] = pm_ff[2*state] 	- pm_min_ff +bm1[2*state];
       assign pmCand11[state] = pm_ff[2*state+1] 	- pm_min_ff +bm1[2*state+1];
    
    end

   //  always_comb begin : RegEx
   //     valid_o_next    <= valid_o_ff;

   //     if(count_input >= tablelen) begin
   //         data_out     <= reg_ex_ff[min_idx_ff][59]; 
   //         valid_o_next <= 1;
   //     end
   //  end
    
   assign	data_out     = reg_ex_ff[min_idx_ff][60]; 
	
    always_comb begin : minPath_Regex
	valid_o_next    = 0;
        pm_next         = pm_ff;
        reg_ex_next     = reg_ex_ff;
       
        pm_min_next     = pm_min_ff;
        min_idx_next    = min_idx_ff;
       

 
        for (integer state = 0; state<STATES_N/2; state++) begin
            
        // pmCand00[state] = pm_ff[2*state] 	- pm_min_ff +bm0[2*state];
        // pmCand01[state] = pm_ff[2*state+1] 	- pm_min_ff +bm0[2*state+1];
        // pmCand10[state] = pm_ff[2*state] 	- pm_min_ff +bm1[2*state];
        // pmCand11[state] = pm_ff[2*state+1] 	- pm_min_ff +bm1[2*state+1];

        if (valid_i) begin

            if(pmCand00[state] <= pmCand01[state]) begin
                pm_next[state] = pmCand00[state];
                pm_temp_wire[state] = pmCand00[state];
                reg_ex_next[state] = reg_ex_ff[2*state]<<1; 
            end 
            else begin
                pm_next[state] = pmCand01[state];
                pm_temp_wire[state] = pmCand01[state];
                reg_ex_next[state] = reg_ex_ff[2*state+1]<<1;
            end

            if(pmCand10[state]<= pmCand11[state]) begin
                pm_next[state+32] = pmCand10[state];
                pm_temp_wire[state+32] = pmCand10[state];
                reg_ex_next[state+32] = (reg_ex_ff[2*state]<<1)+1; 
            end
            else begin
                pm_next[state+32] = pmCand11[state];
                pm_temp_wire[state+32] = pmCand11[state];
                reg_ex_next[state+32] = (reg_ex_ff[2*state+1]<<1)+1; 
            end
           valid_o_next = 1;
    
        end
        end
        if (valid_i) begin 
        for (int state = 0; state<STATES_N-1; state++) begin
          
            if(state==0)begin
                if (pm_temp_wire[state]< 2048) begin
                    pm_min_temp  = pm_temp_wire[state];
                    //pm_min_next <= pm_temp_wire[state];
                    min_idx_next = state; 
                end
            end
                else begin
                    if(pm_temp_wire[state]< pm_min_temp) begin
                    pm_min_temp  =  pm_temp_wire[state];
                   // pm_min_next  <= pm_temp_wire[state];
                    min_idx_next = state;
                    end
                end

            end
	        
            pm_min_next = pm_min_temp; 
        end
      

        //Initial/First stage of tree comparision.
        // for (integer i_s0 =0 ; i_s0 <= STATES_N / 2 - 1; i_s0++) begin
        //     if (pm_ff[2 * i_s0] < pm_ff[2 * i_s0 + 1]) begin
        //         min_s0[i_s0] <= pm_ff[2 * i_s0];
        //         idx_s0[i_s0] <= 2 * i_s0;
        //     end else begin
        //         min_s0[i_s0] <= pm_ff[2 * i_s0 + 1];
        //         idx_s0[i_s0] <= 2 * i_s0 + 1;
        //     end 
        // end 

        // // Second stage of tree comparision
        // for (integer i_s1 =0 ; i_s1 <= STATES_N / 4 - 1; i_s1++) begin
        //     if (min_s0[2 * i_s1] < min_s0[2 * i_s1 + 1]) begin
        //         min_s1[i_s1] <= min_s0[2 * i_s1];
        //         idx_s1[i_s1] <= idx_s0[2 * i_s1];
        // end else begin
        //         min_s1[i_s1] <= min_s0[2 * i_s1 + 1];
        //         idx_s1[i_s1] <= idx_s0[2 * i_s1 + 1];
        //      end 
        // end

        // // Third stage of tree comparision.
        // for (integer i_s2 =0 ; i_s2 <= STATES_N / 8 - 1; i_s2++) begin
        //     if (min_s1[2 * i_s2] < min_s1[2 * i_s2 + 1]) begin
        //         min_s2[i_s2] <= min_s1[2 * i_s2];
        //         idx_s2[i_s2] <= idx_s1[2 * i_s2];
        // end
        //     else begin
        //         min_s2[i_s2] <= min_s1[2 * i_s2 + 1];
        //         idx_s2[i_s2] <= idx_s1[2 * i_s2 + 1];
        //      end 
        // end

        // // Fourth stage of tree comparision.
        // for (integer i_s3 =0 ; i_s3 <= STATES_N / 16 - 1; i_s3++) begin
        //     if (min_s2[2 * i_s3] < min_s2[2 * i_s3 + 1]) begin
        //         min_s3[i_s3] <= min_s2[2 * i_s3];
        //         idx_s3[i_s3] <= idx_s2[2 * i_s3];
        //     end else begin
        //         min_s3[i_s3] <= min_s2[2 * i_s3 + 1];
        //         idx_s3[i_s3] <= idx_s2[2 * i_s3 + 1];
        //      end 
        // end

        // // Last/Fifth stage of tree comparision.
        // for (integer i_s4 =0 ; i_s4 <= STATES_N / 32 - 1; i_s4++) begin
        //     if (min_s3[2 * i_s4] < min_s3[2 * i_s4 + 1]) begin
        //         min_s4[i_s4] <= min_s3[2 * i_s4];
        //         idx_s4[i_s4] <= idx_s3[2 * i_s4];
        //     end else begin
        //         min_s4[i_s4] <= min_s3[2 * i_s4 + 1];
        //         idx_s4[i_s4] <= idx_s3[2 * i_s4 + 1];
        //      end 
        // end
        
        //end
        //always_comb begin : PMIN
            
        // pm_min_next     = pm_min_ff;
        // min_idx_next    = min_idx_ff;
        // if (valid_i) begin
        // for (integer state = 0; state<STATES_N/2-1; state++) begin
        //      if(state==0)begin  // Inital evaluation 
        //         if ((pm_temp_wire[state]< 2048) && (pm_temp_wire[state] < pm_temp_wire[state+32])) begin
        //             pm_min_temp  = pm_temp_wire[state];
        //             min_idx_next = state; 
        //         end else begin
        //         // if (pm_temp_wire[state+32] < pm_min_temp) begin
        //             pm_min_temp = pm_temp_wire[state+32];
        //             //pm_min_next  = pm_temp_wire[state];
        //             min_idx_next = state+32; 
        //         end
        //             pm_min_next = pm_min_temp;
        //     end 
        //     else begin
        //         if ((pm_temp_wire[state]< pm_min_ff)) begin
        //             pm_min_temp = pm_temp_wire[state];
        //             min_idx_next = state;  
        //         end
        //         // end
        //         if(pm_temp_wire[state+32] <pm_min_temp) begin
               
        //             pm_min_temp = pm_temp_wire[state+32];
        //             min_idx_next = state+32; 
        //         end
                   
        //     end
        
        //  end
        //  pm_min_next = pm_min_temp;
        // end
        //end
         end
        
    

    
endmodule