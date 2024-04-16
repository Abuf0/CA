module crgu(
    // scan
    input scan_clk,     // from PAD
    input scan_rstn,    // from PAD
    input scan_mode,    // from PAD
    input scan_enable,  // from PAD
    // clock source
    input AD_OSC32K,    // From AD interface
    input AD_OSC13M,    // From AD interface
    input CLKIN,    // from PAD
    input SPI_CLK,  // from PAD
    input I2C_CLK,  // from PAD
    // reset source
    input AD_POR_RSTN,  // From AD interface
    input cmd_reset,    // From spi/i2c
    input shut_rstn,    // From PMU
    // clock & reset ctrl 
    input rg_clk_sel,   // from reg_ctrl @ 6.5M
    input clk_en,   // From PMU @ 32K
    input rg_top_start, // From reg_ctrl @ 6.5M
    input data_ctrl_en, // TODO & for sync
    input rg_fifo_clk_en,   // From reg_ctrl @ 6.5M
    input rg_efuse_en,  // From reg_ctrl @ 6.5M
    // clock dest
    output logic clk_32k,  // To PMU, INT
    output logic clk_32k_tim,   // To timer_ctrl
    output logic clk_6p5m_reg,  // To reg_ctrl
    output logic clk_6p5m_spis, // To spis
    output logic clk_6p5m_i2cs, // To i2cs
    output logic clk_6p5m_data, // To data_ctrl
    output logic clk_6p5m_fifo, // To fifo_ctrl
    output logic clk_6p5m_efuse,// To efuse_ctrl
    output logic clk_13m_slot,  // To timeslog_manager
    output logic clk_13m_afe,   // To AFE
    // reset dest
    output logic rst_32k_alon_n,    // To PMU, INT
    output logic rst_reg_n,    // To reg_ctrl
    output logic rst_spis_n,    // To spis
    output logic rst_i2cs_n,    // To i2cs
    output logic rst_slot_n,    // To timeslot_manager
    output logic rst_afe_n,     // To AFE
    output logic rst_tim_n,     // To timer_ctrl
    output logic rst_data_n,    // To data_ctrl
    output logic rst_fifo_n,    // To fifo_ctrl
    output logic rst_fifo_spis_n,   // To spis
    output logic rst_fifo_i2cs_n,   // To i2cs
    output logic rst_clk_spis_n,    // To spis
    output logic rst_efuse_n   // To efuse_ctrl
);

logic AD_OSC32K_scan;
logic CLKIN_scan;
logic rg_top_start_sync;
logic AD_OSC13M_scan;
logic clk_en_sync;
logic clk_32k_alon_scan;
logic clk_32k_shut_scan;
logic clk_13m_alon_scan;
logic clk_13m_shut_scan;
logic clk_6p5m_alon;
logic clk_6p5m_alon_scan;
logic clk_6p5m_shut_scan;

logic clk_spis_scan;
logic clk_i2cs_scan;

logic ad_por_rstn_scan;
logic rst_13m_alon_n;
logic rst_13m_shut_n;
logic async_rst_alon_n;
logic async_rst_shut_n;
logic fifo_rstn;
logic rg_top_start_pos;
logic rg_top_start_d1;

// generate clock dest
// 32K
genpart_ckmux2 dtc_OSC32K_scanmux   (.clkin1(scan_clk), .clkin0(AD_OSC32K), .sel(scan_mode), .clkout(AD_OSC32K_scan));
genpart_ckmux2 dtc_CLKIN_scanmux   (.clkin1(scan_clk), .clkin0(CLKIN), .sel(scan_mode), .clkout(CLKIN_scan));
omsp_clock_mux clk_32k_mux_inst (.clk_in0(AD_OSC32K_scan), .clk_in1(CLKIN_scan), .select(rg_clk_sel), .clk_out(clk_32k_alon_scan), .resetn(ad_por_rstn_scan), .scan_mode(scan_mode), .scan_rstn(scan_rstn));

genpart_ckgt clk_32k_shut_ckgt_inst (.clk(clk_32k_alon_scan), .gclk(clk_32k_shut_scan), .scan_enable(scan_enable), .enable(clk_en));
genpart_ckgt clk_32k_tim_ckgt_inst (.clk(clk_32k_shut_scan), .gclk(clk_32k_tim), .scan_enable(scan_enable), .enable(rg_top_start_sync));
assign clk_32k = clk_32k_alon_scan;

// 13M
genpart_ckmux2 dtc_OSC13M_scanmux   (.clkin1(scan_clk), .clkin0(AD_OSC13M), .sel(scan_mode), .clkout(AD_OSC13M_scan));
genpart_ckgt clk_13m_slot_ckgt_inst (.clk(clk_13m_alon_scan), .gclk(clk_13m_shut_scan), .scan_enable(scan_enable), .enable(clk_en_sync));
//genpart_ckgt clk_13m_afe_ckgt_inst (.clk(clk_13m_slot), .gclk(clk_13m_afe), .scan_enable(scan_enable), .enable(rg_top_start));
assign clk_13m_alon_scan = AD_OSC13M_scan;
assign clk_13m_slot = clk_13m_shut_scan;
assign clk_13m_afe = clk_13m_shut_scan;
// 6.5M
clk_div #(.WIDTH(2))  clk_osc13m_div_inst  (.clk(AD_OSC13M_scan), .rstn(rst_13m_alon_n), .div_dat(2'b10), .clk_div_o(clk_6p5m_alon));
genpart_ckmux2 dtc_clk_6p5m_scanmux   (.clkin1(scan_clk), .clkin0(clk_6p5m_alon), .sel(scan_mode), .clkout(clk_6p5m_alon_scan));
genpart_ckgt clk_6p5m_shut_ckgt_inst (.clk(clk_6p5m_alon_scan), .gclk(clk_6p5m_shut_scan), .scan_enable(scan_enable), .enable(clk_en_sync));
genpart_ckgt clk_6p5m_data_ckgt_inst (.clk(clk_6p5m_shut_scan), .gclk(clk_6p5m_data), .scan_enable(scan_enable), .enable(data_ctrl_en));
genpart_ckgt clk_6p5m_fifo_ckgt_inst (.clk(clk_6p5m_shut_scan), .gclk(clk_6p5m_fifo), .scan_enable(scan_enable), .enable(rg_fifo_clk_en));
genpart_ckgt clk_6p5m_efuse_ckgt_inst (.clk(clk_6p5m_shut_scan), .gclk(clk_6p5m_efuse), .scan_enable(scan_enable), .enable(rg_efuse_en));
assign clk_6p5m_reg = clk_6p5m_alon_scan;
assign clk_6p5m_spis = clk_6p5m_shut_scan;
assign clk_6p5m_i2cs = clk_6p5m_shut_scan;

// SPIS/I2CS
genpart_ckmux2 dtc_clk_spis_scanmux   (.clkin1(scan_clk), .clkin0(SPI_CLK), .sel(scan_mode), .clkout(clk_spis_scan));
genpart_ckmux2 dtc_clk_i2cs_scanmux   (.clkin1(scan_clk), .clkin0(I2C_CLK), .sel(scan_mode), .clkout(clk_i2cs_scan));

// generate reset dest
assign async_rst_alon_n = AD_POR_RSTN & ~cmd_reset;
assign async_rst_shut_n = async_rst_alon_n & shut_rstn;
assign fifo_rstn = rg_top_start_pos | ~rg_fifo_clk_en;
// alon
genpart_ckmux2 dtc_ad_por_rstn_scanmux   (.clkin1(scan_rstn), .clkin0(AD_POR_RSTN), .sel(scan_mode), .clkout(ad_por_rstn_scan));
genpart_rstn rstn_32k_alon_n_inst (.clk(clk_32k_alon_scan), .rstn_i(async_rst_alon_n), .sw_reset(1'b0), .scan_mode(scan_mode), .scan_rstn(scan_rstn), .rstn_o(rst_32k_alon_n));
genpart_rstn rstn_13m_alon_n_inst (.clk(clk_13m_alon_scan), .rstn_i(async_rst_alon_n), .sw_reset(1'b0), .scan_mode(scan_mode), .scan_rstn(scan_rstn), .rstn_o(rst_13m_alon_n));
genpart_rstn rstn_clk_spis_n_inst (.clk(clk_spis_scan), .rstn_i(async_rst_alon_n), .sw_reset(1'b0), .scan_mode(scan_mode), .scan_rstn(scan_rstn), .rstn_o(rst_clk_spis_n));
// shut
genpart_rstn rstn_13m_shut_n_inst (.clk(clk_13m_alon_scan), .rstn_i(async_rst_shut_n), .sw_reset(1'b0), .scan_mode(scan_mode), .scan_rstn(scan_rstn), .rstn_o(rst_13m_shut_n));
genpart_rstn rstn_tim_n_inst (.clk(clk_32k_alon_scan), .rstn_i(async_rst_shut_n), .sw_reset(~rg_top_start_sync), .scan_mode(scan_mode), .scan_rstn(scan_rstn), .rstn_o(rst_tim_n));
genpart_rstn rstn_data_n_inst (.clk(clk_13m_alon_scan), .rstn_i(async_rst_shut_n), .sw_reset(~data_ctrl_en), .scan_mode(scan_mode), .scan_rstn(scan_rstn), .rstn_o(rst_data_n));
genpart_rstn rstn_fifo_n_inst (.clk(clk_13m_alon_scan), .rstn_i(async_rst_shut_n), .sw_reset(fifo_rstn), .scan_mode(scan_mode), .scan_rstn(scan_rstn), .rstn_o(rst_fifo_n));
genpart_rstn rstn_fifo_spis_n_inst (.clk(clk_spis_scan), .rstn_i(async_rst_shut_n), .sw_reset(fifo_rstn), .scan_mode(scan_mode), .scan_rstn(scan_rstn), .rstn_o(rst_fifo_spis_n));
genpart_rstn rstn_fifo_i2cs_n_inst (.clk(clk_i2cs_scan), .rstn_i(async_rst_shut_n), .sw_reset(fifo_rstn), .scan_mode(scan_mode), .scan_rstn(scan_rstn), .rstn_o(rst_fifo_i2cs_n));
genpart_rstn rstn_efuse_n_inst (.clk(clk_13m_alon_scan), .rstn_i(async_rst_shut_n), .sw_reset(~rg_efuse_en), .scan_mode(scan_mode), .scan_rstn(scan_rstn), .rstn_o(rst_efuse_n));
assign rst_reg_n = rst_13m_alon_n;
assign rst_spis_n = rst_13m_shut_n;
assign rst_i2cs_n = rst_13m_shut_n;
assign rst_slot_n = rst_13m_shut_n;
assign rst_afe_n  = rst_13m_shut_n;

// sync
sync_level clk_en_sync_inst (.clk(clk_13m_alon_scan), .rstn(rst_13m_alon_n), .data_in(rg_top_start), .data_out(clk_en_sync));    // 32K --> 13M
sync_level rg_top_start_sync_inst (.clk(clk_32k_alon_scan), .rstn(rst_32k_alon_n), .data_in(rg_top_start), .data_out(rg_top_start_sync));   // 6.5M --> 32K

always_ff@(posedge clk_6p5m_reg or negedge rst_reg_n) begin
    if(~rst_reg_n)
        rg_top_start_d1 <= 1'b0;
    else 
        rg_top_start_d1 <= rg_top_start;
end
assign rg_top_start_pos = rg_top_start & ~rg_top_start_d1;

endmodule