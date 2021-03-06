module viterbi_decoder 

import viterbi_pkg::*; // wildcard import

(
    input logic                  clk_i,
    input logic                  rst_ni,
    input logic                  flush,               

    input logic[7:0]             dataX,  // placeholder for TB purpose
    input logic[7:0]             dataY,
    
    input logic                  valid_i,  // trigger

    output logic                 valid_o,
    output logic                 data_out  
                            
    );

    bm_array        bm0,bm1;  // bmu signal to pmu
    logic           valid_o_bm;           // trigger signal for pmu

    bmu bmu_inst_0 (

    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .flush      (flush),               

    .dataX      (dataX),
    .dataY      (dataY),
    
    .valid_i    (valid_i),  // trigger

    .valid_o    (valid_o_bm),  
    .bm0        (bm0), 
    .bm1        (bm1)

    );


    pmu pmu_inst (

    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .flush      (flush),              

    .bm0       (bm0),
    .bm1       (bm1),  

    .valid_i    (valid_o_bm),  // trigger

    .valid_o    (valid_o),  
    .data_out   (data_out)

    );

endmodule: viterbi_decoder 
