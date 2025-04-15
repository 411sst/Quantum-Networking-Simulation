# Quantum Networking Simulation Using NS2

This project simulates quantum key distribution (QKD) protocols and compares them with traditional encryption approaches using Network Simulator 2 (NS2). It features a multi-node network topology and implements multiple QKD protocols.

## Project Overview

Quantum Key Distribution represents the future of secure communications, leveraging quantum mechanical principles to create theoretically unbreakable encryption keys. This simulation project provides a comprehensive platform for studying, comparing, and visualizing quantum cryptographic protocols in realistic network environments.

### Key Features

- Implementation of multiple QKD protocols (BB84, B92, E91)
- Advanced 6-node network topology with quantum repeaters
- Realistic modeling of quantum channel effects
- Sophisticated eavesdropping scenarios and detection
- Comprehensive performance analysis and visualization
- Detailed comparison between quantum and traditional approaches

## Project Structure

- `src/` - TCL scripts for NS2 simulations
  - `basic_network.tcl` - Simple two-node network setup
  - `qkd_simulation.tcl` - BB84 quantum key distribution simulation
  - `traditional_encryption.tcl` - AES/RSA encryption simulation
  - `eavesdropper_simulation.tcl` - Comparison with eavesdropper present
  - `multi_node_network.tcl` - Advanced six-node network topology simulation
  - `advanced_qkd_protocols.tcl` - Implementation of BB84, B92, and E91 protocols
  - `protocol_analyzer.py` - Analyzes and compares QKD protocol performance
  - `network_analyzer.py` - Analyzes network performance metrics
  - `data_analyzer.py` - Comprehensive data analysis and visualization
- `results/` - Output files from simulations
  - `logs/` - Protocol execution logs
  - `metrics/` - Performance metrics data
- `graphs/` - Generated visualization graphs
  - `protocols/` - Protocol comparison visualizations
  - `network/` - Network performance visualizations
- `report/` - Project documentation and report
- `presentation/` - Presentation materials

## Setup Instructions

1. Install NS2 and required dependencies:
   ```bash
   sudo apt-get update
   sudo apt-get install ns2 nam tcl8.6 tk8.6
   ```

2. Install Python dependencies for analysis:
   ```bash
   pip install numpy matplotlib pandas networkx scipy
   ```

3. Set up the project directory structure:
   ```bash
   mkdir -p src results/logs results/metrics graphs/protocols graphs/network report presentation
   ```

4. Run the advanced multi-node simulation:
   ```bash
   cd src
   ns multi_node_network.tcl
   ```

5. Run the advanced QKD protocols simulation:
   ```bash
   cd src
   ns advanced_qkd_protocols.tcl
   ```

6. Analyze the results:
   ```bash
   python src/protocol_analyzer.py results/bb84_protocol.txt results/b92_protocol.txt results/protocol_comparison.txt
   python src/network_analyzer.py results/multi_node_trace.tr results/network_metrics.txt
   python src/data_analyzer.py
   ```

7. Run all simulations with a single command:
   ```bash
   ./run_all.sh
   ```

8. Review the generated graphs in the `graphs/` directory and reports in the `results/` directory

## Implementation Details

### Quantum Key Distribution Protocols

1. **BB84 Protocol (Bennett-Brassard 1984)**
   - The original QKD protocol using four quantum states in two bases
   - Detection of eavesdropping through quantum bit error rate (QBER)
   - Full implementation with basis reconciliation, error estimation, and privacy amplification

2. **B92 Protocol (Bennett 1992)**
   - Simplified QKD protocol using only two non-orthogonal quantum states
   - More efficient implementation but potentially lower key generation rate
   - Implemented with proper quantum channel modeling and eavesdropping detection

3. **E91 Protocol (Ekert 1991)**
   - Entanglement-based QKD protocol using Bell's inequality
   - Security based on fundamental quantum mechanical principles
   - Implementation includes entanglement distribution and Bell state measurements

### Network Architecture

The advanced network topology includes:

- **Core Quantum Nodes**: Alice, Bob, and two Quantum Repeater nodes
- **Edge Network Nodes**: Traditional network nodes for classical communication
- **Eavesdropper Nodes**: Eve1 and Eve2 for simulating different attack strategies
- **Variable Links**: Different bandwidth, delay, and queue configurations for realistic simulation

### Performance Analysis

The project includes comprehensive analysis tools:

- **Protocol Comparison**: Side-by-side analysis of all QKD protocols
- **Security Evaluation**: Quantitative assessment of eavesdropping detection capabilities
- **Efficiency Analysis**: Key generation rates and resource requirements
- **Network Performance**: Throughput, delay, and loss metrics across the network

## Running Experiments

The project supports various experimental scenarios:

1. **Basic Operation**: Standard protocol operation without interference
   ```bash
   ns src/multi_node_network.tcl
   ```

2. **Eavesdropping Detection**: Active Eve nodes intercepting quantum states
   ```bash
   ns src/advanced_qkd_protocols.tcl
   ```

3. **Protocol Comparison**: Automated comparison of all implemented protocols
   ```bash
   python src/protocol_analyzer.py results/bb84_protocol.txt results/b92_protocol.txt results/protocol_comparison.txt
   ```

4. **Comprehensive Analysis**: Complete analysis and visualization of all results
   ```bash
   python src/data_analyzer.py
   ```

## Results and Visualization

After running the simulations, you can find:

- Protocol comparison graphs in `graphs/protocols/`
- Network performance visualizations in `graphs/network/`
- Comprehensive report in `results/comparative_report.md`
- Raw data logs in `results/logs/`

## Advanced Customization

The simulation can be customized by modifying parameters in the TCL scripts:

- Quantum error rates and channel losses
- Network topology and link characteristics
- Eavesdropping strategies and detection thresholds
- Protocol-specific parameters

## References

- Bennett, C. H., & Brassard, G. (1984). Quantum cryptography: Public key distribution and coin tossing. *Theoretical Computer Science*, 560, 7-11.
- Bennett, C. H. (1992). Quantum cryptography using any two nonorthogonal states. *Physical Review Letters*, 68(21), 3121.
- Ekert, A. K. (1991). Quantum cryptography based on Bell's theorem. *Physical Review Letters*, 67(6), 661.
- Gisin, N., Ribordy, G., Tittel, W., & Zbinden, H. (2002). Quantum cryptography. *Reviews of Modern Physics*, 74(1), 145.
- Scarani, V., Bechmann-Pasquinucci, H., Cerf, N. J., Dušek, M., Lütkenhaus, N., & Peev, M. (2009). The security of practical quantum key distribution. *Reviews of Modern Physics*, 81(3), 1301.
- The Network Simulator - ns-2. https://www.isi.edu/nsnam/ns/
