module int_ctrl_tb();
parameter NW = 12;
logic           clk_32k;
logic           rst_n;
logic [NW-1:0]  events_enable_int;   // correlate with INT pin 
logic [NW-1:0]  event_clear; // int clear
logic           rg_int_low_en;    // 0: HIGH; 1: LOW
logic           rg_int_level_en;  // 0: pulse; 1: level
logic [10:0]    rg_int_width;  // [1;2048]xT32k
logic [5:0]     rg_cold_time;   // [1;64]x1ms
logic           int_after_frame;  // 0: now; 1: after frame
logic           rg_timer_on;
logic           rg_timer_mode;  // 0: single; 1: auto
logic [8:0]     rg_timer_sel;   // [1;300]x0.2s
logic           frame_on;
logic           fifo_upov_flag;
logic           fifo_downov_flag;
logic           fifo_waterline_flag;
logic           user_int_triger;  // user_int_info TODO
logic           frame_done_flag;
logic           data_satg_flag;
logic           sample_err_flag;
logic           cap_cancel_done_flag;
logic           ldo_ov_flag;
logic           opst_exc_flag;
// intr output
logic [NW-1:0] events;   // RO; int status
logic          int_out;

logic clk_1k;

always #15625 clk_32k=~clk_32k;
always #500000 clk_1k=~clk_1k;

initial begin
    clk_32k = 0;
    clk_1k = 0;
    rst_n = 0;
    events_enable_int = -1;
    event_clear = 0;
    rg_int_low_en = 0;
    rg_int_level_en = 1;
    rg_int_width = 11'h27f;
    rg_cold_time = 6'h13;
    int_after_frame = 0;
    rg_timer_on   = 0;
    rg_timer_mode = 0;
    rg_timer_sel  = 0;
    frame_on = 0;
    fifo_upov_flag = 0;      
    fifo_downov_flag = 0;    
    fifo_waterline_flag = 0; 
    user_int_triger = 0;     
    frame_done_flag = 0;     
    data_satg_flag = 0;      
    sample_err_flag = 0;     
    cap_cancel_done_flag = 0;
    ldo_ov_flag = 0;      
    opst_exc_flag = 0;     
    repeat(5) @(negedge clk_1k); 
    @(negedge clk_32k);
    rst_n = 1;
    repeat(10) @(negedge clk_1k);  
    @(negedge clk_32k);
    event_clear = -1;
    @(negedge clk_32k);
    event_clear = 0;
    repeat(10) @(negedge clk_1k);  
    @(negedge clk_32k);
    user_int_triger = 1;
    @(negedge clk_32k);
    user_int_triger = 0;
    repeat(100) @(negedge clk_1k);  
    @(negedge clk_32k);
    event_clear = -1;
    @(negedge clk_32k);
    event_clear = 0;
    repeat(100) @(negedge clk_1k); 
    $finish(2);

end

int_ctrl #(.NW(12)) int_ctrl_inst(
.clk_32k(              clk_32k     ),
.rst_n(                rst_n     ),
.events_enable_int(    events_enable_int),
.event_clear(        event_clear),
.rg_int_low_en(        rg_int_low_en ),
.rg_int_level_en(      rg_int_level_en ),
.rg_int_width(         rg_int_width ),
.rg_cold_time(        rg_cold_time  ),
.int_after_frame(      int_after_frame  ),
.rg_timer_on(          rg_timer_on ),
.rg_timer_mode(        rg_timer_mode  ),
.rg_timer_sel(         rg_timer_sel    ),   
.frame_on(             frame_on),
.fifo_upov_flag(       fifo_upov_flag ),
.fifo_downov_flag(     fifo_downov_flag  ),
.fifo_waterline_flag(  fifo_waterline_flag   ),  
.user_int_triger(      user_int_triger    ),       
.frame_done_flag(      frame_done_flag   ),    
.data_satg_flag(       data_satg_flag   ),  
.sample_err_flag(      sample_err_flag   ), 
.cap_cancel_done_flag( cap_cancel_done_flag   ),     
.ldo_ov_flag(        ldo_ov_flag),
.opst_exc_flag(        opst_exc_flag),
.events(events),
.int_out(int_out)
);

initial begin
    $fsdbDumpfile("int_ctrl_tb");
    $fsdbDumpvars();
end
endmodule