module efuse_rw_ctrl#(
    parameter NW = 64,
    parameter NR = 64
)(
    input                       clk,
    input                       rst_n,
    input                       pmu_efuse_start,
    // config from digit
    input [1:0]                 rg_efuse_mode,
    input                       rg_efuse_start,
    input [$clog2(256/NR)-1:0]  rg_efuse_read_sel, // TODO
    input [$clog2(256/NW)-1:0]  rg_efuse_write_sel, // TODO
    input [15:0]                rg_efuse_password,
    input                       rg_efuse_blank_en,
    input [NW-1:0]              rg_efuse_wdata,
    // RO to reg_ctrl
    output logic [NR-1:0]       rg_efuse_rdata,
    output logic                rg_efuse_read_done_manual,
    output logic                rg_efuse_write_done_manual,
    output logic                rg_efuse_no_blank,
    output logic                efuse_autoload_done,
    output logic                efuse_autoload_vld,
    output logic                efuse_busy,
    output logic [$clog2(256/NR)-1:0] efuse_read_sel, // TODO
    output logic [$clog2(256/NW)-1:0] efuse_write_sel, // TODO 
    output logic                read_start,          
    input                       read_done,
    input [NR-1:0]              read_data,
    input                       efuse_busy_read,
    output logic                write_start,
    input                       write_done,   // TODO
    output logic [NW-1:0]       write_data, // TODO
    input                       efuse_busy_write    
);

parameter AUTOLOAD_TIMES = 256/NR;

typedef enum logic [1:0] {STANDBY,AUTOLOAD,READ,WRITE} state_t;
state_t state_c,state_n;

logic read_en;
logic write_en;
logic [$clog2(256/NR)-1:0] autoload_cnt;
logic read_done_d1;
logic read_done_d2;
logic read_done_d1_pos;
logic read_done_pos;
logic autoload_done_pre;
logic autoload_done_pre_d1;
logic is_autoload;
logic [NR-1:0] efuse_autoload_data;
logic [NR-1:0] read_data_manual;
logic efuse_no_blank;
logic read_start_auto_pre;
logic read_start_auto;
logic efuse_busy_pre;


assign read_en = efuse_autoload_done && read_start;
assign write_en = efuse_autoload_done && write_start;

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        state_c <= STANDBY;
    else
        state_c <= state_n;
end
always @(*) begin
    if(~rst_n)
        state_n = STANDBY;
    else begin
        state_n = STANDBY;
        case(state_c)
            STANDBY:    begin
                state_n = pmu_efuse_start?  AUTOLOAD:
                          read_en?          READ:
                          write_en?         WRITE:
                                            STANDBY;
            end
            AUTOLOAD:   begin
                state_n = efuse_autoload_done?    STANDBY:AUTOLOAD;
            end
            READ:   begin
                state_n = read_done?    STANDBY:READ;
            end
            WRITE:  begin
                state_n = write_done?   STANDBY:WRITE;
            end
            default:
                state_n = STANDBY;
        endcase
    end
end

assign is_autoload = (state_c==AUTOLOAD);

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        autoload_cnt <= 'd0;
    else if(pmu_efuse_start)
        autoload_cnt <= 'd0;
    else if(is_autoload && read_done_d1_pos)
        autoload_cnt <= autoload_cnt + 1'b1;
end

assign autoload_done_pre = ((autoload_cnt == AUTOLOAD_TIMES-1) && read_done_d1_pos && is_autoload);
always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        efuse_autoload_done <= 1'b0;
    else if(autoload_done_pre_d1)
        efuse_autoload_done <= 1'b1;
end

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        efuse_autoload_data <= 'd0;
    else if(is_autoload && read_done_pos)
        efuse_autoload_data <= read_data;
end

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        efuse_autoload_vld <= 1'b0;
    else if(autoload_done_pre)
        efuse_autoload_vld <= 1'b1;
    else 
        efuse_autoload_vld <= 1'b0;
end

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        efuse_no_blank <= 1'b0;
    else if(is_autoload & read_done_d1_pos & rg_efuse_blank_en) // TODO
        efuse_no_blank <= (efuse_no_blank | (efuse_autoload_data != 'd0));
end

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        rg_efuse_no_blank <= 1'b0;
    else if(autoload_done_pre_d1 && rg_efuse_blank_en)
        rg_efuse_no_blank <= efuse_no_blank;
end

assign efuse_read_sel = is_autoload?    autoload_cnt:rg_efuse_read_sel;
assign read_start_manual = (rg_efuse_mode==2'd0) && rg_efuse_start && ~efuse_busy_pre;
assign write_start_manual = (rg_efuse_mode==2'd1) && rg_efuse_start && ~efuse_busy_pre;
assign read_start = read_start_auto | read_start_manual;     
assign write_start = write_start_manual;
assign write_data = rg_efuse_wdata;
assign efuse_write_sel = rg_efuse_write_sel;
assign rg_efuse_write_done_manual = write_done;

assign efuse_busy_pre = is_autoload | efuse_busy_read | efuse_busy_write;

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        read_start_auto <= 1'b0;
    else if(read_start_auto_pre)
        read_start_auto <= 1'b1;
    else 
        read_start_auto <= 1'b0;
end

assign read_start_auto_pre = pmu_efuse_start | (is_autoload & read_done_d1_pos & autoload_cnt < AUTOLOAD_TIMES-1);

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        efuse_busy <= 1'b0;
    else 
        efuse_busy <= efuse_busy_pre;
end

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        rg_efuse_read_done_manual <= 1'b0;
    else if(read_start_manual)
        rg_efuse_read_done_manual <= 1'b0;
    else if(read_done_pos && (state_c==READ))
        rg_efuse_read_done_manual <= 1'b1;
end

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        read_data_manual <= 'd0;
    else if(read_done_pos && (state_c==READ))
        read_data_manual <= read_data;
end

assign autoload_data_pre = is_autoload & read_done_d1_pos & (autoload_cnt==2'd1);    // TODO ???

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        rg_efuse_rdata <= 'd0;
    else if(autoload_data_pre)
        rg_efuse_rdata <= efuse_autoload_data;
    else if(rg_efuse_read_done_manual)
        rg_efuse_rdata <= read_data_manual;
end

//
always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        autoload_done_pre_d1 <= 1'b0;
    else 
        autoload_done_pre_d1 <= autoload_done_pre;
end
always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        {read_done_d2,read_done_d1} <= 2'd0;
    else 
        {read_done_d2,read_done_d1} <= {read_done_d1,read_done};
end
assign read_done_pos = read_done & ~read_done_d1;
assign read_done_d1_pos = read_done_d1 & ~read_done_d2;

endmodule