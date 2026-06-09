`timescale 1ns / 1ps

module instruction_mem (
    input  logic [31:0] instr_addr,
    output logic [31:0] instr_code
);

    logic [31:0] instr_rom[0:127];

    `ifdef TEST_SIMULATION
    initial begin

        // instr_rom[0] = 32'h0031_02b3; // ADD X5 = X2 + X3
        // instr_rom[1] = 32'h0041_82b3; // ADD X5 = X3 + X4
        // instr_rom[2] = 32'h0031_2123; // sw x2, x3, 2 : rs1, rs2, imm
        // instr_rom[3] = 32'h0021_2403; // lw x8, x2, 2 : rd, rs1, imm
        // instr_rom[4] = 32'h0043_8413; // addi x8, x7, 4 : rd, rs1, imm
        // // instr_rom[5] = 32'h0080_056f;
        // instr_rom[5] = 32'h1234_52B7; // LUI   x5, 0x12345
        //                       // x5 = 0x12345000

        // instr_rom[6] = 32'h0001_0317; // AUIPC x6, 0x00010
        //                             // x6 = PC + 0x00010000

        // instr_rom[7] = 32'h0002_80E7; // JALR  x1, 0(x5)
        //                             // x1 = PC + 4
        //                             // PC = x5 + 0
        // instr_rom[8] = 32'h0080_00EF; // JAL   x1, +8
        //                             // x1 = PC + 4
        //                             // PC = PC + 8

        // // BEQ : ex) if true the PC = PC - 8 
        // instr_rom[9] = 32'hFE84_0CE3; // BEQ x8, x8, -8 : rs1, rs2, imm, PC = PC + imm
        // instr_rom[2] = {7'b0100_000, 5d5, 5'd4, 3'b000, 5'd1, 7'b0110011};     // SUB X1 = X4 - X5
        // instr_rom[3] = {7'b0100_000, 5'd4, 5'd5, 3'b000, 5'd2, 7'b0110011};     // SUB X2 = X5 - X4
        // instr_rom[4] = {7'b0000_000, 5'd5, 5'd4, 3'b001, 5'd3, 7'b0110011};     // SLL X3 = X4 << X5
        // instr_rom[5] = {7'b0000_000, 5'd31, 5'd30, 3'b010, 5'd6, 7'b0110011};   // SLT X6 = (X30 < X31) ? 1:0;
        // instr_rom[6] = {7'b0000_000, 5'd31, 5'd5, 3'b010, 5'd7, 7'b0110011};   // SLT X7 = (X5 < X31) ? 1:0;
        // instr_rom[7] = {7'b0000_000, 5'd31, 5'd5, 3'b011, 5'd8, 7'b0110011};   //SLTU X8 = (X5 < X31) ? 1:0;
        // instr_rom[8] = {7'b0000_000, 5'd4, 5'd5, 3'b100, 5'd9, 7'b0110011};     // XOR X9 = (X5 ^ X4)
        // instr_rom[9] = {7'b0000_000, 5'd4, 5'd30, 3'b101, 5'd10, 7'b0110011};   // SRL X10 = X30 >> X4
        // instr_rom[10] = {7'b0100_000, 5'd4, 5'd30, 3'b101, 5'd11, 7'b0110011};  // SRA X11 = X30 >> X4 (msb-extends)
        // instr_rom[11] = {7'b0000_000', 5'd4, 5'd5, 3'b110, 5'd12, 7'b0110011};   // OR  X12 = X5 | X4
        // instr_rom[12] = {7'b0000_000, 5'd4, 5'd5, 3'b111, 5'd13, 7'b0110011};   // AND X13 = X5 & X4
        // =========================
        // S-type Store Instructions
        // =========================

        // instr_rom[0] = 32'h0050_8023;  // SB  : mem[x1 + 0] = x5[7:0]
        // instr_rom[1] = 32'h0060_9123;  // SH  : mem[x1 + 2] = x6[15:0]
        // instr_rom[2] = 32'h0070_A223;  // SW  : mem[x1 + 4] = x7[31:0]


        // // =========================
        // // I-type Load Instructions
        // // =========================

        // instr_rom[3]  = 32'h0000_8403; // LB  : x8  = sign_extend(mem[x1 + 0][7:0])
        // instr_rom[4]  = 32'h0020_9483; // LH  : x9  = sign_extend(mem[x1 + 2][15:0])
        // instr_rom[5] = 32'h0040_A503;  // LW  : x10 = mem[x1 + 4][31:0]
        // instr_rom[6]  = 32'h0010_C583; // LBU : x11 = zero_extend(mem[x1 + 1][7:0])
        // instr_rom[7]  = 32'h0020_D603; // LHU : x12 = zero_extend(mem[x1 + 2][15:0])


        // // =========================
        // // I-type ALU Instructions
        // // =========================

        // instr_rom[8] = 32'h00A0_8693;  // ADDI  : x13 = x1 + 10
        // instr_rom[9]  = 32'hFFF0_A713; // SLTI  : x14 = ($signed(x1) < -1) ? 1 : 0
        // instr_rom[10] = 32'h0050_B793;  // SLTIU : x15 = (x1 < 5) ? 1 : 0
        // instr_rom[11] = 32'h00F0_C813;  // XORI  : x16 = x1 ^ 15
        // instr_rom[12] = 32'h0F00_E893;  // ORI   : x17 = x1 | 240
        // instr_rom[13] = 32'h0FF0_F913;  // ANDI  : x18 = x1 & 255


        // // =========================
        // // I-type Shift Instructions
        // // =========================

        // instr_rom[14] = 32'h0030_9993;  // SLLI : x19 = x1 << 3
        // instr_rom[15] = 32'h0020_DA13;  // SRLI : x20 = x1 >> 2
        // instr_rom[16] = 32'h4020_DA93;  // SRAI : x21 = $signed(x1) >>> 2

    end
    `endif

    initial begin
        // $readmemh("instruction_code.mem", instr_rom); // 다른 directory면 경로추가
         $readmemh("instruction_code_sort.mem", instr_rom);
    end

    assign instr_code = instr_rom[instr_addr[31:2]];

endmodule
