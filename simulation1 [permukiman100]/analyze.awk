# s 1.000000000 _0_ AGT  --- 0 tcp 40 [0 0 0 0] ------- [0:0 1:0 32 0] [0 0] 0 0
# r 1.000000000 _0_ RTR  --- 0 tcp 40 [0 0 0 0] ------- [0:0 1:0 32 0] [0 0] 0 0

# $1 -> Event
# $2 -> Time
# $3 -> Node id
# $4 -> Layer/Level
# $5 -> Flags
# $6 -> Sequence Number
# $7 -> Packet Type
# $8 -> Packet Size 

# ========================================================================
# startTime, stopTime, sendPackets, receivedPackets, AVG Throughput, PDR
# ========================================================================

#!/bin/awk -f
{
	event = $1
	time = 0 + $2 # Make sure that "time" has a numeric type.
	node_id = $3
	pkt_size = 0 + $8
	level = $4

	if (level == "AGT" && event == "s" && $7 == "cbr") {
		sent++
	if (!startTime || (time < startTime)) {
		startTime = time
		}
	}

	if (level == "AGT" && event == "r" && $7 == "cbr") {
		receive++
	if (time > stopTime) {
		stopTime = time
		}

		recvdSize += pkt_size
		}
	}

END {
printf("=============== Start QoS ===============\n")
printf(".........................................\n")
printf("*startTime: \t\t %f\n",startTime)
printf("*stopTime: \t\t %f\n",stopTime)
printf(".........................................\n")
printf("*sentPackets: \t\t %d\n",sent)
printf("*receivedPackets: \t %d\n",receive)
printf(".........................................\n")
printf("*AVG Throughput [Kbps]:  %.2f\n",(recvdSize/(stopTime-startTime))*(8/1000));
printf("*Packet Delivery Ratio:  %.2f%\n",(receive/sent)*100);
printf("*Packet Loss:  \t\t %.2f%\n",((sent-receive)/sent)*100);
}

# ========================================================================
# AVG End to End Delay
# ========================================================================

BEGIN {
	seqno=-1;
	dp=0;
	rp=0;
	cnt=0;
	}

	{
	if($4=="AGT"&&$1=="s"&&seqno<$6)
	{
	seqno=$6;
	}
	else if(($4=="AGT")&&($1=="r"))
	{
	rp++;
	}
	else if($1=="D"&&$7=="tcp")
	{
	dp++;
	}


	# End2End Delay
	if($4=="AGT"&&$1=="s")
	{
	start_time[$6]=$2;
	}
	else if(($4=="AGT")&&($1=="r"))
	{
	end_time[$6]=$2;
	}
	else if($1=="D"&&$7="tcp")
	{
	end_time[$6]=-1;
	}
	}

END {
	for(i=0;i<=seqno;i++)
	{
	if(end_time[i]>0)
	{
	delay[i]=end_time[i]-start_time[i];
	cnt++;
	}
	else
	{
	delay[i]=-1;
	}
	}
	for(i=0;i<=seqno;i++)
	{
	if(delay[i]>0)
	{
	ssdelay=ssdelay+delay[i];
	}
	}

	ssdelay=ssdelay/(cnt+1);

printf("*AVG E2E Delay [dtk]: \t %.5f\n",ssdelay);
printf(".........................................\n")
printf("================ End QoS ================\n")
}
