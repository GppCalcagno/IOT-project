print "********************************************";
print "*                                          *";
print "*             TOSSIM Script                *";
print "*                                          *";
print "********************************************";

import sys;
import time;


from TOSSIM import *;

t = Tossim([]);

t = Tossim([]);


topofile="topology.txt";
modelfile="meyer-heavy.txt";

simulation_out = open("SIMULATION", "w");
out = simulation_out;


print >>out,"Initializing mac....";
mac = t.mac();
print >>out,"Initializing radio channels....";
radio=t.radio();
print >>out,"    using topology file:",topofile;
print >>out,"    using noise file:",modelfile;
print >>out,"Initializing simulator....";
t.init();


#Add debug channel
print >>out,"Activate debug message on channel boot"
t.addChannel("boot",out);

print >>out,"Activate debug message on channel status"
t.addChannel("status",out);

print >>out,"Activate debug message on channel timer"
t.addChannel("timer",out);

print >>out,"Activate debug message on channel radio"
t.addChannel("radio",out);


#Create nodes

#Create node 1
print >>out,"Creating node 0 (master)"
node0 =t.getNode(0);
time0 = 0*t.ticksPerSecond();
node0.bootAtTime(time0);
print >>out,">>>Node 0 boots at time",  time0/t.ticksPerSecond(), "[sec]";

#Create node 2
print >>out,"Creating node 1"
node1 =t.getNode(1);
time1 = 1*t.ticksPerSecond();
node1.bootAtTime(time1);
print >>out,">>>Node 1 boots at time",  time1/t.ticksPerSecond(), "[sec]";

#Create node 3
print >>out,"Creating node 2"
node2 =t.getNode(2);
time2 = 2*t.ticksPerSecond();
node2.bootAtTime(time2);
print >>out,">>>Node 2 boots at time",  time2/t.ticksPerSecond(), "[sec]";

#Create node 4
print >>out,"Creating node 3"
node3 =t.getNode(3);
time3 = 3*t.ticksPerSecond();
node3.bootAtTime(time3);
print >>out,">>>Node 3 boots at time",  time3/t.ticksPerSecond(), "[sec]";


print >>out,"Creating radio channels..."
f = open(topofile, "r");
lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
    print >>out,">>>Setting radio channel from node ", s[0], " to node ", s[1], " with gain ", s[2], " dBm"
    radio.add(int(s[0]), int(s[1]), float(s[2]))


#creation of channel model
print >>out,"Initializing Closest Pattern Matching (CPM)...";
noise = open(modelfile, "r")
lines = noise.readlines()
compl = 0;
mid_compl = 0;

print >>out,"Reading noise model data file:", modelfile;
print >>out,"Loading:",
for line in lines:
    str = line.strip()
    if (str != "") and ( compl < 10000 ):
        val = int(str)
        mid_compl = mid_compl + 1;
        if ( mid_compl > 5000 ):
            compl = compl + mid_compl;
            mid_compl = 0;
            sys.stdout.flush()
        for i in range(0, 4):
            t.getNode(i).addNoiseTraceReading(val)
print >>out,"Done!";


for i in range(0, 4):
    print >>out,">>>Creating noise model for node:",i;
    t.getNode(i).createNoiseModel()

print >>out,"Start simulation with TOSSIM! \n\n\n";
print "Start simulation with TOSSIM! \n";

for i in range(0,10000):
	if (i == 5000): 
		node1.turnOff();
		node3.turnOff();
		print >>out,"\n>>SHUTTING DOWN CHILDREN<<\n"	
	t.runNextEvent()
	
print >>out,"\n\n\nSimulation finished!";
print "\nSimulation finished!";

simulation_out.close()



