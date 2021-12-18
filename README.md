# RISC-V TensorCore

The goals of the RISC-V TensorCore project are to create RISC-V V-extension-based hardware accelerators that leverage
custom numerics to gain energy-efficiency, performance, reproducibility, or reliable computations for robotics, model-predictive
control, AI/ML, Reinforcement Learning, data acquisition and signal processing applications.

As many embedded intelligence applications will reside on the edge, and hardware experimentation requires a cost-effective
and flexible design environment, most of the vector engines presented here are targeted as softcores on different FPGA platforms.
As the reconfigurability of an FPGA adds overhead to the realization of the logic for a computational transformation, it
is paramount for energy-efficiency that the computational engine takes full advantage of the hardmacros available in the FPGA.
The micro-architecture of a vector engine maps well to the DSP-slice architecture of most FPGAs, hence the selection of vector
architectures to deliver on custom compute engines with custom numerics.


Furthermore, when introducing custom numerics, the language support for these new types will always lag by many years, and sometimes
the language standard committee will never be motivated to adapt. This means that only languages that offer user-defined types, such as 
Julia and C++, are ready to take advantage of custom hardware accelerators that differentiate through custom numerics. The user-defined type
can be emulated by the scalar core, and computational kernels can be executed faithfully in the custom arithmetic by the vector engine.
A user-defined type library, such as [Universal](https://github.com/stillwater-sc/universal) will function as the custom type
emulation layer, and higher level libraries, such as [hprBLAS](https://github.com/stillwater-sc/hpr-blas) will function as the 
kernel dispatch layer.



Transactional Verilog design and Verilator Testbench for a RISC-V TensorCore Vector co-processor for reproducible computation.
