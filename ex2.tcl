if {$argc == 1} {
    set flag  [lindex $argv 0] 

} else {
    puts "  CBR2-TCP2    n2 "
    puts "                \ "
    puts "  CBR0-TCP1 n1-- n3 ---- n4 "
    puts "                / "
    puts "  CBR0-TCP0    n0 "
    puts ""
    puts "  Usage: ns $argv0 (0: original, 1: incr lineal, 2: slow start) "
    puts ""
    exit 1
}


if {$flag==0} {
	set trailer .tcporig
}
if {$flag==1} {
	set trailer .linc
}
if {$flag==2} {
	set trailer .slow
}


set tracefile sor$trailer
set cwfile cw$trailer



#Es crea l'objecte simulador
set ns [new Simulator]

#S'obre l'arxiu per traçar resultats
set nf [open $tracefile  w]
$ns trace-all $nf

set nff [open $cwfile  w]

#Definim el procediment per acabar
proc finish {} {
        global ns nf nff tracefile cwfile trailer 
        $ns flush-trace
	# Processem "sor.tr" pre obtenir els paquets enviats
	exec awk {{ if ($1=="-" && $3==1 && $4=2) print $2, 49}}  $tracefile > tx$trailer
	# Processem "sor.tr" pre obtenir els paquets perduts
	exec awk {{ if ($1=="d" && $3==2 && $4=3) print $2, 44}}  $tracefile  > drop$trailer
	exec awk {{  print $2,$3}}  $tracefile  > out$trailer

        close $nf
        close $nff
        exit 0
}

# Procediment per gravar els temps del TCP
proc grava { } {
	global ns tcp1 nff
	# ObtÉ la finestra de congestió
        set cw  [$tcp1 set cwnd_] 
	set now [$ns now]
	puts $nff "$now $cw"

	$ns at [expr $now+0.1] "grava"
}

#Creem 5 nodes
#
#      n2
#       \
#        \
#   n1--- n3--------n4
#        /
#       /
#      n0
 
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]

#Creem línies duplex entre els nodes
$ns duplex-link $n0 $n3 5Mb 20ms DropTail
$ns duplex-link $n1 $n3 5Mb 20ms DropTail
$ns duplex-link $n2 $n3 5Mb 20ms DropTail
$ns duplex-link $n3 $n4 1Mb 50ms DropTail


# Pel node 0; un agent TCP 
set tcp0 [new Agent/TCP]
$ns attach-agent $n0 $tcp0
set cbr0 [new Application/Traffic/CBR]
$cbr0 set rate_ 0.5Mbps
$cbr0 attach-agent $tcp0
$tcp0 set class_ 0


# Pel node 1; un agent TCP Reno
set tcp1 [new Agent/TCP/Reno]
$ns attach-agent $n1 $tcp1
set cbr1 [new Application/Traffic/CBR]
$cbr1 set rate_ 0.5Mbps
$cbr1 attach-agent $tcp1
$tcp1 set class_ 0


# Pel node 2; un agent TCP Vegas
set tcp2 [new Agent/TCP/Vegas]
$ns attach-agent $n2 $tcp2
set cbr2 [new Application/Traffic/CBR]
$cbr2 set rate_ 0.5Mbps
$cbr2 attach-agent $tcp2
$tcp2 set class_ 0

# Pel node 4
set null0 [new Agent/TCPSink]
$ns attach-agent $n4 $null0
set null1 [new Agent/TCPSink]
$ns attach-agent $n4 $null1
set null2 [new Agent/TCPSink]
$ns attach-agent $n4 $null2


# Connectem els agents
$ns connect $tcp0 $null0
$ns connect $tcp1 $null1
$ns connect $tcp2 $null2



set iterations 20

for {set k 0} {$k < $iterations} {set k [expr {$k+0.5}]} {

    puts "CBR0 start: $k "
    $ns at $k "$cbr0 start"

    set k [expr {$k + 0.5}]
    puts "CBR0 stop: $k "
    $ns at $k "$cbr0 stop"

}
puts "\n"

# A 0s arranquem la font CBR1. Als 1.00s. l'aturem

for {set k 0} {$k < $iterations} {set k [expr {$k+1}]} {

    puts "CBR1 start: $k "
    $ns at $k "$cbr1 start"

    set k [expr {$k+1}]
    puts "CBR1 stop: $k "
    $ns at $k "$cbr1 stop"

}
puts "\n"

# A 0s arranquem la font CBR2. Als 1.00s. l'aturem

for {set k 0} {$k < $iterations} {set k [expr {$k+2}]} {

    puts "CBR2 start: $k "
    $ns at $k "$cbr2 start"

    set k [expr {$k+2}]
    puts "CBR2 stop: $k "
    $ns at $k "$cbr2 stop"
}
puts "\n"

# Modifiquem els procediments de control de congestió (slow_start i increment linial)
# Modifiquem la finestra de congestió màxima


$tcp0 set tcpTick_ 0.01
$tcp0 set cwnd_ 40

$tcp1 set tcpTick_ 0.01
$tcp1 set cwnd_ 40

$tcp2 set tcpTick_ 0.01
$tcp2 set cwnd_ 40



# Aturem la simulació als 20 s.
$ns at 20.0 "finish"


#Executem la simulació
$ns run
