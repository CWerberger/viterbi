
package viterbi_pkg;
        
        parameter K = 7;
        parameter STATES_N = 2**(K-1) ; // 64

        // Path Metric arrays
        parameter  PM_MAX_BITS  = 11; // 2048 -> infinite
        parameter  tblen        = 60; // vertical depth of the trellis
        
        typedef logic [0:STATES_N-1][PM_MAX_BITS:0] pm_array; 
        typedef logic [0:STATES_N-1][PM_MAX_BITS:0] temp_pm_array;    
        typedef logic [0:STATES_N-1][tblen:0] reg_ex_array; //64x60
        typedef logic [PM_MAX_BITS:0] pmMin_array;

        typedef logic [7:0] bm_array[STATES_N]; 
	localparam logic [31:0] SHUFFLE_MASK_L [4] =
          '{32'h00ff_0000, 32'h0f00_0f00, 32'h3030_3030, 32'h4444_4444};


        localparam logic [0:63][1:0] trellisDiagr = { 
                2'b00, 2'b11, 2'b01, 2'b10, 2'b00,2'b11,2'b01,2'b10, 2'b11,
                2'b00,2'b10,2'b01,2'b11,2'b00,2'b10,2'b01,2'b11,2'b00,2'b10,
                2'b01,2'b11, 2'b00,2'b10,2'b01,2'b00,2'b11,2'b01,2'b10,2'b00,
                2'b11,2'b01,2'b10,2'b10,2'b01,2'b11,2'b00,2'b10,2'b01,2'b11,
                2'b00,2'b01,2'b10,2'b00,2'b11,2'b01,2'b10,2'b00,2'b11,2'b01,
                2'b10,2'b00,2'b11,2'b01,2'b10,2'b00,2'b11,2'b10,2'b01,2'b11,
                2'b00,2'b10,2'b01,2'b11,2'b00};

endpackage : viterbi_pkg
