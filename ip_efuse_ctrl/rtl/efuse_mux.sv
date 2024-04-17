module efuse_mux#(
    parameter NW = 64,
    parameter NR = 64    
)(
    input clk,
    input rst_n,
    input scan_mode,
    input rg_efuse_reg_mode,
    input rg_efuse_pgmen,
    input rg_efuse_rden,
    input rg_efuse_aen,
    input [7:0] rg_efuse_addr,
    output logic [7:0] rg_efuse_d,
    input read_pgmen,
    input read_rden,
    input read_aen,
    input [7:0] read_addr,
    output logic [7:0] read_rdata,
    input busy_read,
    input write_pgmen,
    input write_rden,
    input write_aen,
    input [7:0] write_addr,
    input busy_write,
    output logic efuse_pgmen_o,
    output logic efuse_rden_o,
    output logic efuse_aen_o,
    output logic [7:0] efuse_addr_o,
    input [7:0] efuse_rdata_i
);

logic rtl_efuse_pgmen;
logic rtl_efuse_rden;
logic rtl_efuse_aen;
logic [7:0] rtl_efuse_addr;
logic [7:0] rtl_efuse_rdata;

logic use_efuse_pgmen;
logic use_efuse_rden;
logic use_efuse_aen;
logic [7:0] use_efuse_addr;
logic [7:0] use_efuse_rdata;

logic use_efuse_pgmen_d1;
logic use_efuse_rden_d1;
logic use_efuse_aen_d1;
logic [7:0] use_efuse_addr_d1;

assign rtl_efuse_pgmen = busy_read? read_pgmen:
                         busy_write? write_pgmen:
                         1'b0;
assign rtl_efuse_rden =  busy_read? read_rden:
                         busy_write? write_rden:
                         1'b0;
assign rtl_efuse_addr =  busy_read? read_addr:
                         busy_write? write_addr:
                         8'd0;
assign rtl_efuse_aen =   busy_read? read_aen:
                         busy_write? write_aen:
                         1'b0;
assign read_rdata = rtl_efuse_rdata;

assign use_efuse_pgmen = rg_efuse_reg_mode? rg_efuse_pgmen:rtl_efuse_pgmen;
assign use_efuse_rden = rg_efuse_reg_mode? rg_efuse_rden:rtl_efuse_rden;
assign use_efuse_aen = rg_efuse_reg_mode? rg_efuse_aen:rtl_efuse_aen;   // TODO rg_efuse_aen replace
assign use_efuse_addr = rg_efuse_reg_mode? rg_efuse_addr:rtl_efuse_addr;
assign rtl_efuse_rdata = rg_efuse_reg_mode? 8'b0:use_efuse_rdata;
assign rg_efuse_d = rg_efuse_reg_mode? use_efuse_rdata:8'd0;

// add for scan
// ******

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        {use_efuse_pgmen_d1,use_efuse_rden_d1,use_efuse_aen_d1,use_efuse_addr_d1} <= 'd0;
    else 
        {use_efuse_pgmen_d1,use_efuse_rden_d1,use_efuse_aen_d1,use_efuse_addr_d1} <= {use_efuse_pgmen,use_efuse_rden,use_efuse_aen,use_efuse_addr};
end

assign efuse_pgmen_o = scan_mode?   1'b0:use_efuse_pgmen_d1;
assign efuse_rden_o = scan_mode?   1'b0:use_efuse_rden_d1;
assign efuse_aen_o = scan_mode?   1'b0:use_efuse_aen_d1;
assign efuse_addr_o = scan_mode?   8'd0:use_efuse_addr_d1;
assign use_efuse_rdata = efuse_rdata_i; // scan

endmodule