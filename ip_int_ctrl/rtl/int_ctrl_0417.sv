module int_ctrl
#(
    parameter       NW = 11   // int bitwidth
)(
    input           clk_32k,    // From crgu
    input           rst_n,      // From crgu
    // int config
    input [NW-1:0]  rg_int_enable,   // From reg_ctrl @ 6.5M    // TODO : whether to dyna 
    input [NW-1:0]  rg_int_clr,     // From reg_manual after-sync @ 32K //  TODO : merge with status by rdl : onwrite = woclr;
    input           rg_int_low_en,    // From reg_ctrl @ 6.5M    // 0: HIGH, 1: LOW
    input           rg_int_level_en,  // From reg_ctrl @ 6.5M    // 0: pulse, 1: level
    input [10:0]    rg_int_width,  // From reg_ctrl @ 6.5M    // [1,2048]xT32k
    input [5:0]     rg_cold_time,   //From reg_ctrl @ 6.5M    // [1,64]x1ms
    input           rg_int_after_frame,  //From reg_ctrl @ 6.5M    // 0: now, 1: after frame
    input           rg_timer_on,    //From reg_manual after-sync @ 32K  // TODO
    input           rg_timer_mode,  //From reg_ctrl @ 6.5M  // 0: single, 1: auto
    input [8:0]     rg_timer_sel,   //From reg_ctrl @ 6.5M  // [1,300]x0.2s
    input           frame_on,       // From timeslot_manager need-sync  // TODO
    // extra int source
    input           fifo_upov_flag, // From FIFO @ 32K
    input           fifo_downov_flag,   // From FIFO @ 32K
    input           fifo_waterline_flag,    // From FIFO @ 32K
    input           user_int_triger,  // From reg_manual after-sync @ 32K //  TODO : add info reg
    input           frame_done_flag,   // From timeslot_manager @ 32K
    input           sample_err_flag,    // From timeslot_manager @ 32K
    input           cap_cancel_done_flag,   // From timeslot_manager @ 32K
    input           ldo_ov_flag,        // From AD interface @ 32K  
    input           circuit_exc_flag,   // From AFE @ 32K
    // int output
    output logic [NW-1:0] int_status,   // To reg_ctrl  // RO, int status
    output logic          int_out       // To PAD

);

logic timer_int_flag;
logic reset_int_flag;

logic reset_state;
logic reset_state_d1;

logic [NW-1:0] int_req_sync;
logic [NW-1:0] int_req_sync_d1;
logic [NW-1:0] int_req_pos;
logic [NW-1:0] int_lat;
logic [NW-1:0] int_req_real;
logic [NW-1:0] int_clr_sync;    // TODO for sync
logic [NW-1:0] int_clr_real;
logic [NW-1:0] int_enable;

logic int_vld;
logic int_out_vld;

logic int_on_d1;
logic int_on_neg;
logic int_on;
logic int_on_final;
logic int_on_real;

logic tout_en;
logic tout_en_d1;
logic tout_en_pos;

logic time_out;
logic time_out_tmp;
logic [10:0] tcnt;
logic [10:0] width_time;
logic [10:0] cold_time;

logic clear_int;
logic set_int;
logic int_out_tmp;

logic check_pulse;
logic gap_en;
logic mask;
logic [4:0] gcnt;

logic timer_on_sync;
logic timer_on_sync_d1;
logic timer_on_sync_neg;
logic [12:0] timer_cnt;
logic [8:0] step_cnt;


genvar i;
generate
    for(i=0;i<NW;i=i+1) begin:  rg_int_after_frame_BK
        if(i==7) begin  // for sample rate error
            assign int_req_real[i] = int_req_pos[i];
        end
        else begin
            always_ff @(posedge clk_32k or negedge rst_n)  begin
                if(~rst_n)
                    int_lat[i] <= 1'b0;
                else if(rg_int_after_frame)  begin
                    if(int_req_pos[i])
                        int_lat[i] <= 1'b1;
                    else if(int_clr_sync[i])
                        int_lat[i] <= 1'b0;
                    else if(~frame_done_flag)   // TODO for sync
                        int_lat[i] <= 1'b0;
                end
            end
            assign int_req_real[i] = rg_int_after_frame?   (int_lat[i] & ~frame_on) : int_req_pos[i];
        end 
    end
endgenerate

generate
    for(i=0;i<NW;i=i+1) begin:  int_status_BK
        always_ff @(posedge clk_32k or negedge rst_n)  begin
            if(~rst_n)  
                int_status[i] <= 1'b0;
            else if(int_req_real[i])
                int_status[i] <= 1'b1;
            else if(int_clr_sync[i])
                int_status[i] <= 1'b0;
        end
    end
endgenerate

/*
always_ff @(posedge clk_32k or negedge rst_n)  begin
    if(~rst_n)
        int_status <= 'd0;
    else if(|int_req_real)
        int_status <= int_req_real | int_status;
    else if(|int_clr_real)
        int_status <= (~int_clr_real) & int_status; 
end
*/

assign int_vld = rg_int_low_en? 1'b0:1'b1;
assign int_out_vld = (int_out == int_vld);

assign int_clr_real = (int_clr_sync & ~int_req_real);  

assign int_on = |(int_status & int_enable);

assign int_on_real = rg_int_level_en?   int_on:int_on_final;

assign cold_time = {rg_cold_time,5'd0}+13'd30;
assign width_time = rg_int_width;
assign time_out_tmp = int_out_vld?  (tcnt==width_time):(tcnt==cold_time);
assign time_out = time_out_tmp | tout_en_pos;
assign tout_en = int_out_vld | int_on_real;

always_ff @(posedge clk_32k or negedge rst_n)  begin
    if(~rst_n)
        tcnt <= 'd0;
    else if(~rg_int_level_en) begin
        if(reset_int_flag)
            tcnt <= cold_time;
        else if(clear_int | set_int | time_out)
            tcnt <= 'd0;
        else if(tout_en)
            tcnt <= tcnt+1'b1;
    end
    else
        tcnt <= 'd0;
end

assign clear_int = (int_out_vld & time_out & ~rg_int_level_en) || (~int_on && int_out_vld);

always_ff @(posedge clk_32k or negedge rst_n)  begin
    if(~rst_n)
        set_int <= 1'b0;
    else if(rg_int_level_en)
        set_int <= (int_on_real & ~int_out_vld);
    else
        set_int <= (int_on_real & time_out & ~int_out_vld);
end

always_ff @(posedge clk_32k or negedge rst_n)  begin
    if(~rst_n)
        int_out_tmp <= 1'b0;
    else if(set_int)
        int_out_tmp <= 1'b1;
    else if(clear_int)
        int_out_tmp <= 1'b0;
end

assign int_out = int_out_tmp?   int_vld:~int_vld;

// reset_int_flag
always_ff @(posedge clk_32k or negedge rst_n)   begin
    if(~rst_n)
        {reset_state, reset_state_d1} <= 2'd0;
    else 
        {reset_state, reset_state_d1} <= {1'b1,reset_state};
end
assign reset_int_flag = reset_state & ~reset_state_d1;

// timer_int_flag
always_ff @(posedge clk_32k or negedge rst_n) begin
    if(~rst_n)
        timer_cnt <= 'd0;
    else if(timer_on_sync_neg)
        timer_cnt <= 'd0;
    else if(timer_on_sync)  begin
        if(rg_timer_mode)
            timer_cnt <= (timer_cnt == 13'd6399)?   'd0:timer_cnt+1'b1;
        else begin
            if(timer_cnt ==13'd6399)
                timer_cnt <= (step_cnt == rg_timer_sel)?    13'd6399:'d0;
            else
                timer_cnt <= timer_cnt+1'b1;
        end
    end
end

always_ff @(posedge clk_32k or negedge rst_n) begin
    if(~rst_n)
        step_cnt <= 'd0;
    else if(timer_on_sync_neg)
        step_cnt <= 'd0;
    else if(timer_on_sync)  begin
        if(rg_timer_mode)  begin
            if(timer_cnt == 13'd6399)
                step_cnt <= (step_cnt == rg_timer_sel)?    'd0:step_cnt+1'b1;
        end
        else begin
            if(timer_cnt == 13'd6399)
                step_cnt <= (step_cnt == rg_timer_sel)?    rg_timer_sel:step_cnt+1'b1;
        end
    end
end

always_ff @(posedge clk_32k or negedge rst_n) begin
    if(~rst_n)
        timer_int_flag <= 1'b0;
    else if({step_cnt,timer_cnt}=={rg_timer_sel,13'd6399})
        timer_int_flag <= 1'b1;
    else
        timer_int_flag <= 1'b0;
end

// pulse gap
/*
pulse_gap pulse_gap_inst(
    .clk(clk_32k),
    .rstn(rst_n),
    .check_pulse(|int_clr_real && int_on_neg),
    .int_on(int_on),
    .int_out_vld(int_out_vld),
    .tcnt(tcnt),
    .int_on_final(int_on_final)
);
*/
assign check_pulse = (|int_clr_real && int_on_neg);
assign gap_en = int_out_vld?    check_pulse:(check_pulse & (tcnt<11'd28));

always_ff @(posedge clk_32k or negedge rst_n)  begin
    if(~rst_n)
        gcnt <= 'd0;
    else if(gap_en)
        gcnt <= int_out_vld?    5'd29:(5'd28-tcnt);
    else if(gcnt!=5'd0)
        gcnt <= gcnt-1'b1;
end

always_ff @(posedge clk_32k or negedge rst_n)  begin
    if(~rst_n)
        mask <= 1'b0;
    else if(gcnt!=5'd0)
        mask <= 1'b1;
    else
        mask <= 1'b0;
end
assign int_on_final = int_on & ~mask;

// sync
// TODO for int_req sync
assign int_req_sync = {
                        circuit_exc_flag,       // 10
                        ldo_ov_flag,            // 9
                        cap_cancel_done_flag,   // 8
                        sample_err_flag,        // 7
                        frame_done_flag,        // 6
                        user_int_triger,        // 5
                        timer_int_flag,         // 4
                        fifo_waterline_flag,    // 3
                        fifo_downov_flag,       // 2
                        fifo_upov_flag,         // 1
                        reset_int_flag          // 0 
                    };
always_ff @(posedge clk_32k or negedge rst_n) begin
    if(~rst_n)
        int_req_sync_d1 <= 'd0;
    else 
        int_req_sync_d1 <= int_req_sync;
end
assign int_req_pos = int_req_sync & ~int_req_sync_d1;

always_ff @(posedge clk_32k or negedge rst_n) begin
    if(~rst_n)
        int_on_d1 <= 'd0;
    else 
        int_on_d1 <= int_on;
end
assign int_on_neg = int_on_d1 & ~int_on;

always_ff @(posedge clk_32k or negedge rst_n) begin
    if(~rst_n)
        tout_en_d1 <= 'd0;
    else 
        tout_en_d1 <= tout_en;
end
assign tout_en_pos = tout_en & ~tout_en_d1;

always_ff @(posedge clk_32k or negedge rst_n) begin
    if(~rst_n)
        timer_on_sync_d1 <= 'd0;
    else 
        timer_on_sync_d1 <= timer_on_sync;
end
assign timer_on_sync_neg = timer_on_sync_d1 & ~timer_on_sync;

assign int_clr_sync = rg_int_clr;
assign int_enable = rg_int_enable;
assign timer_on_sync = rg_timer_on;

endmodule