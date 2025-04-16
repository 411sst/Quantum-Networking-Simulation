# Advanced Multi-Node Network Setup for QKD Simulation
# This script creates a sophisticated 6-node network with advanced topology

# Initialize the simulator
# Create necessary directories
exec mkdir -p results
set ns [new Simulator]

# Enable multicast routing for group communication scenarios
$ns multicast

# Set up different colors for different data flows
$ns color 1 Blue
$ns color 2 Red
$ns color 3 Green
$ns color 4 Yellow
$ns color 5 Orange
$ns color 6 Purple

# Open trace file
set tracefile [open results/multi_node_trace.tr w]
$ns trace-all $tracefile

# Open NAM trace file
set namfile [open results/multi_node_nam.nam w]
$ns namtrace-all $namfile

# Create a log file for network statistics
set netlog [open results/network_stats.txt w]

# Define a 'finish' procedure
proc finish {} {
    global ns tracefile namfile netlog
    $ns flush-trace
    close $tracefile
    close $namfile
    close $netlog
    exec nam results/multi_node_nam.nam &
    puts "Generating performance statistics..."
    exec python3 src/network_analyzer.py results/multi_node_trace.tr results/performance_stats.txt
    puts "Done. Check results/performance_stats.txt for detailed analysis."
    exit 0
}

# Create the network nodes
puts "Creating network topology with 6 nodes..."

# Core network nodes (quantum-enabled)
set alice [$ns node]
set bob [$ns node]
set quantum_repeater1 [$ns node]
set quantum_repeater2 [$ns node]

# Edge network nodes (traditional-only)
set edge_node1 [$ns node]
set edge_node2 [$ns node]

# Potential eavesdroppers
set eve1 [$ns node]
set eve2 [$ns node]

# Set node shapes for visualization
$alice shape "circle"
$bob shape "circle"
$quantum_repeater1 shape "square"
$quantum_repeater2 shape "square"
$edge_node1 shape "hexagon"
$edge_node2 shape "hexagon"
$eve1 shape "triangle"
$eve2 shape "triangle"

# Set node colors for visualization
$alice color "blue"
$bob color "green"
$quantum_repeater1 color "cyan"
$quantum_repeater2 color "cyan"
$edge_node1 color "gold"
$edge_node2 color "gold"
$eve1 color "red"
$eve2 color "red"

# Label the nodes
$ns at 0.0 "$alice label Alice"
$ns at 0.0 "$bob label Bob"
$ns at 0.0 "$quantum_repeater1 label QRepeater1"
$ns at 0.0 "$quantum_repeater2 label QRepeater2"
$ns at 0.0 "$edge_node1 label EdgeNode1"
$ns at 0.0 "$edge_node2 label EdgeNode2"
$ns at 0.0 "$eve1 label Eve1"
$ns at 0.0 "$eve2 label Eve2"

# Create links with different bandwidths and delays to simulate realistic network
# Quantum links (high-quality optical fiber connections)
$ns duplex-link $alice $quantum_repeater1 10Mb 5ms DropTail
$ns duplex-link $quantum_repeater1 $quantum_repeater2 5Mb 15ms DropTail
$ns duplex-link $quantum_repeater2 $bob 10Mb 5ms DropTail

# Edge links (standard network connections)
$ns duplex-link $alice $edge_node1 100Mb 2ms DropTail
$ns duplex-link $bob $edge_node2 100Mb 2ms DropTail

# Eavesdropper links (for attack simulation)
$ns duplex-link $eve1 $quantum_repeater1 1Mb 1ms DropTail
$ns duplex-link $eve2 $quantum_repeater2 1Mb 1ms DropTail

# Set queue sizes and link parameters
$ns queue-limit $alice $quantum_repeater1 50
$ns queue-limit $quantum_repeater1 $quantum_repeater2 30
$ns queue-limit $quantum_repeater2 $bob 50

# Set up link characteristics
$ns bandwidth $quantum_repeater1 $quantum_repeater2 5Mb duplex
$ns delay $quantum_repeater1 $quantum_repeater2 15ms

# Position nodes for NAM visualization
# Core QKD path
$ns duplex-link-op $alice $quantum_repeater1 orient right
$ns duplex-link-op $quantum_repeater1 $quantum_repeater2 orient right
$ns duplex-link-op $quantum_repeater2 $bob orient right

# Edge node connections
$ns duplex-link-op $alice $edge_node1 orient down-right
$ns duplex-link-op $bob $edge_node2 orient down-left

# Eavesdropper connections
$ns duplex-link-op $eve1 $quantum_repeater1 orient up
$ns duplex-link-op $eve2 $quantum_repeater2 orient up

# Define network monitoring procedure
proc record_stats {} {
    global ns netlog alice quantum_repeater1 quantum_repeater2 bob
    set time 0.1
    set now [$ns now]
    
    # Get link statistics for core quantum path
    set bw1 [$ns link $alice $quantum_repeater1]
    set bw2 [$ns link $quantum_repeater1 $quantum_repeater2]
    set bw3 [$ns link $quantum_repeater2 $bob]
    
    # Record queue lengths
    set q1 [[$bw1 queue] set blocked_]
    set q2 [[$bw2 queue] set blocked_]
    set q3 [[$bw3 queue] set blocked_]
    
    # Write to log file
    puts $netlog "$now [expr $q1] [expr $q2] [expr $q3]"
    
    # Re-schedule recording
    $ns at [expr $now+$time] "record_stats"
}

# Procedure to simulate quantum state attenuation
proc simulate_quantum_attenuation {distance} {
    # Realistic attenuation model for quantum signals
    # Typical fiber optic loss is 0.2 dB/km
    set attenuation_factor [expr exp(-0.2 * $distance / 10.0)]
    return $attenuation_factor
}

# QKD Implementation for multi-hop network
proc run_multi_hop_qkd {src repeater1 repeater2 dst log} {
    global ns
    
    puts $log "Starting Multi-Hop QKD Protocol Simulation"
    puts $log "========================================"
    
    # Get link objects
    set link1 [$ns link $src $repeater1]
    set link2 [$ns link $repeater1 $repeater2]
    set link3 [$ns link $repeater2 $dst]

    # Get delays from link objects (converting to ms)
    set link1_delay [expr [$link1 delay] * 1000]
    set link2_delay [expr [$link2 delay] * 1000]
    set link3_delay [expr [$link3 delay] * 1000]
    
    # Convert delays to approximate distances (assuming 5μs/km)
    set link1_dist [expr double($link1_delay) * 1000 / 5]
    set link2_dist [expr double($link2_delay) * 1000 / 5]
    set link3_dist [expr double($link3_delay) * 1000 / 5]
    set total_dist [expr $link1_dist + $link2_dist + $link3_dist]
    
    puts $log "\nEstimated link distances:"
    puts $log "  $src to $repeater1: $link1_dist km"
    puts $log "  $repeater1 to $repeater2: $link2_dist km"
    puts $log "  $repeater2 to $dst: $link3_dist km"
    puts $log "  Total distance: $total_dist km"
    
    # Calculate quantum signal attenuation for each link
    set atten1 [simulate_quantum_attenuation $link1_dist]
    set atten2 [simulate_quantum_attenuation $link2_dist]
    set atten3 [simulate_quantum_attenuation $link3_dist]
    set total_atten [expr $atten1 * $atten2 * $atten3]
    
    puts $log "\nQuantum signal attenuation factors:"
    puts $log "  Link 1: $atten1"
    puts $log "  Link 2: $atten2"
    puts $log "  Link 3: $atten3"
    puts $log "  End-to-end: $total_atten"
    
    # Simulate key establishment with repeaters
    puts $log "\nBeginning multi-hop key establishment:"
    
    # Step 1: QKD between src and repeater1
    puts $log "\n1. Establishing quantum key between $src and $repeater1"
    if {$atten1 < 0.1} {
        puts $log "WARNING: Signal too weak for reliable key generation"
    }
    set key_rate1 [expr int(10000 * $atten1)]
    puts $log "Estimated secure key rate: $key_rate1 bits/sec"
    
    # Step 2: QKD between repeater1 and repeater2
    puts $log "\n2. Establishing quantum key between $repeater1 and $repeater2"
    if {$atten2 < 0.1} {
        puts $log "WARNING: Signal too weak for reliable key generation"
    }
    set key_rate2 [expr int(10000 * $atten2)]
    puts $log "Estimated secure key rate: $key_rate2 bits/sec"
    
    # Step 3: QKD between repeater2 and dst
    puts $log "\n3. Establishing quantum key between $repeater2 and $dst"
    if {$atten3 < 0.1} {
        puts $log "WARNING: Signal too weak for reliable key generation"
    }
    set key_rate3 [expr int(10000 * $atten3)]
    puts $log "Estimated secure key rate: $key_rate3 bits/sec"
    
    # Step 4: Key relay protocol
    puts $log "\n4. Performing key relay protocol across repeaters"
    set end_to_end_rate [expr min($key_rate1, min($key_rate2, $key_rate3)) / 3]
    puts $log "End-to-end secure key rate: $end_to_end_rate bits/sec"
    
    # Return estimated secure key rate
    return $end_to_end_rate
}

# Set up TCP connections for data traffic simulation
# Connection 1: Alice to Bob via quantum path
set tcp1 [new Agent/TCP/Reno]
$tcp1 set class_ 1
$ns attach-agent $alice $tcp1
set sink1 [new Agent/TCPSink]
$ns attach-agent $bob $sink1
$ns connect $tcp1 $sink1

# Connection 2: Edge node traffic
set tcp2 [new Agent/TCP/Reno]
$tcp2 set class_ 2
$ns attach-agent $edge_node1 $tcp2
set sink2 [new Agent/TCPSink]
$ns attach-agent $edge_node2 $sink2
$ns connect $tcp2 $sink2

# Applications for data transmission
# FTP over TCP for main quantum path
set ftp1 [new Application/FTP]
$ftp1 set type_ FTP
$ftp1 attach-agent $tcp1

# CBR traffic for edge network
set cbr [new Application/Traffic/CBR]
$cbr set packetSize_ 1000
$cbr set interval_ 0.01
$cbr attach-agent $tcp2

# Schedule events
# Start network monitoring
$ns at 0.0 "record_stats"

# Start QKD protocol simulation
$ns at 1.0 "puts \"Starting multi-hop QKD simulation...\""
$ns at 1.0 "run_multi_hop_qkd $alice $quantum_repeater1 $quantum_repeater2 $bob $netlog"

# Generate background traffic
$ns at 2.0 "$ftp1 start"
$ns at 2.5 "$cbr start"

# Simulate network congestion at a specific time
$ns rtmodel-at 3.0 down $quantum_repeater1 $quantum_repeater2
$ns rtmodel-at 3.5 up $quantum_repeater1 $quantum_repeater2

# Stop applications
$ns at 4.5 "$ftp1 stop"
$ns at 4.7 "$cbr stop"

# Call the finish procedure
$ns at 5.0 "finish"

# Run the simulation
puts "Starting Advanced Multi-Node Network Simulation..."
$ns run
