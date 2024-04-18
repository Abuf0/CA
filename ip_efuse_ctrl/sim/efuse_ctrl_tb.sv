module efuse_ctrl_tb;

// efuse_ctrl Parameters
parameter PERIOD = 153.846;
parameter NW  = 64;
parameter NR  = 64;

// efuse_ctrl Inputs
logic   clk                                  = 0 ;
logic   rst_n                                = 0 ;
logic   scan_mode = 0;
logic   pmu_efuse_start                      = 0 ;
logic   [1:0]  rg_efuse_mode                 = 0 ;
logic   rg_efuse_start                       = 0 ;
logic   rg_efuse_blank_en                    = 0 ;
logic   [15:0]  rg_efuse_password            = 16'h55AA ;
logic   [NW-1:0]  rg_efuse_wdata             = 0 ;
logic   [5:0]  rg_efuse_trd                  = 3 ;
logic   [9:0]  rg_efuse_tpgm                 = 3 ;
logic   rg_efuse_reg_mode                    = 0 ;
logic   [$clog2(256/NR)-1:0]  rg_efuse_read_sel = 0 ;
logic   [$clog2(256/NW)-1:0]  rg_efuse_write_sel = 0 ;
logic   rg_efuse_pgmen                       = 0 ;
logic   rg_efuse_rden                        = 0 ;
logic   rg_efuse_aen                         = 0 ;
logic   [7:0]  rg_efuse_addr                 = 0 ;
logic   [7:0]  efuse_rdata_i                 = 0 ;

// efuse_ctrl Outputs
logic [NR-1:0] rg_efuse_rdata        ;
logic [7:0] rg_efuse_d;
logic rg_efuse_read_done_manual      ;
logic rg_efuse_write_done_manual     ;
logic rg_efuse_no_blank              ;
logic efuse_pgmen_o                  ;
logic efuse_rden_o                   ;
logic efuse_aen_o                    ;
logic [7:0] efuse_addr_o             ;
logic efuse_autoload_done            ;
logic efuse_autoload_vld             ;
logic efuse_busy                     ;



initial begin
    forever #(PERIOD/2)  clk=~clk;
end

initial begin
    rg_efuse_read_sel = 0 ;
    rg_efuse_write_sel = 0 ;
    #(PERIOD*10) rst_n  =  1;
    @(negedge clk);
    pmu_efuse_start = 1;
    @(negedge clk);
    pmu_efuse_start = 0;
    efuse_rdata_i =8'hf0;
    repeat(150) @(negedge clk);
    efuse_rdata_i =8'h12;
    repeat(150) @(negedge clk);
    efuse_rdata_i =8'h34;
    repeat(150) @(negedge clk);
    efuse_rdata_i =8'h56;
    repeat(150) @(negedge clk);   
    repeat(150) @(negedge clk); 
    rg_efuse_wdata = 64'hf0f1f2f3f4f5f6f7;
    rg_efuse_write_sel = 1;
    rg_efuse_mode = 1;
    @(negedge clk);
    rg_efuse_start = 1;
    @(negedge clk);
    rg_efuse_start = 0;
    repeat(5000) @(negedge clk);
    rg_efuse_read_sel = 1;
    rg_efuse_mode = 0;
    @(negedge clk);
    rg_efuse_start = 1;
    @(negedge clk);
    rg_efuse_start = 0;
    repeat(500) @(negedge clk);

    $finish(2);

end

efuse_ctrl #(.NW ( NW ),.NR ( NR )) efuse_ctrl_inst (
    .clk                               ( clk                              ),
    .rst_n                             ( rst_n                            ),
    .scan_mode                         ( scan_mode                        ),
    .pmu_efuse_start                   ( pmu_efuse_start                  ),
    .rg_efuse_mode                     ( rg_efuse_mode                    ),
    .rg_efuse_start                    ( rg_efuse_start                   ),
    .rg_efuse_blank_en                 ( rg_efuse_blank_en                ),
    .rg_efuse_password                 ( rg_efuse_password                ),
    .rg_efuse_wdata                    ( rg_efuse_wdata                   ),
    .rg_efuse_trd                      ( rg_efuse_trd                     ),
    .rg_efuse_tpgm                     ( rg_efuse_tpgm                    ),
    .rg_efuse_reg_mode                 ( rg_efuse_reg_mode                ),
    .rg_efuse_read_sel                 ( rg_efuse_read_sel                ),
    .rg_efuse_write_sel                ( rg_efuse_write_sel               ),
    .rg_efuse_pgmen                    ( rg_efuse_pgmen                   ),
    .rg_efuse_rden                     ( rg_efuse_rden                    ),
    .rg_efuse_aen                      ( rg_efuse_aen                     ),
    .rg_efuse_addr                     ( rg_efuse_addr                    ),
    .efuse_rdata_i                     ( efuse_rdata_i                    ),
    .rg_efuse_rdata                    ( rg_efuse_rdata                   ),
    .rg_efuse_d                        ( rg_efuse_d                       ),
    .rg_efuse_read_done_manual         ( rg_efuse_read_done_manual        ),
    .rg_efuse_write_done_manual        ( rg_efuse_write_done_manual       ),
    .rg_efuse_no_blank                 ( rg_efuse_no_blank                ),
    .efuse_pgmen_o                     ( efuse_pgmen_o                    ),
    .efuse_rden_o                      ( efuse_rden_o                     ),
    .efuse_aen_o                       ( efuse_aen_o                      ),
    .efuse_addr_o                      ( efuse_addr_o                     ),
    .efuse_autoload_done               ( efuse_autoload_done              ),
    .efuse_autoload_vld                ( efuse_autoload_vld               ),
    .efuse_busy                        ( efuse_busy                       )
);
/*
efuse_ctrl_new #(.NW ( NW ),.NR ( NR )) efuse_ctrl_new_inst (
    .clk                               ( clk                              ),
    .rst_n                             ( rst_n                            ),
    .scan_mode                         ( scan_mode                        ),
    .pmu_efuse_start                   ( pmu_efuse_start                  ),
    .rg_efuse_mode                     ( rg_efuse_mode                    ),
    .rg_efuse_start                    ( rg_efuse_start                   ),
    .rg_efuse_blank_en                 ( rg_efuse_blank_en                ),
    .rg_efuse_password                 ( rg_efuse_password                ),
    .rg_efuse_wdata                    ( rg_efuse_wdata                   ),
    .rg_efuse_trd                      ( rg_efuse_trd                     ),
    .rg_efuse_tpgm                     ( rg_efuse_tpgm                    ),
    .rg_efuse_reg_mode                 ( rg_efuse_reg_mode                ),
    .rg_efuse_read_sel                 ( rg_efuse_read_sel                ),
    .rg_efuse_write_sel                ( rg_efuse_write_sel               ),
    .rg_efuse_pgmen                    ( rg_efuse_pgmen                   ),
    .rg_efuse_rden                     ( rg_efuse_rden                    ),
    .rg_efuse_aen                      ( rg_efuse_aen                     ),
    .rg_efuse_addr                     ( rg_efuse_addr                    ),
    .efuse_rdata_i                     ( efuse_rdata_i                    ),
    .rg_efuse_rdata                    ( rg_efuse_rdata_new                   ),
    .rg_efuse_d                        ( rg_efuse_d_new                       ),
    .rg_efuse_read_done_manual         ( rg_efuse_read_done_manual        ),
    .rg_efuse_write_done_manual        ( rg_efuse_write_done_manual       ),
    .rg_efuse_no_blank                 ( rg_efuse_no_blank                ),
    .efuse_pgmen_o                     ( efuse_pgmen_o                    ),
    .efuse_rden_o                      ( efuse_rden_o                     ),
    .efuse_aen_o                       ( efuse_aen_o                      ),
    .efuse_addr_o                      ( efuse_addr_o                     ),
    .efuse_autoload_done               ( efuse_autoload_done              ),
    .efuse_autoload_vld                ( efuse_autoload_vld               ),
    .efuse_busy                        ( efuse_busy                      )
);
*/


initial begin    
    $fsdbDumpfile("efuse_ctrl.fsdb");
    $fsdbDumpvars();
end

endmodule