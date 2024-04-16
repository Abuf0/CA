module crgu(
    // scan
    input scan_clk,
    input scan_rstn,
    input scan_mode,
    input scan_enable,
    // clock source
    input AD_OSC32K,
    input AD_OSC13M,
    input CLKIN,
    input SPI_CLK,
    input I2C_CLK,
    // reset source
    input AD_POR_RSTN,
    input cmd_reset,
    // clock & reset ctrl 
    input clk_en,   // From PMU @ 32K
    input rg_top_start, // From reg_ctrl @ 6.5M
    input data_ctrl_en, // TODO
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

);

logic AD_OSC32K_scan;
logic CLKIN_scan;
logic rg_top_start_sync;
logic AD_OSC13M_scan;
logic clk_en_sync;
logic clk_32k_alon_scan;
logic clk_32k_shut_scan;
logic clk_13m_shut_scan;
logic clk_6p5m_alon;
logic clk_6p5m_alon_scan;
logic clk_6p5m_shut_scan;

logic ad_por_rstn_scan;
logic rst_osc13m_n;
logic rst_osc32k_n;

// generate clock dest
// 32K
genpart_ckmux2 dtc_OSC32K_scanmux   (.clkin1(scan_clk), .clkin0(AD_OSC32K), .sel(scan_mode), .clkout(AD_OSC32K_scan));
genpart_ckmux2 dtc_OSC32K_scanmux   (.clkin1(scan_clk), .clkin0(CLKIN), .sel(scan_mode), .clkout(CLKIN_scan));
omsp_clock_mux clk_32k_mux_inst (.clk_in0(AD_OSC32K_scan), .clk_in1(CLKIN_scan), .select(rg_clk_sel), .clk_out(clk_32k_alon_scan), .resetn(ad_por_rstn_scan), .scan_mode(scan_mode), .scan_rstn(scan_rstn));

genpart_ckgt clk_32k_shut_ckgt_inst (.clk(clk_32k_alon_scan), .gclk(clk_32k_shut_scan), .scan_enable(scan_enable), .enable(clk_en));
genpart_ckgt clk_32k_tim_ckgt_inst (.clk(clk_32k_shut_scan), .gclk(clk_32k_tim), .scan_enable(scan_enable), .enable(rg_top_start_sync));
assign clk_32k = clk_32k_alon_scan;

// 13M
genpart_ckmux2 dtc_OSC13M_scanmux   (.clkin1(scan_clk), .clkin0(AD_OSC13M), .sel(scan_mode), .clkout(AD_OSC13M_scan));
genpart_ckgt clk_13m_slot_ckgt_inst (.clk(AD_OSC13M_scan), .gclk(clk_13m_shut_scan), .scan_enable(scan_enable), .enable(clk_en_sync));
//genpart_ckgt clk_13m_afe_ckgt_inst (.clk(clk_13m_slot), .gclk(clk_13m_afe), .scan_enable(scan_enable), .enable(rg_top_start));
assign clk_13m_slot = clk_13m_shut_scan;
assign clk_13m_afe = clk_13m_shut_scan;
// 6.5M
clk_div #(.WIDTH(2))  clk_osc13m_div_inst  (.clk(AD_OSC13M_scan), .rstn(rst_osc13m_n), .div_dat(2'b10), .clk_div_o(clk_6p5m_alon));
genpart_ckmux2 dtc_clk_6p5m_scanmux   (.clkin1(scan_clk), .clkin0(clk_6p5m_alon), .sel(scan_mode), .clkout(clk_6p5m_alon_scan));
genpart_ckgt clk_6p5m_shut_ckgt_inst (.clk(clk_6p5m_alon_scan), .gclk(clk_6p5m_shut_scan), .scan_enable(scan_enable), .enable(clk_en_sync));
genpart_ckgt clk_6p5m_data_ckgt_inst (.clk(clk_6p5m_shut_scan), .gclk(clk_6p5m_data), .scan_enable(scan_enable), .enable(data_ctrl_en));
genpart_ckgt clk_6p5m_fifo_ckgt_inst (.clk(clk_6p5m_shut_scan), .gclk(clk_6p5m_fifo), .scan_enable(scan_enable), .enable(rg_fifo_clk_en));
genpart_ckgt clk_6p5m_efuse_ckgt_inst (.clk(clk_6p5m_shut_scan), .gclk(clk_6p5m_efuse), .scan_enable(scan_enable), .enable(rg_efuse_en));
assign clk_6p5m_reg = clk_6p5m_alon_scan;
assign clk_6p5m_spis = clk_6p5m_shut_scan;
assign clk_6p5m_i2cs = clk_6p5m_shut_scan;

// generate reset dest


// sync
sync_level clk_en_sync_inst (.clk(AD_OSC13M_scan), .rstn(rst_osc13m_n), .data_in(rg_top_start), .data_out(clk_en_sync));    // 32K --> 13M
sync_level rg_top_start_sync_inst (.clk(clk_32k_alon_scan), .rstn(rst_osc32k_n), .data_in(rg_top_start), .data_out(rg_top_start_sync));   // 6.5M --> 32K

endmodule