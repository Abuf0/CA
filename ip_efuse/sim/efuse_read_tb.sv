`timescale  1ns / 1ps        

module tb_efuse_read;        

// efuse_read Parameters     
parameter PERIOD    = 153.846    ;
parameter NR        = 64    ;
parameter RSEL      = 256/NR;
parameter BYTE_NUM  = NR/8  ;

// efuse_read Inputs
logic   clk                          ;
logic   rst_n                        ;
logic   [5:0]  rg_efuse_trd          ;
logic   [$clog2(RSEL)-1:0]  read_sel ;
logic   read_start                   ;
logic   [7:0]  efuse_rdata           ;

// efuse_read Outputs
logic read_done                      ;
logic [NR-1:0] read_data             ;
logic busy_read                      ;
logic eufse_pgmen_o                  ;
logic efuse_rden_o                   ;
logic efuse_aen_o                    ;
logic [7:0] efuse_addr_o             ;


initial  begin
    forever #(PERIOD/2)  clk=~clk;
end

initial  begin
    clk = 0;
    rst_n = 0;
    rg_efuse_trd = 0;
    read_sel = 0;
    read_start = 0;
    efuse_rdata = 0;    // EFUSE return

    #(PERIOD*10) rst_n  =  1;
    @(negedge clk);
    efuse_rdata = 8'hf0;
    @(negedge clk);
    read_start = 1;
    @(negedge clk);
    read_start = 0;

    #(PERIOD*100)
    $finish(2);
end

efuse_read #(
    .NR       ( NR       ),
    .RSEL     ( RSEL     ),
    .BYTE_NUM ( BYTE_NUM ))
 u_efuse_read (
    .clk                       ( clk                     ),
    .rst_n                     ( rst_n                   ),
    .rg_efuse_trd              ( rg_efuse_trd            ),
    .read_sel                  ( read_sel                ),
    .read_start                ( read_start              ),
    .efuse_rdata               ( efuse_rdata             ),

    .read_done                 (read_done                ),
    .read_data                 (read_data                ),
    .busy_read                 (busy_read                ),
    .eufse_pgmen_o             (eufse_pgmen_o            ),
    .efuse_rden_o              (efuse_rden_o             ),
    .efuse_aen_o               (efuse_aen_o              ),
    .efuse_addr_o              (efuse_addr_o             )
);

initial  begin
    $fsdbDumpfile("efuse_read.fsdb");
    $fsdbDumpvars();
end

endmodule