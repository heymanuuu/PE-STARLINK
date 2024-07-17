set ns [new Simulator]
$ns set-address-format hierarchical
proc finish {} {
    global ns nf
    $ns flush-trace
    close $nf
    #exec nam ./nam/starlink1_3_1.nam 
}
# Create trace files
set tracefile [open ./tr/starlink1_3_1.tr w]
$ns trace-all $tracefile
set nf [open ./nam/starlink1_3_1.nam w]
$ns namtrace-all $nf
array set nodes {}
proc createSatelliteNodes {filename ns} {
    global nodes
    set nodeFile [open $filename r]
    set lines [split [read $nodeFile] "\n"]
    close $nodeFile
    set current_cluster 0
    set node_count 0
    set node_num 0
    foreach line $lines {
        if {$line eq ""} {
            continue
        }
        if {[regexp {^Cluster(\d+)} $line match cluster_id]} {
           # puts $cluster_id
            set current_cluster $cluster_id
            set node_num 0
            continue
        }
set parts [regexp -all -inline {(\S+)} $line]
        if {[llength $parts] == 0} {
            puts "Error: Invalid line format: $line"
            continue
        }
        set satellite_name [lindex $parts 0]
        set node_addr "0.$current_cluster.$node_num"
        set node [$ns node $node_addr]
        set nodes($satellite_name) $node
        #puts "Created node $satellite_name at $node_addr"
        #puts $node_count
        incr node_num
        incr node_count
    }  
    return $node_count
}
proc createLinksFromDelayFile {filename ns} {
    global nodes
    set links_cnt 0
    # Open and read the delay file
    set file [open $filename r]
    set delay_data [split [read $file] "\n"]
    close $file
    # Iterate through each line in the delay data
    foreach line $delay_data {
        # Skip empty lines
        if {[string trim $line] eq ""} {
            continue
        }
        # Parse each line to get satellite names and delay
        set parts [split $line]
        if {[llength $parts] != 3} {
            puts "Error: Invalid line format: $line"
            continue
        }
set satellite1 [lindex $parts 0]
        set satellite2 [lindex $parts 1]
        set delay [lindex $parts 2]
        # Create bidirectional links between nodes
        $ns duplex-link $nodes($satellite1) $nodes($satellite2) 200Mb ${delay}ms DropTail
        #puts ${delay}ms
        # Set the link cost (delay) using the 'cost' command
        $ns cost $nodes($satellite1) $nodes($satellite2) $delay
        $ns cost $nodes($satellite2) $nodes($satellite1) $delay
        # Output for verification
        #puts "Created bidirectional link between $satellite1 and $satellite2 with delay $delay ms"
        incr links_cnt
    }
        #puts "num of links : $links_cnt"
}

proc haversine {lat1 lon1 lat2 lon2} {
    set R 6371.0 ;
    set dlat [expr {($lat2 - $lat1) * 0.017453292519943295}] ;
    set dlon [expr {($lon2 - $lon1) * 0.017453292519943295}]
    set a [expr {sin($dlat/2) * sin($dlat/2) + cos($lat1 * 0.017453292519943295) * cos($lat2 * 0.017453292519943295) * sin($dlon/2) * sin($dlon/2)}]
    set c [expr {2 * atan2(sqrt($a), sqrt(1-$a))}]
    return [expr {$R * $c}]
}

proc findClosestSatellite {filename lat lon} {
    set file [open $filename r]
    set lines [split [read $file] "\n"]
    close $file
    set min_distance -1
    set closest_satellite ""
    set closest_lat ""
    set closest_lon ""
    set closest_alt ""
    foreach line $lines {
        if {[regexp {Cluster} $line]} {
            continue
        }
if {[regexp {(\S+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)} $line match satellite_name sat_lat sat_lon sat_alt]} {
            set distance [haversine $lat $lon $sat_lat $sat_lon]
            if {$min_distance == -1 || $distance < $min_distance} {
                set min_distance $distance
                set closest_satellite $satellite_name
                set closest_lat $sat_lat
                set closest_lon $sat_lon
                set closest_alt $sat_alt
            }
        }
    }
    return "$closest_satellite $closest_lat $closest_lon $closest_alt"
}
proc euclideanDistance {lat1 lon1 alt1 lat2 lon2 alt2} {
    set dlat [expr {$lat2 - $lat1}]
    set dlon [expr {$lon2 - $lon1}]
    set dalt [expr {$alt2 - $alt1}]
    return [expr {sqrt($dlat*$dlat + $dlon*$dlon + $dalt*$dalt)}]
}

proc interrupt_satellites {interrupt_rate file_path} {
    global ns nodes
    set exclude_list {
        "STARLINK-30341_57714" "STARLINK-6118_57106" "STARLINK-30332_57700"
        "STARLINK-30310_57733" "STARLINK-5680_55455" "STARLINK-6084_56111"
        "STARLINK-5091_54873" "STARLINK-5782_56034" "STARLINK-5395_54831"
        "STARLINK-5651_55357" "STARLINK-30489_57974" "STARLINK-30365_57734"
        "STARLINK-30855_58222" "STARLINK-5027_55370" "STARLINK-30334_57719"
        "STARLINK-5945_56018" "STARLINK-6317_56526" "STARLINK-5668_55350"
    }
    set satellites [list]
    set f [open $file_path r]
    while {[gets $f line] >= 0} {
        if {[string match "STARLINK*" $line]} {
            set satellite_name [lindex [split $line] 0]
            if {$satellite_name ni $exclude_list} {
                lappend satellites $satellite_name
            }
        }
    }
    close $f
 set total [llength $satellites]
    set num_interrupt [expr {int($interrupt_rate * $total)}]
    set selected [list]
    set len $total
    for {set i 0} {$i < $num_interrupt} {incr i} {
        set idx [expr {int(rand() * $len)}]
        lappend selected [lindex $satellites $idx]
        set satellites [lreplace $satellites $idx $idx]
        set len [llength $satellites]
    }
    for {set i 0} {$i < $num_interrupt} {incr i} {
        set satellite [lindex $selected $i]
        $ns rtmodel-at 5 down $nodes($satellite)
        $ns rtmodel-at 6 up $nodes($satellite)
    }
}
# create satellite nodes
set nodeCount [createSatelliteNodes "/mnt/hgfs/share/starlink1/satByCluster2.txt" $ns]
#puts "Total nodes created: $nodeCount"


set shanghai_lat 31.2304
set shanghai_lon 121.4737
set Berkeley_lat 37.7739
set Berkeley_lon -122.1671
set wuhan_lat 30.4655
set wuhan_lon 114.6252
set shanghai "shanghai"
set Berkeley "Berkeley"
set wuhan "wuhan"
set node_wuhan [$ns node 0.15.86]
set nodes($wuhan) $node_wuhan
set node_Berkeley [$ns node 0.1.124]
set nodes($Berkeley) $node_Berkeley
set closest_satelliteInfo_wuhan [findClosestSatellite "/mnt/hgfs/share/starlink1/satByCluster2.txt" $wuhan_lat $wuhan_lon]
set closest_satelliteInfo_Berkeley [findClosestSatellite "/mnt/hgfs/share/starlink1/satByCluster2.txt" $Berkeley_lat $Berkeley_lon]

set parts1 [split $closest_satelliteInfo_wuhan " "]
set closest_satellite_wuhan [lindex $parts1 0]
set closest_satellite_wuhan_lat [lindex $parts1 1]
set closest_satellite_wuhan_lon [lindex $parts1 2]
set closest_satellite_wuhan_alt [lindex $parts1 3]
set parts2 [split $closest_satelliteInfo_Berkeley " "]
set closest_satellite_Berkeley [lindex $parts2 0]
set closest_satellite_Berkeley_lat [lindex $parts2 1]
set closest_satellite_Berkeley_lon [lindex $parts2 2]
set closest_satellite_Berkeley_alt [lindex $parts2 3]
set distance1 [euclideanDistance $wuhan_lat $wuhan_lat 0 $closest_satellite_wuhan_lat $closest_satellite_wuhan_lon $closest_satellite_wuhan_alt]
set distance2 [euclideanDistance $Berkeley_lat $Berkeley_lat 0 $closest_satellite_Berkeley_lat $closest_satellite_Berkeley_lon $closest_satellite_Berkeley_alt]
set c 299792.458;
set delay1 [format "%.2f" [expr ($distance1 / $c*1000)]]
set delay2 [format "%.2f" [expr ($distance2 / $c*1000)]]

# Topology information
lappend domain1 1
AddrParams set domain_num_ $domain1
lappend cluster1 80
AddrParams set cluster_num_ $cluster1
lappend eilastlevel1 86 125 88 62 42 82 91 82 90 131 103 89 28 89 69 87 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
AddrParams set nodes_num_ $eilastlevel1

# Assuming nodes array is already populated from createSatelliteNodes function
createLinksFromDelayFile "/mnt/hgfs/share/starlink1/delay.txt" $ns
$ns duplex-link $nodes($wuhan) $nodes($closest_satellite_wuhan) 200Mb ${delay1}ms DropTail
$ns cost $nodes($wuhan) $nodes($closest_satellite_wuhan) $delay1
$ns cost $nodes($closest_satellite_wuhan) $nodes($wuhan) $delay1
$ns duplex-link $nodes($Berkeley) $nodes($closest_satellite_Berkeley) 200Mb ${delay2}ms DropTail
$ns cost $nodes($Berkeley) $nodes($closest_satellite_Berkeley) $delay2
$ns cost $nodes($closest_satellite_Berkeley) $nodes($Berkeley) $delay2

Agent/TCP set dupacks_ 1
Agent/TCP set cwnd_ 400
Agent/TCP set ssthresh_ 400
set tcp_sender [new Agent/TCP]
set tcp_receiver [new Agent/TCPSink]
$tcp_sender set window_ 1000
$tcp_sender set windowInit_ 1000  
$tcp_sender set packetSize_ 200  
$tcp_receiver set window_ 400  
$tcp_receiver set windowInit_ 400

$ns attach-agent $nodes($wuhan) $tcp_sender
$ns attach-agent $nodes($Berkeley) $tcp_receiver

$ns connect $tcp_sender $tcp_receiver

set cbr [new Application/Traffic/CBR]
$cbr attach-agent $tcp_sender
$cbr set packetSize_ 200
$cbr set rate_ 5M
$cbr set random_ 1

set interrupt_rate 0.01
interrupt_satellites $interrupt_rate "/mnt/hgfs/share/starlink1/satByCluster2.txt"

$ns at 1.0 "$cbr start"
#$ns rtmodel-at 10.0 down $nodes(ONEWEB-0490_54113)
for {set i 5.01} {$i < 7} {set i [format "%.3f" [expr $i+0.5]]} {
  #puts $i
  $ns at $i "$ns compute-routes"
}
$ns at 61.0 "$cbr stop"
$ns at 4000 "finish"
$ns run
