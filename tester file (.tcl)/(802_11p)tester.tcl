# --------------------------------------------------
# define node configuration paramaters
# --------------------------------------------------

set val(chan)           Channel/WirelessChannel;	# channel type
set val(prop)           Propagation/TwoRayGround;	# radio-propagation model
set val(netif)          Phy/WirelessPhyExt;		# network interface type
set val(mac)            Mac/802_11Ext;			# MAC type
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
# config IEEE 802.11p NS-2.35 default
# https://sites.google.com/site/nahoons2/english-con/ns2-simulation-with-802-11p
# --------------------------------------------------

Phy/WirelessPhyExt set CSThresh_                3.9810717055349694e-13;	# -94 dBm wireless interface sensitivity
Phy/WirelessPhyExt set Pt_                      0.1;			# equals 20dBm when considering antenna gains of 1.0
Phy/WirelessPhyExt set freq_                    5.9e+9;
Phy/WirelessPhyExt set noise_floor_             1.26e-13;		# -99 dBm for 10MHz bandwidth
Phy/WirelessPhyExt set L_                       1.0;			# default radio circuit gain/loss
Phy/WirelessPhyExt set PowerMonitorThresh_      3.981071705534985e-18;	# -174 dBm power monitor sensitivity (=level of gaussian noise)
Phy/WirelessPhyExt set HeaderDuration_          0.000040;		# 40 us
Phy/WirelessPhyExt set BasicModulationScheme_   0;
Phy/WirelessPhyExt set PreambleCaptureSwitch_   1;
Phy/WirelessPhyExt set DataCaptureSwitch_       1;
Phy/WirelessPhyExt set SINR_PreambleCapture_    3.1623;     		# 5 dB
Phy/WirelessPhyExt set SINR_DataCapture_        10.0;      		# 10 dB
Phy/WirelessPhyExt set trace_dist_              1e6;			# PHY trace until distance of 1 Mio. km ("infinity")
Phy/WirelessPhyExt set PHY_DBG_                 0;

Mac/802_11Ext set CWMin_                        15;
Mac/802_11Ext set CWMax_                        1023;
Mac/802_11Ext set SlotTime_                     0.000013;
Mac/802_11Ext set SIFS_                         0.000032;
Mac/802_11Ext set ShortRetryLimit_              7;
Mac/802_11Ext set LongRetryLimit_               4;
Mac/802_11Ext set HeaderDuration_               0.000040;
Mac/802_11Ext set SymbolDuration_               0.000008;
Mac/802_11Ext set BasicModulationScheme_        0;
Mac/802_11Ext set use_802_11a_flag_             true;
Mac/802_11Ext set RTSThreshold_                 2346;
Mac/802_11Ext set MAC_DBG                       0;

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
