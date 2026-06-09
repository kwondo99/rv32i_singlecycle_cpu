`timescale 1ns / 1ps

module top_rv32i_soc (
    input logic clk,
    input logic rst
);

    logic [31:0] instr_code;
    logic [31:0] instr_addr, daddr, dwdata, drdata;

    logic       dwe;
    logic [2:0] mem_mode;

    instruction_mem U_INSTR_ROM (.*);

    rv32i_cpu U_RV32I_CPU (.*);

    data_mem U_DATA_RAM (.*);

endmodule
