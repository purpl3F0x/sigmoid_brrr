# Hardware-friendly Approximations for the Sigmoid Function

This project explores various methods for approximating the sigmoid function, commonly used in neural networks, with a focus on hardware-friendly implementations. Using our findings, we implement a 5-stage pipelined SystemVerilog design for calculating the function in bfloat16 precision, with a piecewise 2nd order polynomial approximation.

![Verilator video](notebooks/img/verilator_demo.webp)

### RTL Design Performance
Our design is capable of reaching an fmax around 113MHz when targetting a ZCU106 board, with a total on-chip power usage of 0.631W (of which 0.592W is static device power usage).
![RTL design power](notebooks/img/vivado_power.png)
![RTL design timing](notebooks/img/vivado_timing.png)
![Vivado elaborated design](notebooks/img/vivado_elaborated.png)

### Project structure:
- notebooks/:
  - Jupyter Notebooks explaining the methods explored in this project
  - Pytorch modules for training approximations for the sigmoid function
- sigmoid_rtl/:
  - rtl/: SystemVerilog implementation of a bfloat16 sigmoid calculation unit with a 5-stage pipeline, using a piecewise 2nd order polynomial.
  - cpp_testbench/: Verilator testbench for the design, featuring an ImGui UI. Offers the ability to step the design cycle-by-cycle and inspect the pipeline at any given moment
  - simulation/: SystemVerilog testbenches for Vivado
  - constraints/: Vivado constraints file