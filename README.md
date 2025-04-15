# Quantum Networking Simulation Using NS2

This project simulates quantum key distribution (QKD) protocols and compares them with traditional encryption approaches using Network Simulator 2 (NS2).

## Project Structure

- `src/` - TCL scripts for NS2 simulations
  - `basic_network.tcl` - Simple two-node network setup
  - `qkd_simulation.tcl` - BB84 quantum key distribution simulation
  - `traditional_encryption.tcl` - AES/RSA encryption simulation
  - `eavesdropper_simulation.tcl` - Comparison with eavesdropper present
- `results/` - Output files from simulations
- `graphs/` - Generated visualization graphs
- `report/` - Project documentation and report
- `presentation/` - Presentation materials

## Setup Instructions

1. Install NS2 and required dependencies:
   ```bash
   sudo apt-get update
   sudo apt-get install ns2 nam
   ```

2. Install Python dependencies for analysis:
   ```bash
   sudo apt-get install python3-matplotlib python3-numpy
   ```

3. Run the simulations:
   ```bash
   cd src
   ns basic_network.tcl
   ns qkd_simulation.tcl
   ns traditional_encryption.tcl
   ns eavesdropper_simulation.tcl
   ```

4. Analyze the results:
   ```bash
   cd ..
   python3 src/data_analyzer.py
   ```

5. Review the generated graphs in the `graphs/` directory

## Implementation Details

This project implements:

1. BB84 Quantum Key Distribution protocol
2. Traditional AES/RSA key exchange and encryption
3. Eavesdropping detection in QKD
4. Performance comparison between quantum and traditional approaches

## References

- Bennett, C. H., & Brassard, G. (1984). Quantum cryptography: Public key distribution and coin tossing.
- The Network Simulator - ns-2. https://www.isi.edu/nsnam/ns/
