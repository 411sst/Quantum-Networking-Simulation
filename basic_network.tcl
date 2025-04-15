# Basic network setup for QKD simulation
# This script creates a simple 2-node network

# Initialize the simulator
set ns [new Simulator]

# Open trace file
set tracefile [open basic_trace.tr w]
$ns trace-all $tracefile

# Open NAM trace file
set namfile [open basic_nam.nam w]
$ns namtrace-all $namfile

# Define a 'finish' procedure
proc finish {} {
    global ns tracefile namfile
    $ns flush-trace
    close $tracefile
    close $namfile
    exec nam basic_nam.nam &
    exit 0
}

# Create two nodes: Alice (node 0) and Bob (node 1)
set alice [$ns node]
set bob [$ns node]

# Set node colors for visualization
$alice color blue
$bob color green

# Label the nodes
$ns at 0.0 "$alice label Alice"
$ns at 0.0 "$bob label Bob"

# Create a duplex link between Alice and Bob with 1Mbps bandwidth and 10ms delay
$ns duplex-link $alice $bob 1Mb 10ms DropTail

# Position nodes for NAM
$ns duplex-link-op $alice $bob orient right

# Setup a simple TCP connection
set tcp [new Agent/TCP]
$ns attach-agent $alice $tcp

set sink [new Agent/TCPSink]
$ns attach-agent $bob $sink

$ns connect $tcp $sink

# Set up a CBR (Constant Bit Rate) traffic over TCP
set cbr [new Application/Traffic/CBR]
$cbr set packetSize_ 500
$cbr set interval_ 0.01
$cbr attach-agent $tcp

# Schedule events
$ns at 0.5 "$cbr start"
$ns at 4.5 "$cbr stop"

# Call the finish procedure after 5 seconds of simulation time
$ns at 5.0 "finish"

# Run the simulation
puts "Starting Simulation..."
$ns run
