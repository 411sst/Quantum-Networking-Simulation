# Quantum Networking Simulation Tutorial

This tutorial will guide you through understanding and running the Quantum Networking Simulation project as a beginner.

## 1. Understanding the Basics

### What is QKD?
Quantum Key Distribution (QKD) is a technique that uses quantum mechanics principles to securely distribute cryptographic keys between parties. Unlike traditional encryption, it can detect any eavesdropping attempts.

### What is NS2?
Network Simulator 2 (NS2) is a discrete event network simulator used for research and education. It allows us to simulate network protocols and understand their behavior without real hardware.

## 2. Setting Up Your Environment

### First-time Installation
Follow these steps to set up the environment on a fresh Ubuntu installation:

```bash
# Update package lists
sudo apt update

# Install NS2 and required dependencies
sudo apt install -y ns2 nam tcl8.6 tk8.6

# Install Python venv support
sudo apt install -y python3-venv python3-full

# Set up directory structure
chmod +x setup_directories.sh
./setup_directories.sh

# Create and activate Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
pip install numpy matplotlib pandas networkx scipy

# Make run script executable
chmod +x src/utils/run_all.sh
```

### Running the Project After Initial Setup

Once you've completed the initial setup, you can run the project in the future with just three simple steps:

1. **Navigate to the project directory**:
   ```bash
   cd quantum-networking-simulation  # or your project directory
   ```

2. **Activate the virtual environment**:
   ```bash
   source venv/bin/activate
   ```

3. **Run the simulation script**:
   ```bash
   ./src/utils/run_all.sh
   ```

That's it! The script will execute all simulations and generate the results.

## 3. Understanding the Project Files

### TCL Scripts
The core simulation files are written in TCL:

- `basic_network.tcl`: Creates a simple network with two nodes
- `qkd_simulation.tcl`: Implements the BB84 QKD protocol
- `traditional_encryption.tcl`: Simulates AES encryption
- `eavesdropper_simulation.tcl`: Compares both approaches with an eavesdropper
- `multi_node_network.tcl`: Creates an advanced 6-node topology
- `advanced_qkd_protocols.tcl`: Implements multiple QKD protocols (BB84, B92, E91)

### Analysis Scripts
The Python scripts process simulation outputs and generate visualizations:

- `protocol_analyzer.py`: Analyzes and compares QKD protocol performance
- `network_analyzer.py`: Analyzes network performance metrics
- `data_analyzer.py`: Comprehensive data analysis and visualization

## 4. Understanding the Output

### Trace Files
NS2 generates trace files (`.tr`) that contain detailed information about each packet, including:
- When it was sent or received
- Source and destination nodes
- Packet size and type

### NAM Files
Network Animator (NAM) files (`.nam`) provide a visual representation of the simulation.

### Log Files
Custom log files (`.txt`) contain protocol-specific information like key bits, error rates, etc.

## 5. Viewing Results

After running the simulations, you can view the results:

```bash
# View protocol comparison visualizations
ls graphs/protocols/

# View network performance visualizations
ls graphs/network/

# View the comprehensive report
less results/comparative_report.md
```

Key visualizations include:
- QBER (Quantum Bit Error Rate) comparisons with and without eavesdropping
- Key generation efficiency across different protocols
- Eavesdropping detection capabilities
- Protocol comparison radar charts

## 6. Experiment Ideas

Once you understand the basics, try these experiments:

1. Modify the error threshold in QKD (default is 15%)
2. Change the network topology by adding more nodes
3. Implement different attack strategies for Eve
4. Add network congestion to see its effect on both protocols

## 7. Common Issues

### NS2 Command Not Found
If you get "command not found" errors for ns, ensure NS2 is properly installed:
```bash
which ns
```

### Python Module Not Found
If you get module import errors, make sure your virtual environment is activated:
```bash
source venv/bin/activate
```

### NAM Not Opening
If NAM doesn't open automatically, try running it manually:
```bash
nam results/traces/multi_node_nam.nam &
```

### Path Reference Errors
If scripts can't find files, check path references in the run_all.sh script.

## 8. Next Steps

After mastering the basics:
1. Read the full project report to understand the theoretical background
2. Explore the NS2 documentation to learn more about network simulation
3. Research current real-world QKD implementations
4. Try implementing additional QKD protocols
