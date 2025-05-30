module top (
    input  clk,
    input  rst,         // 同步高有效重設

    input  in_valid,
    input  [3:0] in_num,
    input  [3:0] in_time,

    output [3:0] num1_out, clk1_out,
    output [3:0] num2_out, clk2_out,
    output [3:0] num3_out, clk3_out,

    output [23:0] qdbg_out, // 假設 DATA_W=8, DEPTH=3 -> 8*3=24

    // Debug outputs (保持原樣)
    output fifo_re_dbg,
    output ld1_dbg, ld2_dbg, ld3_dbg,
    output [2:0] busy_dbg,
    output fifo_full_dbg, fifo_emp_dbg,
    output [3:0] fifo_num_dbg, fifo_tim_dbg,
    output [3:0] dn1_dbg, dn2_dbg, dn3_dbg,
    output [3:0] dt1_dbg, dt2_dbg, dt3_dbg
);

    // 內部線路
    wire fifo_re_signal;
    wire ld1_signal, ld2_signal, ld3_signal;
    wire [2:0] busy_signal; // {busy_c3, busy_c2, busy_c1}
    wire fifo_full_signal;
    wire fifo_emp_signal;
    wire [3:0] fifo_num_signal;
    wire [3:0] fifo_tim_signal;
    wire [3:0] dn1_to_c1, dn2_to_c2, dn3_to_c3;
    wire [3:0] dt1_to_c1, dt2_to_c2, dt3_to_c3;


    // 1. 佇列 FIFO
    // queue DATA_W=8 (4-bit num + 4-bit time)
    queue #(
        .DEPTH(3),
        .DATA_W(8)
    ) u_queue (
        .clk(clk),
        .rst(rst),
        .we(in_valid),    // 寫入使能
        .dn_in(in_num),   // 客人編號
        .dt_in(in_time),  // 服務時間
        .re(fifo_re_signal), // 讀出使能
        .qn_out(fifo_num_signal),
        .qt_out(fifo_tim_signal),
        .full(fifo_full_signal),
        .empty(fifo_emp_signal),
        .qdbg(qdbg_out)
    );

    // 2. 調度器 Dispatcher
    dispatcher #(
        .NUM_W(4),
        .TIME_W(4)
    ) u_disp (
        .clk(clk),
        .rst(rst),
        .empty(fifo_emp_signal),
        .qn_in(fifo_num_signal),
        .qt_in(fifo_tim_signal),
        .busy_in(busy_signal), // {c3_busy, c2_busy, c1_busy}
        .re_out(fifo_re_signal),
        .ld1_out(ld1_signal), .dn1_out(dn1_to_c1), .dt1_out(dt1_to_c1),
        .ld2_out(ld2_signal), .dn2_out(dn2_to_c2), .dt2_out(dt2_to_c2),
        .ld3_out(ld3_signal), .dn3_out(dn3_to_c3), .dt3_out(dt3_to_c3)
    );

    // 3. 三個櫃檯 Counter
    counter #(
        .NUM_W(4),
        .TIME_W(4)
    ) u_c1 (
        .clk(clk), .rst(rst),
        .ld(ld1_signal), .dn_in(dn1_to_c1), .dt_in(dt1_to_c1),
        .busy(busy_signal[0]), .num_out(num1_out), .rem_out(clk1_out)
    );

    counter #(
        .NUM_W(4),
        .TIME_W(4)
    ) u_c2 (
        .clk(clk), .rst(rst),
        .ld(ld2_signal), .dn_in(dn2_to_c2), .dt_in(dt2_to_c2),
        .busy(busy_signal[1]), .num_out(num2_out), .rem_out(clk2_out)
    );

    counter #(
        .NUM_W(4),
        .TIME_W(4)
    ) u_c3 (
        .clk(clk), .rst(rst),
        .ld(ld3_signal), .dn_in(dn3_to_c3), .dt_in(dt3_to_c3),
        .busy(busy_signal[2]), .num_out(num3_out), .rem_out(clk3_out)
    );

    // 連接除錯輸出
    assign fifo_re_dbg   = fifo_re_signal;
    assign ld1_dbg       = ld1_signal;
    assign ld2_dbg       = ld2_signal;
    assign ld3_dbg       = ld3_signal;
    assign busy_dbg      = busy_signal;
    assign fifo_full_dbg = fifo_full_signal;
    assign fifo_emp_dbg  = fifo_emp_signal;
    assign fifo_num_dbg  = fifo_num_signal;
    assign fifo_tim_dbg  = fifo_tim_signal;
    assign dn1_dbg       = dn1_to_c1;
    assign dt1_dbg       = dt1_to_c1;
    assign dn2_dbg       = dn2_to_c2;
    assign dt2_dbg       = dt2_to_c2;
    assign dn3_dbg       = dn3_to_c3;
    assign dt3_dbg       = dt3_to_c3;

endmodule