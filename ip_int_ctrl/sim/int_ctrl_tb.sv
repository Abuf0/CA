module int_ctrl_tb();
parameter NW = 11;
logic           clk_32k;
logic           rst_n;
logic [NW-1:0]  rg_int_enable;   // correlate with INT pin 
logic [NW-1:0]  rg_int_clr; // int clear
logic           rg_int_low_en;    // 0: HIGH; 1: LOW
logic           rg_int_level_en;  // 0: pulse; 1: level
logic [10:0]    rg_int_width;  // [1;2048]xT32k
logic [5:0]     rg_cold_time;   // [1;64]x1ms
logic           rg_int_after_frame;  // 0: now; 1: after frame
logic           rg_timer_on;
logic           rg_timer_mode;  // 0: single; 1: auto
logic [8:0]     rg_timer_sel;   // [1;300]x0.2s
logic           frame_on;
logic           fifo_upov_flag;
logic           fifo_downov_flag;
logic           fifo_waterline_flag;
logic           user_int_triger;  // user_int_info TODO
logic           frame_done_flag;
logic           sample_err_flag;
logic           cap_cancel_done_flag;
logic           ldo_ov_flag;
logic           circuit_exc_flag;
// intr output
logic [NW-1:0] int_status;   // RO; int status
logic          int_out;

logic clk_test;

always #15625 clk_32k=~clk_32k;
always #5000000 clk_test=~clk_test;

initial begin
    clk_32k = 0;
    clk_test = 0;
    rst_n = 0;
    rg_int_enable = 1;
    rg_int_clr = 0;
    rg_int_low_en = 0;
    rg_int_level_en = 0;
    rg_int_width = 11'h27f;
    rg_cold_time = 6'h13;
    rg_int_after_frame = 0;
    rg_timer_on   = 0;
    rg_timer_mode = 0;
    rg_timer_sel  = 0;
    frame_on = 0;
    fifo_upov_flag = 0;      
    fifo_downov_flag = 0;    
    fifo_waterline_flag = 0; 
    user_int_triger = 0;     
    frame_done_flag = 0;          
    sample_err_flag = 0;     
    cap_cancel_done_flag = 0;
    ldo_ov_flag = 0;      
    circuit_exc_flag = 0;     
    repeat(5) @(negedge clk_test); 
    rst_n = 1;
    repeat(10) @(negedge clk_test);  
    clear_int(-1);
    repeat(10) @(negedge clk_test);  
    user_int_req();
    repeat(20) @(negedge clk_test); 
    rg_int_enable = -1;
    repeat(10) @(negedge clk_test);  
    user_int_req();
    repeat(20) @(negedge clk_test);  
    smp_int_req();
    repeat(20) @(negedge clk_test); 
    clear_int(12'h100);
    repeat(20) @(negedge clk_test); 
    clear_int(-1);
    @(negedge clk_32k)
    user_int_req();
    repeat(10) @(negedge clk_test);  
    $finish(2);

end
task clear_int(input [NW-1:0] int_clr);
    @(negedge clk_32k);
    rg_int_clr = int_clr;
    @(negedge clk_32k);
    rg_int_clr = 0;
endtask
task user_int_req;
    @(negedge clk_32k);
    user_int_triger = 1;
    @(negedge clk_32k);
    user_int_triger = 0;
endtask
task smp_int_req;
    @(negedge clk_32k);
    sample_err_flag = 1;
    @(negedge clk_32k);
    sample_err_flag = 0;
endtask

int_ctrl #(.NW(NW)) U_INT_CTRL_0(
.clk_32k(              clk_32k     ),
.rst_n(                rst_n     ),
.rg_int_enable(    rg_int_enable),
.rg_int_clr(        rg_int_clr),
.rg_int_low_en(        rg_int_low_en ),
.rg_int_level_en(      rg_int_level_en ),
.rg_int_width(         rg_int_width ),
.rg_cold_time(        rg_cold_time  ),
.rg_int_after_frame(      rg_int_after_frame  ),
.rg_timer_on(          rg_timer_on ),
.rg_timer_mode(        rg_timer_mode  ),
.rg_timer_sel(         rg_timer_sel    ),   
.frame_on(             frame_on),
.fifo_upov_flag(       fifo_upov_flag ),
.fifo_downov_flag(     fifo_downov_flag  ),
.fifo_waterline_flag(  fifo_waterline_flag   ),  
.user_int_triger(      user_int_triger    ),       
.frame_done_flag(      frame_done_flag   ),    
.sample_err_flag(      sample_err_flag   ), 
.cap_cancel_done_flag( cap_cancel_done_flag   ),     
.ldo_ov_flag(        ldo_ov_flag),
.circuit_exc_flag(        circuit_exc_flag),
.int_status(int_status),
.int_out(int_out)
);

initial begin
    //$fsdbDumpfile("int_ctrl_tb");
    $fsdbDumpfile("int_ctrl_tb.fsdb");
    $fsdbDumpvars(0,U_INT_CTRL_0);
end
endmodule