`timescale 1ns / 1ps
`include "define.vh"

module datapath (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instr_code,
    input  logic        rf_we,
    input  logic        alusrc_sel,
    input  logic [ 3:0] alu_control,
    input  logic [ 2:0] rfsrc_sel,
    input  logic        branch,
    input  logic        jal,
    input  logic        jalr,
    input  logic [ 2:0] mem_mode,
    input  logic [31:0] drdata,
    output logic [31:0] instr_addr,
    output logic [31:0] daddr,
    output logic [31:0] dwdata
);

    logic [31:0] rs1, rs2, alu_result, rfsrc_mux_out;
    logic [31:0] imm_extend, alu_rs2_mux;
    logic [31:0] load_data;
    logic b_taken;

    assign daddr  = alu_result;
    assign dwdata = rs2;

    load_data_extender U_LOAD_DATA_EXTENDER (
        .drdata   (drdata),
        .daddr    (daddr),
        .funct3   (mem_mode),
        .load_data(load_data)
    );

    // mux_2x1 U_REG_FILE_SRC_MUX (
    //     .in0    (alu_result),
    //     .in1    (load_data),
    //     .sel    (rfsrc_sel),
    //     .out_mux(rfsrc_mux_out)
    // );

    //WB
    mux_8x1 U_REG_FILE_SRC_MUX (
        .in0    (alu_result),
        .in1    (load_data),
        .in2    (imm_extend),
        .in3    (pc_imm),          // AUIPC
        .in4    (instr_addr + 4),  // JAL,JALR
        .sel    (rfsrc_sel),
        .out_mux(rfsrc_mux_out)
    );

    register_file U_REG_FILE (
        .clk   (clk),
        .raddr1(instr_code[19:15]),
        .raddr2(instr_code[24:20]),
        .rf_we (rf_we),  // write enable 
        .waddr (instr_code[11:7]),
        .wdata (rfsrc_mux_out),
        .rdata1(rs1),
        .rdata2(rs2)
    );

    alu U_ALU (
        .alu_control(alu_control),
        .rs1        (rs1),          // rs1
        .rs2        (alu_rs2_mux),  // rs2
        .b_taken    (b_taken),      // compare 
        .alu_result (alu_result)    // rd
    );

    mux_2x1 U_ALU_RS2_MUX (
        .in0    (rs2),
        .in1    (imm_extend),
        .sel    (alusrc_sel),
        .out_mux(alu_rs2_mux)
    );

    imm_extend U_IMM_EXTEND (
        .instr_code(instr_code),
        .imm_extend(imm_extend)
    );

    logic [31:0] pc_4;
    logic [31:0] pc_imm;
    logic [31:0] pc_in;

    mux_2x1 U_PC_JALR_MUX (
        .in0    (instr_addr),
        .in1    (rs1),
        .sel    (jalr),
        .out_mux(pc_in)
    );

    program_counter U_PC (
        .clk           (clk),
        .rst           (rst),
        .pc_counter_sel(jal || (b_taken && branch)),
        .pc_in         (pc_in),                       // for next program count
        .imm_extend    (imm_extend),
        .pc_4          (pc_4),
        .pc_imm        (pc_imm),
        .pc_out        (instr_addr)                   // current program count
    );

endmodule

module program_counter (
    input  logic        clk,
    input  logic        rst,
    input  logic        pc_counter_sel,
    input  logic [31:0] pc_in,           // pc_out or rs1
    input  logic [31:0] imm_extend,
    output logic [31:0] pc_4,
    output logic [31:0] pc_imm,
    output logic [31:0] pc_out
);

    logic [31:0] pc_reg;
    // logic [31:0] pc_4;
    // logic [31:0] pc_imm;

    assign pc_out = pc_reg;
    assign pc_4   = pc_in + 32'd4;
    assign pc_imm = pc_in + imm_extend;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) pc_reg <= 0;
        else begin
            if (pc_counter_sel) pc_reg <= pc_imm;
            else pc_reg <= pc_4;
        end
    end

endmodule

// module program_counter (
// input  logic        clk,
// input  logic        rst,
// input  logic        pc_counter_sel,
// input  logic [31:0] pc_in,
// input  logic [31:0] imm_extend,
// output logic [31:0] pc_out
// );
// 
// logic [31:0] pc_reg;
// 
// assign pc_out = pc_reg;
// 
// always_ff @(posedge clk, posedge rst) begin
// if (rst) pc_reg <= 0;
// else begin
// if (pc_counter_sel) pc_reg <= pc_in + imm_extend;
// else pc_reg <= pc_in + 4;
// end
// end
// 
// endmodule

module load_data_extender (
    input  logic [31:0] drdata,
    input  logic [31:0] daddr,
    input  logic [ 2:0] funct3,
    output logic [31:0] load_data
);

    always_comb begin
        load_data = 32'd0;
        case (funct3)
            `LB: begin
                case (daddr[1:0])
                    2'b00: load_data = {{24{drdata[7]}}, drdata[7:0]};
                    2'b01: load_data = {{24{drdata[15]}}, drdata[15:8]};
                    2'b10: load_data = {{24{drdata[23]}}, drdata[23:16]};
                    2'b11: load_data = {{24{drdata[31]}}, drdata[31:24]};
                endcase
            end
            `LH: begin
                case (daddr[1])
                    1'b0: load_data = {{16{drdata[15]}}, drdata[15:0]};
                    1'b1: load_data = {{16{drdata[31]}}, drdata[31:16]};
                endcase
            end
            `LW: load_data = drdata;
            `LBU: begin
                case (daddr[1:0])
                    2'b00: load_data = {24'd0, drdata[7:0]};
                    2'b01: load_data = {24'd0, drdata[15:8]};
                    2'b10: load_data = {24'd0, drdata[23:16]};
                    2'b11: load_data = {24'd0, drdata[31:24]};
                endcase
            end
            `LHU: begin
                case (daddr[1])
                    1'b0: load_data = {16'd0, drdata[15:0]};
                    1'b1: load_data = {16'd0, drdata[31:16]};
                endcase
            end
        endcase
    end

endmodule

module mux_2x1 (
    input  logic [31:0] in0,
    input  logic [31:0] in1,
    input  logic        sel,
    output logic [31:0] out_mux
);

    assign out_mux = sel ? in1 : in0;

endmodule

module mux_8x1 (
    input  logic [31:0] in0,
    input  logic [31:0] in1,
    input  logic [31:0] in2,
    input  logic [31:0] in3,
    input  logic [31:0] in4,
    input  logic [ 2:0] sel,
    output logic [31:0] out_mux
);

    always_comb begin
        out_mux = 32'd0;
        case (sel)
            3'b000: out_mux = in0;
            3'b001: out_mux = in1;
            3'b010: out_mux = in2;
            3'b011: out_mux = in3;
            3'b100: out_mux = in4;
        endcase
    end

endmodule

module imm_extend (
    input  logic [31:0] instr_code,
    output logic [31:0] imm_extend
);

    always_comb begin
        imm_extend = 0;
        case (instr_code[6:0])
            `S_TYPE:
            imm_extend = {
                {20{instr_code[31]}}, instr_code[31:25], instr_code[11:7]
            };
            `IL_TYPE, `I_TYPE, `JALR_TYPE:
            imm_extend = {{20{instr_code[31]}}, instr_code[31:20]};
            // $signed({instr_code[31:25], instr_code[11:7], 20'd0}) >> 20;
            `B_TYPE:
            imm_extend = {
                {19{instr_code[31]}},
                instr_code[31],
                instr_code[7],
                instr_code[30:25],  // 6
                instr_code[11:8],  // 4
                1'b0
            };
            `LUI_TYPE, `AUIPC_TYPE: imm_extend = {instr_code[31:12], 12'd0};
            `J_TYPE:
            imm_extend = {
                {12{instr_code[31]}},  // 12
                instr_code[19:12],  // 8
                instr_code[20],  // 1
                instr_code[30:21],  // 10
                1'b0  // 1
            };
        endcase
    end


endmodule

module alu (
    input  logic [ 3:0] alu_control,
    input  logic [31:0] rs1,          //rs1
    input  logic [31:0] rs2,          //rs2
    output logic        b_taken,
    output logic [31:0] alu_result
);

    always_comb begin
        alu_result = 32'd0;
        b_taken = 1'b0;

        case (alu_control)
            // R-type RD = RS1 + RS2 
            // I-type RD = RS1 + Imm(RS2)
            `ADD: alu_result = rs1 + rs2;
            `SUB: alu_result = rs1 - rs2;
            `SLL: alu_result = rs1 << rs2;
            `SLT: alu_result = (($signed(rs1)) < ($signed(rs2))) ? 1 : 0;
            `SLTU: alu_result = (rs1 < rs2) ? 1 : 0;
            `XOR: alu_result = rs1 ^ rs2;
            `SRL:
            alu_result = rs1 >> rs2[4:0];  // rs2[4:0] 문서에 써있음
            `SRA: alu_result = $signed(rs1) >>> rs2[4:0];  //msb_extend
            `OR: alu_result = rs1 | rs2;
            `AND: alu_result = rs1 & rs2;
        endcase

        case (alu_control[2:0])
            `BEQ: begin
                if (rs1 == rs2) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            `BNE: begin
                if (rs1 != rs2) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            `BLT: begin
                if ($signed(rs1) < $signed(rs2)) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            `BGE: begin
                if ($signed(rs1) >= $signed(rs2)) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            `BLTU: begin
                if (rs1 < rs2) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            `BGEU: begin
                if (rs1 >= rs2) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
        endcase

    end

endmodule

module register_file (
    input  logic        clk,
    input  logic [ 4:0] raddr1,  // rs1
    input  logic [ 4:0] raddr2,  // rs2
    input  logic        rf_we,   // write enable 
    input  logic [ 4:0] waddr,   // rd 
    input  logic [31:0] wdata,   // rd write data 
    output logic [31:0] rdata1,  // rs1 read data
    output logic [31:0] rdata2   // rs2 read data
);

    logic [31:0] register_file[1:31];

`ifdef TEST_SIMULATION
    int i = 0;
    initial begin
        register_file[1] = 0;
        for (i = 2; i < 30; i++) begin
            register_file[i] = i;
        end
        register_file[30] = 32'hFFFF_FFF9;
        register_file[31] = 32'hFFFF_FFFA;
    end
`endif

    always_ff @(posedge clk) begin
        if (rf_we) begin
            register_file[waddr] <= wdata;
        end
    end

    assign rdata1 = (raddr1 != 0) ? register_file[raddr1] : 32'd0;
    assign rdata2 = (raddr2 != 0) ? register_file[raddr2] : 32'd0;

endmodule


