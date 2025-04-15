#!/usr/bin/env python3
"""
Network Analyzer for QKD Simulations
This script processes NS2 trace files and generates network performance metrics.
"""

import sys
import os
import re
import numpy as np
import matplotlib.pyplot as plt
from collections import defaultdict

def ensure_directory(directory):
    """Ensure the specified directory exists."""
    if not os.path.exists(directory):
        os.makedirs(directory)

def parse_trace_file(file_path):
    """Parse an NS2 trace file and extract relevant information."""
    events = []
    
    try:
        with open(file_path, 'r') as f:
            for line in f:
                if line.startswith('#'):
                    continue
                    
                parts = line.strip().split()
                if len(parts) < 12:
                    continue
                
                event = {
                    'event_type': parts[0],  # + (enqueue), - (dequeue), r (receive), d (drop)
                    'time': float(parts[1]),
                    'from_node': int(parts[2]),
                    'to_node': int(parts[3]),
                    'packet_type': parts[4],
                    'packet_size': int(parts[5]),
                    'flags': parts[6],
                    'flow_id': int(parts[7]),
                    'src_addr': parts[8],
                    'dst_addr': parts[9],
                    'seq_num': int(parts[10]),
                    'packet_id': int(parts[11])
                }
                events.append(event)
    except Exception as e:
        print(f"Error parsing trace file {file_path}: {e}")
        return []
    
    return events

def calculate_throughput(events, interval=0.1):
    """Calculate throughput over time."""
    # Group events by time interval
    throughput_data = defaultdict(int)
    max_time = max(event['time'] for event in events)
    intervals = np.arange(0, max_time + interval, interval)
    
    # Sum packet sizes for received packets
    for event in events:
        if event['event_type'] == 'r':  # received packet
            interval_idx = int(event['time'] / interval)
            if interval_idx < len(intervals):
                throughput_data[intervals[interval_idx]] += event['packet_size']
    
    # Convert to bits per second
    times = sorted(throughput_data.keys())
    throughput = [(throughput_data[t] * 8) / interval for t in times]  # Convert bytes to bits
    
    return times, throughput

def calculate_packet_loss(events):
    """Calculate packet loss ratio."""
    packets_sent = sum(1 for event in events if event['event_type'] == '+')
    packets_dropped = sum(1 for event in events if event['event_type'] == 'd')
    
    if packets_sent == 0:
        return 0
    
    return packets_dropped / packets_sent

def calculate_end_to_end_delay(events):
    """Calculate end-to-end delay for packets."""
    # Track packet send and receive times
    packet_times = {}
    delays = []
    
    for event in events:
        packet_id = event['packet_id']
        
        if event['event_type'] == '+' and event['from_node'] == 0:  # Packet sent from source
            packet_times[packet_id] = event['time']
        
        elif event['event_type'] == 'r' and event['to_node'] == 1:  # Packet received at destination
            if packet_id in packet_times:
                delay = event['time'] - packet_times[packet_id]
                delays.append(delay)
    
    return delays

def analyze_node_activity(events):
    """Analyze activity at each node."""
    node_activity = defaultdict(lambda: {'sent': 0, 'received': 0, 'dropped': 0})
    
    for event in events:
        if event['event_type'] == '+':  # Packet sent
            node_activity[event['from_node']]['sent'] += 1
        
        elif event['event_type'] == 'r':  # Packet received
            node_activity[event['to_node']]['received'] += 1
        
        elif event['event_type'] == 'd':  # Packet dropped
            node_activity[event['from_node']]['dropped'] += 1
    
    return node_activity

def analyze_queueing_delay(events):
    """Calculate queueing delay at each node."""
    queue_times = {}  # (node, packet_id) -> enqueue_time
    queue_delays = defaultdict(list)
    
    for event in events:
        node = event['from_node']
        packet_id = event['packet_id']
        
        if event['event_type'] == '+':  # Packet enqueued
            queue_times[(node, packet_id)] = event['time']
        
        elif event['event_type'] == '-':  # Packet dequeued
            if (node, packet_id) in queue_times:
                delay = event['time'] - queue_times[(node, packet_id)]
                queue_delays[node].append(delay)
    
    # Calculate average queueing delay per node
    avg_queue_delays = {}
    for node, delays in queue_delays.items():
        if delays:
            avg_queue_delays[node] = sum(delays) / len(delays)
        else:
            avg_queue_delays[node] = 0
    
    return avg_queue_delays

def plot_throughput(times, throughput, output_path):
    """Plot throughput over time."""
    plt.figure(figsize=(10, 6))
    plt.plot(times, throughput, 'b-')
    plt.xlabel('Time (s)')
    plt.ylabel('Throughput (bits/s)')
    plt.title('Network Throughput Over Time')
    plt.grid(True)
    plt.savefig(output_path, dpi=300)
    plt.close()

def plot_delay_histogram(delays, output_path):
    """Plot histogram of packet delays."""
    plt.figure(figsize=(10, 6))
    plt.hist(delays, bins=20, alpha=0.7, color='blue', edgecolor='black')
    plt.xlabel('Delay (s)')
    plt.ylabel('Number of Packets')
    plt.title('End-to-End Packet Delay Distribution')
    plt.grid(True, axis='y', linestyle='--', alpha=0.7)
    
    # Add mean and median information
    if delays:
        mean_delay = sum(delays) / len(delays)
        median_delay = sorted(delays)[len(delays)//2]
        plt.axvline(mean_delay, color='r', linestyle='dashed', linewidth=2, label=f'Mean: {mean_delay:.3f}s')
        plt.axvline(median_delay, color='g', linestyle='dashed', linewidth=2, label=f'Median: {median_delay:.3f}s')
        plt.legend()
    
    plt.savefig(output_path, dpi=300)
    plt.close()

def plot_node_activity(node_activity, output_path):
    """Plot node activity statistics."""
    nodes = sorted(node_activity.keys())
    sent = [node_activity[node]['sent'] for node in nodes]
    received = [node_activity[node]['received'] for node in nodes]
    dropped = [node_activity[node]['dropped'] for node in nodes]
    
    plt.figure(figsize=(12, 7))
    
    x = np.arange(len(nodes))
    width = 0.25
    
    plt.bar(x - width, sent, width, label='Packets Sent', color='blue')
    plt.bar(x, received, width, label='Packets Received', color='green')
    plt.bar(x + width, dropped, width, label='Packets Dropped', color='red')
    
    plt.xlabel('Node ID')
    plt.ylabel('Number of Packets')
    plt.title('Node Activity Statistics')
    plt.xticks(x, [f'Node {node}' for node in nodes])
    plt.legend()
    plt.grid(True, axis='y', linestyle='--', alpha=0.7)
    
    plt.tight_layout()
    plt.savefig(output_path, dpi=300)
    plt.close()

def plot_queue_delays(queue_delays, output_path):
    """Plot average queueing delay at each node."""
    nodes = sorted(queue_delays.keys())
    delays = [queue_delays[node] * 1000 for node in nodes]  # Convert to milliseconds
    
    plt.figure(figsize=(10, 6))
    plt.bar(range(len(nodes)), delays, color='purple')
    plt.xlabel('Node ID')
    plt.ylabel('Average Queueing Delay (ms)')
    plt.title('Average Queueing Delay by Node')
    plt.xticks(range(len(nodes)), [f'Node {node}' for node in nodes])
    plt.grid(True, axis='y', linestyle='--', alpha=0.7)
    
    plt.tight_layout()
    plt.savefig(output_path, dpi=300)
    plt.close()

def analyze_protocol_overhead(events):
    """Analyze overhead caused by protocol control packets."""
    data_packets = 0
    control_packets = 0
    
    for event in events:
        if event['event_type'] == '+':  # Only count sent packets
            if event['packet_type'] == 'tcp':
                data_packets += 1
            else:
                # Assuming all non-TCP packets are control packets
                control_packets += 1
    
    total_packets = data_packets + control_packets
    if total_packets == 0:
        return 0
    
    return (control_packets / total_packets) * 100  # Return as percentage

def main():
    if len(sys.argv) < 3:
        print("Usage: network_analyzer.py trace_file.tr output_stats.txt")
        sys.exit(1)
    
    trace_file = sys.argv[1]
    output_file = sys.argv[2]
    
    # Create output directories
    graphs_dir = "graphs"
    ensure_directory(graphs_dir)
    
    # Parse the trace file
    print(f"Parsing trace file: {trace_file}")
    events = parse_trace_file(trace_file)
    
    if not events:
        print("No events found in trace file.")
        sys.exit(1)
    
    # Calculate performance metrics
    print("Calculating network performance metrics...")
    times, throughput = calculate_throughput(events)
    packet_loss_ratio = calculate_packet_loss(events)
    delays = calculate_end_to_end_delay(events)
    node_activity = analyze_node_activity(events)
    queue_delays = analyze_queueing_delay(events)
    protocol_overhead = analyze_protocol_overhead(events)
    
    # Generate visualizations
    print("Generating visualizations...")
    plot_throughput(times, throughput, os.path.join(graphs_dir, 'throughput.png'))
    
    if delays:
        plot_delay_histogram(delays, os.path.join(graphs_dir, 'delay_histogram.png'))
    
    plot_node_activity(node_activity, os.path.join(graphs_dir, 'node_activity.png'))
    plot_queue_delays(queue_delays, os.path.join(graphs_dir, 'queue_delays.png'))
    
    # Write statistics to output file
    print(f"Writing statistics to: {output_file}")
    with open(output_file, 'w') as f:
        f.write("=================================================\n")
        f.write("Network Performance Analysis for QKD Simulation\n")
        f.write("=================================================\n\n")
        
        f.write("1. Basic Statistics:\n")
        f.write(f"   Total events processed: {len(events)}\n")
        f.write(f"   Simulation duration: {max(event['time'] for event in events):.2f} seconds\n")
        f.write(f"   Number of active nodes: {len(node_activity)}\n\n")
        
        f.write("2. Performance Metrics:\n")
        
        if times and throughput:
            avg_throughput = sum(throughput) / len(throughput)
            peak_throughput = max(throughput)
            f.write(f"   Average throughput: {avg_throughput:.2f} bits/s\n")
            f.write(f"   Peak throughput: {peak_throughput:.2f} bits/s\n")
        
        f.write(f"   Packet loss ratio: {packet_loss_ratio:.2%}\n")
        
        if delays:
            avg_delay = sum(delays) / len(delays)
            min_delay = min(delays)
            max_delay = max(delays)
            jitter = np.std(delays) if len(delays) > 1 else 0
            
            f.write(f"   Average end-to-end delay: {avg_delay:.4f} seconds\n")
            f.write(f"   Minimum delay: {min_delay:.4f} seconds\n")
            f.write(f"   Maximum delay: {max_delay:.4f} seconds\n")
            f.write(f"   Delay jitter: {jitter:.4f} seconds\n")
        
        f.write(f"   Protocol overhead: {protocol_overhead:.2f}%\n\n")
        
        f.write("3. Node Activity:\n")
        for node, stats in sorted(node_activity.items()):
            f.write(f"   Node {node}:\n")
            f.write(f"     Packets sent: {stats['sent']}\n")
            f.write(f"     Packets received: {stats['received']}\n")
            f.write(f"     Packets dropped: {stats['dropped']}\n")
            if stats['sent'] > 0:
                drop_ratio = stats['dropped'] / stats['sent']
                f.write(f"     Drop ratio: {drop_ratio:.2%}\n")
            f.write("\n")
        
        f.write("4. Queueing Analysis:\n")
        for node, delay in sorted(queue_delays.items()):
            f.write(f"   Node {node} average queueing delay: {delay*1000:.2f} ms\n")
        
        f.write("\n=================================================\n")
        f.write("Analysis complete. See 'graphs/' directory for visualizations.\n")
    
    print("Analysis complete!")

if __name__ == "__main__":
    main()
