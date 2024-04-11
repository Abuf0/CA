`timescale  1ns / 1ps

module efuse_write_tb;

// efuse_write Parameters
parameter PERIOD = 153.846    ;
parameter NW    = 64    ;
parameter WSEL  = 256/NW;

// efuse_write Inputs
logic   clk                                  = 0 ;
logic   rst_n                                = 0 ;
logic   [9:0]  rg_efuse_tpgm                 = 0 ;
logic   [$clog2(WSEL)-1:0]  write_sel        = 0 ;
logic   [NW-1:0]  write_data                 = 0 ;
logic   write_start                          = 0 ;

// efuse_write Outputs
logic   write_done                     ;
logic   busy_write                     ;
logic   eufse_pgmen_o                  ;
logic   efuse_rden_o                   ;
logic   efuse_aen_o                    ;
logic   [7:0] efuse_addr_o             ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial begin
    #(PERIOD*10) rst_n  =  1;
    @(negedge clk);
    write_data = 8'hf0;
    @(negedge clk);
    write_start = 1;
    @(negedge clk);
    write_start = 0;
    #(PERIOD*1000)
    @(negedge clk);
    write_sel = 1;
    write_data = 8'h12;
    @(negedge clk);
    write_start = 1;
    @(negedge clk);
    write_start = 0;
    #(PERIOD*1000)
    @(negedge clk);
    write_sel = 2;
    write_data = 8'h34;
    @(negedge clk);
    write_start = 1;
    @(negedge clk);
    write_start = 0;
    #(PERIOD*1000)
    @(negedge clk);
    write_sel = 3;
    write_data = 8'h56;
    @(negedge clk);
    write_start = 1;
    @(negedge clk);
    write_start = 0;
    #(PERIOD*1000)
    $finish(2);
end

efuse_write #(
    .NW   ( NW   ),
    .WSEL ( WSEL ))
 u_efuse_write (
    .clk                       ( clk                      ),
    .rst_n                     ( rst_n                    ),
    .rg_efuse_tpgm             ( rg_efuse_tpgm            ),
    .write_sel                 ( write_sel                ),
    .write_data                ( write_data               ),
    .write_start               ( write_start              ),

    .write_done          ( write_done                       ),
    .busy_write          ( busy_write                       ),
    .eufse_pgmen_o       ( eufse_pgmen_o                    ),
    .efuse_rden_o        ( efuse_rden_o                     ),
    .efuse_aen_o         ( efuse_aen_o                      ),
    .efuse_addr_o        ( efuse_addr_o                     )
);

initial  begin
    $fsdbDumpfile("efuse_write.fsdb");
    $fsdbDumpvars();
end

endmodule