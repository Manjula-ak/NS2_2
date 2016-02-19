ECEN602 HW5 NS2 Simulation 
(implementation of a small network in ns2)
-----------------------------------------------------------------

Team Number: 10
Member 1 # Li Wan 
Member 2 # Sama Avani 
---------------------------------------

Description/Comments:
--------------------
1. Created eight nodes H1 and H2 correspond to src1 and src2; R1 and R2 correspond to two different routers respectively; H3 and H4 correspond to rcv1 and rcv2. H6 to src3 and H5 to rcv3
2. Established appropriate links(duplex) wih DropTail and RED queue mechanism 
3. Created TCP agents and attached it to H1 and H2, UDP agents to H6
4. Added FTP traffic source over these TCP agents, CBR traffic over UDP
5. Created two TCP sinks and attached them to H3 and H4, UDP sink to H5
6. Recorded bandwidth data using set bw0 and set bw1 at the two sinks, set bw2 to the third sink.
7. Used four global variables sum_throughput1, sum_throughput2 sum_throughput3 and count to calculate the average throughput of src1, src2 and src3
4. Printed these results using puts. 

Usage Syntax:
-------------------
ns ns2.tcl <QUEUE STRATEGY> <SCENARIO_NO>

<QUEUE STRATEGY> is either of { DROPTAIL, RED }
<SCENARIO_NO> is either of { 1, 2}
