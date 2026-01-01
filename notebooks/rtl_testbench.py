#!/usr/bin/env python

# Manages generating input data for our Verilog testbench to consume, and parsing the output data it generates
import numpy as np
import struct

class RTLTestbench:
    # Generate text file to feed our testbench
    @classmethod
    def generateInput(cls, start, stop, num = 100, filename = "testbench_results/rtl_testbench_inputs.txt"):
        x = np.linspace(start, stop, num)
        
        # Convert to bfloat16, write to file as hex
        with open(filename, "w") as file:
            for value in x:
                hex_value = cls.f32_to_bf16(value)
                file.write(f"{hex_value}\n")

    # Parse the testbench's output to an f32 array
    @classmethod
    def parseOutput(cls, filename):
        floats = []
        
        with open(filename, 'r') as file:
            for line in file:
                bf16 = line.strip()
                floats.append(cls.bf16_to_f32(bf16))
        return np.array(floats)

    @classmethod
    def f32_to_bf16(cls, f):
        f32_bytes = struct.pack('>f', f)    
        f32_int = struct.unpack('>I', f32_bytes)[0]
        # Truncate mantissa
        bf16_int = f32_int >> 16
        
        bf16_bytes = struct.pack('>H', bf16_int)
        return bf16_bytes.hex()
    
    @classmethod
    def bf16_to_f32(cls, bf16_hex):
        bf16_int = int(bf16_hex, 16)
        f32_int = bf16_int << 16
        return struct.unpack('>f', struct.pack('>I', f32_int))[0]

# Generate inputs from [-10, 10] when the file is ran on its own
if __name__ == "__main__":
    RTLTestbench.generateInput(-10, 10)
