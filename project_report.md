# Quantum Networking Simulation Using NS2

## Abstract
This project simulates and compares quantum key distribution (QKD) with traditional encryption protocols in network environments. Using the Network Simulator 2 (NS2), we implemented BB84 quantum cryptography protocol and compared it with AES encryption to evaluate security properties, performance metrics, and resistance to eavesdropping attacks. Our results demonstrate QKD's unique ability to detect eavesdropping attempts, highlighting the trade-offs between security guarantees and implementation requirements.

## 1. Introduction
### 1.1 Background
Quantum Key Distribution represents a paradigm shift in secure communications, leveraging quantum mechanical principles to establish secure cryptographic keys. Unlike traditional encryption which relies on computational hardness assumptions, QKD provides information-theoretic security based on the laws of physics.

### 1.2 Problem Statement
Traditional encryption methods like AES and RSA may become vulnerable to quantum computing attacks in the future. This project evaluates how quantum cryptography techniques, specifically the BB84 protocol, can enhance network security by providing eavesdropping detection capabilities that traditional cryptography lacks.

### 1.3 Objectives
- Simulate BB84 quantum key distribution protocol using NS2
- Compare QKD with traditional AES encryption
- Analyze performance metrics including latency, key generation overhead, and security
- Evaluate effectiveness against eavesdropping attacks

## 2. Literature Review
### 2.1 Quantum Key Distribution
Quantum Key Distribution was first proposed by Bennett and Brassard in 1984 with their BB84 protocol. QKD leverages quantum properties like the uncertainty principle and the no-cloning theorem to create provably secure communication channels. Any eavesdropping attempt disturbs the quantum states, revealing the presence of the attacker.

### 2.2 Traditional Encryption
Traditional encryption systems like AES use mathematically complex operations to secure data. The security relies on computational hardness assumptions rather than fundamental physics, making them potentially vulnerable to future computational advances.

### 2.3 Network Security Simulation
NS2 is an event-driven simulation tool widely used for network research. While it doesn't natively support quantum properties, researchers have demonstrated techniques to simulate quantum effects in classical simulation environments.

## 3. Methodology
### 3.1 Simulation Environment
- Network Simulator 2 (NS2) version: 2.35
- Operating System: Ubuntu 22.04
- Topology: Three-node network (Alice, Bob, Eve)
- Analysis tools: Python with Matplotlib for visualization

### 3.2 BB84 Protocol Implementation
The BB84 protocol was simulated with the following steps:
1. Alice generates random bits and encodes them using random bases
2. Quantum states are transmitted to Bob
3. Bob measures using randomly selected bases
4. Alice and Bob compare basis selections over a public channel
5. Bits measured with matching bases form the raw key
6. Error detection is performed to identify potential eavesdropping

### 3.3 AES Simulation
Traditional encryption was simulated using AES:
1. Key generation and exchange using RSA
2. Symmetric encryption of data using the shared key
3. Transmission of encrypted data
4. Decryption at the receiver

### 3.4 Eavesdropping Simulation
Eve was simulated as an intermediate node that:
- For QKD: Intercepts quantum states, measures them, and forwards the result
- For AES: Captures encrypted traffic without detection

## 4. Results and Analysis
### 4.1 Security Comparison
[Insert security comparison graph]

The QKD protocol successfully detected eavesdropping attempts through increased error rates, while traditional encryption remained unaware of Eve's presence.

### 4.2 Performance Metrics
[Insert performance metrics graphs]

Performance analysis shows QKD requires additional overhead for key generation and error checking, resulting in higher latency for initial key establishment.

### 4.3 Error Rate Analysis
[Insert error rate graph]

With Eve present, the QKD error rate increased to approximately 25%, well above the 15% threshold that indicates eavesdropping.

### 4.4 Scalability Considerations
QKD shows limitations in terms of distance and network topology due to the nature of quantum communication, while traditional encryption scales more effectively across large networks.

## 5. Discussion
### 5.1 Security Implications
QKD's ability to detect eavesdropping provides a significant security advantage over traditional methods. This fundamental difference in security guarantees represents a paradigm shift in secure communications.

### 5.2 Implementation Challenges
Practical implementation of QKD faces challenges including:
- Specialized hardware requirements
- Distance limitations
- Integration with existing network infrastructure

### 5.3 Future Applications
QKD shows particular promise for high-security applications such as:
- Government and military communications
- Financial transaction security
- Critical infrastructure protection

## 6. Conclusion
Our simulation demonstrates that QKD offers stronger security guarantees through eavesdropping detection at the cost of increased complexity and resource requirements. Traditional encryption provides better performance and compatibility with existing infrastructure but lacks the ability to detect passive monitoring.

The future of network security likely lies in hybrid approaches that combine quantum and classical techniques, leveraging the strengths of each while mitigating their respective weaknesses.

## 7. Future Work
- Extend the simulation to include quantum repeaters
- Implement additional QKD protocols (E91, B92)
- Develop more realistic channel noise models
- Explore integration with existing VPN technologies

## References
1. Bennett, C. H., & Brassard, G. (1984). Quantum cryptography: Public key distribution and coin tossing. Theoretical Computer Science, 560, 7-11.
2. The Network Simulator - ns-2. (n.d.). Retrieved from https://www.isi.edu/nsnam/ns/
3. Scarani, V., Bechmann-Pasquinucci, H., Cerf, N. J., Dušek, M., Lütkenhaus, N., & Peev, M. (2009). The security of practical quantum key distribution. Reviews of Modern Physics, 81(3), 1301.
4. Gisin, N., Ribordy, G., Tittel, W., & Zbinden, H. (2002). Quantum cryptography. Reviews of Modern Physics, 74(1), 145.
5. Lo, H. K., Curty, M., & Tamaki, K. (2014). Secure quantum key distribution. Nature Photonics, 8(8), 595-604.

## Appendices
### Appendix A: NS2 Code Snippets
```tcl
# Code snippets of key implementations
```

### Appendix B: Simulation Parameters
| Parameter | QKD Value | AES Value |
|-----------|-----------|-----------|
| Key Size  | Variable (depends on quantum bit exchange) | 256 bits |
| Error Threshold | 15% | N/A |
| Link Bandwidth | 1 Mbps | 1 Mbps |
| Link Delay | 10 ms | 10 ms |
| Simulation Duration | 5 seconds | 5 seconds |

### Appendix C: Sample Outputs
Sample output logs from simulation runs with and without eavesdropping.
