#!/bin/bash
# Script to create all necessary directories for the quantum networking simulation project

echo "========================================================"
echo "   Creating directory structure for Quantum Networking   "
echo "   Simulation Project                                   "
echo "========================================================"

# Create main directories
mkdir -p src
mkdir -p results
mkdir -p graphs
mkdir -p docs

# Create subdirectories
echo "Creating source code directories..."
mkdir -p src/tcl_scripts
mkdir -p src/analysis
mkdir -p src/utils

echo "Creating results directories..."
mkdir -p results/logs
mkdir -p results/metrics
mkdir -p results/traces

echo "Creating visualization directories..."
mkdir -p graphs/protocols
mkdir -p graphs/network

echo "Creating documentation directories..."
mkdir -p docs/report
mkdir -p docs/presentation
mkdir -p docs/tutorials

echo "========================================================"
echo "   Directory structure created successfully!            "
echo "========================================================"
echo
echo "Project directories:"
echo "- src/: Source code files"
echo "  - tcl_scripts/: NS2 TCL simulation scripts"
echo "  - analysis/: Python analysis tools"
echo "  - utils/: Utility scripts"
echo
echo "- results/: Simulation results"
echo "  - logs/: Protocol execution logs"
echo "  - metrics/: Performance metrics data"
echo "  - traces/: NS2 trace files"
echo
echo "- graphs/: Generated visualizations"
echo "  - protocols/: Protocol comparison graphs"
echo "  - network/: Network performance graphs"
echo
echo "- docs/: Documentation"
echo "  - report/: Project reports"
echo "  - presentation/: Presentation materials"
echo "  - tutorials/: User tutorials"
echo
echo "You can now proceed with running the simulations!"
