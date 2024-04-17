module efuse_read#(
    parameter NR = 64,
    parameter RSEL = 256/NR
)(
    input clk,  // 6.5M
    input rst_n,
    // from&to digital
    input [5:0] rg_efuse_trd,   // TODO for bitwidth
    input [$clog2(RSEL)-1:0] read_sel,
    input read_start,
    output logic read_done,
    output logic [NR-1:0] read_data,
    output logic busy_read,
    // from&to efuse
    output logic efuse_pgmen_o,
    output logic efuse_rden_o,
    output logic efuse_aen_o,
    output logic [7:0] efuse_addr_o,
    input [7:0] efuse_rdata
);

parameter BYTE_NUM = NR/8;    // 64/8=8

logic read_done_en;
logic read_start_d1;
logic aen_low_done;
logic aen_high_done;
logic [4:0] efuse_byte_addr;
logic read_hold;
logic rdata_lock_en;
logic [6:0] read_cnt;   // TODO for bitwidth
logic read_cnt_clear;
logic read_cnt_en;
logic read_done_en_pre;

// generate ctrl sig for EFUSE
assign efuse_pgmen_o =  1'b0;

always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        efuse_rden_o <= 1'b0;
    else if(read_start)
        efuse_rden_o <= 1'b1;
    else if(read_done_en)
        efuse_rden_o <= 1'b0;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        efuse_aen_o <= 1'b0;
    else if(read_start_d1 | aen_low_done)   
        efuse_aen_o <= 1'b1;
    else if(aen_high_done)  
        efuse_aen_o <= 1'b0;
end

assign efuse_addr_o = {3'd0,efuse_byte_addr};
always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        efuse_byte_addr <= 'd0;
    else if(read_start)
        efuse_byte_addr <= BYTE_NUM*read_sel;
    else if(read_hold)  
        efuse_byte_addr <= efuse_byte_addr + 1'b1;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        read_data <= 'd0;
    else if(read_start)
        read_data <= 'd0;
    else if(rdata_lock_en)  
        read_data <= {read_data[NR-9:0],efuse_rdata};
end

// generate sig for digital
always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        read_done <= 1'b0;
    else if(read_start)
        read_done <= 1'b0;
    else if(read_done_en)
        read_done <= 1'b1;
end

always_ff @(posedge clk or negedge rst_n) begin // TODO :??with read_done
    if(~rst_n)
        busy_read <= 1'b0;
    else if(read_start)
        busy_read <= 1'b1;
    else if(read_done_en)
        busy_read <= 1'b0;
end

// timing ctrl
always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        read_cnt <= 'd0;
    else if(read_cnt_clear)
        read_cnt <= 'd0;
    else if(read_cnt_en)
        read_cnt <= read_cnt + 1'b1;
end
assign read_cnt_clear = read_start | read_start_d1 | aen_high_done | aen_low_done;
always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        read_cnt_en <= 1'b0;
    else if(read_start)
        read_cnt_en <= 1'b1;
    else if(read_done_en_pre)
        read_cnt_en <= 1'b0;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        read_start_d1 <= 1'b0;
    else
        read_start_d1 <= read_start;
end

assign read_hold = (read_cnt=='d0) & busy_read & ~read_start_d1 & ~efuse_aen_o;
assign rdata_lock_en = (read_cnt=={1'b0,rg_efuse_trd}) & efuse_aen_o & busy_read;
assign aen_high_done = (read_cnt=={1'b0,rg_efuse_trd}+1'b1) & efuse_aen_o & busy_read;
assign aen_low_done = (read_cnt==7'hf) & ~efuse_aen_o & busy_read;
assign read_done_en_pre = aen_high_done & (efuse_byte_addr == BYTE_NUM*read_sel+BYTE_NUM-1);
assign read_done_en = read_hold & (efuse_byte_addr == BYTE_NUM*read_sel+BYTE_NUM-1);

endmodule