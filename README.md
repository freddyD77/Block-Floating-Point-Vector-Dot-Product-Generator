# Block-Floating-Point-Vector-Dot-Product-Generator

This system takes 2 floating point vectors. Converts them both to block floating point format. Performs a simplified dot product of the 2 vectors, 
and then converts the result back to standard floating point. The system is parameterized by vector length, floating point size, and block floating 
point size. 

The highest speeds achieved on a Xilinx U280 FPGA card was 475MHz. And the system offered up to 492% resource utilization improvement
for ideal parameters.
