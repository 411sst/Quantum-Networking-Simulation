#!/bin/bash
# Master script to run all simulations and analysis for the 
# Quantum Networking Simulation Project with improved error handling

# Function to handle errors
handle_error() {
    echo -e "\nERROR: $1"
    echo "Continuing with next step..."
}

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

# Function to run a simulation
run_simulation() {
    echo -e "\n=== Running $2 ==="
    if [ -f "src/$1" ]; then
        cd src
        if ns "$1"; then
            echo "$2 completed successfully."
        else
            handle_error "$2 failed."
        fi
        cd ..
    else
        handle_error "Script src/$1 not found."
    fi
}

# Run all simulations
run_simulation "multi_node_network.tcl" "Advanced Multi-Node Network Simulation"
run_simulation "advanced_qkd_protocols.tcl" "Advanced QKD Protocols Simulation"
run_simulation "basic_network.tcl" "Basic Network Simulation"
run_simulation "qkd_simulation.tcl" "Standard QKD Simulation"
run_simulation "traditional_encryption.tcl" "Traditional Encryption Simulation"
run_simulation "eavesdropper_simulation.tcl" "Eavesdropper Simulation"

# Function to run an analysis script
run_analysis() {
    echo -e "\n=== Running $2 ==="
    if [ -f "src/$1" ]; then
        if python3 "src/$1" $3; then
            echo "$2 completed successfully."
        else
            handle_error "$2 failed."
        fi
    else
        handle_error "Script src/$1 not found."
    fi
}

# Run analysis scripts with error handling
run_analysis "protocol_analyzer.py" "Protocol Analysis" "results/bb84_protocol.txt results/b92_protocol.txt results/protocol_comparison.txt"
run_analysis "network_analyzer.py" "Network Performance Analysis" "results/multi_node_trace.tr results/network_metrics.txt"
run_analysis "data_analyzer.py" "Comprehensive Data Analysis" ""

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
