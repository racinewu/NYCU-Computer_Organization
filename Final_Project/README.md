# Simple Processor
The Simple Processor is a digital hardware design that simulates the behavior of a basic instruction-driven processor. The system decodes incoming instructions, performs arithmetic or memory operations, and updates the processor state accordingly.

## Problem Formulation
Given a stream of 32-bit instructions, the processor must correctly decode and execute each instruction while maintaining the internal register file, program counter (PC), and memory interactions. The processor should compute results based on register operands, immediate values, and memory accesses, while ensuring the correct instruction sequence and execution timing. The output includes updated register values, memory operations, and the next instruction address for continuous execution.

## Features
- **Instruction Set Compatibility**: Supports instruction sets used in the 2021–2024 course projects.
- **Extensible Architecture**: Designed with a clean and modular structure for easy future extension.
- **FSM Implementation**: The standard version uses an FSM to control instruction execution.
- **Pipelined Implementation**: A pipelined version improves throughput by overlapping instruction stages.

## Environment:
|  Operating System  |  HDL Simulator Version  | Verilog Standard |
|--------------------|-------------------------|------------------|
|     Windows 11     |   Icarus Verilog 12.0   |   Verilog-2001   |

## Directory Structure
```
Final_Project/
  ├── <year>
  │   ├── spec.pdf
  │   ├── instruction.txt
  │   ├── mem.txt
  │   ├── MEM.v
  │   ├── PATTERN.v
  │   ├── PATTERN_p.v
  │   ├── TESTBED.v
  │   └── TESTBED_p.v
  ├── SP.v
  ├── SP_pipeline.v
  │
  └── README.md
```

## Usage Guide
### How to compile
To compile the Verilog design, simply run
```
cd <year>
iverilog -o test TESTBED.v     // for non-pipeline design
iverilog -o test_p TESTBED_p.v // for pipeline design
```
### How to execute
Run the simulation with
```
vvp test   // for non-pipeline design
vvp test_p // for pipeline design
```
### How to plot
To visualize the simulation waveforms and inspect the signal transitions
```
gtkwave SP.vcd &   // for non-pipeline design
gtkwave SP_p.vcd & // for pipeline design
```

## Experiment
<p align="center">
  <img src="./img/success.png" alt="Success Result" width="800">
</p>
<p align="center">Figure 1. Success result</p>

<p align="center">
  <img src="./img/fail.png" alt="Fail Result" width="800">
</p>
<p align="center">Figure 2. Fail result</p>