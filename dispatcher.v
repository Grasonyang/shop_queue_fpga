//--------------------------------------------------------------
//  dispatcher.v (版本 C: 每次只處理一個，嚴格等待 re_out 的效果)
//--------------------------------------------------------------
module dispatcher #(
    parameter NUM_W = 4,
    parameter TIME_W = 4
) (
    input  clk,
    input  rst,

    input  empty,
    input  [NUM_W-1:0]  qn_in,
    input  [TIME_W-1:0] qt_in,
    input  [2:0]        busy_in,

    output reg re_out,

    output reg ld1_out, ld2_out, ld3_out,
    output reg [NUM_W-1:0]  dn1_out, dn2_out, dn3_out,
    output reg [TIME_W-1:0] dt1_out, dt2_out, dt3_out
);

    reg dispatch_pending_r; // 標記是否正在等待上一次 re_out 的結果

    always @(posedge clk) begin
        if (rst) begin
            re_out  <= 1'b0;
            ld1_out <= 1'b0; dn1_out <= 0; dt1_out <= 0;
            ld2_out <= 1'b0; dn2_out <= 0; dt2_out <= 0;
            ld3_out <= 1'b0; dn3_out <= 0; dt3_out <= 0;
            dispatch_pending_r <= 1'b0;
        end
        else begin
            // 預設值
            re_out  <= 1'b0;
            ld1_out <= 1'b0; dn1_out <= 0; dt1_out <= 0;
            ld2_out <= 1'b0; dn2_out <= 0; dt2_out <= 0;
            ld3_out <= 1'b0; dn3_out <= 0; dt3_out <= 0;

            if (dispatch_pending_r) begin
                // 上個週期發出了 re_out，本週期等待 FIFO 更新，不進行新的派發決策
                // 並且清除 pending 標記，以便下個週期可以重新決策
                dispatch_pending_r <= 1'b0;
            end
            else if (!empty) begin // 如果沒有 pending 的派發，且 FIFO 非空
                // 優先櫃檯1
                if (!busy_in[0]) begin
                    re_out  <= 1'b1;
                    ld1_out <= 1'b1;
                    dn1_out <= qn_in;
                    dt1_out <= qt_in;
                    dispatch_pending_r <= 1'b1; // 標記已發出 re_out
                end
                // 若櫃檯1忙，則考慮櫃檯2
                else if (!busy_in[1]) begin
                    re_out  <= 1'b1;
                    ld2_out <= 1'b1;
                    dn2_out <= qn_in;
                    dt2_out <= qt_in;
                    dispatch_pending_r <= 1'b1; // 標記已發出 re_out
                end
                // 若櫃檯1和2都忙，則考慮櫃檯3
                else if (!busy_in[2]) begin
                    re_out  <= 1'b1;
                    ld3_out <= 1'b1;
                    dn3_out <= qn_in;
                    dt3_out <= qt_in;
                    dispatch_pending_r <= 1'b1; // 標記已發出 re_out
                end
                // else: 所有櫃檯都忙，不派發，dispatch_pending_r 保持 0
            end
            // else: FIFO 為空，不派發，dispatch_pending_r 保持 0
        end
    end
endmodule