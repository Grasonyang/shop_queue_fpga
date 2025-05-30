module queue #(
    parameter DEPTH = 3,
    parameter DATA_W = 8,
    parameter PTR_W = (DEPTH == 1) ? 1 : $clog2(DEPTH)
) (
    input  clk,
    input  rst,

    input               we,
    input  [3:0]        dn_in,
    input  [3:0]        dt_in,

    input               re,         // 來自 dispatcher
    output [3:0]        qn_out,
    output [3:0]        qt_out,

    output              full,
    output              empty,

    output [(DATA_W*DEPTH)-1:0] qdbg
);

    localparam COUNT_W = (DEPTH == 0) ? 1 : $clog2(DEPTH + 1);

    reg [DATA_W-1:0] mem [0:DEPTH-1];
    reg [PTR_W-1:0]  hd_r;      // head 讀指標 (寄存器)
    reg [PTR_W-1:0]  tl_r;      // tail 寫指標 (寄存器)
    reg [COUNT_W-1:0] count_r;  // 佇列目前元素數 (寄存器)

    // 中間信號，用於計算下一個狀態
    wire write_en_comb;
    wire read_en_comb;
    wire [PTR_W-1:0] hd_next;
    wire [PTR_W-1:0] tl_next;
    wire [COUNT_W-1:0] count_next;

    // 組合邏輯計算 full 和 empty 狀態，以及是否會發生讀寫
    assign full = (count_r == DEPTH);
    assign empty = (count_r == 0);

    assign write_en_comb = we && !full;
    assign read_en_comb  = re && !empty; // dispatcher 發來的 re，且 queue 非空

    // 輸出數據直接來自 mem[hd_r] (當前讀指針指向的數據)
    // 注意：這表示 qn_out/qt_out 會在 hd_r 更新後的下一個週期才看到新數據
    // 如果希望同週期看到，qn_out/qt_out 應基於 hd_next 或更複雜的邏輯
    assign qn_out = mem[hd_r][7:4];
    assign qt_out = mem[hd_r][3:0];

    // 計算下一個狀態的指針和計數器
    assign tl_next = write_en_comb ? ((DEPTH > 0 && tl_r == DEPTH-1) ? 0 : tl_r + 1) : tl_r;
    assign hd_next = read_en_comb  ? ((DEPTH > 0 && hd_r == DEPTH-1) ? 0 : hd_r + 1) : hd_r;

    assign count_next = (write_en_comb && !read_en_comb) ? count_r + 1 :
                        (!write_en_comb && read_en_comb) ? count_r - 1 :
                                                           count_r;
    integer i;
    // qdbg 生成
    generate
        genvar k;
        for (k = 0; k < DEPTH; k = k + 1) begin : qdbg_gen
            assign qdbg[(k+1)*DATA_W-1 -: DATA_W] = mem[k];
        end
        if (DEPTH == 0) begin : qdbg_empty_case
            assign qdbg = 0;
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            hd_r    <= 0;
            tl_r    <= 0;
            count_r <= 0;
            for (i = 0; i < DEPTH; i = i + 1) begin
                mem[i] <= 0;
            end
        end
        else begin
            if (write_en_comb) begin
                mem[tl_r] <= {dn_in, dt_in}; // 寫入當前的 tl_r
            end

            // 更新指針和計數器
            // 注意：如果同時讀寫，count_r 不變，但 hd_r 和 tl_r 都會移動
            hd_r    <= hd_next;
            tl_r    <= tl_next;
            count_r <= count_next;
        end
    end
endmodule