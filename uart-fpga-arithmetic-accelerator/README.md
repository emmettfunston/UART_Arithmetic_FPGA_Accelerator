# UART-Controlled FPGA Arithmetic Accelerator

SystemVerilog UART-controlled 8-bit unsigned addition and multiplication accelerator implemented on the Digilent Arty A7-100T (Xilinx Artix-7 XC7A100T) using AMD Vivado 2026.1.

## Results

| Metric | Result |
| --- | --- |
| FPGA | XC7A100T-1CSG324C |
| System clock | 100 MHz |
| UART | 115200 baud, 8N1 |
| Operations | Unsigned 8-bit addition and multiplication |
| Result width | 16 bits |
| Setup WNS | +2.461 ns |
| Setup TNS | 0 ns |
| Hold WHS | +0.060 ns |
| LUTs | 162 |
| Flip-flops | 113 |
| FPGA slices | 56 |
| DSP blocks | 0 |
| Physical hardware tests | 106/106 passing |
| Behavioral simulation tests | 106/106 passing |

The resource values are from a Vivado fully placed utilization report. Timing values are from the implemented timing summary. The 100 MHz clock constraint was met; a maximum operating frequency was not established.

## Architecture

```text
PC / Python / USB-UART
         |
         v
      uart_rx
         |
         v
    command_fsm -----> arithmetic_unit
         |                   |
         +<----- result ----+
         |
         v
      uart_tx
         |
         v
PC / Python / USB-UART
```

`top.sv` integrates the UART receive and transmit modules, command FSM, combinational datapath, and status LED. `command_fsm.sv` stores the opcode and operands, captures the 16-bit result, and transmits the result after coordinating with the UART transmitter's busy signal.

## UART protocol

A command consists of three bytes:

| Byte | Description |
| --- | --- |
| 0 | `0x01` for add; `0x02` for multiply |
| 1 | Operand A, unsigned 8-bit |
| 2 | Operand B, unsigned 8-bit |

The reply is two bytes, low byte first (little-endian).

Example: `[0x02, 0x0C, 0x07]` requests `12 * 7`; the response `[0x54, 0x00]` represents decimal 84.

The interface is intended for a sequential client that sends one command and waits for its response. It does not currently implement a receive FIFO, framing-error reporting, or arbitrary streamed transactions.

## Reproduce

1. Create an RTL project in Vivado for `xc7a100tcsg324-1`.
2. Add `rtl/*.sv` as design sources and choose `top` as the synthesis top.
3. Add `constraints/arty_a7.xdc` as a constraints source.
4. Run synthesis, implementation, and bitstream generation, then program the Arty A7.
5. Install Python dependency: `python -m pip install -r software/requirements.txt`.
6. Set `PORT` in `software/test_accelerator.py` to the board's serial port and run `python software/test_accelerator.py`.
7. Add `sim/tb_top.sv` as a simulation source, set `tb_top` as simulation top, launch behavioral simulation, and execute `run all`.

BTN0 resets the controller, and the single-color green LD4 indicates received-byte activity (`led0` in the RTL).

## Evidence

Add project-specific screenshots to `images/` and report files to `reports/`:

- `images/simulation_waveform.png`: opcode, operands, result, UART handshake, and FSM waveforms.
- `images/timing_summary.png`: timing closure at 100 MHz.
- `images/fpga_floorplan.png`: implemented-design placement.
- `images/hardware_tests.png`: physical board verification output.
- `reports/utilization.rpt`: Vivado utilization report.
- `reports/timing_summary.rpt`: Vivado timing summary report.

## Project layout

```text
rtl/          Synthesizable SystemVerilog
sim/          Self-checking XSim testbench
software/     PySerial hardware tests
constraints/  Arty A7 clock and I/O pin constraints
images/       Project screenshots
reports/      Vivado-generated reports
```
