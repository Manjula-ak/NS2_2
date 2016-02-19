if { $argc != 2 } {
        puts "Invalid usage!"
        puts "For example: ns $argv0 <queue_mechanism> <senario_no>"
        puts "Please try again."
    }
set mech [lindex $argv 0]
set senario_case [lindex $argv 1]
if {$senario_case > 3 || $senario_case < 1} { 
	puts "Invalid senario case $senario_case" 
   	exit
}
global mechanism
if {$mech == "DROPTAIL"} {
	set mechanism "DropTail"
} elseif {$mech == "RED"} {
	set mechanism "RED"
} else {
	puts "Invalid queue mechanism $mech"
	exit
}

#Create a simulator object
set ns [new Simulator]

#Open the output files
set f0 [open src1_$mechanism$senario_case.tr w]
set f1 [open src2_$mechanism$senario_case.tr w]
set f2 [open src3_$mechanism$senario_case.tr w]

#Open the NAM trace file
set namfile [open out.nam w]
$ns namtrace-all $namfile

set sum_throughput1 0
set sum_throughput2 0
set sum_throughput3 0
set count 0

#Create 8 nodes
set H1 [$ns node]
set H2 [$ns node]
set R1 [$ns node]
set R2 [$ns node]
set H3 [$ns node]
set H4 [$ns node]
if {$senario_case ==2} {
set H5 [$ns node]
set H6 [$ns node]
}


# Setting RED parameters
if {$mechanism == "RED"} {
Queue/RED set thresh_ 10
Queue/RED set maxthresh_ 15
Queue/RED set linterm_ 50
} 
$ns duplex-link $H1 $R1 10Mb 1ms $mechanism
$ns duplex-link $H2 $R1 10Mb 1ms $mechanism
$ns duplex-link $R1 $R2 1Mb 10ms $mechanism
$ns duplex-link $R2 $H3 10Mb 1ms $mechanism
$ns duplex-link $R2 $H4 10Mb 1ms $mechanism

# Queue limit for the link
$ns queue-limit $R1 $R2 20

if {$senario_case == 2} {
	$ns duplex-link $H6 $R1 10Mb 1ms $mechanism
	$ns duplex-link $R2 $H5 10Mb 1ms $mechanism

	#Create a UDP agent and attach it to node n6
	set udp0 [new Agent/UDP]
	$ns attach-agent $H6 $udp0

	# Create a CBR traffic source and attach it to udp0
	set cbr0 [new Application/Traffic/CBR]
	$cbr0 set PacketSize_ 100
	$cbr0 set rate_ 1Mb
	$cbr0 attach-agent $udp0
	
	#Create three traffic sinks and attach them to the node h5
	set sink2 [new Agent/LossMonitor]
	$ns attach-agent $H5 $sink2

	#$ns connect $udp0 $null0 
	$ns connect $udp0 $sink2
} 


#Create a TCP agent and attach it to node H1 H2
set tcp0 [new Agent/TCP/Reno]
set tcp1 [new Agent/TCP/Reno]
$ns attach-agent $H1 $tcp0
$ns attach-agent $H2 $tcp1

# Create a FTP traffic source and attach it to tcp0 tcp1
set ftp0 [new Application/FTP]
set ftp1 [new Application/FTP]

# Attach traffic source to the traffic generator
$ftp0 attach-agent $tcp0
$ftp1 attach-agent $tcp1

#Create three traffic sinks and attach them to the node H3 H4
set sink0 [new Agent/TCPSink]
set sink1 [new Agent/TCPSink]

$ns attach-agent $H3 $sink0
$ns attach-agent $H4 $sink1

#Connect the source and the sink
$ns connect $tcp0 $sink0
$ns connect $tcp1 $sink1

#Give node position (for NAM)
$ns duplex-link-op $R1 $R2 orient right
$ns duplex-link-op $H1 $R1 orient right-down
$ns duplex-link-op $H2 $R1 orient right-up
$ns duplex-link-op $R2 $H3 orient right-up
$ns duplex-link-op $R2 $H4 orient right-down
if {$senario_case ==2} {
$ns duplex-link-op $H6 $R1 orient right-up
$ns duplex-link-op $R2 $H5 orient right-down
}

#Initialize the parameter
proc initialize {} {
	global senario_case sink0 sink1
	$sink0 set bytes_ 0
	$sink1 set bytes_ 0
	if {$senario_case == 2} {
		global sink2
		$sink2 set bytes_ 0
	}
}

#Define a 'finish' procedure
proc finish {} {
		global f0 f1 f2 argv mechanism senario_case sum_throughput1 sum_throughput2 sum_throughput3 count
		close $f0
		close $f1
		puts "Average throughput for (src1) = [expr $sum_throughput1/$count] MBits/s "
		puts "Average throughput for (src2) = [expr $sum_throughput2/$count] MBits/s "
		exec nam out.nam &
		#Call xgraph to display the results
		if {$senario_case == 2} {
		close $f2
		puts "Average throughput for (src3) = [expr $sum_throughput3/$count] MBits/s "
		}

		if {$senario_case == 1} {
		exec xgraph src1_$mechanism$senario_case.tr src2_$mechanism$senario_case.tr -geometry 800x400 &
		}

		if {[lindex $argv 1] == 2} {
		exec xgraph src2_$mechanism$senario_case.tr src3_$mechanism$senario_case.tr -geometry 800x400 &
		exec xgraph src1_$mechanism$senario_case.tr src3_$mechanism$senario_case.tr -geometry 800x400 &
		exec xgraph src1_$mechanism$senario_case.tr src2_$mechanism$senario_case.tr -geometry 800x400 &
		exec xgraph src1_$mechanism$senario_case.tr src2_$mechanism$senario_case.tr src3_$mechanism$senario_case.tr -geometry 800x400 &
		}
		exit 0	
	}


#Define a procedure which periodically records the bandwidth
proc record {} {
		global sink0 sink1 sink2 f0 f1 f2 mechanism senario_case sum_throughput1 sum_throughput2 sum_throughput3 count 
		#Get an instance of the simulator	
		set ns [Simulator instance]
		#Set the time after which the procedure should be called again	
		set time 0.99
		#How many bytes have been received by the traffic sinks?	
		set bw0 [$sink0 set bytes_]
		set bw1 [$sink1 set bytes_]
		#Get the current time
		set now [$ns now]
		#Calculate the bandwidth (in MBit/s) and write it to the files
		set sum_throughput1 [expr $sum_throughput1 + $bw0/$time*8/1000000]
		set sum_throughput2 [expr $sum_throughput2 + $bw1/$time*8/1000000]
		set count [expr $count + 1]

		puts $f0 "$now [expr $bw0/$time*8/1000000]"
		puts $f1 "$now [expr $bw1/$time*8/1000000]"

		if {$senario_case == 2} {
		set bw2 [$sink2 set bytes_]
		set sum_throughput3 [expr $sum_throughput3 + $bw2/$time*8/1000000]
		puts $f2 "$now [expr $bw2/$time*8/1000000]"
		$sink2 set bytes_ 0
		}

		#Reset the bytes_ values on the traffic sinks
		$sink0 set bytes_ 0
		$sink1 set bytes_ 0
	
		#Re-schedule the procedure
		$ns at [expr $now+$time] "record"
	}


#Start the traffic sources
$ns at 0.0 "$ftp0 start"
$ns at 0.0 "$ftp1 start"

$ns at 30.0 "initialize"
$ns at 30.0 "record"

if {$senario_case == 2} {
	$ns at 0.0 "$cbr0 start"
	$ns at 180.0 "$cbr0 stop"
	$udp0 set class_ 3
	$ns color 3 Green
}
#Stop the traffic sources
$ns at 180.0 "$ftp0 stop"
$ns at 180.0 "$ftp1 stop"

#Define different colors for data flows
$tcp0 set class_ 1
$tcp1 set class_ 2
$ns color 1 Blue
$ns color 2 Red

#Call the finish procedure after 180 seconds simulation time
$ns at 180.0 "finish"

$ns run

