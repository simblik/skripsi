# --------------------------------------------------
# define node configuration paramaters
# --------------------------------------------------

set val(chan)           Channel/WirelessChannel;	# channel type
set val(prop)           Propagation/TwoRayGround;	# radio-propagation model
set val(netif)          Phy/WirelessPhy;		# network interface type
set val(mac)            Mac/802_11;			# MAC type
set val(ifq)            Queue/DropTail/PriQueue;	# interface queue type
set val(ll)             LL;				# link layer type
set val(ant)            Antenna/OmniAntenna;		# antenna model
set val(ifqlen)         50;				# max packet in queue
set val(nn)             100;				# number of mobilenodes
set val(rp)             AODV;				# routing protocol
set val(x) 		1100;				# x coordinate
set val(y) 		1100;				# y coordinate
set val(stop)           180;				# time to stop simulation

# --------------------------------------------------
# config IEEE 802.11b NS-2.35 default
# http://read.pudn.com/downloads165/doc/756173/Simulate_802.11b_Channel_NS2.pdf
# --------------------------------------------------

Antenna/OmniAntenna set Gt_ 1.0;			# Transmit antenna gain  
Antenna/OmniAntenna set Gr_ 1.0;			# Receive  antenna gain
Antenna/OmniAntenna set Z_ 1.5;				# Antenna High
Phy/WirelessPhy set RXThresh_ 3.65262e-10; 		# receiver threshold (W) 250m WA def for WAVELAN
Phy/WirelessPhy set CSThresh_ 1.559e-11; 		# carrier sensing threshold (W) 550m def for WAVELAN
Phy/WirelessPhy set CPThresh_ 10.0;        		# capture threshold (dB)
Phy/WirelessPhy set freq_ 2.472e9;       		# Operating Freq IEEE 802.11b Channel 13 (2.472 GHz)
Phy/WirelessPhy set L_ 1.0;              		# System loss factor default
Phy/WirelessPhy set Pt_ 0.28183815;           		# transmitter power 250m def for WAVELAN
Phy/WirelessPhy set bandwidth_ 11Mb;			# 11 Mbps bandwidth corresponden to maximal data rate

Mac/802_11 set RTSThreshold_ 3000;			# RTS Threshold to suppress RTS/CTS
Mac/802_11 set basicRate_ 1Mb;				# 1 Mbps broadcast
Mac/802_11 set dataRate_ 11Mb;				# 11 Mbps data (2 for 802.11 & 11 for 802.11b)

# --------------------------------------------------
# for starting simulation configuration
# --------------------------------------------------

# Initialize Simulator
set ns_		[new Simulator]

# Initialize Trace file
set tracefd	[open tracing.tr w]
$ns_ trace-all $tracefd

# Initialize Network Animator
set namtrace 	[open animation.nam w]
$ns_ namtrace-all-wireless $namtrace $val(x) $val(y)

# set up topography object
set topo       [new Topography]
$topo load_flatgrid $val(x) $val(y)

# create  General Operations Director (GOD) object. 
set god_ [create-god $val(nn)]

# create nn mobilenodes [$val(nn)] and attach them to the channel.

# configure nodes
        $ns_ node-config -adhocRouting $val(rp) \
                         -llType $val(ll) \
                         -macType $val(mac) \
                         -ifqType $val(ifq) \
                         -ifqLen $val(ifqlen) \
                         -antType $val(ant) \
                         -propType $val(prop) \
                         -phyType $val(netif) \
                         -channelType $val(chan) \
                         -topoInstance $topo \
                         -agentTrace ON \
                         -routerTrace ON \
                         -macTrace ON \
                         -movementTrace ON                   
 
# create Nodes
        for {set i 0} {$i < $val(nn) } {incr i} {
                set node_($i) [$ns_ node]
                $node_($i) random-motion 0; # if 0 disable motion
        }

puts "Loading movement pattern ..."
source mobility.tcl

# setup UDP connection
set udp [new Agent/UDP]
set null [new Agent/LossMonitor]
$ns_ attach-agent $node_(0) $udp
$node_(0) color red
$ns_ at 0.0 "$node_(0) color green"
$ns_ attach-agent $node_(1) $null
$node_(1) color blue
$ns_ at 0.0 "$node_(1) color red"
$ns_ connect $udp $null
set cbr [new Application/Traffic/CBR]
$cbr set packetSize_ 1024
$cbr set rate_ 256Kb
$cbr attach-agent $udp
$ns_ at 0.1 "$cbr start"
$ns_ at 180.0 "$cbr stop"

# defines the node size in Network Animator
for {set i 0} {$i < $val(nn)} {incr i} {
	$ns_ initial_node_pos $node_($i) 25
}

# start transmission at time t = 0.0 Sec
$ns_ at 0.0 "$cbr start";

# reset Nodes at time 180 sec
for {set i 0} {$i < $val(nn) } {incr i} {
    $ns_ at 180.0 "$node_($i) reset";
}

$ns_ at $val(stop).0002 "puts \"NS EXITING...\" ; $ns_ halt"
$ns_ at $val(stop).0001 "stop"

proc stop {} {
global ns_ tracefd namtrace

    $ns_ flush-trace
    close $tracefd
    close $namtrace
}

# begin simulation
puts "Starting Simulation..."

$ns_ run