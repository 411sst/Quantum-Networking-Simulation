# Advanced QKD Protocols Implementation (BB84 and B92)
# This script implements multiple QKD protocols with advanced features

# Helper function to sum a list
# Create necessary directories
exec mkdir -p results
proc sum {list} {
    set sum 0
    foreach element $list {
        if {$element != -1} {
            set sum [expr $sum + $element]
        }
    }
    return $sum
}

# Helper function to calculate mean of a list
proc mean {list} {
    set count 0
    set sum 0
    foreach element $list {
        if {$element != -1} {
            set sum [expr $sum + $element]
            incr count
        }
    }
    if {$count == 0} {return 0}
    return [expr double($sum) / $count]
}

# Initialize the simulator
set ns [new Simulator]

# Open trace file
set tracefile [open results/advanced_qkd_trace.tr w]
$ns trace-all $tracefile

# Open NAM trace file
set namfile [open results/advanced_qkd_nam.nam w]
$ns namtrace-all $namfile

# Create log files for different protocols
set bb84log [open results/bb84_protocol.txt w]
set b92log [open results/b92_protocol.txt w]
set e91log [open results/e91_protocol.txt w]
set complog [open results/protocol_comparison.txt w]

# Define a 'finish' procedure
proc finish {} {
    global ns tracefile namfile bb84log b92log e91log complog
    $ns flush-trace
    close $tracefile
    close $namfile
    close $bb84log
    close $b92log
    close $e91log
    close $complog
    exec nam results/advanced_qkd_nam.nam &
    puts "Generating visualizations..."
    exec python3 src/protocol_analyzer.py results/bb84_protocol.txt results/b92_protocol.txt results/protocol_comparison.txt
    puts "Done. Check results directory for detailed analysis and graphs."
    exit 0
}

# Create network nodes
set alice [$ns node]
set bob [$ns node]
set quantum_repeater [$ns node]
set eve [$ns node]

# Set node colors and labels
$alice color blue
$bob color green
$quantum_repeater color cyan
$eve color red

$ns at 0.0 "$alice label Alice"
$ns at 0.0 "$bob label Bob"
$ns at 0.0 "$quantum_repeater label QRepeater"
$ns at 0.0 "$eve label Eve"

# Create links between nodes
$ns duplex-link $alice $quantum_repeater 10Mb 5ms DropTail
$ns duplex-link $quantum_repeater $bob 10Mb 5ms DropTail
$ns duplex-link $eve $quantum_repeater 1Mb 1ms DropTail

# Position nodes for NAM
$ns duplex-link-op $alice $quantum_repeater orient right
$ns duplex-link-op $quantum_repeater $bob orient right
$ns duplex-link-op $eve $quantum_repeater orient up

# B92 Protocol Implementation
proc simulate_B92 {aliceNode bobNode eveNode log eavesdrop {quantum_error_rate 0.05} {loss_rate 0.1}} {
    global ns
    
    # Parameters
    set qbitCount 1000      ;# Number of qubits to send
    set bitsMatched 0       ;# Counter for matched bits
    set errorRate 0         ;# Error rate due to eavesdropping
    
    puts $log "==================================================="
    puts $log "Starting B92 Protocol Simulation"
    puts $log "==================================================="
    puts $log "Configuration:"
    puts $log "  - Qubits: $qbitCount"
    puts $log "  - Quantum Error Rate: $quantum_error_rate"
    puts $log "  - Photon Loss Rate: $loss_rate"
    puts $log "  - Eavesdropping: [expr {$eavesdrop ? "Active" : "None"}]"
    puts $log "---------------------------------------------------\n"
    
    # Generate random bits for Alice (0 or 1)
    puts $log "Alice's random bits (first 50):"
    set aliceBits {}
    for {set i 0} {$i < $qbitCount} {incr i} {
        set bit [expr int(rand() * 2)]
        lappend aliceBits $bit
        if {$i < 50} {
            puts -nonewline $log "$bit "
            if {[expr ($i+1) % 10] == 0} {puts $log ""}
        } elseif {$i == 50} {
            puts $log "..."
        }
    }
    
    # In B92, Alice uses specific encodings:
    # Bit 0 is encoded as |0⟩ (horizontal polarization)
    # Bit 1 is encoded as |+⟩ (diagonal polarization)
    puts $log "\nAlice encodes bits using B92 encoding scheme:"
    puts $log "  - Bit 0 encoded as |0⟩ (horizontal polarization)"
    puts $log "  - Bit 1 encoded as |+⟩ (diagonal polarization)"
    
    # Simulate photon loss during transmission
    set photonLost {}
    puts $log "\nSimulating quantum channel losses ($loss_rate):"
    for {set i 0} {$i < $qbitCount} {incr i} {
        # Check if photon is lost during transmission
        if {rand() < $loss_rate} {
            lappend photonLost 1  ;# Photon lost
        } else {
            lappend photonLost 0  ;# Photon transmitted successfully
        }
    }
    
    set lostCount [sum $photonLost]
    puts $log "Total photons lost: $lostCount ([expr double($lostCount)*100.0/$qbitCount]%)"
    
    # If Eve is eavesdropping, she measures with random bases
    set measuredByEve {}
    if {$eavesdrop} {
        puts $log "\nEve is actively eavesdropping..."
        puts $log "In B92, Eve uses random measurement bases (rectilinear or diagonal)"
        
        # Eve's bases (0=horizontal/vertical, 1=diagonal)
        set eveBases {}
        for {set i 0} {$i < $qbitCount} {incr i} {
            set basis [expr int(rand() * 2)]
            lappend eveBases $basis
        }
        
        # Eve's measurements (will disturb quantum states)
        for {set i 0} {$i < $qbitCount} {incr i} {
            if {[lindex $photonLost $i] == 1} {
                # Photon was lost, Eve doesn't get it
                lappend measuredByEve -1
                continue
            }
            
            set aliceBit [lindex $aliceBits $i]
            set eveBasis [lindex $eveBases $i]
            
            # In B92, bit 0 is |0⟩ and bit 1 is |+⟩
            if {$aliceBit == 0} {
                # Alice sent |0⟩
                if {$eveBasis == 0} {
                    # Eve measures in rectilinear basis - will get 0
                    set measuredBit 0
                } else {
                    # Eve measures in diagonal - 50% chance each for 0/1
                    set measuredBit [expr int(rand() * 2)]
                }
            } else {
                # Alice sent |+⟩
                if {$eveBasis == 0} {
                    # Eve measures in rectilinear - 50% chance each for 0/1
                    set measuredBit [expr int(rand() * 2)]
                } else {
                    # Eve measures in diagonal - will get 1
                    set measuredBit 1
                }
            }
            lappend measuredByEve $measuredBit
        }
        puts $log "Eve has intercepted and remeasured the quantum states"
    }
    
    # Bob's measurements
    puts $log "\nBob performs B92 protocol measurements:"
    puts $log "In B92, Bob randomly chooses between two non-orthogonal bases:"
    puts $log "  - Measures in diagonal basis to detect |0⟩"
    puts $log "  - Measures in rectilinear basis to detect |+⟩"
    
    # Bob's basis choices (0=diagonal for detecting |0⟩, 1=rectilinear for detecting |+⟩)
    set bobBases {}
    for {set i 0} {$i < $qbitCount} {incr i} {
        set basis [expr int(rand() * 2)]
        lappend bobBases $basis
    }
    
    # Bob's measurement results (in B92, Bob can only detect specific combinations)
    puts $log "\nBob's measurement results:"
    set bobResults {}
    set conclusiveResults {}
    
    for {set i 0} {$i < $qbitCount} {incr i} {
        # Check if photon was lost
        if {[lindex $photonLost $i] == 1} {
            # Photon was lost, Bob doesn't detect it
            lappend bobResults -1
            lappend conclusiveResults -1
            continue
        }
        
        set aliceBit [lindex $aliceBits $i]
        set bobBasis [lindex $bobBases $i]
        
        # Add quantum channel noise
        set channel_error 0
        if {rand() < $quantum_error_rate} {
            set channel_error 1
        }
        
        if {$eavesdrop} {
            # If Eve intercepted, Bob measures states that Eve resent
            set eveMeasurement [lindex $measuredByEve $i]
            if {$eveMeasurement == -1} {
                # Photon was lost before Eve got it
                lappend bobResults -1
                lappend conclusiveResults -1
                continue
            }
            
            # Now Bob measures based on Eve's resent state
            set aliceBit $eveMeasurement  # Use Eve's measurement as the new state
        }
        
        # In B92, Bob's measurement:
        # If Alice sent |0⟩ (bit 0) and Bob measures in diagonal basis, 
        # he has 50% chance to get result that couldn't have come from |+⟩
        # If Alice sent |+⟩ (bit 1) and Bob measures in rectilinear basis,
        # he has 50% chance to get result that couldn't have come from |0⟩
        
        set conclusive 0
        set result -1
        
        if {$aliceBit == 0} {
            # Alice sent |0⟩
            if {$bobBasis == 0} {
                # Bob measures in diagonal basis
                if {rand() < 0.5} {
                    # Bob gets a conclusive result (can't be |+⟩)
                    set result 0
                    set conclusive 1
                } else {
                    # Inconclusive result
                    set result -1
                    set conclusive 0
                }
            } else {
                # Bob measures in rectilinear, will always get |0⟩
                # but this doesn't distinguish states, so inconclusive
                set result 0
                set conclusive 0
            }
        } else {
            # Alice sent |+⟩
            if {$bobBasis == 1} {
                # Bob measures in rectilinear basis
                if {rand() < 0.5} {
                    # Bob gets a conclusive result (can't be |0⟩)
                    set result 1
                    set conclusive 1
                } else {
                    # Inconclusive result
                    set result -1
                    set conclusive 0
                }
            } else {
                # Bob measures in diagonal, will always get |+⟩
                # but this doesn't distinguish states, so inconclusive
                set result 1
                set conclusive 0
            }
        }
        
        # Apply channel error to conclusive results
        if {$conclusive && $channel_error} {
            # Flip the bit due to channel error
            set result [expr 1 - $result]
        }
        
        lappend bobResults $result
        lappend conclusiveResults $conclusive
    }
    
    # Extract the sifted key (only from conclusive measurements)
    puts $log "\nB92 key sifting (keeping only conclusive measurements):"
    set siftedBits {}
    set siftedPositions {}
    
    for {set i 0} {$i < $qbitCount} {incr i} {
        if {[lindex $conclusiveResults $i] == 1} {
            # This was a conclusive measurement
            lappend siftedPositions $i
            lappend siftedBits [lindex $aliceBits $i]
        }
    }
    
    set keyLength [llength $siftedBits]
    puts $log "After sifting, raw key length: $keyLength bits"
    
    # In B92, conclusive results directly reveal the bit value
    puts $log "\nAlice's raw key bits (first 50):"
    for {set i 0} {$i < [llength $siftedBits] && $i < 50} {incr i} {
        puts -nonewline $log "[lindex $siftedBits $i] "
        if {[expr ($i+1) % 10] == 0} {puts $log ""}
    }
    puts $log ""
    
    # Get Bob's actual bits for sifted positions
    puts $log "\nBob's raw key bits (first 50):"
    set bobKey {}
    set errorCount 0
    
    for {set i 0} {$i < [llength $siftedPositions]} {incr i} {
        set pos [lindex $siftedPositions $i]
        # In B92, when Bob gets a conclusive result, it directly indicates the bit value
        set bobBit [lindex $bobResults $pos]
        lappend bobKey $bobBit
        
        if {$i < 50} {
            puts -nonewline $log "$bobBit "
            if {[expr ($i+1) % 10] == 0} {puts $log ""}
        } elseif {$i == 50} {
            puts $log "..."
        }
        
        # Count errors - in B92, conclusive results should match the original bit
        if {$bobBit != [lindex $siftedBits $i]} {
            incr errorCount
        }
    }
    puts $log ""
    
    # Calculate quantum bit error rate (QBER)
    if {$keyLength > 0} {
        set errorRate [expr double($errorCount) / $keyLength]
    } else {
        set errorRate 0
    }
    
    puts $log "\nQuantum Bit Error Rate (QBER): $errorRate"
    puts $log "B92 error threshold: 0.12"  # B92 usually has lower threshold than BB84
    
    # Error correction and privacy amplification (similar to BB84)
    puts $log "\nPerforming error correction and privacy amplification..."
    set finalKeyLength [expr int($keyLength * 0.8)]  ;# Reduce key length for security
    puts $log "Final secure key length: $finalKeyLength bits"
    
    # Decision based on error rate
    if {$errorRate > 0.12} {
        puts $log "\nQBER TOO HIGH - Potential eavesdropping detected!"
        puts $log "B92 Protocol ABORTED"
        return [list 0 $errorRate $keyLength $finalKeyLength]
    } else {
        puts $log "\nQBER acceptable - Proceeding with key"
        puts $log "Final secure key established successfully"
        return [list 1 $errorRate $keyLength $finalKeyLength]
    }
}

# E91 Protocol Simulation (based on quantum entanglement)
proc simulate_E91 {aliceNode bobNode eveNode log eavesdrop {quantum_error_rate 0.05} {loss_rate 0.15}} {
    global ns
    
    # Parameters
    set qbitCount 1000      ;# Number of entangled pairs
    
    puts $log "==================================================="
    puts $log "Starting E91 (Ekert91) Protocol Simulation"
    puts $log "==================================================="
    puts $log "Configuration:"
    puts $log "  - Entangled Pairs: $qbitCount"
    puts $log "  - Quantum Error Rate: $quantum_error_rate"
    puts $log "  - Photon Loss Rate: $loss_rate"
    puts $log "  - Eavesdropping: [expr {$eavesdrop ? "Active" : "None"}]"
    puts $log "---------------------------------------------------\n"
    
    puts $log "E91 Protocol uses entangled photon pairs to establish keys."
    puts $log "It can detect eavesdropping through Bell inequality violations.\n"
    
    puts $log "Source generates $qbitCount entangled photon pairs in singlet states."
    puts $log "One photon from each pair is sent to Alice, the other to Bob.\n"
    
    # Simulate photon loss (higher for entangled pairs)
    set pairsLost {}
    for {set i 0} {$i < $qbitCount} {incr i} {
        if {rand() < $loss_rate} {
            lappend pairsLost 1  ;# Pair was lost
        } else {
            lappend pairsLost 0  ;# Pair transmitted successfully
        }
    }
    
    set lostCount [sum $pairsLost]
    puts $log "Total entangled pairs lost: $lostCount ([expr double($lostCount)*100.0/$qbitCount]%)\n"
    
    # E91 uses 3 measurement bases for Alice and Bob
    # Alice uses angles: 0°, 45°, 90°
    # Bob uses angles: 45°, 90°, 135°
    # Only 0°-0°, 45°-45°, and 90°-90° are used for key generation
    # Other combinations are used to test Bell inequalities
    
    puts $log "Alice randomly selects measurement angles (0°, 45°, 90°)"
    puts $log "Bob randomly selects measurement angles (45°, 90°, 135°)\n"
    
    # Alice's basis choices (0=0°, 1=45°, 2=90°)
    set aliceBases {}
    for {set i 0} {$i < $qbitCount} {incr i} {
        set basis [expr int(rand() * 3)]
        lappend aliceBases $basis
    }
    
    # Bob's basis choices (0=45°, 1=90°, 2=135°)
    set bobBases {}
    for {set i 0} {$i < $qbitCount} {incr i} {
        set basis [expr int(rand() * 3)]
        lappend bobBases $basis
    }
    
    # Measurement results for Alice and Bob
    set aliceResults {}
    set bobResults {}
    
    for {set i 0} {$i < $qbitCount} {incr i} {
        if {[lindex $pairsLost $i] == 1} {
            # Pair was lost
            lappend aliceResults -1
            lappend bobResults -1
            continue
        }
        
        # For entangled pairs, results are correlated
        # For singlet state, measurements at same angle give opposite results
        set aliceBasis [lindex $aliceBases $i]
        set bobBasis [lindex $bobBases $i]
        
        # Add quantum noise
        set noise [expr rand() < $quantum_error_rate ? 1 : 0]
        
        # Eavesdropping disrupts entanglement
        set disruption [expr $eavesdrop ? (rand() < 0.5 ? 1 : 0) : 0]
        
        # Calculate measurement results
        # For simplicity, we'll say matching bases give perfectly correlated results without eavesdropping
        if {$aliceBasis == 1 && $bobBasis == 0} {
            # Both measuring at 45°
            set aliceResult [expr int(rand() * 2)]
            set bobResult [expr (1 - $aliceResult + $noise + $disruption) % 2]
        } elseif {$aliceBasis == 2 && $bobBasis == 1} {
            # Both measuring at 90°
            set aliceResult [expr int(rand() * 2)]
            set bobResult [expr (1 - $aliceResult + $noise + $disruption) % 2]
        } else {
            # Non-matching bases - uncorrelated results used for Bell test
            set aliceResult [expr int(rand() * 2)]
            set bobResult [expr int(rand() * 2)]
        }
        
        lappend aliceResults $aliceResult
        lappend bobResults $bobResult
    }
    
    # Public discussion of bases - keep only matching bases for key
    puts $log "Alice and Bob publicly discuss their basis choices:"
    set siftedBits {}
    set bellTestPairs {}
    
    for {set i 0} {$i < $qbitCount} {incr i} {
        if {[lindex $pairsLost $i] == 1} {
            continue
        }
        
        set aliceBasis [lindex $aliceBases $i]
        set bobBasis [lindex $bobBases $i]
        
        if {($aliceBasis == 1 && $bobBasis == 0) || 
            ($aliceBasis == 2 && $bobBasis == 1)} {
            # Same measurement angle - use for key
            lappend siftedBits [lindex $aliceResults $i]
        } else {
            # Different angles - use for Bell test
            lappend bellTestPairs $i
        }
    }
    
    set keyLength [llength $siftedBits]
    puts $log "After sifting, raw key length: $keyLength bits"
    
    # Bell test to detect eavesdropping
    puts $log "\nPerforming Bell inequality test with [llength $bellTestPairs] pairs"
    
    # Simulate Bell test result
    set bellViolation [expr !$eavesdrop]
    if {$eavesdrop} {
        puts $log "Bell inequality test failed - eavesdropping detected!"
        puts $log "Entanglement has been disrupted."
        return [list 0 0 $keyLength 0]
    } else {
        puts $log "Bell inequality test passed - no eavesdropping detected."
        
        # Continue with error correction and privacy amplification
        set finalKeyLength [expr int($keyLength * 0.8)]
        puts $log "\nFinal secure key length: $finalKeyLength bits"
        return [list 1 0 $keyLength $finalKeyLength]
    }
}

# BB84 Protocol Implementation with extended features
proc simulate_BB84 {aliceNode bobNode eveNode log eavesdrop {quantum_error_rate 0.05} {loss_rate 0.1}} {
    global ns
    
    # Parameters
    set qbitCount 1000      ;# Increased from 100 for better statistics
    set bitsMatched 0       ;# Counter for matched bits
    set errorRate 0         ;# Error rate due to eavesdropping
    
    puts $log "==================================================="
    puts $log "Starting Enhanced BB84 Protocol Simulation"
    puts $log "==================================================="
    puts $log "Configuration:"
    puts $log "  - Qubits: $qbitCount"
    puts $log "  - Quantum Error Rate: $quantum_error_rate"
    puts $log "  - Photon Loss Rate: $loss_rate"
    puts $log "  - Eavesdropping: [expr {$eavesdrop ? "Active" : "None"}]"
    puts $log "---------------------------------------------------\n"
    
    # Generate random bits for Alice (0 or 1)
    puts $log "Alice's random bits (first 50):"
    set aliceBits {}
    for {set i 0} {$i < $qbitCount} {incr i} {
        set bit [expr int(rand() * 2)]
        lappend aliceBits $bit
        if {$i < 50} {
            puts -nonewline $log "$bit "
            if {[expr ($i+1) % 10] == 0} {puts $log ""}
        } elseif {$i == 50} {
            puts $log "..."
        }
    }
    
    # Generate random bases for Alice (0=rectilinear (+), 1=diagonal (×))
    puts $log "\nAlice's random bases (first 50):"
    set aliceBases {}
    for {set i 0} {$i < $qbitCount} {incr i} {
        set basis [expr int(rand() * 2)]
        lappend aliceBases $basis
        if {$i < 50} {
            puts -nonewline $log "$basis "
            if {[expr ($i+1) % 10] == 0} {puts $log ""}
        } elseif {$i == 50} {
            puts $log "..."
        }
    }
    
    # Simulate quantum state preparation
    puts $log "\nAlice prepares quantum states according to bits and bases"
    
    # Simulate photon loss during transmission (realistic quantum channel)
    set photonLost {}
    puts $log "\nSimulating quantum channel losses ($loss_rate):"
    for {set i 0} {$i < $qbitCount} {incr i} {
        # Check if photon is lost during transmission
        if {rand() < $loss_rate} {
            lappend photonLost 1  ;# Photon lost
        } else {
            lappend photonLost 0  ;# Photon transmitted successfully
        }
    }
    
    set lostCount [sum $photonLost]
    puts $log "Total photons lost: $lostCount ([expr double($lostCount)*100.0/$qbitCount]%)"
    
    # If Eve is eavesdropping, she measures with random bases
    set measuredByEve {}
    set eveBases {}
    if {$eavesdrop} {
        puts $log "\nEve is actively eavesdropping..."
        puts $log "Eve's random bases (first 50):"
        
        for {set i 0} {$i < $qbitCount} {incr i} {
            set basis [expr int(rand() * 2)]
            lappend eveBases $basis
            if {$i < 50} {
                puts -nonewline $log "$basis "
                if {[expr ($i+1) % 10] == 0} {puts $log ""}
            } elseif {$i == 50} {
                puts $log "..."
            }
        }
        
        # Eve's measurements (will disturb quantum states)
        puts $log "\nEve's measurements (which disturb states):"
        for {set i 0} {$i < $qbitCount} {incr i} {
            if {[lindex $photonLost $i] == 1} {
                # Photon was lost, Eve doesn't get it
                lappend measuredByEve -1
                continue
            }
            
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
        }
        puts $log "Eve has intercepted and remeasured the quantum states"
    }
    
    # Bob measures with random bases (0=rectilinear, 1=diagonal)
    puts $log "\nBob's random bases (first 50):"
    set bobBases {}
    for {set i 0} {$i < $qbitCount} {incr i} {
        set basis [expr int(rand() * 2)]
        lappend bobBases $basis
        if {$i < 50} {
            puts -nonewline $log "$basis "
            if {[expr ($i+1) % 10] == 0} {puts $log ""}
        } elseif {$i == 50} {
            puts $log "..."
        }
    }
    
    # Bob's measurement results
    puts $log "\nBob's measurement results (first 50):"
    set bobResults {}
    for {set i 0} {$i < $qbitCount} {incr i} {
        # Check if photon was lost
        if {[lindex $photonLost $i] == 1} {
            # Photon was lost, Bob doesn't detect it
            lappend bobResults -1
            if {$i < 50} {
                puts -nonewline $log "- "
                if {[expr ($i+1) % 10] == 0} {puts $log ""}
            } elseif {$i == 50} {
                puts $log "..."
            }
            continue
        }
        
        set aliceBit [lindex $aliceBits $i]
        set aliceBasis [lindex $aliceBases $i]
        set bobBasis [lindex $bobBases $i]
        
        # Add quantum channel noise
        set channel_error 0
        if {rand() < $quantum_error_rate} {
            set channel_error 1
        }
        
        if {$eavesdrop} {
            # If Eve intercepted, Bob measures states that Eve resent
            set eveMeasurement [lindex $measuredByEve $i]
            if {$eveMeasurement == -1} {
                # Photon was lost before Eve got it
                lappend bobResults -1
                if {$i < 50} {
                    puts -nonewline $log "- "
                    if {[expr ($i+1) % 10] == 0} {puts $log ""}
                } elseif {$i == 50} {
                    puts $log "..."
                }
                continue
            }
            
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
                # Same basis - correct measurement with possible channel error
                set result [expr ($aliceBit + $channel_error) % 2]
            } else {
                # Different basis - random result
                set result [expr int(rand() * 2)]
            }
        }
        
        lappend bobResults $result
        if {$i < 50} {
            if {[lindex $bobResults $i] == -1} {
                puts -nonewline $log "- "
            } else {
                puts -nonewline $log "[lindex $bobResults $i] "
            }
            if {[expr ($i+1) % 10] == 0} {puts $log ""}
        } elseif {$i == 50} {
            puts $log "..."
        }
    }
    
    # Public discussion of bases (via classical channel)
    puts $log "\nAlice and Bob publicly compare bases and discard lost photons:"
    set siftedBits {}
    set siftedPositions {}
    
    for {set i 0} {$i < $qbitCount} {incr i} {
        # Skip lost photons
        if {[lindex $bobResults $i] == -1} {
            continue
        }
        
        set aliceBasis [lindex $aliceBases $i]
        set bobBasis [lindex $bobBases $i]
        
        if {$aliceBasis == $bobBasis} {
            if {$i < 20} {
                puts $log "Position $i: Matching basis ($aliceBasis)"
            } elseif {$i == 20} {
                puts $log "..."
            }
            lappend siftedPositions $i
            lappend siftedBits [lindex $aliceBits $i]
        }
    }
    
    set keyLength [llength $siftedBits]
    puts $log "\nAfter sifting, raw key length: $keyLength bits"
    
    puts $log "\nAlice's raw key bits (first 50):"
    for {set i 0} {$i < [llength $siftedBits] && $i < 50} {incr i} {
        puts -nonewline $log "[lindex $siftedBits $i] "
        if {[expr ($i+1) % 10] == 0} {puts $log ""}
    }
    puts $log ""
    
    # Get Bob's actual bits for sifted positions
    puts $log "\nBob's raw key bits (first 50):"
    set bobKey {}
    set errorCount 0
    
    for {set i 0} {$i < [llength $siftedPositions]} {incr i} {
        set pos [lindex $siftedPositions $i]
        set bobBit [lindex $bobResults $pos]
        lappend bobKey $bobBit
        
        if {$i < 50} {
            puts -nonewline $log "$bobBit "
            if {[expr ($i+1) % 10] == 0} {puts $log ""}
        } elseif {$i == 50} {
            puts $log "..."
        }
        
        # Count errors
        if {$bobBit != [lindex $siftedBits $i]} {
            incr errorCount
        }
    }
    puts $log ""
    
    # Calculate quantum bit error rate (QBER)
    set errorRate [expr double($errorCount) / $keyLength]
    
    puts $log "\nQuantum Bit Error Rate (QBER): $errorRate"
    puts $log "BB84 error threshold: 0.15"
    
    # Advanced error correction (simulate simple parity check)
    puts $log "\nPerforming error correction..."
    set correctedErrors 0
    set blockSize 7  ;# Size of parity check blocks
    
    # Only perform error correction if we have enough bits
    if {$keyLength >= $blockSize * 2} {
        set numBlocks [expr int($keyLength / $blockSize)]
        puts $log "Using $numBlocks parity check blocks of size $blockSize"
        
        for {set block 0} {$block < $numBlocks} {incr block} {
            set aliceBlockParity 0
            set bobBlockParity 0
            
            # Calculate parity for this block
            for {set j 0} {$j < $blockSize} {incr j} {
                set idx [expr $block * $blockSize + $j]
                if {$idx >= $keyLength} break
                
                set aliceBlockParity [expr ($aliceBlockParity + [lindex $siftedBits $idx]) % 2]
                set bobBlockParity [expr ($bobBlockParity + [lindex $bobKey $idx]) % 2]
            }
            
            # If parities don't match, there's at least one error
            if {$aliceBlockParity != $bobBlockParity} {
                incr correctedErrors
                puts $log "Error detected in block $block - corrected"
            }
        }
    } else {
        puts $log "Not enough bits for error correction"
    }
    
    puts $log "Errors corrected: $correctedErrors"
    
    # Privacy amplification (simulate with hash function)
    puts $log "\nPerforming privacy amplification..."
    set finalKeyLength [expr int($keyLength * 0.8)]  ;# Reduce key length for security
    puts $log "Final secure key length after privacy amplification: $finalKeyLength bits"
    
    # Decision based on error rate
    if {$errorRate > 0.15} {
        puts $log "\nQBER TOO HIGH - Potential eavesdropping detected!"
        puts $log "BB84 Protocol ABORTED"
        return [list 0 $errorRate $keyLength $finalKeyLength]
    } else {
        puts $log "\nQBER acceptable - Proceeding with key"
        puts $log "Final secure key established successfully"
        return [list 1 $errorRate $keyLength $finalKeyLength]
    }
}
