`timescale 1ns / 1ps
`include "define.vh"

module control_unit (
    input  logic [31:0] instr_code,
    output logic        rf_we,
    output logic        branch,
    output logic        alusrc_sel,
    output logic [ 3:0] alu_control,
    output logic [ 2:0] rfsrc_sel,
    output logic        jal,
    output logic        jalr,
    output logic [ 2:0] mem_mode,
    output logic        dwe
);

    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [6:0] opcode;

    assign funct3 = instr_code[14:12];
    assign funct7 = instr_code[31:25];
    assign opcode = instr_code[6:0];

    // [DEBUG]
    typedef enum logic [6:0] {
        DBG_R_TYPE  = `R_TYPE,
        DBG_S_TYPE  = `S_TYPE,
        DBG_IL_TYPE = `IL_TYPE,
        DBG_I_TYPE  = `I_TYPE,
        DBG_B_TYPE  = `B_TYPE,
        DBG_JALR    = `JALR_TYPE,
        DBG_LUI     = `LUI_TYPE,
        DBG_AUIPC   = `AUIPC_TYPE,
        DBG_J       = `J_TYPE
    } opcode_dbg_e;

    opcode_dbg_e opcode_dbg;

    assign opcode_dbg = opcode_dbg_e'(opcode);

    always_comb begin
        rf_we       = 1'b0;
        alusrc_sel  = 1'b0;
        alu_control = 4'd0;
        rfsrc_sel   = 3'b000;
        jal         = 1'b0;
        jalr        = 1'b0;
        mem_mode    = 3'b000;
        dwe         = 1'b0;
        branch      = 1'b0;
        case (opcode)
            `R_TYPE: begin
                rf_we       = 1'b1;
                alusrc_sel  = 1'b0;
                alu_control = {funct7[5], funct3};
                mem_mode    = 3'b0;
                rfsrc_sel   = 3'b000;
                dwe         = 1'b0;
            end
            `S_TYPE: begin
                rf_we       = 1'b0;
                alusrc_sel  = 1'b1;
                alu_control = `ADD;
                rfsrc_sel   = 3'b000;
                mem_mode    = funct3;
                dwe         = 1'b1;
            end
            `IL_TYPE: begin
                rf_we       = 1'b1;
                alusrc_sel  = 1'b1;  // rs1 + imm
                alu_control = `ADD;
                rfsrc_sel   = 3'b001;  // from data memory
                mem_mode    = funct3;
                dwe         = 1'b0;
            end
            `I_TYPE: begin
                rf_we      = 1'b1;
                alusrc_sel = 1'b1;  // rs1 + imm
                if (funct3 == 3'b101) alu_control = {funct7[5], funct3};
                else alu_control = {1'b0, funct3};
                rfsrc_sel = 3'b000;
                mem_mode  = 3'b000;
                dwe       = 1'b0;
            end
            `B_TYPE: begin
                rf_we       = 1'b0;
                branch      = 1'b1;
                alusrc_sel  = 1'b0;
                alu_control = {1'b0, funct3};
                rfsrc_sel   = 3'b000;
                mem_mode    = 3'b000;
                dwe         = 1'b0;
            end
            `JALR_TYPE: begin
                rf_we       = 1'b1;
                branch      = 1'b0;
                alusrc_sel  = 1'b0;
                alu_control = {1'b0, funct3};
                rfsrc_sel   = 3'b100;
                jal         = 1'b1;
                jalr        = 1'b1;
                mem_mode    = 3'b000;
                dwe         = 1'b0;
            end
            `LUI_TYPE: begin
                rf_we       = 1'b1;
                branch      = 1'b0;
                alusrc_sel  = 1'b0;
                alu_control = {1'b0, funct3};
                rfsrc_sel   = 3'b010;
                jal         = 1'b0;
                jalr        = 1'b0;
                mem_mode    = 3'b000;
                dwe         = 1'b0;
            end
            `AUIPC_TYPE: begin
                rf_we       = 1'b1;
                branch      = 1'b0;
                alusrc_sel  = 1'b0;
                alu_control = {1'b0, funct3};
                rfsrc_sel   = 3'b011;
                jal         = 1'b0;
                jalr        = 1'b0;
                mem_mode    = 3'b000;
                dwe         = 1'b0;
            end
            `J_TYPE: begin
                rf_we       = 1'b1;
                branch      = 1'b0;
                alusrc_sel  = 1'b0;
                alu_control = {1'b0, funct3};
                rfsrc_sel   = 3'b100;
                jal         = 1'b1;
                jalr        = 1'b0;
                mem_mode    = 3'b000;
                dwe         = 1'b0;
            end
        endcase
    end

endmodule


