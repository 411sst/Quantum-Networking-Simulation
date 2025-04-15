# Traditional Encryption (AES) Simulation in NS2
# This script simulates traditional encryption between Alice and Bob

# Initialize the simulator
set ns [new Simulator]

# Open trace file
set tracefile [open aes_trace.tr w]
$ns trace-all $tracefile

# Open NAM trace file
set namfile [open aes_nam.nam w]
$ns namtrace-all $namfile

# Create a log file for encryption data
set enclog [open aes_log.txt w]

# Define a 'finish' procedure
proc finish {} {
    global ns tracefile namfile enclog
    $ns flush-trace
    close $tracefile
    close $namfile
    close $enclog
    exec nam aes_nam.nam &
    exit 0
}

# Create three nodes: Alice (0), Bob (1), and Eve (2)
set alice [$ns node]
set bob [$ns node]
set eve [$ns node]

# Set node colors for visualization
$alice color blue
$bob color green
$eve color red

# Label the nodes
$ns at 0.0 "$alice label Alice"
$ns at 0.0 "$bob label Bob"
$ns at 0.0 "$eve label Eve"

# Create links between nodes
$ns duplex-link $alice $bob 1Mb 10ms DropTail
$ns duplex-link $eve $alice 1Mb 10ms DropTail
$ns duplex-link $eve $bob 1Mb 10ms DropTail

# Position nodes for NAM
$ns duplex-link-op $alice $bob orient right
$ns duplex-link-op $eve $alice orient right-up
$ns duplex-link-op $eve $bob orient right-down

# Simulate Traditional Key Exchange (AES)
proc simulateAESKeyExchange {aliceNode bobNode eveNode log eavesdrop} {
    global ns
    
    puts $log "Starting Traditional AES Key Exchange Simulation"
    puts $log "========================================\n"
    
    # Generate an AES key for Alice
    puts $log "Alice generates a random 256-bit AES key..."
    set aesKey ""
    for {set i 0} {$i < 64} {incr i} {
        append aesKey [format "%x" [expr int(rand() * 16)]]
    }
    puts $log "AES Key: $aesKey\n"
    
    # Simulate RSA key exchange
    puts $log "Bob sends his public RSA key to Alice...\n"
    
    # Simulate key encryption with Bob's public key
    puts $log "Alice encrypts the AES key with Bob's RSA public key...\n"
    
    # Transmit encrypted key
    puts $log "Alice sends the encrypted AES key to Bob...\n"
    
    # Simulate eavesdropping
    if {$eavesdrop} {
        puts $log "Eve intercepts the encrypted key transmission..."
        puts $log "Eve cannot decrypt the key without Bob's private key"
        puts $log "However, Eve can intercept all further communications\n"
    }
    
    # Decrypt key
    puts $log "Bob decrypts the AES key using his RSA private key\n"
    
    # Key exchange complete
    puts $log "Secure key exchange completed successfully"
    puts $log "Alice and Bob now share a symmetric 256-bit AES key"
    
    # Difference from QKD
    puts $log "\nIMPORTANT DIFFERENCE FROM QKD:"
    puts $log "In traditional encryption, if Eve intercepts the encrypted key,"
    puts $log "Alice and Bob CANNOT DETECT the eavesdropping!"
    puts $log "The security relies on computational complexity of RSA."
    
    return 1
}

# Simulate AES Encrypted Data Transmission
proc simulateAESTransmission {aliceNode bobNode eveNode log size eavesdrop} {
    global ns
    
    puts $log "\n\nSimulating AES Encrypted Data Transmission"
    puts $log "======================================"
    
    # Simulate encryption
    set startEncrypt [clock milliseconds]
    after 10 ;# Simulate encryption time
    set endEncrypt [clock milliseconds]
    set encTime [expr $endEncrypt - $startEncrypt]
    
    puts $log "\nAlice encrypts a $size byte message with AES..."
    puts $log "Encryption time: $encTime ms"
    
    # Transmit data
    set transmitTime [expr int(double($size) / 1000000.0 * 8.0 * 1000)]
    after $transmitTime
    puts $log "Transmitting encrypted data ($size bytes)..."
    puts $log "Transmission time (1Mbps link): $transmitTime ms"
    
    # Eavesdropping
    if {$eavesdrop} {
        puts $log "\nEve intercepts the encrypted transmission..."
        puts $log "Eve cannot decrypt the content without the AES key"
        puts $log "But Eve has a perfect copy of the encrypted data"
    }
    
    # Decryption
    set startDecrypt [clock milliseconds]
    after 10 ;# Simulate decryption time
    set endDecrypt [clock milliseconds]
    set decTime [expr $endDecrypt - $startDecrypt]
    
    puts $log "\nBob decrypts the message with the shared AES key..."
    puts $log "Decryption time: $decTime ms"
    
    # Total
    set totalTime [expr $encTime + $transmitTime + $decTime]
    puts $log "\nTotal time: $totalTime ms"
    
    return $totalTime
}

# Set up standard TCP connection for simulation
set tcp [new Agent/TCP]
$ns attach-agent $alice $tcp
set sink [new Agent/TCPSink]
$ns attach-agent $bob $sink
$ns connect $tcp $sink

set cbr [new Application/Traffic/CBR]
$cbr set packetSize_ 500
$cbr set interval_ 0.01
$cbr attach-agent $tcp

# Schedule AES simulation
$ns at 0.5 "puts \"Starting AES key exchange simulation...\""
$ns at 0.5 "simulateAESKeyExchange $alice $bob $eve $enclog 0"  ;# 0 = no eavesdropping

# Simulate data transfer with different packet sizes
$ns at 2.0 "puts \"Simulating AES encrypted data transfer...\""
$ns at 2.0 "simulateAESTransmission $alice $bob $eve $enclog 1024 0"   ;# 1KB
$ns at 3.0 "simulateAESTransmission $alice $bob $eve $enclog 10240 0"  ;# 10KB
$ns at 4.0 "simulateAESTransmission $alice $bob $eve $enclog 102400 0" ;# 100KB

# Schedule standard traffic
$ns at 2.0 "$cbr start"
$ns at 4.0 "$cbr stop"

# Call the finish procedure
$ns at 5.0 "finish"

# Run the simulation
puts "Starting Simulation..."
$ns run
