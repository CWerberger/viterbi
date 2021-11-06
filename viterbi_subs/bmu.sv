module bmu 
    import viterbi_pkg::*; // wildcard import
   #(
    // parameters
    ) 
    (
    input logic                  clk_i,
    input logic                  rst_ni,
    input logic                  flush,               

    input logic[7:0]             dataX,
    input logic[7:0]             dataY,
    
    input logic                  valid_i,  // trigger

    output logic                 valid_o,  
    output bm_array              bm0, // 2 bmu needed for both states
    output bm_array              bm1
                            
    );

    bm_array bm_dist_0_ff, bm_dist_0_next, bm_dist_1_ff, bm_dist_1_next;
    logic valid_out_ff, valid_out_next;
  
    logic [2:0] absdiffX0;
    logic [2:0] absdiffX1;
    logic [2:0] absdiffY0;
    logic [2:0] absdiffY1;
    logic [1:0] temp [64];

    assign bm0 		= bm_dist_0_ff;
    assign bm1 		= bm_dist_1_ff;
    assign valid_o	= valid_out_ff;


    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (!rst_ni) begin
            bm_dist_0_ff <= '{default : 64'h0};
            bm_dist_1_ff <= '{default : 64'h0};
            valid_out_ff <=  0;            
        end 
	else if (flush == 1) begin
	    bm_dist_0_ff <= '{default : 64'h0};
            bm_dist_1_ff <= '{default : 64'h0};
            valid_out_ff <=  0; 
	end
	else begin
            bm_dist_0_ff <= bm_dist_0_next;
            bm_dist_1_ff <= bm_dist_1_next;
            valid_out_ff <= valid_out_next;   
        end
    end

always @* begin

	valid_out_next <= 0;
	bm_dist_0_next <= bm_dist_0_ff;
	bm_dist_1_next <= bm_dist_1_ff;	

    if (valid_i) begin
	
	valid_out_next <= 1;

    	for (int state_count = 0; state_count < 64 ; state_count++) begin
		temp[state_count] = trellisDiagr[state_count];
        	if (trellisDiagr[state_count] >=2 ) begin
            		absdiffX0 = 7 - dataX;
            		absdiffX1 = dataX;
			//temp[state_count] = trellisDiagr[state_count];
        	end 
        	else begin
            		absdiffX0 = dataX;
	    		absdiffX1 = 7 - dataX;
        	end

        	if (trellisDiagr[state_count] == 1 || trellisDiagr[state_count] == 3 ) begin
            		absdiffY0 = 7 - dataY;
	    		absdiffY1 = dataY;
       		end 
        	else begin
            		absdiffY0 = dataY;
	        	absdiffY1 = 7 - dataY;
        	end

        	if ( dataX == 255 ) begin
			bm_dist_0_next[state_count] <= absdiffY0 * absdiffY0 + 9; 
               		bm_dist_1_next[state_count] <= absdiffY1 * absdiffY1 + 16; 
        	end 
        	else if (dataY == 255) begin
                	bm_dist_0_next[state_count] <= absdiffX0 * absdiffX0 + 9; 
                	bm_dist_1_next[state_count] <= absdiffX1 * absdiffX1 + 16; 
        	end 
	    	else begin
			bm_dist_0_next[state_count] <= absdiffX0 * absdiffX0 + absdiffY0 * absdiffY0;
                	bm_dist_1_next[state_count] <= absdiffX1 * absdiffX1 + absdiffY1 * absdiffY1;
        	end   
    	end
    end
end
    
endmodule