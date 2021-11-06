module  puncturing
    #(
    // parameters
    ) 
    (
    input logic                 clk_i,
    input logic                 rst_ni,

    input logic [7:0]           data_in;
    input logic                 bPunct;                            

    output logic[7:0]           dataX;
    output logic[7:0]           dataY;
    output logic                valid;  // for bmu to start

    );

    typedef enum logic      {punctured        = 0,
                              npunctured       = 1} state;
    
    state state_ff, state_next;

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (!rst_ni) begin
            state_ff		<= npunctured;
        end else begin
            state_ff 		<= state_next;
        end
    end

    always_comb begin
    state_next <= state_ff;
    dataX <= '0;
    dataY <= '0;
    valid <= '0;
    temp     = 0;
        case (state_ff)
            npunctured: begin
                dataX(2:0) <= data_in(2:0);
                dataY(2:0) <= data_in(5:3);
                valid <= '1;
                if(bPunct== 1'b1)
                    state_next <= punctured;
            end

            punctured:  begin
                state_next <= npunctured
                dataX(5:3) <= data_in(5:3); 
                dataY(2:0) <= data_in(2:0);
                valid <= '1;
            end
            default: begin
                
            end
        end
    end
    
endmodule puncturing