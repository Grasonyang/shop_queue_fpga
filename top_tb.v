`timescale 1ns / 1ps
module top_tb;

	// Inputs
	reg clk;
	reg rst; // Active high reset
	reg in_valid;
	reg [3:0] in_num;
	reg [3:0] in_time;

	// Outputs from DUT (matching top.v)
	wire [3:0] num1_out; // Changed from num1
	wire [3:0] clk1_out; // Changed from clk1
	wire [3:0] num2_out; // Changed from num2
	wire [3:0] clk2_out; // Changed from clk2
	wire [3:0] num3_out; // Changed from num3
	wire [3:0] clk3_out; // Changed from clk3
	wire [23:0] qdbg_out; // Changed from qdbg, assuming DATA_W=8, DEPTH=3 for DUT's queue

	// Debug outputs from DUT (matching top.v)
	wire fifo_re_dbg;   // Changed from fifo_re
	wire ld1_dbg;       // Changed from ld1
	wire ld2_dbg;       // Changed from ld2
	wire ld3_dbg;       // Changed from ld3
	wire [2:0] busy_dbg;  // Changed from busy
	wire fifo_full_dbg; // Changed from fifo_full
	wire fifo_emp_dbg;  // Changed from fifo_emp
	wire [3:0] fifo_num_dbg; // Changed from fifo_num
	wire [3:0] fifo_tim_dbg; // Changed from fifo_tim
	wire [3:0] dn1_dbg;      // Changed from dn1
	wire [3:0] dt1_dbg;      // Changed from dt1
	wire [3:0] dn2_dbg;      // Changed from dn2
	wire [3:0] dt2_dbg;      // Changed from dt2
	wire [3:0] dn3_dbg;      // Changed from dn3
	wire [3:0] dt3_dbg;      // Changed from dt3

	// Instantiate the Unit Under Test (UUT)
	top uut (
		.clk(clk),
		.rst(rst),
		.in_valid(in_valid),
		.in_num(in_num),
		.in_time(in_time),
		.num1_out(num1_out), // Matched
		.clk1_out(clk1_out), // Matched
		.num2_out(num2_out), // Matched
		.clk2_out(clk2_out), // Matched
		.num3_out(num3_out), // Matched
		.clk3_out(clk3_out), // Matched
		.qdbg_out(qdbg_out), // Matched

		// Debug outputs connection
		.fifo_re_dbg(fifo_re_dbg),     // Matched
		.ld1_dbg(ld1_dbg),             // Matched
		.ld2_dbg(ld2_dbg),             // Matched
		.ld3_dbg(ld3_dbg),             // Matched
		.busy_dbg(busy_dbg),           // Matched
		.fifo_full_dbg(fifo_full_dbg), // Matched
		.fifo_emp_dbg(fifo_emp_dbg),   // Matched
		.fifo_num_dbg(fifo_num_dbg),   // Matched
		.fifo_tim_dbg(fifo_tim_dbg),   // Matched
		.dn1_dbg(dn1_dbg),             // Matched
		.dt1_dbg(dt1_dbg),             // Matched
		.dn2_dbg(dn2_dbg),             // Matched
		.dt2_dbg(dt2_dbg),             // Matched
		.dn3_dbg(dn3_dbg),             // Matched
		.dt3_dbg(dt3_dbg)              // Matched
	);

//==== Clock : 20 ns 週期 ======================================
always #10 clk = ~clk;

//==== Reset (Active High, Synchronous) ========================
initial begin
    clk = 0;
    rst = 1; // Assert active-high reset
    in_valid = 0;
    in_num = 0;
    in_time = 0;

    // Hold reset for a few clock cycles to ensure it's properly sampled
    repeat (3) @(posedge clk); // Hold reset for 3 active clock edges

    rst = 0;           // De-assert reset. DUT will see rst=0 on the next posedge clk.
end

//==== 送客人 Task =============================================
task send_cust;
    input [3:0] num;
    input [3:0] tim;
begin
    @(negedge clk); // Apply inputs on negedge, stable for posedge sampling by DUT
    in_valid = 1;
    in_num   = num;
    in_time  = tim;
    @(negedge clk); // Hold inputs for one full clock cycle (from negedge to next negedge)
    in_valid = 0;
    // Clearing in_num and in_time is optional as in_valid controls their use.
    // in_num   = 4'd0;
    // in_time  = 4'd0;
end
endtask

//==== Stimulus ================================================
initial begin
    // Wait for reset to be de-asserted and the system to be out of reset state
    wait (rst == 0);    // Ensure rst signal itself is low
    @(posedge clk);     // Wait for the first clock edge where DUT processes rst=0

    // ── 先填滿三個櫃台 ───────────────────────────────
    send_cust(4'd1, 4'd3);
    send_cust(4'd2, 4'd2);
    send_cust(4'd3, 4'd4);

    // ── 再塞進 FIFO（深度 3）────────────────────────
    send_cust(4'd4, 4'd1);
    send_cust(4'd5, 4'd5);
    send_cust(4'd6, 4'd2);

    // ── 佇列已滿，以下客人應被丟棄 ──────────────────
    send_cust(4'd7, 4'd3); // DUT's queue should prevent overwrite if full

    // ── 等待部分櫃台釋放，再送新客人 ────────────────
    #500; // 500ns delay
    send_cust(4'd8, 4'd2);
    send_cust(4'd9, 4'd6);

    // ── 結束模擬 ───────────────────────────────────
    #1000 $finish; // 1000ns delay before finishing
end

//==== 波形輸出 (VCD) ==========================================
initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars(0, top_tb); // Dump all signals in the testbench and below
end

endmodule