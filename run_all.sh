#!/bin/bash
# Master script to run all simulations and analysis for the 
# Quantum Networking Simulation Project with improved error handling

# Function to handle errors
handle_error() {
    echo -e "\nERROR: $1"
    echo "Continuing with next step..."
}

# Function to ensure directory exists
ensure_directory() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        echo "Created directory: $1"
    fi
}

echo "========================================================"
echo "   Quantum Networking Simulation - Complete Execution   "
echo "========================================================"

# Create directory structure if it doesn't exist
echo -e "\n=== Setting up directory structure ==="
ensure_directory "src"
ensure_directory "results"
ensure_directory "results/logs"
ensure_directory "results/metrics"
ensure_directory "results/traces"
ensure_directory "graphs"
ensure_directory "graphs/protocols"
ensure_directory "graphs/network"
echo "Directory structure created."

# Check if NS2 is installed
if ! command -v ns &> /dev/null; then
    echo "WARNING: NS2 is not installed or not in PATH."
    echo "This may cause simulation errors."
else
    echo "NS2 found at: $(which ns)"
fi

# Check if Python and required packages are installed
if ! command -v python3 &> /dev/null; then
    echo "WARNING: Python 3 is not installed or not in PATH."
    echo "This may cause analysis errors."
else
    echo "Python 3 found at: $(which python3)"
    
    # Check for required Python packages
    echo "Checking for required Python packages..."
    missing_packages=()
    
    for package in numpy matplotlib pandas networkx; do
        if ! python3 -c "import $package" &> /dev/null; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -ne 0 ]; then
        echo "WARNING: Missing Python packages: ${missing_packages[*]}"
        echo "You can install them with: pip install ${missing_packages[*]}"
        echo "Continuing anyway, but some analysis may fail."
    else
        echo "All required Python packages are installed."
    fi
fi

# Function to run a simulation
run_simulation() {
    echo -e "\n=== Running $2 ==="
    
    # First check if the file exists in the current directory
    if [ -f "$1" ]; then
        if ns "$1"; then
            echo "$2 completed successfully."
            return 0
        else
            handle_error "$2 failed."
            return 1
        fi
    # Then check if it exists in the src directory
    elif [ -f "src/$1" ]; then
        cd src
        if ns "$1"; then
            echo "$2 completed successfully."
            cd ..
            return 0
        else
            handle_error "$2 failed."
            cd ..
            return 1
        fi
    # Then check if it exists in the src/tcl_scripts directory
    elif [ -f "src/tcl_scripts/$1" ]; then
        cd src/tcl_scripts
        if ns "$1"; then
            echo "$2 completed successfully."
            cd ../..
            return 0
        else
            handle_error "$2 failed."
            cd ../..
            return 1
        fi
    else
        handle_error "Script $1 not found."
        return 1
    fi
}

# Function to run an analysis script
run_analysis() {
    echo -e "\n=== Running $2 ==="
    
    # Check multiple locations for the script
    script_path=""
    if [ -f "$1" ]; then
        script_path="$1"
    elif [ -f "src/$1" ]; then
        script_path="src/$1"
    elif [ -f "src/analysis/$1" ]; then
        script_path="src/analysis/$1"
    fi
    
    if [ -n "$script_path" ]; then
        if python3 "$script_path" $3; then
            echo "$2 completed successfully."
            return 0
        else
            handle_error "$2 failed."
            return 1
        fi
    else
        handle_error "Script $1 not found."
        return 1
    fi
}

# Run all simulations
run_simulation "multi_node_network.tcl" "Advanced Multi-Node Network Simulation"
run_simulation "advanced_qkd_protocols.tcl" "Advanced QKD Protocols Simulation"
run_simulation "basic_network.tcl" "Basic Network Simulation"
run_simulation "qkd_simulation.tcl" "Standard QKD Simulation"
run_simulation "traditional_encryption.tcl" "Traditional Encryption Simulation"
run_simulation "eavesdropper_simulation.tcl" "Eavesdropper Simulation"

# Copy any trace files to results directory if they aren't already there
echo -e "\n=== Organizing simulation output files ==="
for file in *.tr *.nam *_log.txt *_protocol.txt; do
    if [ -f "$file" ]; then
        echo "Moving $file to results directory"
        mv "$file" results/ 2>/dev/null || cp "$file" results/
    fi
done

# Run analysis scripts with error handling
BB84_LOG="results/bb84_protocol.txt"
B92_LOG="results/b92_protocol.txt"
E91_LOG="results/e91_protocol.txt"
COMP_LOG="results/protocol_comparison.txt"

# Check if required log files exist
if [ ! -f "$BB84_LOG" ]; then
    echo "Warning: BB84 protocol log file not found at $BB84_LOG"
    # Try to find a suitable substitute
    BB84_FILE=$(find results -name "*bb84*.txt" -o -name "*BB84*.txt" | head -n 1)
    if [ -n "$BB84_FILE" ]; then
        BB84_LOG="$BB84_FILE"
        echo "Using $BB84_LOG instead"
    fi
fi

if [ ! -f "$B92_LOG" ]; then
    echo "Warning: B92 protocol log file not found at $B92_LOG"
    # Try to find a suitable substitute
    B92_FILE=$(find results -name "*b92*.txt" -o -name "*B92*.txt" | head -n 1)
    if [ -n "$B92_FILE" ]; then
        B92_LOG="$B92_FILE"
        echo "Using $B92_LOG instead"
    fi
fi

if [ ! -f "$COMP_LOG" ]; then
    echo "Warning: Protocol comparison log file not found at $COMP_LOG"
    # Try to find a suitable substitute
    COMP_FILE=$(find results -name "*comparison*.txt" -o -name "*compare*.txt" | head -n 1)
    if [ -n "$COMP_FILE" ]; then
        COMP_LOG="$COMP_FILE"
        echo "Using $COMP_LOG instead"
    fi
fi

# Run analysis scripts, but continue on failure
run_analysis "protocol_analyzer.py" "Protocol Analysis" "$BB84_LOG $B92_LOG $COMP_LOG"

# Find a trace file for network analysis
TRACE_FILE=$(find results -name "*.tr" | head -n 1)
if [ -n "$TRACE_FILE" ]; then
    run_analysis "network_analyzer.py" "Network Performance Analysis" "$TRACE_FILE results/network_metrics.txt"
else
    echo "Warning: No trace files found for network analysis"
fi

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
