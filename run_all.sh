#!/bin/bash
# Master script to run all simulations and analysis for the 
# Quantum Networking Simulation Project

echo "========================================================"
echo "   Quantum Networking Simulation - Complete Execution   "
echo "========================================================"

# Create directory structure if it doesn't exist
echo -e "\n=== Setting up directory structure ==="
mkdir -p src results/logs results/metrics graphs/protocols graphs/network report presentation
echo "Directory structure created."

# Check if NS2 is installed
if ! command -v ns &> /dev/null; then
    echo "ERROR: NS2 is not installed or not in PATH."
    echo "Please install NS2 with: sudo apt-get install ns2 nam"
    exit 1
fi

# Check if Python and required packages are installed
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 is not installed or not in PATH."
    echo "Please install Python 3 and required packages."
    exit 1
fi

# Run all simulations
echo -e "\n=== Running Advanced Multi-Node Network Simulation ==="
cd src
ns multi_node_network.tcl
echo "Advanced multi-node simulation completed."

echo -e "\n=== Running Advanced QKD Protocols Simulation ==="
ns advanced_qkd_protocols.tcl
echo "Advanced QKD protocols simulation completed."

echo -e "\n=== Running Basic Network Simulation ==="
ns basic_network.tcl
echo "Basic network simulation completed."

echo -e "\n=== Running Standard QKD Simulation ==="
ns qkd_simulation.tcl
echo "Standard QKD simulation completed."

echo -e "\n=== Running Traditional Encryption Simulation ==="
ns traditional_encryption.tcl
echo "Traditional encryption simulation completed."

echo -e "\n=== Running Eavesdropper Simulation ==="
ns eavesdropper_simulation.tcl
echo "Eavesdropper simulation completed."

# Return to main directory
cd ..

# Run analysis scripts
echo -e "\n=== Running Protocol Analysis ==="
python3 src/protocol_analyzer.py results/bb84_protocol.txt results/b92_protocol.txt results/protocol_comparison.txt
echo "Protocol analysis completed."

echo -e "\n=== Running Network Performance Analysis ==="
python3 src/network_analyzer.py results/multi_node_trace.tr results/network_metrics.txt
echo "Network performance analysis completed."

echo -e "\n=== Running Comprehensive Data Analysis ==="
python3 src/data_analyzer.py
echo "Comprehensive data analysis completed."

echo -e "\n========================================================"
echo "   Simulation and Analysis Complete   "
echo "========================================================"
echo -e "\nResults are available in:"
echo " - results/            (Raw data and logs)"
echo " - graphs/protocols/   (Protocol comparison visualizations)"
echo " - graphs/network/     (Network performance visualizations)"
echo " - results/comparative_report.md (Comprehensive report)"
echo -e "\nTo view network animations, use:"
echo " $ nam results/multi_node_nam.nam"
echo -e "\nTo view the comprehensive report:"
echo " $ less results/comparative_report.md"
