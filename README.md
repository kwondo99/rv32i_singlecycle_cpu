# RV32I Single Cycle CPU

## Project Overview
RISC-V RV32I 명령어 집합을 기반으로 Single Cycle CPU를 SystemVerilog로 설계한 프로젝트입니다.

명령어 타입별 Datapath와 Control Unit을 구현하고, Assembly Code 시뮬레이션을 통해 Register File, Data Memory, PC 변화가 정상적으로 동작하는지 검증했습니다.

## My Role
- RV32I Single Cycle CPU RTL 설계
- Register File, Instruction Memory, Data Memory 구현
- Assembly Code 기반 시뮬레이션 검증
- Waveform 분석 및 디버깅

## Main Features
- R-Type 명령어 구현
- I-Type 연산 및 Load 명령어 구현
- S-Type Store 명령어 구현
- B-Type Branch 명령어 구현
- JAL / JALR / LUI / AUIPC 구현
- PC Update Logic 구현

## Tools
- SystemVerilog
- Vivado
- Vivado Simulator

## Result
- RTL 설계 완료
- 타입별 명령어 시뮬레이션 검증 완료
