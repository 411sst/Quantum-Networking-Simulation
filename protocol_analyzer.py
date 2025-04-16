#!/usr/bin/env python3
"""
QKD Protocol Analyzer
This script processes QKD protocol simulation results and generates visualizations.
"""

import sys
import re
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import PercentFormatter
import os

def ensure_directory(directory):
    """Ensure the specified directory exists."""
    if not os.path.exists(directory):
        os.makedirs(directory)

def extract_metrics(filename):
    """Extract key metrics from the protocol log file."""
    metrics = {
        'protocol': os.path.basename(filename).split('_')[0],
        'qber': [],
        'key_length': [],
        'final_key_length': [],
        'success': [],
        'eavesdropping': []
    }
    
    try:
        with open(filename, 'r') as f:
            content = f.read()
            
            # Extract experiment configurations
            eavesdropping_sections = content.split("Eavesdropping: ")
            for i, section in enumerate(eavesdropping_sections[1:], 1):
                is_eavesdropping = section.strip().startswith("Active")
                metrics['eavesdropping'].append(is_eavesdropping)
                
                # Extract QBER
                qber_match = re.search(r"Quantum Bit Error Rate \(QBER\): ([0-9.]+)", section)
                if qber_match:
                    metrics['qber'].append(float(qber_match.group(1)))
                
                # Extract key lengths
                raw_key_match = re.search(r"raw key length: (\d+) bits", section)
                if raw_key_match:
                    metrics['key_length'].append(int(raw_key_match.group(1)))
                
                final_key_match = re.search(r"Final secure key length.+?: (\d+) bits", section)
                if final_key_match:
                    metrics['final_key_length'].append(int(final_key_match.group(1)))
                
                # Extract success
                if "Protocol ABORTED" in section:
                    metrics['success'].append(False)
                else:
                    metrics['success'].append(True)
    
    except Exception as e:
        print(f"Error processing {filename}: {e}")
        
    return metrics

def extract_comparison_data(comparison_file):
    """Extract comparison data from the comparison log file."""
    data = {
        'protocols': [],
        'no_eve': {
            'success': [],
            'qber': [],
            'raw_key': [],
            'final_key': [],
            'efficiency': []
        },
        'with_eve': {
            'success': [],
            'qber': [],
            'raw_key': [],
            'final_key': [],
            'detection': []
        }
    }
    
    try:
        with open(comparison_file, 'r') as f:
            content = f.read()
            
            # Get the without eavesdropping section
            no_eve_match = re.search(r"--- Performance Without Eavesdropping ---\n(.*?)---", 
                                     content, re.DOTALL)
            if no_eve_match:
                no_eve_section = no_eve_match.group(1)
                protocol_lines = re.findall(r"(\w+)\s+\|\s+(Yes|No)\s+\|\s+([0-9.]+)\s+\|\s+([0-9]+)\s+\|\s+([0-9]+)\s+\|\s+([0-9.]+)", 
                                           no_eve_section)
                for line in protocol_lines:
                    data['protocols'].append(line[0])
                    data['no_eve']['success'].append(line[1] == 'Yes')
                    data['no_eve']['qber'].append(float(line[2]))
                    data['no_eve']['raw_key'].append(int(line[3]))
                    data['no_eve']['final_key'].append(int(line[4]))
                    data['no_eve']['efficiency'].append(float(line[5].strip('%')))
            
            # Get the with eavesdropping section
            with_eve_match = re.search(r"--- Performance With Eavesdropping ---\n(.*?)---", 
                                      content, re.DOTALL)
            if with_eve_match:
                with_eve_section = with_eve_match.group(1)
                protocol_lines = re.findall(r"(\w+)\s+\|\s+(Yes|No)\s+\|\s+([0-9.]+)\s+\|\s+([0-9]+)\s+\|\s+([0-9]+)\s+\|\s+(\w+)", 
                                           with_eve_section)
                for line in protocol_lines:
                    data['with_eve']['success'].append(line[1] == 'Yes')
                    data['with_eve']['qber'].append(float(line[2]))
                    data['with_eve']['raw_key'].append(int(line[3]))
                    data['with_eve']['final_key'].append(int(line[4]))
                    data['with_eve']['detection'].append(line[5] == 'Detected')
    
    except Exception as e:
        print(f"Error processing comparison file: {e}")
        
    return data

def plot_qber_comparison(comparison_data, output_dir):
    """Plot QBER comparison with and without eavesdropping."""
    plt.figure(figsize=(10, 6))
    
    x = np.arange(len(comparison_data['protocols']))
    width = 0.35
    
    plt.bar(x - width/2, comparison_data['no_eve']['qber'], width, label='Without Eavesdropping', color='green')
    plt.bar(x + width/2, comparison_data['with_eve']['qber'], width, label='With Eavesdropping', color='red')
    
    plt.xlabel('Protocol')
    plt.ylabel('Quantum Bit Error Rate (QBER)')
    plt.title('Effect of Eavesdropping on QBER')
    plt.xticks(x, comparison_data['protocols'])
    plt.legend()
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    
    # Add threshold lines
    plt.axhline(y=0.15, color='orange', linestyle='--', label='BB84 Threshold (15%)')
    plt.axhline(y=0.12, color='cyan', linestyle='--', label='B92 Threshold (12%)')
    plt.legend()
    
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'qber_comparison.png'), dpi=300)
    plt.close()

def plot_key_generation_efficiency(comparison_data, output_dir):
    """Plot key generation efficiency."""
    plt.figure(figsize=(10, 6))
    
    protocols = comparison_data['protocols']
    efficiency_no_eve = [raw/1000 for raw in comparison_data['no_eve']['raw_key']]
    efficiency_with_eve = [raw/1000 for raw in comparison_data['with_eve']['raw_key']]
    
    x = np.arange(len(protocols))
    width = 0.35
    
    plt.bar(x - width/2, efficiency_no_eve, width, label='Without Eavesdropping', color='green')
    plt.bar(x + width/2, efficiency_with_eve, width, label='With Eavesdropping', color='red')
    
    plt.xlabel('Protocol')
    plt.ylabel('Key Generation Rate (bits/qubit)')
    plt.title('Key Generation Efficiency Comparison')
    plt.xticks(x, protocols)
    plt.legend()
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'key_efficiency.png'), dpi=300)
    plt.close()

def plot_security_comparison(comparison_data, output_dir):
    """Plot security comparison chart."""
    plt.figure(figsize=(10, 6))
    
    protocols = comparison_data['protocols']
    detection_rates = [100 if detected else 0 for detected in comparison_data['with_eve']['detection']]
    
    plt.bar(protocols, detection_rates, color=['blue', 'orange', 'green'])
    
    plt.xlabel('Protocol')
    plt.ylabel('Eavesdropping Detection Rate (%)')
    plt.title('Eavesdropping Detection Capability')
    plt.ylim(0, 100)
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    
    # Add values on top of bars
    for i, v in enumerate(detection_rates):
        plt.text(i, v + 5, f"{v}%", ha='center')
    
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'security_comparison.png'), dpi=300)
    plt.close()

def plot_final_key_length(comparison_data, output_dir):
    """Plot final secure key length comparison."""
    plt.figure(figsize=(10, 6))
    
    x = np.arange(len(comparison_data['protocols']))
    width = 0.35
    
    plt.bar(x - width/2, comparison_data['no_eve']['final_key'], width, 
            label='Without Eavesdropping', color='green')
    plt.bar(x + width/2, comparison_data['with_eve']['final_key'], width, 
            label='With Eavesdropping', color='red')
    
    plt.xlabel('Protocol')
    plt.ylabel('Final Secure Key Length (bits)')
    plt.title('Final Secure Key Length Comparison')
    plt.xticks(x, comparison_data['protocols'])
    plt.legend()
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'final_key_length.png'), dpi=300)
    plt.close()

def plot_protocol_overhead(comparison_data, output_dir):
    """Plot protocol overhead comparison."""
    plt.figure(figsize=(10, 6))
    
    protocols = comparison_data['protocols']
    overhead = [(1000 - raw)/10 for raw in comparison_data['no_eve']['raw_key']]
    
    plt.bar(protocols, overhead, color=['blue', 'orange', 'green'])
    
    plt.xlabel('Protocol')
    plt.ylabel('Overhead (%)')
    plt.title('Protocol Overhead Comparison')
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    
    # Add values on top of bars
    for i, v in enumerate(overhead):
        plt.text(i, v + 1, f"{v:.1f}%", ha='center')
    
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'protocol_overhead.png'), dpi=300)
    plt.close()

def create_comparison_radar_chart(comparison_data, output_dir):
    """Create a radar chart comparing the protocols across multiple dimensions."""
    # Normalize data for radar chart
    categories = ['Key Efficiency', 'Eve Detection', 'Implementation\nSimplicity', 
                 'Quantum Resource\nEfficiency', 'Error Tolerance']
    
    # Create normalized scores for each protocol (subjective, based on known properties)
    # BB84
    bb84_scores = [
        comparison_data['no_eve']['raw_key'][0]/1000 if (len(comparison_data['no_eve']['raw_key']) > 0) else 0,  # Key efficiency
        1 if comparison_data['with_eve']['detection'][0] else 0,  # Eve detection
        0.7,  # Implementation simplicity (moderate)
        0.6,  # Quantum resource efficiency (moderate)
        1 - comparison_data['no_eve']['qber'][0]/0.15  # Error tolerance
    ]
    
    # B92
    b92_scores = [
        comparison_data['no_eve']['raw_key'][1]/1000,  # Key efficiency
        1 if comparison_data['with_eve']['detection'][1] else 0,  # Eve detection
        0.9,  # Implementation simplicity (high)
        0.8,  # Quantum resource efficiency (high)
        1 - comparison_data['no_eve']['qber'][1]/0.12  # Error tolerance
    ]
    
    # E91
    e91_scores = [
        comparison_data['no_eve']['raw_key'][2]/1000,  # Key efficiency
        1 if comparison_data['with_eve']['detection'][2] else 0,  # Eve detection
        0.5,  # Implementation simplicity (low)
        0.4,  # Quantum resource efficiency (low)
        0.9  # Error tolerance (high)
    ]
    
    # Normalize all scores to 0-1 range
    max_scores = []
    for i in range(len(categories)):
        max_score = max(bb84_scores[i], b92_scores[i], e91_scores[i])
        if max_score > 0:
            bb84_scores[i] /= max_score
            b92_scores[i] /= max_score
            e91_scores[i] /= max_score
    
    # Set up the radar chart
    angles = np.linspace(0, 2*np.pi, len(categories), endpoint=False).tolist()
    angles += angles[:1]  # Close the polygon
    
    bb84_scores += bb84_scores[:1]
    b92_scores += b92_scores[:1]
    e91_scores += e91_scores[:1]
    
    fig, ax = plt.subplots(figsize=(10, 8), subplot_kw=dict(polar=True))
    
    ax.plot(angles, bb84_scores, 'b-', linewidth=2, label='BB84')
    ax.fill(angles, bb84_scores, 'blue', alpha=0.1)
    
    ax.plot(angles, b92_scores, 'r-', linewidth=2, label='B92')
    ax.fill(angles, b92_scores, 'red', alpha=0.1)
    
    ax.plot(angles, e91_scores, 'g-', linewidth=2, label='E91')
    ax.fill(angles, e91_scores, 'green', alpha=0.1)
    
    ax.set_thetagrids(np.degrees(angles[:-1]), categories)
    ax.set_ylim(0, 1)
    ax.set_title('Protocol Comparison: Multiple Factors', size=15)
    ax.legend(loc='upper right')
    ax.grid(True)
    
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'protocol_radar_comparison.png'), dpi=300)
    plt.close()

def main():
    if len(sys.argv) < 4:
        print("Usage: protocol_analyzer.py bb84_log.txt b92_log.txt comparison_log.txt")
        sys.exit(1)
    
    bb84_file = sys.argv[1]
    b92_file = sys.argv[2]
    comparison_file = sys.argv[3]
    
    # Create output directory
    output_dir = "graphs"
    ensure_directory(output_dir)
    
    # Extract metrics
    bb84_metrics = extract_metrics(bb84_file)
    b92_metrics = extract_metrics(b92_file)
    comparison_data = extract_comparison_data(comparison_file)
    
    # Generate visualizations
    print("Generating visualizations...")
    
    plot_qber_comparison(comparison_data, output_dir)
    plot_key_generation_efficiency(comparison_data, output_dir)
    plot_security_comparison(comparison_data, output_dir)
    plot_final_key_length(comparison_data, output_dir)
    plot_protocol_overhead(comparison_data, output_dir)
    create_comparison_radar_chart(comparison_data, output_dir)
    
    print(f"Visualizations saved to {output_dir}/")

if __name__ == "__main__":
    main()
