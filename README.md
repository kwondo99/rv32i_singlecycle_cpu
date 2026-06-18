# RV32I Single-Cycle CPU

RISC-V 32비트 기본 정수 명령어 집합(RV32I)을 지원하는 **싱글 사이클 CPU**를 설계하고, C 코드가 어셈블리(ASM)로 변환되어 하드웨어에서 실행되는 과정을 분석한 프로젝트입니다.

> 작성자: 권동오 · 2026.05.26

---

## 목표

1. Single-cycle RV32I CPU 설계
2. C 코드의 Assembly 변환 과정을 분석하여 하드웨어 동작 이해

---

## 개요

### RISC-V

- 자주 사용되는 단순한 명령어를 중심으로 구성하여 하드웨어 로직을 최소화하고, 명령어 실행 효율을 높인 개방형 ISA
- CISC의 복잡한 명령어 중 실제로 자주 사용되는 핵심 명령어를 중심으로 단순화
- 구조가 단순하여 CPU 설계, 파이프라인 구성, 제어 로직 구현에 유리

### RV32I

RISC-V 아키텍처 중 32비트 기반의 기본 정수 명령어 집합으로, 다음 6가지 명령어 포맷을 가집니다.

| 포맷 | 설명 |
|------|------|
| R-type | 레지스터 간 연산 |
| I-type | immediate 연산 / load / jalr |
| S-type | store |
| B-type | 조건 분기(branch) |
| U-type | upper immediate (LUI, AUIPC) |
| J-type | jump (JAL) |

---

## 아키텍처

### 주요 구성 요소 (RV32I_CPU)

| 블록 | 역할 |
|------|------|
| ROM (Instruction Memory) | 명령어 저장 / `instr_code` 출력 |
| Control Unit | opcode·funct 기반으로 제어 신호 생성 |
| Register File | 32개 레지스터(x0~x31), `x0`은 항상 0 |
| ALU | 산술/논리 연산 수행 |
| Extend | immediate 부호/영 확장 |
| PC | 프로그램 카운터 (PC+4, branch, jump 분기) |
| RAM (Data Memory) | 데이터 저장 (word 단위) |
| Load Data Extender | load 데이터의 byte/halfword 선택 및 확장 |

### 레지스터 / 메모리 사양

- **XLEN = 32** (32비트 레지스터 32개)
- 데이터 메모리는 **word(4byte) 단위**, little-endian 구성 (`0 byte`가 최하위)

### Control Unit 신호

`funct7 = instr_code[31:25]`, `funct3 = instr_code[14:12]` 를 이용해 아래 제어 신호를 생성합니다.

- `rf_we` (register write enable)
- `alusrc_sel`, `alu_control`
- `rfsrc_sel` (write-back 데이터 소스 선택)
- `jal`, `jalr`, `branch`
- `mem_mode`, `dwe` (data write enable)

| 명령어 타입 | rf_we | alusrc_sel | rfsrc_sel | dwe | branch |
|-------------|:----:|:----------:|:---------:|:---:|:------:|
| R-Type  | 1 | 0 | 3'b000 | 0 | 0 |
| S-Type  | 0 | 1 | 3'b000 | 1 | 0 |
| IL-Type (load) | 1 | 1 | 3'b001 | 0 | 0 |
| I-Type  | 1 | 1 | 3'b000 | 0 | 0 |
| B-Type  | 0 | 0 | 3'b000 | 0 | 1 |
| jalr    | 1 | 0 | 3'b100 | 0 | 0 |
| LUI     | 1 | 0 | 3'b010 | 0 | 0 |
| AUIPC   | 1 | 0 | 3'b011 | 0 | 0 |
| JAL     | 1 | 0 | 3'b100 | 0 | 0 |

---

## 지원 명령어

### R-type
`ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND`

### I-type (연산)
`ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI`

### I-type (load)
`LB`, `LH`, `LW`, `LBU`, `LHU` — byte/halfword load 시 sign/zero extension 처리

### S-type (store)
`SB`, `SH`, `SW`

### B-type (branch)
`BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`

### U-type
`LUI` (rd = imm), `AUIPC` (rd = PC + imm)

### J-type
`JAL` (rd = PC+4, PC = PC + imm), `JALR` (rd = PC+4, PC = rs1 + imm)

---

## 시뮬레이션

### 검증 방식

1. 레지스터와 Data Memory에 초기값 저장
2. R / I / S / B / U / J-type 명령어를 각각 시뮬레이션
3. Register, Data Memory, PC 값의 변화를 확인

### 초기값

**레지스터**

| 레지스터 | 초기값 | 해석 |
|------|--------|------|
| x1 | 32'h0000_0000 | 0 |
| x2 | 32'h0000_0002 | 2 |
| x3 | 32'h0000_0003 | 3 |
| x4 | 32'hFFFF_FFF9 | signed -7 |
| x5 | 32'hFFFF_FFFA | signed -6 |
| x6 | 32'h0000_0006 | 6 |
| x7 | 32'h0000_0007 | 7 |

**Data Memory**

| 주소 | 초기값 |
|------|--------|
| data_ram[0] | 32'h0000_00F9 |
| data_ram[1] | 32'h0000_8001 |
| data_ram[2] | 32'h1234_ABCD |

각 명령어 타입별로 시뮬레이션을 수행하여 의도한 연산 결과와 PC 변화가 정상적으로 나오는 것을 파형(waveform)으로 확인하였습니다.

---

## C 코드 ASM 분석

버블 정렬(bubble sort) C 코드를 컴파일하여 생성된 어셈블리를 CPU에서 실행하고, 함수 호출/스택 동작을 분석하였습니다.

### 분석 대상 코드

```c
void sort(int *pNum, int size);
void swap(int *a, int *b);

void main(void) {
    int Num[6] = {3, 5, 9, 1, 7};
    int a = 0;
    sort(Num, 5);
    a = 0x12345678;
    while(1); // halt
    return;
}

void sort(int *pNum, int size) {
    int temp;
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size - i; j++) {
            if (pNum[j] > pNum[j+1]) {
                swap(&pNum[j], &pNum[j+1]);
            }
        }
    }
    return;
}

void swap(int *a, int *b) {
    int temp = *a;
    *a = *b;
    *b = temp;
    return;
}
```


## 트러블 슈팅

**1. 문제 발견**
LB, LH 명령어 검증 중 데이터 메모리의 하위 비트만 Load 되는 현상 발생.

**2. 원인**
데이터 메모리를 word 단위로 설계했지만, Load 과정에서 byte/halfword 단위의 데이터 선택 동작을 정의하지 않음.

**3. 해결**
`case` 문과 `if` 문을 사용하여 전체 주소(`daddr`)를 기준으로 byte/halfword 위치를 선택하도록 수정. 선택된 데이터를 sign extension 하여 LB, LH 명령어가 정상적으로 동작하도록 개선.

```verilog
`LB: begin
    case (daddr[1:0])
        2'b00: load_data = {{24{drdata[7]}},  drdata[7:0]};
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
```

---

## 배운 점

1. RISC-V CPU의 구조와 동작 원리를 이해하였다.
2. CPU 설계를 통해 PC, Control Unit, Register File, ALU, Data Memory가 명령어 실행 과정에서 서로 연결되어 동작하는 흐름을 이해하였다.
3. ASM 분석을 통해 C 코드가 실제 CPU에서 어떤 명령어 흐름으로 실행되는지 확인하였다.
