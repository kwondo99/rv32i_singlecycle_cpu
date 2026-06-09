`timescale 1ns / 1ps
`include "define.vh"

module data_mem (
    input  logic        clk,
    input  logic        dwe,
    input  logic [ 2:0] mem_mode,
    input  logic [31:0] daddr,
    input  logic [31:0] dwdata,
    output logic [31:0] drdata
);

    logic [31:0] data_ram[0:63];

    // initial begin
    //     for (int i = 0; i < 32; i++) begin
    //         data_ram[i] = i;
    //     end
    // end


    always_ff @(posedge clk) begin
        if (dwe) begin
            case (mem_mode)
                // SB
                `SB: begin
                    case (daddr[1:0])
                        2'b00: data_ram[daddr[31:2]][7:0] <= dwdata[7:0];
                        2'b01: data_ram[daddr[31:2]][15:8] <= dwdata[7:0];
                        2'b10: data_ram[daddr[31:2]][23:16] <= dwdata[7:0];
                        2'b11: data_ram[daddr[31:2]][31:24] <= dwdata[7:0];
                    endcase
                end
                // SH 
                `SH: begin
                    case (daddr[1])
                        1'b0: data_ram[daddr[31:2]][15:0] <= dwdata[15:0];
                        1'b1: data_ram[daddr[31:2]][31:16] <= dwdata[15:0];
                    endcase
                end
                // SW
                `SW: data_ram[daddr[31:2]] <= dwdata;
            endcase
        end
    end

    assign drdata = data_ram[daddr[31:2]];

endmodule
