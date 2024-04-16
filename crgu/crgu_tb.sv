`timescale  1ns / 1ps

module crgu_tb;

// crgu Parameters

// crgu Inputs
logic   scan_clk                             = 0 ;
logic   scan_rstn                            = 0 ;
logic   scan_mode                            = 0 ;
logic   scan_enable                          = 0 ;
logic   AD_OSC32K                            = 0 ;
logic   AD_OSC13M                            = 0 ;
logic   CLKIN                                = 0 ;
logic   SPI_CLK                              = 0 ;
logic   I2C_CLK                              = 0 ;
logic   AD_POR_RSTN                          = 0 ;
logic   cmd_reset                            = 0 ;
logic   shut_rstn                            = 0 ;
logic   rg_clk_sel                           = 1 ;
logic   clk_en                               = 0 ;
logic   rg_top_start                         = 0 ;
logic   data_ctrl_en                         = 0 ;
logic   rg_fifo_clk_en                       = 0 ;
logic   rg_efuse_en                          = 0 ;

// crgu Outputs
logic clk_32k                        ;
logic clk_32k_tim                    ;
logic clk_6p5m_reg                   ;
logic clk_6p5m_spis                  ;
logic clk_6p5m_i2cs                  ;
logic clk_6p5m_data                  ;
logic clk_6p5m_fifo                  ;
logic clk_6p5m_efuse                 ;
logic clk_13m_slot                   ;
logic clk_13m_afe                    ;
logic rst_32k_alon_n                 ;
logic rst_reg_n                      ;
logic rst_spis_n                     ;
logic rst_i2cs_n                     ;
logic rst_slot_n                     ;
logic rst_afe_n                      ;
logic rst_tim_n                      ;
logic rst_data_n                     ;
logic rst_fifo_n                     ;
logic rst_fifo_spis_n                ;
logic rst_fifo_i2cs_n                ;
logic rst_clk_spis_n                 ;
logic rst_efuse_n                    ;

always #(7.692/2) AD_OSC13M = ~AD_OSC13M;
always #(3125/2)  AD_OSC32K = ~AD_OSC32K;
always #(3051.76/2)  CLKIN = ~CLKIN;
always #(5/2) SPI_CLK = ~SPI_CLK;
always #(2000/2) I2C_CLK = ~I2C_CLK;

initial begin
    repeat(5)   @(negedge AD_OSC32K);
    AD_POR_RSTN = 1;
    shut_rstn = 1;
    // clk alon case
    repeat(10)   @(negedge AD_OSC32K);
    // clk shut case
    clk_en = 1;
    repeat(10)   @(negedge AD_OSC32K);    
    data_ctrl_en = 1;
    repeat(10)   @(negedge AD_OSC32K); 
    rg_fifo_clk_en = 1;
    repeat(10)   @(negedge AD_OSC32K); 
    rg_efuse_en = 1;
    repeat(10)   @(negedge AD_OSC32K); 
    rg_top_start = 1;
    repeat(10)   @(negedge AD_OSC32K); 
    // rstn case
    shut_rstn = 0;
    repeat(10)   @(negedge AD_OSC32K); 
    shut_rstn = 1;
    repeat(10)   @(negedge AD_OSC32K); 
    @(posedge SPI_CLK);
    #1
    cmd_reset = 1;
    @(posedge SPI_CLK);
    #1
    cmd_reset = 0;
    repeat(10)   @(negedge AD_OSC32K); 
    data_ctrl_en = 0;
    repeat(10)   @(negedge AD_OSC32K);
    data_ctrl_en = 1;
    repeat(10)   @(negedge AD_OSC32K);
    rg_efuse_en = 0;
    repeat(10)   @(negedge AD_OSC32K);
    rg_efuse_en = 1;
    repeat(10)   @(negedge AD_OSC32K);
    rg_top_start = 0;
    repeat(10)   @(negedge AD_OSC32K);
    rg_top_start = 1;
    repeat(10)   @(negedge AD_OSC32K);
    rg_fifo_clk_en = 0;
    repeat(10)   @(negedge AD_OSC32K);
    rg_fifo_clk_en = 1;
    repeat(10)   @(negedge AD_OSC32K);      
    @(posedge SPI_CLK);
    #1
    rg_clk_sel = 1;
    repeat(10)   @(negedge AD_OSC32K); 
    $finish(2);
end

crgu  U_CRGU (
    .scan_clk                ( scan_clk          ),
    .scan_rstn               ( scan_rstn         ),
    .scan_mode               ( scan_mode         ),
    .scan_enable             ( scan_enable       ),
    .AD_OSC32K               ( AD_OSC32K         ),
    .AD_OSC13M               ( AD_OSC13M         ),
    .CLKIN                   ( CLKIN             ),
    .SPI_CLK                 ( SPI_CLK           ),
    .I2C_CLK                 ( I2C_CLK           ),
    .AD_POR_RSTN             ( AD_POR_RSTN       ),
    .cmd_reset               ( cmd_reset         ),
    .shut_rstn               ( shut_rstn         ),
    .rg_clk_sel              ( rg_clk_sel        ),
    .clk_en                  ( clk_en            ),
    .rg_top_start            ( rg_top_start      ),
    .data_ctrl_en            ( data_ctrl_en      ),
    .rg_fifo_clk_en          ( rg_fifo_clk_en    ),
    .rg_efuse_en             ( rg_efuse_en       ),
    .clk_32k                 ( clk_32k           ),
    .clk_32k_tim             ( clk_32k_tim       ),
    .clk_6p5m_reg            ( clk_6p5m_reg      ),
    .clk_6p5m_spis           ( clk_6p5m_spis     ),
    .clk_6p5m_i2cs           ( clk_6p5m_i2cs     ),
    .clk_6p5m_data           ( clk_6p5m_data     ),
    .clk_6p5m_fifo           ( clk_6p5m_fifo     ),
    .clk_6p5m_efuse          ( clk_6p5m_efuse    ),
    .clk_13m_slot            ( clk_13m_slot      ),
    .clk_13m_afe             ( clk_13m_afe       ),
    .rst_32k_alon_n          ( rst_32k_alon_n    ),
    .rst_reg_n               ( rst_reg_n         ),
    .rst_spis_n              ( rst_spis_n        ),
    .rst_i2cs_n              ( rst_i2cs_n        ),
    .rst_slot_n              ( rst_slot_n        ),
    .rst_afe_n               ( rst_afe_n         ),
    .rst_tim_n               ( rst_tim_n         ),
    .rst_data_n              ( rst_data_n        ),
    .rst_fifo_n              ( rst_fifo_n        ),
    .rst_fifo_spis_n         ( rst_fifo_spis_n   ),
    .rst_fifo_i2cs_n         ( rst_fifo_i2cs_n   ),
    .rst_clk_spis_n          ( rst_clk_spis_n    ),
    .rst_efuse_n             ( rst_efuse_n       )
);

initial begin
    $fsdbDumpfile("crgu_tb.fsdb");
    $fsdbDumpvars();
end

endmodule