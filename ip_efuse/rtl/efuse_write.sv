module efuse_write#(
    parameter NW = 64,
    parameter WSEL = 256/NW
)(
    input clk,  // 6.5M
    input rst_n,
    // from&to digital
    input [9:0] rg_efuse_tpgm,   // TODO for bitwidth
    input [$clog2(WSEL)-1:0] write_sel,
    input [NW-1:0] write_data,
    input write_start,
    output logic write_done,
    output logic busy_write,
    // from&to efuse
    output logic eufse_pgmen_o,
    output logic efuse_rden_o,
    output logic efuse_aen_o,
    output logic [7:0] efuse_addr_o
);

logic [NW-1:0] wdata_rest;
logic start_fsm;
logic write_done_en;
logic aen_high_done;
logic aen_low_done;
logic [9:0] write_cnt;
logic write_cnt_clear;
logic write_cnt_en;

typedef enum logic [2:0] {STANDBY,START_JUDGE,INIT,WDATA_JUDGE,AEN_H,AEN_L,W_HOLD} state_t;
state_t state_c,state_n;

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
            STANDBY: begin
                state_n = write_start?  START_JUDGE:STANDBY;
            end
            START_JUDGE: begin
                state_n = (|write_data)?    INIT:STANDBY;
            end
            INIT: begin
                state_n = WDATA_JUDGE;
            end
            WDATA_JUDGE: begin
                if(wdata_rest == 'd0)
                    state_n = STANDBY;
                else
                    state_n = wdata_rest[0]?    AEN_H:AEN_L;
            end
            AEN_H: begin
                state_n = aen_high_done?    W_HOLD:AEN_H;
            end
            W_HOLD: begin
                state_n = (|wdata_rest)?    AEN_L:STANDBY;
            end
            AEN_L: begin
                state_n = aen_low_done? WDATA_JUDGE:AEN_L;
            end
            default:
                state_n = STANDBY;
        endcase
    end
end

assign busy_write = (state_c!=STANDBY);

// generate ctrl sig for EUSE
assign eufse_pgmen_o = (state_c!=STANDBY);
assign efuse_rden_o = 1'b0;
assign efuse_aen_o = (state_c==AEN_H);

always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        efuse_addr_o <= 'd0;
    else if(write_done_en)
        efuse_addr_o <= 'd0;
    else if(start_fsm)
        efuse_addr_o <= NW*write_sel;
    else if(addr_change_en)
        efuse_addr_o <= (efuse_addr_o==NW*write_sel)?    NW*write_sel : efuse_addr_o+1'b1;
end

// generate sig for digital
always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        write_done <= 1'b0;
    else if(start_fsm)  // why 
        write_done <= 1'b0;
    else if(write_done_en)
        write_done <= 1'b1;
end
assign write_done_en = (state_c!=STANDBY && state_n==STANDBY);

// generate fsm ctrl sig
always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        wdata_rest <= 'd0;
    else if(start_fsm)
        wdata_rest <= write_data;
    else if(state_c==WDATA_JUDGE)
        wdata_rest <= (wdata_rest >> 1);
end

assign start_fsm = (state_c==STANDBY && write_start);
assign addr_change_en = (state_c==INIT) || (state_c==AEN_L && aen_low_done);

// timing ctrl
always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        write_cnt <= 'd0;
    else if(write_cnt_clear)
        write_cnt <= 'd0;
    else if(write_cnt_en)
        write_cnt <= write_cnt + 1'b1;
end
assign write_cnt_clear = (state_c==WDATA_JUDGE) | aen_high_done | aen_low_done;
assign write_cnt_en = (state_c==AEN_H) | (state_c==AEN_L);

assign aen_high_done = (state_c==AEN_H) && (write_cnt==(rg_efuse_tpgm-1'b1));
assign aen_low_done = (state_c==AEN_L) && (write_cnt==10'd13);

endmodule