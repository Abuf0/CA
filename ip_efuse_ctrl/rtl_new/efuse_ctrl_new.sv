module efuse_ctrl_new #(
    parameter NW = 64,
    parameter NR = 64
)(
    input clk,
    input rst_n,
    input scan_mode,
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
    output logic [7:0] rg_efuse_d,
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
logic efuse_pgmen;
logic efuse_rden ;
logic efuse_aen  ;
logic [7:0] efuse_addr;
logic [7:0] read_rdata;
logic [7:0] efuse_d;

efuse_rw_ctrl_new #(.NW(NW),.NR(NR)) efuse_rw_ctrl_new_inst(
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
   .rg_efuse_write_done_manual ( rg_efuse_write_done_manual     ),
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
efuse_rw_timing #(.NW(NW),.NR(NR)) efuse_rw_timing_inst (
    .clk                       ( clk                     ),
    .rst_n                     ( rst_n                   ),
    .read_start                ( read_start              ),
    .write_start               ( write_start             ),
    .read_sel                  ( efuse_read_sel          ),  
    .write_sel                 ( efuse_write_sel         ),    
    .rg_efuse_trd              ( rg_efuse_trd            ),
    .rg_efuse_tpgm             ( rg_efuse_tpgm           ),
    .rg_efuse_mode             ( rg_efuse_mode[0]           ),  // TODO       
    .read_data                 ( read_data               ),
    .write_data                ( write_data              ),
    .efuse_pgmen               ( efuse_pgmen             ),
    .efuse_rden                ( efuse_rden              ),
    .efuse_aen                 ( efuse_aen               ),
    .efuse_addr                ( efuse_addr              ),
    .efuse_d                   ( efuse_d                 ),
    .busy_read                 ( efuse_busy_read         ),
    .busy_write                ( efuse_busy_write        ),
    .read_done                 ( read_done               ),    
    .write_done                ( write_done              )
);
efuse_mux_new #(.NW ( NW ),.NR ( NR )) efuse_mux_new_inst (
    .clk                       ( clk                     ),
    .rst_n                     ( rst_n                   ),
    .scan_mode                 ( scan_mode               ),
    .rg_efuse_reg_mode         ( rg_efuse_reg_mode       ),
    .rg_efuse_pgmen            ( rg_efuse_pgmen          ),
    .rg_efuse_rden             ( rg_efuse_rden           ),
    .rg_efuse_aen              ( rg_efuse_aen            ),
    .rg_efuse_addr             ( rg_efuse_addr           ),
    .efuse_pgmen               ( efuse_pgmen             ),
    .efuse_rden                ( efuse_rden              ),
    .efuse_aen                 ( efuse_aen               ),
    .efuse_addr                ( efuse_addr              ),
    .busy_read                 ( efuse_busy_read         ),
    .busy_write                ( efuse_busy_write        ),
    .efuse_rdata_i             ( efuse_rdata_i           ),
    .rg_efuse_d                ( rg_efuse_d              ),
    .read_rdata                ( efuse_d                 ), // <-- EFUSE
    .efuse_pgmen_o             ( efuse_pgmen_o           ),
    .efuse_rden_o              ( efuse_rden_o            ),
    .efuse_aen_o               ( efuse_aen_o             ),
    .efuse_addr_o              ( efuse_addr_o            )
);    
endmodule