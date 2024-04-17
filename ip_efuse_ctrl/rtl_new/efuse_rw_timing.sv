module efuse_rw_timing#(parameter NW=64,parameter NR=64)(
    input clk,
    input rst_n,
    input read_start,   //
    input write_start,  //
    input [$clog2(256/NR)-1:0]  read_sel, 
    input [$clog2(256/NW)-1:0]  write_sel,
    input is_autoload,
    input [5:0] rg_efuse_trd,
    input [9:0] rg_efuse_tpgm,
    input rg_efuse_mode,    // 0:read 1:write
    input [NW-1:0] write_data,    //
    output logic [NR-1:0] read_data,
    output logic efuse_pgmen,
    output logic efuse_rden,
    output logic efuse_aen,
    output logic [7:0] efuse_addr,
    input [7:0] efuse_d,
    output logic busy_read,
    output logic busy_write,
    output logic read_done,
    output logic write_done
);

parameter WSEL=NW;
parameter RSEL=NR/8;
typedef enum logic [1:0] {IDLE,INIT,AEN_H,AEN_L} state_t;
state_t state_c,state_n;

//typedef enum logic [1:0] {RIDLE,RINIT,RAEN_H,RAEN_L} rstate_t;
//rstate_t rstate_c,rstate_n;
//typedef enum logic [1:0] {WIDLE,WINIT,WAEN_H,WAEN_L} wstate_t;
//wstate_t wstate_c,wstate_n;

logic init_done;
logic low_end;
logic high_end;
logic low_timeout;
logic high_timeout;
logic [5:0] high_time;
logic [9:0] low_time;
logic [9:0] tcnt;
logic read_done_pre;
logic write_done_pre;
logic [63:0] wdata_rest;
logic efuse_d_lock_en;
logic write_skip;
logic [7:0] read_end_addr;

assign init_done = 1'b1;
assign high_timeout = efuse_aen && (tcnt == high_time+1'b1);
assign low_timeout = (~efuse_aen) && (tcnt == low_time);
assign high_time = rg_efuse_mode?   rg_efuse_tpgm : rg_efuse_trd;
assign low_time = rg_efuse_mode?    'd13:'d9;  // 1900ns : 1250ns
assign low_end = low_timeout;
assign high_end = high_timeout;
assign rw_start = rg_efuse_mode?    write_start : read_start;
assign read_end_addr = is_autoload?  8'd31:(RSEL*read_sel+RSEL-1);
assign read_done_pre = (efuse_addr == read_end_addr) && ~rg_efuse_mode && low_end;
assign write_done_pre = (state_c!=IDLE && state_n==IDLE) && rg_efuse_mode; 
assign efuse_d_lock_en = efuse_aen & ~rg_efuse_mode & (tcnt == high_time);

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        state_c <= IDLE;
    else
        state_c <= state_n;
end
always @(*) begin
    if(~rst_n)
        state_n = IDLE;
    else begin
        state_n = IDLE;
        case(state_c)
            IDLE:    begin
                state_n = rw_start?  INIT:IDLE;
            end
            INIT:   begin
                state_n = (rg_efuse_mode && ~|write_data)?  IDLE:
                          init_done?    AEN_H:INIT;
            end
            AEN_H:   begin
                state_n = high_end?    AEN_L:AEN_H;
            end
            AEN_L:  begin
                if(low_end) begin
                    if(rg_efuse_mode) begin
                        //if(write_done_pre | rest_zero)
                        //if(rest_zero)
                        if(~|wdata_rest)
                            state_n = IDLE;
                        else 
                            state_n = wdata_rest[0]?    AEN_H:AEN_L;
                    end
                    else
                        state_n = read_done?    IDLE:AEN_H;
                end
                else begin
                    state_n = AEN_L;
                end
            end
            default:
                state_n = IDLE;
        endcase
    end
end

assign efuse_pgmen = (state_c!=IDLE) && rg_efuse_mode;
assign efuse_rden = (state_c!=IDLE) && ~rg_efuse_mode;
//assign efuse_aen = (state_c==AEN_H);
always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        efuse_aen <= 1'b0;
    else if(state_c==AEN_H)
        efuse_aen <= 1'b1;
    else 
        efuse_aen <= 1'b0;
end
always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        efuse_addr <= 'd0;
    else if(state_c==INIT)
        //efuse_addr <= NB*rw_sel;
        efuse_addr <= rg_efuse_mode?    WSEL*write_sel:RSEL*read_sel;
    else if(((state_c==AEN_L) && (state_n==AEN_H)) || write_skip)   // or add tcnt==xx
        efuse_addr <= efuse_addr + 1'b1;
end
assign write_skip = (state_c == AEN_L && ~wdata_rest[0] && low_end);
always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        read_data <= 'd0;
    else if(read_start)
        read_data <= 'd0;
    else if(efuse_d_lock_en)  
        read_data <= {read_data[NR-9:0],efuse_d};
end

always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        read_done <= 1'b0;
    else if(read_start)
        read_done <= 1'b0;
    else if(read_done_pre)
        read_done <= 1'b1;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        write_done <= 1'b0;
    else if(write_start)
        write_done <= 1'b0;
    else if(write_done_pre)
        write_done <= 1'b1;
end

always_ff @(posedge clk or negedge rst_n) begin 
    if(~rst_n)
        busy_read <= 1'b0;
    else if(read_start)
        busy_read <= 1'b1;
    else if(read_done_pre)
        busy_read <= 1'b0;
end

always_ff @(posedge clk or negedge rst_n) begin 
    if(~rst_n)
        busy_write <= 1'b0;
    else if(write_start)
        busy_write <= 1'b1;
    else if(write_done_pre)
        busy_write <= 1'b0;
end

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        wdata_rest <= 'd0;
    else if(state_c==INIT && rg_efuse_mode)
        wdata_rest <= write_data;
    else if((state_c==AEN_H && high_end) || write_skip )
        wdata_rest <= (wdata_rest >> 1);
end

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        tcnt <= 'd0;
    else if(state_n != state_c)
        tcnt <= 'd0;
    else if(write_skip)
        tcnt <= 'd0;
    else if(state_c == AEN_H | state_c == AEN_L)
        tcnt <= tcnt + 1'b1;
end


endmodule