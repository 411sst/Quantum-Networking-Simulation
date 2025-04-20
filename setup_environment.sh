#!/bin/bash
# Setup script for Quantum Networking Simulation project
# This script creates the directory structure and installs required dependencies

echo "============================================================"
echo "  Quantum Networking Simulation - Environment Setup Script  "
echo "============================================================"

# Create the directory structure
echo -e "\n=== Creating directory structure ==="
mkdir -p src/tcl_scripts src/analysis src/utils
mkdir -p results/logs results/metrics results/traces
mkdir -p graphs/protocols graphs/network
mkdir -p docs/report docs/presentation docs/tutorials

echo "Directory structure created successfully."

# Check for NS2
echo -e "\n=== Checking for NS2 ==="
if command -v ns &> /dev/null; then
    echo "NS2 is installed at: $(which ns)"
else
    echo "NS2 is not installed."
    echo "To install NS2 on Ubuntu/Debian, run:"
    echo "  sudo apt update"
    echo "  sudo apt install ns2 nam tcl8.6 tk8.6"
fi

# Check for Python
echo -e "\n=== Checking for Python ==="
if command -v python3 &> /dev/null; then
    echo "Python 3 is installed at: $(which python3)"
    PYTHON_VERSION=$(python3 --version)
    echo "Version: $PYTHON_VERSION"
else
    echo "Python 3 is not installed."
    echo "To install Python 3 on Ubuntu/Debian, run:"
    echo "  sudo apt update"
    echo "  sudo apt install python3 python3-pip python3-venv"
    exit 1
fi

# Set up Python virtual environment
echo -e "\n=== Setting up Python virtual environment ==="
if [ ! -d "venv" ]; then
    echo "Creating new virtual environment..."
    if python3 -m venv venv; then
        echo "Virtual environment created successfully."
    else
        echo "Failed to create virtual environment."
        echo "You may need to install venv package:"
        echo "  sudo apt install python3-venv"
        
        # Try to continue anyway
        echo "Attempting to install required packages globally..."
        pip3 install numpy matplotlib pandas networkx scipy
        echo "NOTE: Packages installed globally. For better isolation, set up a virtual environment."
        
        echo -e "\n=== Setup complete, but with warnings ==="
        exit 1
    fi
else
    echo "Using existing virtual environment."
fi

# Activate virtual environment and install packages
echo -e "\n=== Installing required Python packages ==="
source venv/bin/activate

# Install required packages
echo "Installing required Python packages..."
pip install --upgrade pip
pip install numpy matplotlib pandas networkx scipy

# Make scripts executable
echo -e "\n=== Making scripts executable ==="
find . -name "*.py" -exec chmod +x {} \;
find . -name "*.sh" -exec chmod +x {} \;

echo -e "\n============================================================"
echo "  Setup completed successfully!                               "
echo "============================================================"
echo -e "\nTo activate the virtual environment, run:"
echo "  source venv/bin/activate"
echo -e "\nTo run all simulations, run:"
echo "  ./run_all.sh"
echo -e "\nTo deactivate the virtual environment when done, run:"
echo "  deactivate"
