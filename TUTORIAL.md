# Quantum Networking Simulation Tutorial

This tutorial will guide you through understanding and running the Quantum Networking Simulation project as a beginner.

## 1. Understanding the Basics

### What is QKD?
Quantum Key Distribution (QKD) is a technique that uses quantum mechanics principles to securely distribute cryptographic keys between parties. Unlike traditional encryption, it can detect any eavesdropping attempts.

### What is NS2?
Network Simulator 2 (NS2) is a discrete event network simulator used for research and education. It allows us to simulate network protocols and understand their behavior without real hardware.

## 2. Setting Up Your Environment

### Installing NS2
Follow these steps to install NS2 on Ubuntu/Linux Mint:

```bash
sudo apt-get update
sudo apt-get install ns2 nam
```

### Verifying Installation
Check if NS2 is installed correctly:

```bash
ns -v
```

You should see the NS2 version number.

## 3. Understanding the Project Files

### TCL Scripts
The core simulation files are written in TCL:

- `basic_network.tcl`: Creates a simple network with two nodes
- `qkd_simulation.tcl`: Implements the BB84 QKD protocol
- `traditional_encryption.tcl`: Simulates AES encryption
- `eavesdropper_simulation.tcl`: Compares both approaches with an eavesdropper

### Analysis Script
The Python script `data_analyzer.py` processes the simulation outputs and generates graphs.

## 4. Running Your First Simulation

### Basic Network
Start with the basic network to ensure everything is working:

```bash
cd src
ns basic_network.tcl
```

You should see a NAM window appear showing the network topology.

### QKD Simulation
Next, run the QKD simulation:

```bash
ns qkd_simulation.tcl
```

This will generate log files with QKD protocol details.

## 5. Understanding the Output

### Trace Files
NS2 generates trace files (`.tr`) that contain detailed information about each packet, including:
- When it was sent or received
- Source and destination nodes
- Packet size and type

### NAM Files
Network Animator (NAM) files (`.nam`) provide a visual representation of the simulation.

### Log Files
Custom log files (`.txt`) contain protocol-specific information like key bits, error rates, etc.

## 6. Analyzing Results

Run the data analyzer to create visual comparisons:

```bash
cd ..
python3 src/data_analyzer.py
```

Check the graphs directory for visual representations of:
- Error rates with and without eavesdropping
- Performance comparisons between QKD and AES
- Security feature comparisons

## 7. Experiment Ideas

Once you understand the basics, try these experiments:

1. Modify the error threshold in QKD (default is 15%)
2. Change the network topology by adding more nodes
3. Implement a different QKD protocol like B92
4. Add network congestion to see its effect on both protocols

## 8. Common Issues

### NAM Not Opening
If NAM doesn't open automatically, try running it manually:

```bash
nam filename.nam &
```

### Python Errors
If you get errors with the data analyzer, ensure you have the required libraries:

```bash
sudo apt-get install python3-matplotlib python3-numpy
```

## 9. Next Steps

After mastering the basics:
1. Read the full project report to understand the theoretical background
2. Explore the NS2 documentation to learn more about network simulation
3. Research current real-world QKD implementations
