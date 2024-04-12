module efuse_ctrl #(
    parameter NW = 64,
    parameter NR = 64
)(
    input clk,
    input rst_n,
    input pmu_efuse_start,
    // config from reg_ctrl
    input [1:0] rg_efuse_mode,
    input rg_efuse_start,
    input rg_efuse_blank_en,
    input [15:0] rg_efuse_password,
    input [NW-1:0] rg_efuse_wdata,
    input [5:0] rg_efuse_trd,
    input [9:0] rg_efuse_tpgm,
    input rg_efuse_reg_mode,
    input [$clog2(256/NR)-1:0]  rg_efuse_read_sel, // TODO
    input [$clog2(256/NW)-1:0]  rg_efuse_write_sel, // TODO
    // reg mode
    input rg_efuse_pgmen,
    input rg_efuse_rden,
    input rg_efuse_aen,
    input [7:0] rg_efuse_addr,
    // RO to reg_ctrl
    output logic [NR-1:0] rg_efuse_rdata,
    output logic rg_efuse_read_done_manual,
    output logic rg_efuse_write_done_manual,
    output logic rg_efuse_no_blank,
    // interface with EFUSE
    output logic efuse_pgmen_o,
    output logic efuse_rden_o,
    output logic efuse_aen_o,
    output logic [7:0] efuse_addr_o,
    input [7:0] efuse_rdata_i,
    output logic efuse_autoload_done,
    output logic efuse_autoload_vld,
    output logic efuse_busy
);

logic read_done;
logic [NR-1:0] read_data;
logic efuse_busy_read;
logic write_done;
logic efuse_busy_write;
logic read_start;
logic write_start;
logic [NW-1:0] write_data;
logic [$clog2(256/NR)-1:0] efuse_read_sel; 
logic [$clog2(256/NW)-1:0] efuse_write_sel;
logic read_pgmen_o;
logic read_rden_o ;
logic read_aen_o  ;
logic read_addr_o ;
logic write_pgmen_o;
logic write_rden_o ;
logic write_aen_o  ;
logic write_addr_o ;

efuse_rw_ctrl #(.NW(NW),.NR(NR)) efuse_rw_ctrl_inst(
   .clk                        ( clk                            ),
   .rst_n                      ( rst_n                          ),
   .pmu_efuse_start            ( pmu_efuse_start                ),
   .rg_efuse_mode              ( rg_efuse_mode                  ),
   .rg_efuse_start             ( rg_efuse_start                 ),
   .rg_efuse_read_sel          ( rg_efuse_read_sel              ),
   .rg_efuse_write_sel         ( rg_efuse_write_sel             ),
   .rg_efuse_password          ( rg_efuse_password              ),
   .rg_efuse_blank_en          ( rg_efuse_blank_en              ),
   .read_done                  ( read_done                      ),
   .read_data                  ( read_data                      ),
   .efuse_busy_read            ( efuse_busy_read                ),
   .write_done                 ( write_done                     ),
   .efuse_busy_write           ( efuse_busy_write               ),
   .rg_efuse_wdata             ( rg_efuse_wdata                 ),
   .rg_efuse_rdata             ( rg_efuse_rdata                 ),
   .rg_efuse_read_done_manual  ( rg_efuse_read_done_manual      ),
   .rg_efuse_no_blank          ( rg_efuse_no_blank              ),
   .efuse_autoload_done        ( efuse_autoload_done            ),
   .efuse_autoload_vld         ( efuse_autoload_vld             ),
   .efuse_busy                 ( efuse_busy                     ),
   .efuse_read_sel             ( efuse_read_sel                 ),
   .efuse_write_sel            ( efuse_write_sel                ),
   .read_start                 ( read_start                     ),
   .write_start                ( write_start                    ),
   .write_data                 ( write_data                     )    
);
efuse_read #(.NR(NR),.RSEL(256/NR)) efuse_read_inst(
    .clk                       ( clk                     ),
    .rst_n                     ( rst_n                   ),
    .rg_efuse_trd              ( rg_efuse_trd            ),
    .read_sel                  ( efuse_read_sel          ),
    .read_start                ( read_start              ),
    .efuse_rdata               ( read_rdata              ), 
    .read_done                 ( read_done               ),
    .read_data                 ( read_data               ),
    .busy_read                 ( busy_read               ),
    .eufse_pgmen_o             ( read_pgmen_o            ), // -> MUX -> EFUSE
    .efuse_rden_o              ( read_rden_o             ), // -> MUX -> EFUSE
    .efuse_aen_o               ( read_aen_o              ), // -> MUX -> EFUSE
    .efuse_addr_o              ( read_addr_o             )  // -> MUX -> EFUSE
);
efuse_write #(.NW(NW),.WSEL(256/NW)) efuse_write_inst (
    .clk                       ( clk                     ),
    .rst_n                     ( rst_n                   ),
    .rg_efuse_tpgm             ( rg_efuse_tpgm           ),
    .write_sel                 ( efuse_write_sel         ),
    .write_data                ( write_data              ),
    .write_start               ( write_start             ),
    .write_done                ( write_done              ),
    .busy_write                ( busy_write              ),
    .eufse_pgmen_o             ( write_pgmen_o           ), // -> MUX -> EFUSE
    .efuse_rden_o              ( write_rden_o            ), // -> MUX -> EFUSE
    .efuse_aen_o               ( write_aen_o             ), // -> MUX -> EFUSE
    .efuse_addr_o              ( write_addr_o            )  // -> MUX -> EFUSE
);
efuse_mux #(.NW ( NW ),.NR ( NR )) efuse_mux_inst (
    .clk                       ( clk                     ),
    .rst_n                     ( rst_n                   ),
    .scan_mode                 ( scan_mode               ),
    .rg_efuse_reg_mode         ( rg_efuse_reg_mode       ),
    .rg_efuse_pgmen            ( rg_efuse_pgmen          ),
    .rg_efuse_rden             ( rg_efuse_rden           ),
    .rg_efuse_aen              ( rg_efuse_aen            ),
    .rg_efuse_addr             ( rg_efuse_addr           ),
    .read_pgmen                ( read_pgmen_o            ),
    .read_rden                 ( read_rden_o             ),
    .read_aen                  ( read_aen_o              ),
    .read_addr                 ( read_addr_o             ),
    .busy_read                 ( busy_read               ),
    .write_pgmen               ( write_pgmen_o           ),
    .write_rden                ( write_rden_o            ),
    .write_aen                 ( write_aen_o             ),
    .write_addr                ( write_addr_o            ),
    .busy_write                ( busy_write              ),
    .efuse_rdata_i             ( efuse_rdata_i           ),
    .rg_efuse_rdata            ( rg_efuse_rdata          ),
    .read_rdata                ( read_rdata              ), // <-- EFUSE
    .efuse_pgmen_o             ( efuse_pgmen_o           ),
    .efuse_rden_o              ( efuse_rden_o            ),
    .efuse_aen_o               ( efuse_aen_o             ),
    .efuse_addr_o              ( efuse_addr_o            )
);    
endmodule