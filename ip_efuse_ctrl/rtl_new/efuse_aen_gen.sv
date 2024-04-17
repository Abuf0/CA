module efuse_aen_gen(
    input clk,
    input rst_n,
    input [9:0] rg_efuse_tpgm,
    input rg_efuse_reg_mode,
    input rg_efuse_refresh, // TODO add
    input rg_efuse_pgmen,
    input rg_efuse_rden,
    input rg_efuse_aen,
    input [7:0] rg_efuse_addr,
    output logic rg_efuse_aen_use,
    output logic rg_efuse_aen_done
);

logic aen_off;
logic aen_on;
logic efuse_aen_write;
logic efuse_addr_clear;
logic efuse_addr_en;
logic rg_efuse_addr_pre;
logic rg_efuse_refresh_d1;
logic [9:0] aen_high_cnt;
logic aen_high_cnt_clear;
logic aen_high_cnt_en;



always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        rg_efuse_aen_done <= 1'b0;
    else if(rg_efuse_reg_mode && rg_efuse_refresh & (rg_efuse_pgmen ^ rg_efuse_rden))
        rg_efuse_aen_done <= 1'b0;
    else if(aen_off)
        rg_efuse_aen_done <= 1'b1;
end

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        efuse_aen_write <= 1'b0;
    else if(aen_off)
        efuse_aen_write <= 1'b0;
    else if(aen_on)
        efuse_aen_write <= 1'b1;
end

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        rg_efuse_addr_pre <= 'b0;
    else if(efuse_addr_clear)
        rg_efuse_addr_pre <= 'b0;
    else if(efuse_addr_en)
        rg_efuse_addr_pre <= rg_efuse_addr;
end

assign efuse_addr_clear = rg_efuse_refresh_d1 & ~(rg_efuse_pgmen ^ rg_efuse_rden);   // TODO
assign efuse_addr_en = rg_efuse_reg_mode & rg_efuse_refresh_d1 & (rg_efuse_pgmen ^ rg_efuse_rden);  // TODO
assign aen_on = rg_efuse_refresh_d1 && (rg_efuse_addr!=rg_efuse_addr_pre) && (rg_efuse_pgmen ^ rg_efuse_rden);

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        aen_high_cnt <= 'd0;
    else if(aen_high_cnt_clear)
        aen_high_cnt <= 'd0;
    else if(aen_high_cnt_en)
        aen_high_cnt <= aen_high_cnt + 1'b1;
end

assign aen_high_cnt_clear = aen_on | aen_off;
assign aen_high_cnt_en = efuse_aen_write && (aen_high_cnt < rg_efuse_tpgm-1'b1) && (rg_efuse_pgmen ^ rg_efuse_rden);
assign aen_off = efuse_aen_write && (aen_high_cnt == rg_efuse_tpgm-1'b1);

assign rg_efuse_aen_use = ~(rg_efuse_pgmen ^ rg_efuse_rden)?    rg_efuse_aen:efuse_aen_write;


endmodule