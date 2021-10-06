
module viterbi
    import viterbi_pkg::status_e;
    #(
      localparam IO_WIDTH= 8,
      localparam int TRELLIS_DIAGR[16] = '{33620736, 33620736, 16908291, 16908291, 16908291, 16908291, 33620736 ,33620736, 196866, 196866, 50332161, 50332161, 50332161, 50332161, 196866, 196866 },
    )(
     input logic                              clk_i,
     input logic                              rst_ni,
     input logic                              trigger_i,
     input logic [IO_WIDTH-1:0]               dataX,
     input logic [IO_WIDTH-1:0]               dataY,
     input logic [IO_WIDTH-1:0]               state,
     output logic [IO_WIDTH-1:0]              result_o,
     output 				         status_e status_o		// check if the IP is working 
     );

int patchmetric = '{0, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048,
		2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 
		2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 
		2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048};   

logic PM_MIN [24] = 24'd0;
logic MIN_IDX [8]  = 8'd0;
logic PM_MIN_LOCAL [24] = 24'd16384;      


logic REDATA0_15 [1023:0] = 1024'd0 
logic REDATA16_31 [1023:0] = 1024'd0
logic REDATA32_47 [1023:0] = 1024'd0
logic REDATA48_63 [1023:0] = 1024'd0

logic RESL0_1 [127:0] = 128'd0
logic RESL2_3 [127:0] = 128'd0
logic RESL4_5 [127:0] = 128'd0
logic RESL6_7 [127:0] = 128'd0
logic RESL8_9 [127:0] = 128'd0
logic RESL10_11 [127:0] = 128'd0
logic RESL12_13 [127:0] = 128'd0
logic RESL14_15 [127:0] = 128'd0

logic RESL16_17 [127:0] = 128'd0
logic RESL18_19 [127:0] = 128'd0
logic RESL20_21 [127:0] = 128'd0
logic RESL22_23 [127:0] = 128'd0
logic RESL24_25 [127:0] = 128'd0
logic RESL26_27 [127:0] = 128'd0
logic RESL28_29 [127:0] = 128'd0
logic RESL30_31 [127:0] = 128'd0

logic RESL32_33 [127:0] = 128'd0
logic RESL34_35 [127:0] = 128'd0
logic RESL36_37 [127:0] = 128'd0
logic RESL38_39 [127:0] = 128'd0
logic RESL40_41 [127:0] = 128'd0
logic RESL42_43 [127:0] = 128'd0
logic RESL44_45 [127:0] = 128'd0
logic RESL46_47 [127:0] = 128'd0

logic RESL48_49 [127:0] = 128'd0
logic RESL50_51 [127:0] = 128'd0
logic RESL52_53 [127:0] = 128'd0
logic RESL54_55 [127:0] = 128'd0
logic RESL56_57 [127:0] = 128'd0
logic RESL58_59 [127:0] = 128'd0
logic RESL60_61 [127:0] = 128'd0
logic RESL62_63 [127:0] = 128'd0



/*nested modules*/
// Set up the SIMD adder and multiplier through modular extensions, start with a single 8 bit adder and multiplier
module addmul(
        output  [7:0] result,
        input   [7:0]      a, 
        input   [7:0]      b
        );

		assign result = {(a[7:0]*a[7:0]) + (b[7:0]*b[7:0])};
        
endmodule: addmul
 
// Put the addmul extensions together to build a SIMD addmul block with the desired bitwidth
module addmul8x4(
    output  [31:0] result, 
    input   [31:0] a, 
    input   [31:0] b
    );

	wire [7:0] t0,t1,t2,t3;
	addmul i0 (t0, a[ 7: 0], b[ 7: 0]);
	addmul i1 (t1, a[15: 8], b[15: 8]);
	addmul i2 (t2, a[23:16], b[23:16]);
	addmul i3 (t3, a[31:24], b[31:24]);
	assign result = {t3, t2, t1, t0};

endmodule : addmul8x4

// Set up a module to check for punctured data (simple multiplexer structure)
module puncturing(
    out[1:0] result,
    in [7:0] dataX,
    in [7:0] dataY
    );

	wire puncturedX = (dataX == 255)? 1:0;
	wire puncturedY = (dataY == 255)? 1:0;
	
	assign result = {puncturedX,puncturedY};

endmodule: puncturing
	

// Set up the SIMD add-substract structure through modular extensions, start with a single 15 bit adder and substractor
module addsub(
    out[11:0] result,
    in [11:0] a,
    in [11:0] b, 
    in [7:0] c
    );

	assign result = { a[11:0] - b[11:0] + c[7:0] };

endmodule: addsub

//----------------------------------------------BMU-Modules-----------------------------------------------------------------------
// Calculate the euclidean distance
module bmuAbsDiff(
    out [63:0] AbsDiffX, 
    out [63:0] AbsDiffY, 
    in [7:0] dataX, 
    in [7:0] dataY, 
    in [31:0] TrellisDiagr
    );

	wire [7:0] tempDataX = 7-dataX;
	wire [7:0] tempDataY = 7-dataY;
	
	// Signals to store the eulidean distance
	// Naming declaration absDiffX1_0 -> distance for X , path 1 , [2*state]
	// Naming declaration absDiffY0_1 -> distance for Y , path 0 , [2*state+1]
	wire [15:0] signal1;	// absDiffX1_0, absDiffX0_0 
	wire [15:0] signal2;	// absDiffX1_1, absDiffX0_1
	wire [15:0] signal3;	// absDiffY1_0, absDiffY0_0
	wire [15:0] signal4;	// absDiffY1_1, absDiffY0_1
	
	wire [15:0] signal5; 	// absDiffX1_0, absDiffX0_0 
	wire [15:0] signal6;	// absDiffX1_1, absDiffX0_1
	wire [15:0] signal7;	// absDiffY1_0, absDiffY0_0
	wire [15:0] signal8;	// absDiffY1_1, absDiffY0_1
	
	// Distance for state and state+1
	assign signal1 = (TrellisDiagr[1] == 1) ? {dataX[7:0],tempDataX} : {tempDataX,dataX[7:0]};
	assign signal2 = (TrellisDiagr[9] == 1) ? {dataX[7:0],tempDataX} : {tempDataX,dataX[7:0]};	
	assign signal3 = (TrellisDiagr[0] == 1) ? {dataY[7:0],tempDataY} : {tempDataY,dataY[7:0]};
	assign signal4 = (TrellisDiagr[8] == 1) ? {dataY[7:0],tempDataY} : {tempDataY,dataY[7:0]};
	// Distance for state+2 and state+3
	assign signal5 = (TrellisDiagr[17] == 1) ? {dataX[7:0],tempDataX} : {tempDataX,dataX[7:0]};
	assign signal6 = (TrellisDiagr[25] == 1) ? {dataX[7:0],tempDataX} : {tempDataX,dataX[7:0]};	
	assign signal7 = (TrellisDiagr[16] == 1) ? {dataY[7:0],tempDataY} : {tempDataY,dataY[7:0]};
	assign signal8 = (TrellisDiagr[24] == 1) ? {dataY[7:0],tempDataY} : {tempDataY,dataY[7:0]};
	// SIMD structure of absDiff 
	// State   and State+1 :Bits [63:56] = absDiff1_0, Bits [55:48] = absDiff0_0, Bits [47:40] = absDiff1_1, Bits [39:32] = absDiff0_1
	// State+2 and State+3 :Bits [31:24] = absDiff1_0, Bits [23:16] = absDiff0_0, Bits [15:8] = absDiff1_1, Bits [7:0] = absDiff0_1
	assign AbsDiffX = {signal1[15:0],signal2[15:0],signal5[15:0],signal6[15:0]};
	assign AbsDiffY = {signal3[15:0],signal4[15:0],signal7[15:0],signal8[15:0]};

endmodule: bmuAbsDif

// Calculate the branch metric
module bmuResult(
    out [31:0] bm0,
    out [31:0] bm1,
    in [7:0] dataX,
    in [7:0] dataY, 
    in [63:0] AbsDiffX,
    in [63:0] AbsDiffY
    );

	wire [1:0] puncture;
	wire [31:0] Product1;
	wire [31:0] Product2;
	// 3 possibel inputs, depending on the puncturing of the data
	wire [63:0] signal1 = {AbsDiffY[63:32], 32'b00000100000000110000010000000011};	// X is punctured, use Y and constant uncertainty (16)
	wire [63:0] signal2 = {AbsDiffX[63:32], 32'b00000100000000110000010000000011};	// Y is punctured, use X and constant uncertainty (9)
	wire [63:0] signal3 = {AbsDiffX[63:32], AbsDiffY[63:32]}; // No puncturing
	wire [63:0] dataIn1;
	
	// Check if the data is punctured
	puncturing i0 (puncture, dataX[7:0],dataY[7:0]); 
	
	// Choose the input, depending on the data puncturing
	CHANGE
	assign dataIn1 =  TIEmux(puncture, signal3, signal2, signal1, signal1);
	
	// Calculate the branch metric
	addmul8x4 i1 (Product1, dataIn1[63:32], dataIn1[31:0]);
	
	// Same procedure as above 
	wire [63:0] signal4 = {AbsDiffY[31:0], 32'b00000100000000110000010000000011};
	wire [63:0] signal5 = {AbsDiffX[31:0], 32'b00000100000000110000010000000011};
	wire [63:0] signal6 = {AbsDiffX[31:0], AbsDiffY[31:0]};
	wire [63:0] dataIn2;
	
CHANGEEEEE	assign dataIn2 =  TIEmux(puncture, signal6, signal5, signal4, signal4);
	
	addmul8x4 i2 (Product2,dataIn2[63:32], dataIn2[31:0]);
	
	// Save the branch metric for the corresponding paths
	assign bm0 = {Product2[7:0],Product2[23:16],Product1[7:0],Product1[23:16]};
	assign bm1 = {Product2[15:8],Product2[31:24],Product1[15:8],Product1[31:24]};

endmodule: bmuResult

//---------------------------------------------PMU-Modules--------------------------------------------------------------------------
// Calculate the path metric for all states, Add branch metric to current path metric, Subtract minIn to avoid an integer overflow
module pmuCand(
    in [23:0] minIn,
    in [23:0] pmIn1,
    in [23:0] pmIn2,
    in [31:0] bm0,
    in [31:0] bm1,
    out [47:0] pmCand0,
    out [47:0] pmCand1
    );

	addsub16x4 i0 (pmCand0, pmIn1, minIn, bm0, pmIn2);
	addsub16x4 i1 (pmCand1, pmIn1, minIn, bm1, pmIn2);

endmodule: pmuCand

// Search for candidates for the minimum path metric and store it in the corresponding states
module pmuOut(
    out [47:0] pmOut,
    in [47:0] pmCand0,
    in [47:0] pmCand1
    );

	wire [11:0] signal1;
	wire [11:0] signal2;
	wire [11:0] signal3;
	wire [11:0] signal4;
	// Select smaller path metric for X0Y0 and X1Y1 and store binary decision value.
	assign signal1 = (pmCand0[11:0] <= pmCand0[23:12]) ? {pmCand0[11:0]} : {pmCand0[23:12]};
	assign signal2 = (pmCand1[11:0] <= pmCand1[23:12]) ? {pmCand1[11:0]} : {pmCand1[23:12]};
	assign signal3 = (pmCand0[35:24] <= pmCand0[47:36]) ? {pmCand0[35:24]} : {pmCand0[47:36]};
	assign signal4 = (pmCand1[35:24] <= pmCand1[47:36]) ? {pmCand1[35:24]} : {pmCand1[47:36]};
	
	assign pmOut = {signal1, signal2, signal3, signal4};

endmodule: pmuOut

// Store the minimum path Metric and the corresponding state, part 2
module pmuMin(
    in [3:0] currentState,
    in [47:0] pmOut,
    in [23:0] pmMinlocalIn,
    in [7:0] minIdxIn,
    out [40:0] dataOut
    ); 	
	
	wire [11:0] min_12;
	wire [11:0] min_34;
	wire [15:0] min;
	
	wire [5:0] temp1;
	wire [5:0] temp2;
	wire [5:0] temp_min;
	
	// Search for minimum value inside the path metric output.
	assign min_12 = (pmOut[11:0] <= pmOut[23:12]) ? {pmOut[11:0]} :  {pmOut[23:12]};
	assign min_34 = (pmOut[35:24] <= pmOut[47:36]) ? {pmOut[35:24]} : {pmOut[47:36]};
	assign min = (min_12 <= min_34) ? {min_12} : {min_34};
	
	// Search for the corresponding state, possible states are:
	// state+0,state+1,state+32,state+33
	assign temp1 = (pmOut[11:0] <= pmOut[23:12]) ? {6'd33} : {6'd1};
	assign temp2 = (pmOut[35:24] <= pmOut[47:36]) ? {6'd32} : {6'd0};
	assign temp_min = (min_12 <= min_34) ? {temp1} : {temp2};
	
	wire [23:0] pmMinlocalOut1,pmMinlocalOut2;
	wire [7:0] minIdxOut;
	
	// Search for minimum value inside the path metric output.
	assign pmMinlocalOut1 = (16384 > min) ? {min} : {16384};
	assign pmMinlocalOut2 = (pmMinlocalIn > min) ? {min} : {pmMinlocalIn};
		
	// Store the corresponding minimum state index
	assign minIdxOut = (pmMinlocalIn > min) ? {{currentState[2:0],1'b0}+temp_min} : {minIdxIn};	
	
	assign dataOut = (currentState == 0 ) ? {pmMinlocalOut1[23:0],minIdxOut[7:0]} : {pmMinlocalOut2[23:0],minIdxOut[7:0]};

endmodule: pmuMin

// Calculate the data distribution for the register exchange method
module registerExchange(
    in [47:0] pmCand0,
    in [47:0]pmCand1,
    out [7:0] reOut
    );

	wire [1:0] signal1;
	wire [1:0] signal2;
	wire [1:0] signal3;
	wire [1:0] signal4;
	
	// Calculate the register distribution 
	assign signal1 = (pmCand0[11:0] <= pmCand0[23:12] ) ? { 2'd0 } : { 2'd1 };
	assign signal2 = (pmCand1[11:0] <= pmCand1[23:12] ) ? { 2'd0 } : { 2'd1 };
	assign signal3 = (pmCand0[35:24] <= pmCand0[47:36] ) ? { 2'd2 } : { 2'd3 };
	assign signal4 = (pmCand1[35:24] <= pmCand1[47:36] ) ? { 2'd2 } : {  2'd3 };
		
	assign reOut = {signal4,signal3,signal2,signal1};	

endmodule: registerExchange

// Save the register changes, depending on the current state and the calculated register distribution
module registerExchangeSave(
    in [7:0] controlData,
    in [255:0] ReData,
    out [127:0] ReSlLowOut, 
    out [127:0] ReSlHighOut
    );
	
	// Possible register values, either 0 or 1 is stored 
	wire [63:0] ReOutZero1 = (controlData[1:0] == 0) ? {(ReData[63:0]<<1)}:{(ReData[127:64]<<1)};
	wire [63:0] ReOutZero2 = (controlData[5:4] == 2) ? {(ReData[191:128]<<1)}:{(ReData[255:192]<<1)};
	wire [63:0] ReOutOne1 = (controlData[3:2] == 0) ? {(ReData[63:0]<<1)+1}:{(ReData[127:64]<<1)+1};
	wire [63:0] ReOutOne2 = (controlData[7:6] == 2) ? {(ReData[191:128]<<1)+1}:{(ReData[255:192]<<1)+1};
	
	// Possible Output, if controlData[8] == 0 then a zero is stored, otherwhise a one is stored
	
	assign ReSlLowOut = {ReOutZero2[63:0],ReOutZero1[63:0]};
	assign ReSlHighOut = { ReOutOne2[63:0],ReOutOne1[63:0]}; 

endmodule: registerExchange


// Save the calculated path metric
module pmuSave(
    in [47:0] pmIn,
    in [3:0] currentState,
    in [767:0] pmOut_in,
    out [767:0] pmOut_out
    );

// Choose the pathmetric for each path depending on the current State
wire [23:0] pm0 = (currentState == 0) ? {pmIn[23:12],pmIn[47:36]}:{pmOut_in[23:0]};
wire [23:0] pm1 = (currentState == 1) ? {pmIn[23:12],pmIn[47:36]}:{pmOut_in[47:24]};
wire [23:0] pm2 = (currentState == 2) ? {pmIn[23:12],pmIn[47:36]}:{pmOut_in[71:48]};
wire [23:0] pm3 = (currentState == 3) ? {pmIn[23:12],pmIn[47:36]}:{pmOut_in[95:72]};
wire [23:0] pm4 = (currentState == 4) ? {pmIn[23:12],pmIn[47:36]}:{pmOut_in[119:96]};
wire [23:0] pm5 = (currentState == 5) ? {pmIn[23:12],pmIn[47:36]}:{pmOut_in[143:120]};
wire [23:0] pm6 = (currentState == 6) ? {pmIn[23:12],pmIn[47:36]}:{pmOut_in[167:144]};
wire [23:0] pm7 = (currentState == 7) ? {pmIn[23:12],pmIn[47:36]}:{pmOut_in[191:168]};
wire [23:0] pm8 = (currentState == 8) ? {pmIn[23:12],pmIn[47:36]}:{pmOut_in[215:192]};
wire [23:0] pm9 = (currentState == 9) ? {pmIn[23:12],pmIn[47:36]}:{pmOut_in[239:216]};
wire [23:0] pm10 = (currentState == 10) ? {pmIn[23:12],pmIn[47:36]}:{pmOut_in[263:240]};
wire [23:0] pm11 = (currentState == 11) ? {pmIn[23:12],pmIn[47:36]}:{pmOut_in[287:264]};
wire [23:0] pm12 = (currentState == 12) ? {pmIn[23:12],pmIn[47:36]}:{pmOut_in[311:288]};
wire [23:0] pm13 = (currentState == 13) ? {pmIn[23:12],pmIn[47:36]}:{pmOut_in[335:312]};
wire [23:0] pm14 = (currentState == 14) ? {pmIn[23:12],pmIn[47:36]}:{pmOut_in[359:336]};
wire [23:0] pm15 = (currentState == 15) ? {pmIn[23:12],pmIn[47:36]}:{pmOut_in[383:360]};
wire [23:0] pm16 = (currentState == 0) ? {pmIn[11:0],pmIn[35:24]}:{pmOut_in[407:384]};
wire [23:0] pm17 = (currentState == 1) ? {pmIn[11:0],pmIn[35:24]}:{pmOut_in[431:408]};
wire [23:0] pm18 = (currentState == 2) ? {pmIn[11:0],pmIn[35:24]}:{pmOut_in[455:432]};
wire [23:0] pm19 = (currentState == 3) ? {pmIn[11:0],pmIn[35:24]}:{pmOut_in[479:456]};
wire [23:0] pm20 = (currentState == 4) ? {pmIn[11:0],pmIn[35:24]}:{pmOut_in[503:480]};
wire [23:0] pm21 = (currentState == 5) ? {pmIn[11:0],pmIn[35:24]}:{pmOut_in[527:504]};
wire [23:0] pm22 = (currentState == 6) ? {pmIn[11:0],pmIn[35:24]}:{pmOut_in[551:528]};	
wire [23:0] pm23 = (currentState == 7) ? {pmIn[11:0],pmIn[35:24]}:{pmOut_in[575:552]};
wire [23:0] pm24 = (currentState == 8) ? {pmIn[11:0],pmIn[35:24]}:{pmOut_in[599:576]};
wire [23:0] pm25 = (currentState == 9) ? {pmIn[11:0],pmIn[35:24]}:{pmOut_in[623:600]};
wire [23:0] pm26 = (currentState == 10) ? {pmIn[11:0],pmIn[35:24]}:{pmOut_in[647:624]};
wire [23:0] pm27 = (currentState == 11) ? {pmIn[11:0],pmIn[35:24]}:{pmOut_in[671:648]};
wire [23:0] pm28 = (currentState == 12) ? {pmIn[11:0],pmIn[35:24]}:{pmOut_in[695:672]};
wire [23:0] pm29 = (currentState == 13) ? {pmIn[11:0],pmIn[35:24]}:{pmOut_in[719:696]};
wire [23:0] pm30 = (currentState == 14) ? {pmIn[11:0],pmIn[35:24]}:{pmOut_in[743:720]};
wire [23:0] pm31 = (currentState == 15) ? {pmIn[11:0],pmIn[35:24]}:{pmOut_in[767:744]};


// Build the output
assign pmOut_out = {pm31,pm30,pm29,pm28,pm27,pm26,pm25,pm24,pm23,pm22,pm21,pm20,pm19,pm18,pm17,pm16,pm15,pm14,pm13,pm12,pm11,pm10,pm9,pm8,pm7,pm6,pm5,pm4,pm3,pm2,pm1,pm0};

endmodule: pmuSave

//--------------------------------------------Viterbi-Operation----------------------------------------------------------------
operation Viterbi {in AR dataX,in AR dataY, in AR currentState, out AR bitOut}
{ inout MIN_IDX, inout PM_MIN, inout PM_MIN_LOCAL, inout PATHMETRIC, inout PMOUT, inout REDATA0_15,inout REDATA16_31,inout REDATA32_47,inout REDATA48_63,inout RESL0_1,inout RESL2_3,inout RESL4_5,inout RESL6_7,inout RESL8_9,inout RESL10_11,inout RESL12_13,inout RESL14_15,inout RESL16_17,inout RESL18_19,inout RESL20_21,inout RESL22_23,inout RESL24_25,inout RESL26_27, inout RESL28_29,inout RESL30_31,inout RESL32_33,inout RESL34_35,inout RESL36_37,inout RESL38_39,inout RESL40_41,inout RESL42_43,inout RESL44_45,inout RESL46_47,inout RESL48_49,inout RESL50_51,inout RESL52_53,inout RESL54_55,inout RESL56_57,inout RESL58_59,inout RESL60_61,inout RESL62_63} 
{

		// Mux change by currentState
	wire [47:0] pmIn = TIEmux(currentState[3:0], PATHMETRIC[47:0],PATHMETRIC[95:48], PATHMETRIC[143:96], PATHMETRIC[191:144], PATHMETRIC[239:192], PATHMETRIC[287:240], PATHMETRIC[335:288], PATHMETRIC[383:336], PATHMETRIC[431:384], PATHMETRIC[479:432], PATHMETRIC[527:480], PATHMETRIC[575:528], PATHMETRIC[623:576], PATHMETRIC[671:624], PATHMETRIC[719:672], PATHMETRIC[767:720]);
	wire [23:0] pmIn1 = pmIn[23:0];
	wire [23:0] pmIn2 = pmIn[47:24];
	
	wire [255:0] ReDataIn = TIEmux(currentState[3:0],REDATA0_15[255:0],REDATA0_15[511:256],REDATA0_15[767:512],REDATA0_15[1023:768],REDATA16_31[255:0],REDATA16_31[511:256],REDATA16_31[767:512],REDATA16_31[1023:768],REDATA32_47[255:0],REDATA32_47[511:256],REDATA32_47[767:512],REDATA32_47[1023:768],REDATA48_63[255:0],REDATA48_63[511:256],REDATA48_63[767:512],REDATA48_63[1023:768]);		
	wire [127:0] ReSlLow,ReSlHigh;
		
	wire [7:0] reOut;
	wire [63:0] AbsDiffX, AbsDiffY;
	wire [47:0] pmCand0,pmCand1, pmOut_local;
	wire [31:0] bm0,bm1;
	wire [40:0] minDataOut;
	wire [31:0] trellisDiagr = TRELLIS_DIAGR[currentState];
	//------------------------------------Viterbi algorithm-----------------------------------------------------------------------		
	bmuAbsDiff i0 (AbsDiffX,AbsDiffY,dataX[7:0],dataY[7:0],trellisDiagr);
	bmuResult i1 (bm0,bm1,dataX[7:0],dataY[7:0],AbsDiffX,AbsDiffY);
	pmuCand i2 (PM_MIN, pmIn1, pmIn2, bm0, bm1,pmCand0,pmCand1);
	registerExchange i3(pmCand0, pmCand1,reOut);
	registerExchangeSave i4({reOut[7:0]},ReDataIn,ReSlLow,ReSlHigh);
	pmuOut i5 (pmOut_local, pmCand0, pmCand1);
	pmuMin i6 ( currentState[3:0],pmOut_local, PM_MIN_LOCAL,MIN_IDX,minDataOut);
	pmuSave i7 (pmOut_local,currentState[3:0],PMOUT,PMOUT);
	//------------------------------------------------------------------------------------------------------------------------------
	//------------------------------------Prepare the next run----------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------------------------
	
	
	//------------------------------------Pathmetric--------------------------------------------------------------------------------
	
	// Save the minimum pathmetric aswell as its corresponding index(state)
	assign PM_MIN_LOCAL = minDataOut[31:8];
	assign PM_MIN = (currentState == 15) ? {minDataOut[31:8]} : {PM_MIN}; 
	assign MIN_IDX = (currentState == 0) ? {8'd0} : {minDataOut[7:0]} ; // Reset minIdx at the start of each new run
	
	// Save the pathmetric	
	assign PATHMETRIC = (currentState == 15) ? {pmOut_local[11:0],pmOut_local[35:24],PMOUT[743:720],PMOUT[719:672],PMOUT[671:624],PMOUT[623:576],PMOUT[575:528],PMOUT[527:480],PMOUT[479:432],PMOUT[431:384],pmOut_local[23:12],pmOut_local[47:36], PMOUT[359:336],PMOUT[335:288],PMOUT[287:240],PMOUT[239:192],PMOUT[191:144],PMOUT[143:96],PMOUT[95:48],PMOUT[47:0]}:{PATHMETRIC[767:720],PATHMETRIC[719:672],PATHMETRIC[671:624],PATHMETRIC[623:576],PATHMETRIC[575:528],PATHMETRIC[527:480],PATHMETRIC[479:432],PATHMETRIC[431:384],PATHMETRIC[383:336],PATHMETRIC[335:288],PATHMETRIC[287:240],PATHMETRIC[239:192],PATHMETRIC[191:144],PATHMETRIC[143:96],PATHMETRIC[95:48],PATHMETRIC[47:0]};
	
	//------------------------------------RegisterExchange---------------------------------------------------------------------------
	
	// Save the calculated RE values
	assign RESL0_1 = (currentState == 0) ? {ReSlLow} : {RESL0_1};
	assign RESL2_3 = (currentState == 1) ? {ReSlLow} : {RESL2_3};
	assign RESL4_5 = (currentState == 2) ? {ReSlLow} : {RESL4_5};
	assign RESL6_7 = (currentState == 3) ? {ReSlLow} : {RESL6_7};
	assign RESL8_9 = (currentState == 4) ? {ReSlLow} : {RESL8_9};
	assign RESL10_11 = (currentState == 5) ? {ReSlLow} : {RESL10_11};
	assign RESL12_13 = (currentState == 6) ? {ReSlLow} : {RESL12_13};
	assign RESL14_15 = (currentState == 7) ? {ReSlLow} : {RESL14_15};
	assign RESL16_17 = (currentState == 8) ? {ReSlLow} : {RESL16_17};
	assign RESL18_19 = (currentState == 9) ? {ReSlLow} : {RESL18_19};
	assign RESL20_21 = (currentState == 10) ? {ReSlLow} : {RESL20_21};
	assign RESL22_23 = (currentState == 11) ? {ReSlLow} : {RESL22_23};
	assign RESL24_25 = (currentState == 12) ? {ReSlLow} : {RESL24_25};
	assign RESL26_27 = (currentState == 13) ? {ReSlLow} : {RESL26_27};
	assign RESL28_29 = (currentState == 14) ? {ReSlLow} : {RESL28_29};
	assign RESL30_31 = (currentState == 15) ? {ReSlLow} : {RESL30_31};
	assign RESL32_33 = (currentState == 0) ? {ReSlHigh} : {RESL32_33};
	assign RESL34_35 = (currentState == 1) ? {ReSlHigh} : {RESL34_35};
	assign RESL36_37 = (currentState == 2) ? {ReSlHigh} : {RESL36_37};
	assign RESL38_39 = (currentState == 3) ? {ReSlHigh} : {RESL38_39};
	assign RESL40_41 = (currentState == 4) ? {ReSlHigh} : {RESL40_41};
	assign RESL42_43 = (currentState == 5) ? {ReSlHigh} : {RESL42_43};
	assign RESL44_45 = (currentState == 6) ? {ReSlHigh} : {RESL44_45};
	assign RESL46_47 = (currentState == 7) ? {ReSlHigh} : {RESL46_47};
	assign RESL48_49 = (currentState == 8) ? {ReSlHigh} : {RESL48_49};
	assign RESL50_51 = (currentState == 9) ? {ReSlHigh} : {RESL50_51};
	assign RESL52_53 = (currentState == 10) ? {ReSlHigh} : {RESL52_53};
	assign RESL54_55 = (currentState == 11) ? {ReSlHigh} : {RESL54_55};
	assign RESL56_57 = (currentState == 12) ? {ReSlHigh} : {RESL56_57};
	assign RESL58_59 = (currentState == 13) ? {ReSlHigh} : {RESL58_59};
	assign RESL60_61 = (currentState == 14) ? {ReSlHigh} : {RESL60_61};
	assign RESL62_63 = (currentState == 15) ? {ReSlHigh} : {RESL62_63};
	
	
	assign REDATA0_15 = (currentState == 15) ? {RESL14_15,RESL12_13,RESL10_11,RESL8_9,RESL6_7,RESL4_5,RESL2_3,RESL0_1} : {REDATA0_15};
	assign REDATA16_31 = (currentState == 15) ? {ReSlLow,RESL28_29,RESL26_27,RESL24_25,RESL22_23,RESL20_21,RESL18_19,RESL16_17} : {REDATA16_31};
	assign REDATA32_47 = (currentState == 15) ? {RESL46_47,RESL44_45,RESL42_43,RESL40_41,RESL38_39,RESL36_37,RESL34_35,RESL32_33} : {REDATA32_47};
	assign REDATA48_63 = (currentState == 15) ? {ReSlHigh,RESL60_61,RESL58_59,RESL56_57,RESL54_55,RESL52_53,RESL50_51,RESL48_49} : {REDATA48_63}; 
		
	//----------------------------------------------------------------------------------------------------------------------------------------------
	//-------------------------------------------Read the Output Bit--------------------------------------------------------------------------------	
	//----------------------------------------------------------------------------------------------------------------------------------------------
		
	// Select the register with the minimum path metric
	wire [63:0] stateOut = TIEmux(minDataOut[5:0],RESL0_1[63:0],RESL0_1[127:64],RESL2_3[63:0],RESL2_3[127:64],RESL4_5[63:0],RESL4_5[127:64],RESL6_7[63:0],RESL6_7[127:64],RESL8_9[63:0],RESL8_9[127:64],RESL10_11[63:0],RESL10_11[127:64],RESL12_13[63:0],RESL12_13[127:64],RESL14_15[63:0],RESL14_15[127:64],RESL16_17[63:0],RESL16_17[127:64],RESL18_19[63:0],RESL18_19[127:64],RESL20_21[63:0],RESL20_21[127:64],RESL22_23[63:0],RESL22_23[127:64],RESL24_25[63:0],RESL24_25[127:64],RESL26_27[63:0],RESL26_27[127:64],RESL28_29[63:0],RESL28_29[127:64],RESL30_31[63:0],RESL30_31[127:64],RESL32_33[63:0],RESL32_33[127:64],RESL34_35[63:0],RESL34_35[127:64],RESL36_37[63:0],RESL36_37[127:64],RESL38_39[63:0],RESL38_39[127:64],RESL40_41[63:0],RESL40_41[127:64],RESL42_43[63:0],RESL42_43[127:64],RESL44_45[63:0],RESL44_45[127:64],RESL46_47[63:0],RESL46_47[127:64],RESL48_49[63:0],RESL48_49[127:64],RESL50_51[63:0],RESL50_51[127:64],RESL52_53[63:0],RESL52_53[127:64],RESL54_55[63:0],RESL54_55[127:64],RESL56_57[63:0],RESL56_57[127:64],RESL58_59[63:0],RESL58_59[127:64],RESL60_61[63:0],RESL60_61[127:64],RESL62_63[63:0],RESL62_63[127:64]);
	// Take bit 60 of the selected register
	assign bitOut = stateOut[60]; 
}	

    status_e state_d, state_ff;
    logic [2*IO_WIDTH-1:0]            	result_d, result_ff;
    int i,k,N;
    logic [2*IO_WIDTH-1:0]	     	temp;
    // initilize Pathmetric
    int patchmetric = '{0, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048,
		2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 
		2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 
		2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048, 2048};   


    assign result_o		= result_ff;
    assign status_o		= state_ff;

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (!rst_ni) begin
            result_ff		<= '0;
            state_ff		<= gf_mult_pkg::IDLE;
        end else begin
            result_ff        	<= result_d;
            state_ff 		<= state_d;
        end
    end // always_ff @ (posedge clk_i, negedge rst_ni)

  
    always_comb begin
    result_d <= result_ff;
    temp     = 0;
        case (state_ff)
            gf_mult_pkg::IDLE: begin
                if (trigger_i) begin
                    state_d	<= gf_mult_pkg::PENDING;
		    result_d	<= '0;
			         
        	end else begin
                    state_d   <= gf_mult_pkg::IDLE;
		end
            end

           gf_mult_pkg::PENDING: begin
              state_d  <= gf_mult_pkg::IDLE;
		          if (op_select_i == 0) begin
		    	     for (N = 0; N < 8 ; N++) begin
		              	result_d[N] <= op_a_i[N] ^ op_b_i[N];
			         end
		    	  end 
		          else begin

	                  for (i = 0; i < 8; i++) begin
      			       if (op_b_i[i] == 1) begin
         			        temp ^= op_a_i << i;
     		   	       end
		            end
			
   		           for (k = 15; k > 7; k--) begin
      			       if (temp[k] == 1) begin
	    			        temp ^= pp_char << (k - 8);
     			       end
   		           end
    		 result_d <= temp ; 
	       end
		end
            default: begin
                state_d      <=gf_mult_pkg::IDLE;
		        
		        result_d     <= '0;
            end

       endcase
    end

    endmodule : gf_mult
