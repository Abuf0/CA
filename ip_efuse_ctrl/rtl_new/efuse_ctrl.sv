module efuse_ctrl #(
    parameter NW = 64,
    parameter NR = 64
)(
    input clk,  // From crgu    // 6.5M gated
    input rst_n,    // From crgu
    input scan_mode,    // From PAD
    input pmu_efuse_start,  // From PMU @ 6.5M
    // config from reg_ctrl
    input [1:0] rg_efuse_mode,  // From reg_ctrl    // 0: read, 1: write
    input rg_efuse_start,   // From reg_ctrl @ 6.5M
    input rg_efuse_blank_en,    // From reg_ctrl @ 6.5M
    input [15:0] rg_efuse_password, // From reg_ctrl @ 6.5M
    input [NW-1:0] rg_efuse_wdata,  // From reg_ctrl @ 6.5M
    input [5:0] rg_efuse_trd,   // From reg_ctrl @ 6.5M
    input [9:0] rg_efuse_tpgm,  // From reg_ctrl @ 6.5M
    input rg_efuse_reg_mode,    // From reg_ctrl @ 6.5M     // 0: auto, 1: reg
    input [$clog2(256/NR)-1:0]  rg_efuse_read_sel, // From reg_ctrl @ 6.5M
    input [$clog2(256/NW)-1:0]  rg_efuse_write_sel, // From reg_ctrl @ 6.5M
    // reg mode
    input rg_efuse_pgmen,   // From reg_ctrl @ 6.5M
    input rg_efuse_rden,    // From reg_ctrl @ 6.5M
    input rg_efuse_aen, // From reg_ctrl @ 6.5M
    input [7:0] rg_efuse_addr,  // From reg_ctrl @ 6.5M
    // RO to reg_ctrl
    output logic [NR-1:0] rg_efuse_rdata,   // To reg_ctrl
    output logic [7:0] rg_efuse_d,  // To reg_ctrl
    output logic rg_efuse_read_done_manual, // To reg_ctrl
    output logic rg_efuse_write_done_manual,    // To reg_ctrl
    output logic rg_efuse_no_blank, // To reg_ctrl
    output logic rg_efuse_aen_done, // To reg_ctrl
    // interface with EFUSE
    output logic efuse_pgmen_o, // To EFUSE IP
    output logic efuse_rden_o,  // To EFUSE IP
    output logic efuse_aen_o,   // To EFUSE IP
    output logic [7:0] efuse_addr_o,    // To EFUSE IP
    input [7:0] efuse_rdata_i,  // From EFUSE IP
    output logic efuse_autoload_done,   // To reg_ctrl
    output logic efuse_autoload_vld,    // To reg_ctrl
    output logic efuse_busy     // To pmu & reg_ctrl
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
efuse_mux #(.NW ( NW ),.NR ( NR )) efuse_mux_inst (
    .clk                       ( clk                     ),
    .rst_n                     ( rst_n                   ),
    .scan_mode                 ( scan_mode               ),
    .rg_efuse_reg_mode         ( rg_efuse_reg_mode       ),
    .rg_efuse_pgmen            ( rg_efuse_pgmen          ),
    .rg_efuse_rden             ( rg_efuse_rden           ),
    .rg_efuse_aen              ( rg_efuse_aen_use        ), // from efuse_aen_gen
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
efuse_aen_gen efuse_aen_gen_inst (
    .clk                       ( clk                     ),
    .rst_n                     ( rst_n                   ),
    .rg_efuse_tpgm             ( rg_efuse_tpgm           ), 
    .rg_efuse_refresh          ( rg_efuse_refresh        ),
    .rg_efuse_pgmen            ( rg_efuse_pgmen          ),
    .rg_efuse_rden             ( rg_efuse_rden           ),
    .rg_efuse_aen              ( rg_efuse_aen            ), 
    .rg_efuse_addr             ( rg_efuse_addr           ),
    .rg_efuse_aen_use          ( rg_efuse_aen_use        ),
    .rg_efuse_aen_done         ( rg_efuse_aen_done       )   
);  
endmodule