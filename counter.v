module counter #(
    parameter NUM_W  = 4,
    parameter TIME_W = 4
) (
    input clk,
    input rst,
    input ld,
    input [NUM_W-1:0] dn_in,
    input [TIME_W-1:0] dt_in,
    output reg busy,
    output reg [NUM_W-1:0] num_out,
    output reg [TIME_W-1:0] rem_out
);
    always @(posedge clk) begin
        if (rst) begin
            busy    <= 1'b0;
            num_out <= 0;
            rem_out <= 0;
        end
        else begin
            if (ld) begin
                busy    <= 1'b1;
                num_out <= dn_in;
                rem_out <= dt_in;
            end
            else if (busy) begin
                if (rem_out > 1) begin
                    rem_out <= rem_out - 1;
                end
                else begin
                    busy    <= 1'b0;
                    num_out <= 0;
                    rem_out <= 0;
                end
            end
        end
    end
    
endmodule