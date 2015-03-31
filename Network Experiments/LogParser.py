import sys, re

regexStr = '\[(?P<time>\d+.\d+)\].+time=(?P<rtt>\d+) ms'

pingLogPath = 'ping.log'
queueLogPath = 'queue.log'

if len(sys.argv) >= 3:
    pingLogPath = sys.argv[1]
    queueLogPath = sys.argv[2]

pingLogFile = open(pingLogPath,mode='r')

outputFile = open('ping.dat',mode='w')
outputFile.write('#Time    RTT in ms\n')

startTime = -1.0

for line in pingLogFile:
    m = re.match(regexStr, line)
    if m is not None:
        time = m.groups()[0]
        if startTime == -1.0:
            startTime = float(time)
            time = 0
        else:
            time = float(time) - startTime

        rtt = m.groups()[1]
        outputFile.write('{0} {1}\n'.format(time, rtt))

outputFile.close()
pingLogFile.close()


queueLogFile = open(queueLogPath,mode='r')

outputFiles = list()
outputFiles.append(open('queue1.dat',mode='w'))
outputFiles.append(open('queue2.dat',mode='w'))

outputFiles[0].write('#Time    Bytes   Packets\n')
outputFiles[1].write('#Time    Bytes   Packets\n')

time = 0
fileIndex = 0

for line in queueLogFile:
    parts = line.split()
    if len(parts) == 0 :
        continue
    elif len(parts) == 1 :
        time = float(parts[0]) - startTime
        fileIndex = 0
        continue
    bytes = parts[1].rstrip('b')
    packets = parts[2].rstrip('p')

    if bytes.count('K') > 0:
        bytes = str(int(bytes.rstrip('K'))*1024)
    
    outputFiles[fileIndex].write('{0} {1} {2}\n'.format(time, bytes, packets))
    fileIndex = fileIndex + 1

outputFiles[0].close()
outputFiles[1].close()
queueLogFile.close()


