#!/bin/bash
# Run all simulations and generate analysis

echo "=== Running Basic Network Simulation ==="
cd src
ns basic_network.tcl
echo "Done."

echo "=== Running QKD Simulation ==="
ns qkd_simulation.tcl
echo "Done."

echo "=== Running Traditional Encryption Simulation ==="
ns traditional_encryption.tcl
echo "Done."

echo "=== Running Eavesdropper Simulation ==="
ns eavesdropper_simulation.tcl
echo "Done."

echo "=== Running Data Analysis ==="
cd ..
python3 src/data_analyzer.py

echo "=== All simulations complete ==="
echo "Results are in the results/ directory"
echo "Graphs are in the graphs/ directory"
