# Eavesdropper Simulation for both QKD and AES in NS2
# This script simulates both protocols with Eve eavesdropping

# Initialize the simulator
set ns [new Simulator]

# Open trace file
set tracefile [open eve_trace.tr w]
$ns trace-all $tracefile

# Open NAM trace file
set namfile [open eve_nam.nam w]
$ns namtrace-all $namfile

# Create log files
set qkdlog [open eve_qkd_log.txt w]
set aeslog [open eve_aes_log.txt w]
set complog [open comparison_log.txt w]

# Define a 'finish' procedure
proc finish {} {
    global ns tracefile namfile qkdlog aeslog complog
    $ns flush-trace
    close $tracefile
    close $namfile
    close $qkdlog
    close $aeslog
    close $complog
    exec nam eve_nam.nam &
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

# QKD BB84 Protocol Simulation with Eavesdropping
proc simulateQKD {aliceNode bobNode eveNode log eavesdrop} {
    global ns
    
    # Parameters
    set qbitCount 100        ;# Number of qubits to send
    set bitsMatched 0        ;# Counter for matched bits
    set errorRate 0          ;# Error rate due to eavesdropping
    
    puts $log "Starting QKD BB84 Protocol Simulation"
    puts $log "===============================\n"
    puts $log "Sending $qbitCount qubits from Alice to Bob"
    
    if {$eavesdrop} {
        puts $log "Eve is actively eavesdropping"
    } else {
        puts $log "No eavesdropping"
    }
    
    # Generate random bits for Alice (0 or 1)
    puts $log "\nAlice's random bits:"
    set aliceBits {}
    for {set i 0} {$i < $qbitCount} {incr i} {
        set bit [expr int(rand() * 2)]
        lappend aliceBits $bit
        puts -nonewline $log "$bit "
        if {[expr ($i+1) % 10] == 0} {puts $log ""}
    }
    
    # Generate random bases for Alice (0=rectilinear, 1=diagonal)
    puts $log "\n\nAlice's random bases:"
    set aliceBases {}
    for {set i 0} {$i < $qbitCount} {incr i} {
        set basis [expr int(rand() * 2)]
        lappend aliceBases $basis
        puts -nonewline $log "$basis "
        if {[expr ($i+1) % 10] == 0} {puts $log ""}
    }
    
    # Simulate quantum state preparation (bits encoded in bases)
    puts $log "\n\nAlice prepares quantum states according to bits and bases"
    
    # If Eve is eavesdropping, she measures with random bases
    set measuredByEve {}
    if {$eavesdrop} {
        puts $log "\nEve intercepts and measures with random bases:"
        set eveBases {}
        for {set i 0} {$i < $qbitCount} {incr i} {
            set basis [expr int(rand() * 2)]
            lappend eveBases $basis
            puts -nonewline $log "$basis "
            if {[expr ($i+1) % 10] == 0} {puts $log ""}
        }
        
        # Eve's measurements (will disturb quantum states)
        puts $log "\n\nEve's measurements (which disturb states):"
        for {set i 0} {$i < $qbitCount} {incr i} {
            set aliceBit [lindex $aliceBits $i]
            set aliceBasis [lindex $aliceBases $i]
            set eveBasis [lindex $eveBases $i]
            
            if {$aliceBasis == $eveBasis} {
                # Eve measures correctly
                set measuredBit $aliceBit
            } else {
                # Eve measures in wrong basis - random result
                set measuredBit [expr int(rand() * 2)]
            }
            lappend measuredByEve $measuredBit
            puts -nonewline $log "$measuredBit "
            if {[expr ($i+1) % 10] == 0} {puts $log ""}
        }
        puts $log "\n\nEve resends quantum states based on her measurements"
    }
    
    # Bob measures with random bases
    puts $log "\nBob measures with random bases:"
    set bobBases {}
    for {set i 0} {$i < $qbitCount} {incr i} {
        set basis [expr int(rand() * 2)]
        lappend bobBases $basis
        puts -nonewline $log "$basis "
        if {[expr ($i+1) % 10] == 0} {puts $log ""}
    }
    
    # Bob's measurement results
    puts $log "\n\nBob's measurement results:"
    set bobResults {}
    for {set i 0} {$i < $qbitCount} {incr i} {
        set aliceBit [lindex $aliceBits $i]
        set aliceBasis [lindex $aliceBases $i]
        set bobBasis [lindex $bobBases $i]
        
        if {$eavesdrop} {
            # If Eve intercepted, Bob measures states that Eve resent
            set eveMeasurement [lindex $measuredByEve $i]
            if {$bobBasis == [lindex $eveBases $i]} {
                # Bob uses same basis as Eve
                set result $eveMeasurement
            } else {
                # Bob uses different basis than Eve - random result
                set result [expr int(rand() * 2)]
            }
        } else {
            # No eavesdropping
            if {$aliceBasis == $bobBasis} {
                # Same basis - correct measurement
                set result $aliceBit
            } else {
                # Different basis - random result
                set result [expr int(rand() * 2)]
            }
        }
        
        lappend bobResults $result
        puts -nonewline $log "$result "
        if {[expr ($i+1) % 10] == 0} {puts $log ""}
    }
    
    # Public discussion of bases (via classical channel)
    puts $log "\n\nAlice and Bob publicly compare bases:"
    set siftedBits {}
    set siftedPositions {}
    
    for {set i 0} {$i < $qbitCount} {incr i} {
        set aliceBasis [lindex $aliceBases $i]
        set bobBasis [lindex $bobBases $i]
        
        if {$aliceBasis == $bobBasis} {
            puts $log "Position $i: Matching basis ($aliceBasis)"
            lappend siftedPositions $i
            lappend siftedBits [lindex $aliceBits $i]
        }
    }
    
    set keyLength [llength $siftedBits]
    puts $log "\nAfter sifting, key length: $keyLength bits"
    
    puts $log "\nSifted key bits (Alice's expected key):"
    for {set i 0} {$i < $keyLength} {incr i} {
        puts -nonewline $log "[lindex $siftedBits $i] "
        if {[expr ($i+1) % 10] == 0} {puts $log ""}
    }
    puts $log ""
    
    # Get Bob's actual bits for sifted positions
    puts $log "\nBob's measured key bits:"
    set bobKey {}
    set errorCount 0
    
    for {set i 0} {$i < [llength $siftedPositions]} {incr i} {
        set pos [lindex $siftedPositions $i]
        set bobBit [lindex $bobResults $pos]
        lappend bobKey $bobBit
        
        puts -nonewline $log "$bobBit "
        if {[expr ($i+1) % 10] == 0} {puts $log ""}
        
        # Count errors
        if {$bobBit != [lindex $siftedBits $i]} {
            incr errorCount
        }
    }
    puts $log ""
    
    # Calculate error rate
    set errorRate [expr double($errorCount) / $keyLength]
    
    puts $log "\nError rate: $errorRate (threshold: 0.15)"
    puts $log "Final key length: $keyLength bits"
    
    # Decision based on error rate
    if {$errorRate > 0.15} {
        puts $log "\nERROR RATE TOO HIGH - Potential eavesdropping detected!"
        puts $log "QKD Protocol ABORTED"
        return 0
    } else {
        puts $log "\nError rate acceptable - Proceeding with key"
        puts $log "Final secure key established"
        return 1
    }
}
