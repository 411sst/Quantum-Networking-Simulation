#!/usr/bin/env python3
"""
Comprehensive Data Analyzer for QKD Simulation
This script processes all simulation data and generates unified reports and visualizations.
"""

import os
import sys
import re
import glob
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import PercentFormatter
import matplotlib.colors as mcolors
import pandas as pd
from collections import defaultdict
import networkx as nx
import subprocess

def ensure_directory(directory):
    """Ensure the specified directory exists."""
    if not os.path.exists(directory):
        os.makedirs(directory)

def extract_qkd_metrics(log_files):
    """Extract QKD performance metrics from log files."""
    protocols = []
    metrics = {
        'protocol': [],
        'eavesdropping': [],
        'qber': [],
        'raw_key_length': [],
        'final_key_length': [],
        'success': []
    }
    
    for log_file in log_files:
        protocol_name = os.path.basename(log_file).split('_')[0]
        protocols.append(protocol_name)
        
        with open(log_file, 'r') as f:
            content = f.read()
            
            # Split by eavesdropping sections
            eavesdropping_sections = []
            if "Eavesdropping: None" in content:
                eavesdropping_sections.append(("None", content.split("Eavesdropping: None")[1]))
            
            if "Eavesdropping: Active" in content:
                eavesdropping_sections.append(("Active", content.split("Eavesdropping: Active")[1]))
            
            for eavesdropping, section in eavesdropping_sections:
                metrics['protocol'].append(protocol_name)
                metrics['eavesdropping'].append(eavesdropping == "Active")
                
                # Extract QBER
                qber_match = re.search(r"Quantum Bit Error Rate \(QBER\): ([0-9.]+)", section)
                if qber_match:
                    metrics['qber'].append(float(qber_match.group(1)))
                else:
                    metrics['qber'].append(None)
                
                # Extract key lengths
                raw_key_match = re.search(r"raw key length: (\d+) bits", section)
                if raw_key_match:
                    metrics['raw_key_length'].append(int(raw_key_match.group(1)))
                else:
                    metrics['raw_key_length'].append(0)
                
                final_key_match = re.search(r"Final secure key length.+?: (\d+) bits", section)
                if final_key_match:
                    metrics['final_key_length'].append(int(final_key_match.group(1)))
                else:
                    metrics['final_key_length'].append(0)
                
                # Extract success
                metrics['success'].append("Protocol ABORTED" not in section)
    
    return pd.DataFrame(metrics)

def extract_trace_metrics(trace_files):
    """Extract network performance metrics from trace files."""
    metrics = {
        'file': [],
        'throughput_avg': [],
        'throughput_peak': [],
        'packet_loss': [],
        'delay_avg': [],
        'delay_jitter': [],
        'protocol_overhead': []
    }
    
    for trace_file in trace_files:
        # Use network_analyzer.py to process the trace file
        output_file = f"results/metrics_{os.path.basename(trace_file)}.txt"
        subprocess.run([
            "python3", "network_analyzer.py", 
            trace_file, output_file
        ])
        
        # Extract metrics from the output file
        with open(output_file, 'r') as f:
            content = f.read()
            
            metrics['file'].append(os.path.basename(trace_file))
            
            # Extract throughput
            throughput_avg_match = re.search(r"Average throughput: ([0-9.]+) bits/s", content)
            if throughput_avg_match:
                metrics['throughput_avg'].append(float(throughput_avg_match.group(1)))
            else:
                metrics['throughput_avg'].append(None)
            
            throughput_peak_match = re.search(r"Peak throughput: ([0-9.]+) bits/s", content)
            if throughput_peak_match:
                metrics['throughput_peak'].append(float(throughput_peak_match.group(1)))
            else:
                metrics['throughput_peak'].append(None)
            
            # Extract packet loss
            packet_loss_match = re.search(r"Packet loss ratio: ([0-9.]+)%", content)
            if packet_loss_match:
                metrics['packet_loss'].append(float(packet_loss_match.group(1)))
            else:
                metrics['packet_loss'].append(None)
            
            # Extract delay
            delay_avg_match = re.search(r"Average end-to-end delay: ([0-9.]+) seconds", content)
            if delay_avg_match:
                metrics['delay_avg'].append(float(delay_avg_match.group(1)))
            else:
                metrics['delay_avg'].append(None)
            
            delay_jitter_match = re.search(r"Delay jitter: ([0-9.]+) seconds", content)
            if delay_jitter_match:
                metrics['delay_jitter'].append(float(delay_jitter_match.group(1)))
            else:
                metrics['delay_jitter'].append(None)
            
            # Extract protocol overhead
            overhead_match = re.search(r"Protocol overhead: ([0-9.]+)%", content)
            if overhead_match:
                metrics['protocol_overhead'].append(float(overhead_match.group(1)))
            else:
                metrics['protocol_overhead'].append(None)
    
    return pd.DataFrame(metrics)

def plot_qkd_comparison(df, output_dir):
    """Generate comparative visualizations for QKD protocols."""
    # Filter data for with/without eavesdropping
    df_no_eve = df[df['eavesdropping'] == False]
    df_with_eve = df[df['eavesdropping'] == True]
    
    # 1. QBER Comparison
    plt.figure(figsize=(12, 7))
    
    # Set up the bars
    protocols = df_no_eve['protocol'].unique()
    x = np.arange(len(protocols))
    width = 0.35
    
    # Get QBER values
    qber_no_eve = [df_no_eve[df_no_eve['protocol'] == p]['qber'].values[0] for p in protocols]
    qber_with_eve = [df_with_eve[df_with_eve['protocol'] == p]['qber'].values[0] for p in protocols]
    
    # Plot the bars
    plt.bar(x - width/2, qber_no_eve, width, label='Without Eavesdropping', color='green', alpha=0.7)
    plt.bar(x + width/2, qber_with_eve, width, label='With Eavesdropping', color='red', alpha=0.7)
    
    # Add threshold lines
    plt.axhline(y=0.15, color='blue', linestyle='--', label='BB84 Threshold (15%)')
    plt.axhline(y=0.12, color='purple', linestyle='--', label='B92 Threshold (12%)')
    
    # Customize plot
    plt.xlabel('Protocol', fontsize=12)
    plt.ylabel('Quantum Bit Error Rate (QBER)', fontsize=12)
    plt.title('Effect of Eavesdropping on QBER by Protocol', fontsize=14)
    plt.xticks(x, protocols)
    plt.legend()
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    
    # Save plot
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'qber_comparison.png'), dpi=300)
    plt.close()
    
    # 2. Key Generation Efficiency
    plt.figure(figsize=(12, 7))
    
    # Get key lengths
    raw_key_no_eve = [df_no_eve[df_no_eve['protocol'] == p]['raw_key_length'].values[0] for p in protocols]
    raw_key_with_eve = [df_with_eve[df_with_eve['protocol'] == p]['raw_key_length'].values[0] for p in protocols]
    
    # Calculate efficiency (bits per qubit)
    efficiency_no_eve = [key/1000 for key in raw_key_no_eve]  # Assuming 1000 qubits sent
    efficiency_with_eve = [key/1000 for key in raw_key_with_eve]
    
    # Plot the bars
    plt.bar(x - width/2, efficiency_no_eve, width, label='Without Eavesdropping', color='green', alpha=0.7)
    plt.bar(x + width/2, efficiency_with_eve, width, label='With Eavesdropping', color='red', alpha=0.7)
    
    # Customize plot
    plt.xlabel('Protocol', fontsize=12)
    plt.ylabel('Key Generation Efficiency (bits/qubit)', fontsize=12)
    plt.title('Key Generation Efficiency by Protocol', fontsize=14)
    plt.xticks(x, protocols)
    plt.legend()
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    
    # Save plot
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'key_efficiency.png'), dpi=300)
    plt.close()
    
    # 3. Eavesdropping Detection
    plt.figure(figsize=(12, 7))
    
    # Check if protocols detected eavesdropping
    detection = [not success for success in df_with_eve['success']]
    
    # Plot the bars
    plt.bar(protocols, [100 if d else 0 for d in detection], color='blue', alpha=0.7)
    
    # Customize plot
    plt.xlabel('Protocol', fontsize=12)
    plt.ylabel('Eavesdropping Detection (%)', fontsize=12)
    plt.title('Eavesdropping Detection Capability by Protocol', fontsize=14)
    plt.yticks([0, 25, 50, 75, 100])
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    
    # Add text labels
    for i, d in enumerate(detection):
        plt.text(i, 50, 'Detected' if d else 'Not Detected', 
                ha='center', va='center', color='white', fontweight='bold')
    
    # Save plot
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'eavesdropping_detection.png'), dpi=300)
    plt.close()
    
    # 4. Protocol Comparison Radar Chart
    # Define the categories and protocols
    categories = ['Key Efficiency', 'Eve Detection', 'Error Tolerance', 
                 'Implementation\nSimplicity', 'Resource\nEfficiency']
    
    # Normalize the data for radar chart
    # These are subjective ratings based on protocol characteristics
    scores = {
        'BB84': [
            efficiency_no_eve[protocols.tolist().index('BB84')] / max(efficiency_no_eve),  # Key Efficiency
            1.0 if 'BB84' in protocols and detection[protocols.tolist().index('BB84')] else 0.0,  # Eve Detection
            0.8,  # Error Tolerance (subjective)
            0.7,  # Implementation Simplicity (subjective)
            0.7   # Resource Efficiency (subjective)
        ],
        'B92': [
            efficiency_no_eve[protocols.tolist().index('B92')] / max(efficiency_no_eve) if 'B92' in protocols else 0,
            1.0 if 'B92' in protocols and detection[protocols.tolist().index('B92')] else 0.0,
            0.6,  # Lower threshold than BB84
            0.9,  # Simpler than BB84
            0.8   # More efficient than BB84
        ],
        'E91': [
            efficiency_no_eve[protocols.tolist().index('E91')] / max(efficiency_no_eve) if 'E91' in protocols else 0,
            1.0 if 'E91' in protocols and detection[protocols.tolist().index('E91')] else 0.0,
            0.9,  # Highest tolerance
            0.5,  # Most complex
            0.4   # Lowest efficiency (needs entanglement)
        ]
    }
    
    # Set up the radar chart
    angles = np.linspace(0, 2*np.pi, len(categories), endpoint=False).tolist()
    angles += angles[:1]  # Close the polygon
    
    fig, ax = plt.subplots(figsize=(10, 10), subplot_kw=dict(polar=True))
    
    # Plot each protocol
    colors = ['blue', 'green', 'red']
    for i, protocol in enumerate(scores.keys()):
        if protocol in protocols:
            values = scores[protocol]
            values += values[:1]  # Close the polygon
            ax.plot(angles, values, color=colors[i], linewidth=2, label=protocol)
            ax.fill(angles, values, color=colors[i], alpha=0.1)
    
    # Customize the chart
    ax.set_thetagrids(np.degrees(angles[:-1]), categories)
    ax.set_ylim(0, 1)
    ax.set_title('Protocol Comparison Across Multiple Dimensions', size=15)
    ax.legend(loc='upper right')
    ax.grid(True)
    
    # Save plot
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'protocol_radar_comparison.png'), dpi=300)
    plt.close()

def visualize_network_topology(output_dir):
    """Create a visualization of the quantum network topology."""
    G = nx.Graph()
    
    # Add nodes
    nodes = {
        'Alice': {'pos': (0, 0), 'color': 'blue', 'role': 'sender'},
        'Bob': {'pos': (10, 0), 'color': 'green', 'role': 'receiver'},
        'QRepeater1': {'pos': (3, 0), 'color': 'cyan', 'role': 'repeater'},
        'QRepeater2': {'pos': (7, 0), 'color': 'cyan', 'role': 'repeater'},
        'EdgeNode1': {'pos': (1, -3), 'color': 'orange', 'role': 'edge'},
        'EdgeNode2': {'pos': (9, -3), 'color': 'orange', 'role': 'edge'},
        'Eve1': {'pos': (3, 3), 'color': 'red', 'role': 'eavesdropper'},
        'Eve2': {'pos': (7, 3), 'color': 'red', 'role': 'eavesdropper'}
    }
    
    for node, attrs in nodes.items():
        G.add_node(node, **attrs)
    
    # Add edges
    edges = [
        ('Alice', 'QRepeater1', {'weight': 1, 'type': 'quantum', 'bandwidth': '10Mb'}),
        ('QRepeater1', 'QRepeater2', {'weight': 2, 'type': 'quantum', 'bandwidth': '5Mb'}),
        ('QRepeater2', 'Bob', {'weight': 1, 'type': 'quantum', 'bandwidth': '10Mb'}),
        ('Alice', 'EdgeNode1', {'weight': 0.5, 'type': 'classical', 'bandwidth': '100Mb'}),
        ('Bob', 'EdgeNode2', {'weight': 0.5, 'type': 'classical', 'bandwidth': '100Mb'}),
        ('Eve1', 'QRepeater1', {'weight': 0.5, 'type': 'attack', 'bandwidth': '1Mb'}),
        ('Eve2', 'QRepeater2', {'weight': 0.5, 'type': 'attack', 'bandwidth': '1Mb'})
    ]
    
    for src, dst, attrs in edges:
        G.add_edge(src, dst, **attrs)
    
    # Create the visualization
    plt.figure(figsize=(12, 8))
    
    # Get node positions
    pos = nx.get_node_attributes(G, 'pos')
    
    # Draw nodes with different colors based on role
    node_colors = [data['color'] for node, data in G.nodes(data=True)]
    node_sizes = [1000 if data['role'] in ['sender', 'receiver'] else 
                 800 if data['role'] == 'repeater' else 
                 600 if data['role'] == 'edge' else 
                 700 for node, data in G.nodes(data=True)]
    
    nx.draw_networkx_nodes(G, pos, node_color=node_colors, node_size=node_sizes, alpha=0.8)
    
    # Draw edges with different styles based on type
    quantum_edges = [(u, v) for u, v, data in G.edges(data=True) if data['type'] == 'quantum']
    classical_edges = [(u, v) for u, v, data in G.edges(data=True) if data['type'] == 'classical']
    attack_edges = [(u, v) for u, v, data in G.edges(data=True) if data['type'] == 'attack']
    
    nx.draw_networkx_edges(G, pos, edgelist=quantum_edges, width=2, edge_color='blue', style='solid', 
                         label='Quantum Channel')
    nx.draw_networkx_edges(G, pos, edgelist=classical_edges, width=1.5, edge_color='black', style='dashed',
                         label='Classical Channel')
    nx.draw_networkx_edges(G, pos, edgelist=attack_edges, width=1, edge_color='red', style='dotted',
                         label='Eavesdropping')
    
    # Add edge labels
    edge_labels = {(u, v): data['bandwidth'] for u, v, data in G.edges(data=True)}
    nx.draw_networkx_edge_labels(G, pos, edge_labels=edge_labels, font_size=8)
    
    # Add node labels
    nx.draw_networkx_labels(G, pos, font_size=10, font_weight='bold')
    
    # Add legend
    plt.legend(scatterpoints=1, loc='lower center', ncol=3, fontsize=10, bbox_to_anchor=(0.5, -0.15))
    
    plt.title('Quantum Network Topology with Multi-hop QKD', fontsize=14)
    plt.axis('off')
    plt.tight_layout()
    
    # Save the visualization
    plt.savefig(os.path.join(output_dir, 'network_topology.png'), dpi=300)
    plt.close()
    
    # Create a diagram of quantum state preparation and measurement
    plt.figure(figsize=(14, 8))
    
    # Define the quantum states
    states = {
        '|0⟩': {'basis': 'Rectilinear', 'angle': 0, 'color': 'blue', 'label': '0-bit'},
        '|1⟩': {'basis': 'Rectilinear', 'angle': 90, 'color': 'blue', 'label': '1-bit'},
        '|+⟩': {'basis': 'Diagonal', 'angle': 45, 'color': 'green', 'label': '0-bit'},
        '|-⟩': {'basis': 'Diagonal', 'angle': 135, 'color': 'green', 'label': '1-bit'}
    }
    
    # Plot layout
    plt.subplot(1, 2, 1)
    # Plot polarization vectors for each state
    for state, attrs in states.items():
        angle_rad = np.radians(attrs['angle'])
        x = np.cos(angle_rad)
        y = np.sin(angle_rad)
        plt.quiver(0, 0, x, y, angles='xy', scale_units='xy', scale=1, 
                 color=attrs['color'], label=f"{state} ({attrs['basis']})")
    
    plt.xlim(-1.2, 1.2)
    plt.ylim(-1.2, 1.2)
    plt.grid(True)
    plt.legend()
    plt.title('Quantum States in BB84 Protocol')
    
    # Plot BB84 protocol flowchart
    plt.subplot(1, 2, 2)
    steps = [
        'Alice generates random bits',
        'Alice chooses random basis for each bit',
        'Alice prepares quantum states',
        'Quantum states transmitted to Bob',
        'Bob measures with random bases',
        'Alice & Bob compare bases (public channel)',
        'Keep only matching basis measurements',
        'Error estimation & detection',
        'Privacy amplification',
        'Final secure key'
    ]
    
    for i, step in enumerate(steps):
        plt.text(0.1, 0.95 - i*0.09, f"{i+1}. {step}", fontsize=10, 
               bbox=dict(facecolor='lightblue', alpha=0.5))
    
    plt.xlim(0, 1)
    plt.ylim(0, 1)
    plt.axis('off')
    plt.title('BB84 Protocol Steps')
    
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'quantum_states_protocol.png'), dpi=300)
    plt.close()

def generate_comparative_report(df_qkd, output_dir):
    """Generate a comprehensive comparative report of QKD implementations."""
    report_file = os.path.join(output_dir, 'comparative_report.md')
    
    with open(report_file, 'w') as f:
        f.write("# Comprehensive QKD Protocol Comparison Report\n\n")
        
        f.write("## 1. Executive Summary\n\n")
        f.write("This report presents a comparative analysis of multiple Quantum Key Distribution (QKD) ")
        f.write("protocols implemented in our multi-node network simulation. ")
        f.write("The analysis covers security aspects, performance metrics, and eavesdropping resistance.\n\n")
        
        # Get protocols
        protocols = df_qkd['protocol'].unique()
        
        f.write("Protocols evaluated:\n")
        for protocol in protocols:
            f.write(f"- {protocol}\n")
        f.write("\n")
        
        # Filter data for with/without eavesdropping
        df_no_eve = df_qkd[df_qkd['eavesdropping'] == False]
        df_with_eve = df_qkd[df_qkd['eavesdropping'] == True]
        
        # Calculate key metrics
        key_efficiencies = {}
        qber_increases = {}
        eve_detected = {}
        
        for protocol in protocols:
            no_eve_data = df_no_eve[df_no_eve['protocol'] == protocol]
            with_eve_data = df_with_eve[df_with_eve['protocol'] == protocol]
            
            if not no_eve_data.empty and not with_eve_data.empty:
                key_efficiencies[protocol] = no_eve_data['raw_key_length'].values[0] / 1000.0
                qber_increases[protocol] = (with_eve_data['qber'].values[0] - no_eve_data['qber'].values[0])
                eve_detected[protocol] = not with_eve_data['success'].values[0]
        
        best_efficiency = max(key_efficiencies.items(), key=lambda x: x[1])[0]
        best_detection = [p for p, detected in eve_detected.items() if detected]
        
        f.write("Key findings:\n")
        f.write(f"- {best_efficiency} provides the best key generation efficiency at {key_efficiencies[best_efficiency]:.3f} bits/qubit\n")
        if best_detection:
            f.write(f"- Eavesdropping successfully detected by: {', '.join(best_detection)}\n")
        else:
            f.write("- No protocol successfully detected eavesdropping in this simulation\n")
        
        best_resilience = min(qber_increases.items(), key=lambda x: x[1])[0]
        f.write(f"- {best_resilience} shows the best resilience to noise with minimal QBER increase\n\n")
        
        f.write("## 2. Protocol Descriptions\n\n")
        
        f.write("### BB84 Protocol\n")
        f.write("Developed by Bennett and Brassard in 1984, BB84 is the first and most widely studied QKD protocol. ")
        f.write("It uses four quantum states that form two conjugate bases (rectilinear and diagonal). ")
        f.write("The security is based on the uncertainty principle and the impossibility of measuring a quantum state in two different bases simultaneously.\n\n")
        
        f.write("### B92 Protocol\n")
        f.write("A simplified variant of BB84 proposed by Bennett in 1992, B92 uses only two non-orthogonal quantum states ")
        f.write("instead of four. This results in a more straightforward implementation at the cost of a slightly reduced key rate ")
        f.write("and potentially higher sensitivity to noise and channel losses.\n\n")
        
        f.write("### E91 Protocol\n")
        f.write("Proposed by Artur Ekert in 1991, E91 uses quantum entanglement for key distribution. ")
        f.write("The security is based on Bell's inequality violations, which provide a test for the presence of an eavesdropper. ")
        f.write("E91 is theoretically more secure but requires entangled photon sources, making it more complex to implement.\n\n")
        
        f.write("## 3. Performance Metrics\n\n")
        
        f.write("### 3.1 Key Generation Efficiency\n\n")
        
        f.write("| Protocol | Raw Key Rate (bits/qubit) | Final Key Rate (bits/qubit) |\n")
        f.write("|----------|--------------------------|-----------------------------|\n")
        
        for protocol in protocols:
            no_eve_data = df_no_eve[df_no_eve['protocol'] == protocol]
            if not no_eve_data.empty:
                raw_rate = no_eve_data['raw_key_length'].values[0] / 1000.0
                final_rate = no_eve_data['final_key_length'].values[0] / 1000.0
                f.write(f"| {protocol} | {raw_rate:.3f} | {final_rate:.3f} |\n")
        
        f.write("\n")
        f.write("*Note: Higher rates indicate better efficiency.*\n\n")
        
        f.write("### 3.2 Quantum Bit Error Rate (QBER)\n\n")
        
        f.write("| Protocol | QBER (No Eve) | QBER (With Eve) | Increase |\n")
        f.write("|----------|---------------|-----------------|----------|\n")
        
        for protocol in protocols:
            no_eve_data = df_no_eve[df_no_eve['protocol'] == protocol]
            with_eve_data = df_with_eve[df_with_eve['protocol'] == protocol]
            
            if not no_eve_data.empty and not with_eve_data.empty:
                qber_no_eve = no_eve_data['qber'].values[0]
                qber_with_eve = with_eve_data['qber'].values[0]
                increase = qber_with_eve - qber_no_eve
                
                f.write(f"| {protocol} | {qber_no_eve:.5f} | {qber_with_eve:.5f} | {increase:.5f} |\n")
        
        f.write("\n")
        f.write("*Note: QBER increase indicates eavesdropping detection sensitivity.*\n\n")
        
        f.write("### 3.3 Eavesdropping Detection\n\n")
        
        f.write("| Protocol | Detected Eavesdropping | Detection Method |\n")
        f.write("|----------|-----------------------|-------------------|\n")
        
        detection_methods = {
            'BB84': 'QBER Threshold (>15%)',
            'B92': 'QBER Threshold (>12%)',
            'E91': 'Bell Inequality Violation'
        }
        
        for protocol in protocols:
            with_eve_data = df_with_eve[df_with_eve['protocol'] == protocol]
            
            if not with_eve_data.empty:
                detected = not with_eve_data['success'].values[0]
                method = detection_methods.get(protocol, 'Unknown')
                
                f.write(f"| {protocol} | {'Yes' if detected else 'No'} | {method} |\n")
        
        f.write("\n\n")
        
        f.write("## 4. Security Analysis\n\n")
        
        f.write("### 4.1 Vulnerability to Attacks\n\n")
        
        vulnerabilities = {
            'BB84': ['Photon-number splitting attack (with weak coherent pulses)',
                    'Trojan horse attack',
                    'Detector vulnerability attacks'],
            'B92': ['Unambiguous state discrimination attack',
                   'Higher vulnerability to loss and noise',
                   'All BB84 vulnerabilities apply'],
            'E91': ['Detector vulnerability attacks',
                   'Side-channel attacks',
                   'Fake-state attacks with imperfect detectors']
        }
        
        for protocol in protocols:
            if protocol in vulnerabilities:
                f.write(f"### {protocol} Vulnerabilities\n")
                f.write("- " + "\n- ".join(vulnerabilities[protocol]) + "\n\n")
        
        f.write("### 4.2 Countermeasures\n\n")
        
        countermeasures = {
            'BB84': ['Decoy state protocol (against photon-number splitting)',
                    'Optical isolation (against Trojan horse attacks)',
                    'Measurement-device-independent QKD'],
            'B92': ['Strong reference pulse technique',
                   'Improved phase encoding',
                   'Limited to high-quality quantum channels'],
            'E91': ['Device-independent QKD implementations',
                   'Strict Bell inequality testing',
                   'Improved entanglement sources']
        }
        
        for protocol in protocols:
            if protocol in countermeasures:
                f.write(f"### {protocol} Countermeasures\n")
                f.write("- " + "\n- ".join(countermeasures[protocol]) + "\n\n")
        
        f.write("## 5. Implementation Complexity\n\n")
        
        complexity = {
            'BB84': {
                'Hardware': 'Moderate (single photon sources, polarization analyzers)',
                'Software': 'Moderate (basis reconciliation, error correction)',
                'Quantum States': '4 states in 2 bases',
                'Key Rate': 'Up to 50% of sent qubits'
            },
            'B92': {
                'Hardware': 'Lower (simpler optical components)',
                'Software': 'Lower (simpler post-processing)',
                'Quantum States': '2 non-orthogonal states',
                'Key Rate': 'Up to 25% of sent qubits'
            },
            'E91': {
                'Hardware': 'High (entangled photon sources, Bell state analyzers)',
                'Software': 'High (entanglement verification, Bell tests)',
                'Quantum States': 'Entangled state pairs',
                'Key Rate': 'Up to 50% of sent qubits'
            }
        }
        
        f.write("| Protocol | Hardware Complexity | Software Complexity | Quantum Resources | Theoretical Key Rate |\n")
        f.write("|----------|---------------------|---------------------|------------------|----------------------|\n")
        
        for protocol in protocols:
            if protocol in complexity:
                c = complexity[protocol]
                f.write(f"| {protocol} | {c['Hardware']} | {c['Software']} | {c['Quantum States']} | {c['Key Rate']} |\n")
        
        f.write("\n\n")
        
        f.write("## 6. Real-World Applications\n\n")
        
        f.write("### BB84\n")
        f.write("- Commercial QKD systems (ID Quantique, Toshiba, etc.)\n")
        f.write("- Metropolitan area network security\n")
        f.write("- Backbone network protection\n")
        f.write("- Financial transaction security\n\n")
        
        f.write("### B92\n")
        f.write("- Resource-constrained environments\n")
        f.write("- Short-distance secure links\n")
        f.write("- Educational and research implementations\n")
        f.write("- Simplified proof-of-concept deployments\n\n")
        
        f.write("### E91\n")
        f.write("- Research environments\n")
        f.write("- High-security applications demanding verification of quantum mechanics\n")
        f.write("- Device-independent security implementations\n")
        f.write("- Quantum networks with entanglement distribution capabilities\n\n")
        
        f.write("## 7. Recommendations\n\n")
        
        f.write("Based on our simulation results and analysis:\n\n")
        
        # Generate recommendations based on the data
        recommendations = []
        
        if 'BB84' in protocols:
            recommendations.append("- **BB84** is recommended for general-purpose quantum security applications, offering the best balance of security, efficiency, and implementation complexity.")
        
        if 'B92' in protocols:
            recommendations.append("- **B92** is suitable for environments with limited resources or where implementation simplicity is prioritized over maximum key generation efficiency.")
        
        if 'E91' in protocols:
            recommendations.append("- **E91** should be considered for high-security applications where implementation complexity is less important than security guarantees.")
        
        # Add specific recommendations based on the simulation results
        best_efficiency_protocol = max(key_efficiencies.items(), key=lambda x: x[1])[0]
        recommendations.append(f"- For maximum key generation efficiency, **{best_efficiency_protocol}** demonstrated the best performance in our simulations.")
        
        best_detected = [p for p, d in eve_detected.items() if d]
        if best_detected:
            recommendations.append(f"- For strongest eavesdropping detection, {', '.join([f'**{p}**' for p in best_detected])} successfully detected intrusion attempts.")
        
        lowest_qber = min([(p, data['qber'].values[0]) for p, data in df_no_eve.groupby('protocol')], key=lambda x: x[1])
        recommendations.append(f"- For environments with noisy quantum channels, **{lowest_qber[0]}** showed the lowest baseline QBER ({lowest_qber[1]:.5f}).")
        
        for recommendation in recommendations:
            f.write(f"{recommendation}\n")
        
        f.write("\n\n")
        
        f.write("## 8. Conclusion\n\n")
        
        f.write("This comprehensive analysis demonstrates the trade-offs between different QKD protocols. ")
        f.write("Each protocol has its strengths and weaknesses in terms of efficiency, security, and implementation complexity. ")
        f.write("The choice of protocol should be guided by the specific requirements of the application, ")
        f.write("including the desired level of security, available resources, and operational constraints.\n\n")
        
        f.write("Our multi-node quantum network simulation provides valuable insights into how these protocols ")
        f.write("perform in realistic network environments with multiple hops, variable channel quality, ")
        f.write("and active eavesdropping attempts. Future work will expand on these findings ")
        f.write("with more sophisticated attack models and additional protocol variations.")
    
    return report_file

def main():
    # Create output directories
    results_dir = "results"
    graphs_dir = "graphs"
    ensure_directory(results_dir)
    ensure_directory(graphs_dir)
    
    print("Starting Comprehensive QKD Simulation Analysis...")
    
    # Find log files
    qkd_logs = glob.glob("results/*_protocol.txt")
    if not qkd_logs:
        print("No QKD protocol log files found in results directory.")
        qkd_logs = []
    
    # Find trace files
    trace_files = glob.glob("*.tr")
    if not trace_files:
        print("No NS2 trace files found.")
        trace_files = []
    
    # Extract metrics
    if qkd_logs:
        print(f"Processing {len(qkd_logs)} QKD protocol log files...")
        df_qkd = extract_qkd_metrics(qkd_logs)
    else:
        df_qkd = pd.DataFrame()
    
    if trace_files:
        print(f"Processing {len(trace_files)} NS2 trace files...")
        df_trace = extract_trace_metrics(trace_files)
    else:
        df_trace = pd.DataFrame()
    
    # Generate visualizations
    if not df_qkd.empty:
        print("Generating QKD protocol comparison visualizations...")
        plot_qkd_comparison(df_qkd, graphs_dir)
    
    print("Creating network topology visualization...")
    visualize_network_topology(graphs_dir)
    
    # Generate comprehensive report
    if not df_qkd.empty:
        print("Generating comprehensive comparative report...")
        report_file = generate_comparative_report(df_qkd, results_dir)
        print(f"Report saved to: {report_file}")
    
    print("\nAnalysis complete!")
    print(f"Results saved to {results_dir}/ directory")
    print(f"Visualizations saved to {graphs_dir}/ directory")

if __name__ == "__main__":
    main()
