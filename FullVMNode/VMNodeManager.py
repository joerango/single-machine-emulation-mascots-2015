import sys, shlex, subprocess
import netifaces, socket

#Modify the following variables to the abolsute path of the VM Image and the 'secret' key.
VM_LOCATION = 'image/UbuntuMinimalServer.img'
SSH_KEY = 'image/id_rsa'

def executeCommandList(commands):
    for cmd in commands:
        print "Executing", cmd
        args = shlex.split(cmd)
        ret = subprocess.call(args)
        if ret != 0:
            return ret
    return 0

def executeCommandInBackground(command):
    print "Executing in BG: ", command
    args = shlex.split(command)
    proc = subprocess.Popen(args)
    proc.poll()
    return proc.returncode

def createBridgeForIntf(interfaceName, bridgeName):
    commands = []
    commands.append('brctl addbr {name}'.format(name=bridgeName))
    commands.append('brctl addif {bridge} {interface}'.format(bridge=bridgeName, interface=interfaceName))
    commands.append('ifconfig {bridge} up'.format(bridge=bridgeName))
    commands.append('ifconfig {interface} up'.format(interface=interfaceName))
    return executeCommandList(commands)

def startVM(bridgeList, sshPort, waitForStartup=True):
    commands = []
    cmd = "qemu-system-i386 -enable-kvm -net nic,vlan=0,macaddr=DE:AD:BE:EF:71:1E -net 'user,hostfwd=tcp::{port}-:22' ".format(port=sshPort)
    idx = 1
    for br in bridgeList:
        cmd = cmd + "-net nic,vlan={vlan},model=virtio -net 'bridge,vlan={vlan},br={bridge}' ".format(vlan=str(idx),bridge=br)
        idx = idx + 1
        
    cmd = cmd + "-m 512M -serial file:{port}.log -display none {VM}".format(port=sshPort, VM=VM_LOCATION)
    ret = executeCommandInBackground(cmd)
    if ret != None:
        return 1

    if waitForStartup:
        waitCmd = "nc -l 9000"
        commands.append(waitCmd)

    return executeCommandList(commands)

def runCommandInVM(sshPort, command):
    if checkPortIsFree(sshPort):
        print "Error: No machine available on port {port}. Aborting...".format(port=sshPort)
        return 1
    cmd = []
    cmd.append('ssh root@localhost -o "StrictHostKeyChecking no" -p{port} -Y -i {sshkey} "{command}"'.format(port=sshPort, sshkey = SSH_KEY, command=command))
    return executeCommandList(cmd)

def checkPortIsFree(port):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(0.5)
        s.connect(('127.0.0.1',int(port)))
        s.close()
        #Connection was successful. Port is NOT free.
        return False
    except:
        return True

def clearAllBridges():
    print "WARNING: All bridges with the prefix 'br-' will be deleted including ones not created by this tool."
    commands = []
    availableIntfs = netifaces.interfaces()
    for intf in availableIntfs:
        if 'br-' in intf:
            commands.append('ifconfig {intf} down'.format(intf=intf))
            commands.append('brctl delbr {intf}'.format(intf=intf))
    return executeCommandList(commands)

def createVMNode(managementPort, intfList):
    if not checkPortIsFree(managementPort):
        print 'Port {port} is already in use. Aborting...'.format(port=managementPort)
        return 1
    availableIntfs = netifaces.interfaces()
    if any(i not in availableIntfs for i in intfList):
        print "Unable to find specified interfaces. Aborting..."
        return 1

    vmBridges = []
    for intf in intfList:
        if 'br-'+intf in availableIntfs:
            print 'Interface {intf} is already part of a bridge. Make sure you\'ve not added it to another VM. Aborting...'.format(intf=intf)
            return 1
        ret = createBridgeForIntf(intf,'br-'+intf)
        vmBridges.append('br-'+intf)
        if ret != 0:
            print 'Bridge creation failed. Aborting...'
            return ret

    ret = startVM(vmBridges,managementPort)
    if ret == 0:
        print 'VM on port {port} successfully started.'.format(port=managementPort)
    else:
        print 'Starting VM on port {port} failed.'.format(port=managementPort)
    return ret



if __name__=='__main__':
    debug = False
    if debug:
        import ptvsd
        ptvsd.enable_attach(None)
        print "Waiting for debugger to attach..."
        ptvsd.wait_for_attach()
        print "Debugger attached."
    
    intfs = ""
    if len(sys.argv) < 2:
        cmd = ''
    else:
        cmd = str.strip(sys.argv[1])

    if cmd == 'removebridges':
        ret = clearAllBridges()
        exit(ret)
    elif cmd == 'startvm':
        if len(sys.argv) != 4:
            print "Usage: {exe} startvm <network interfaces to assign to vm(comma separated)> <management port to assign to vm>".format(exe=sys.argv[0])
            exit(1)

        intfs = str.strip(sys.argv[2]).split(',')
        port = str.strip(sys.argv[3])
        ret = createVMNode(port,intfs)
        exit(ret)

    elif cmd == 'runcmd': 
        if len(sys.argv) != 4:
            print "Usage: {exe} runcmd <vm management port> <command (use quotes for commands containing spaces)>".format(exe=sys.argv[0])
            exit(1)

        port = str.strip(sys.argv[2])
        vmcmd = str.strip(sys.argv[3])
        ret = runCommandInVM(port, vmcmd)
        exit(ret)
    
    elif cmd == 'xterm': 
        if len(sys.argv) != 3:
            print "Usage: {exe} xterm <vm management port>".format(exe=sys.argv[0])
            exit(1)

        port = str.strip(sys.argv[2])
        ret = runCommandInVM(port, "xterm")
        exit(ret)   
   
    elif cmd == 'shutdown': 
        if len(sys.argv) != 3:
            print "Usage: {exe} shutdown <vm management port>".format(exe=sys.argv[0])
            exit(1)

        port = str.strip(sys.argv[2])
        ret = runCommandInVM(port, "shutdown -h now")
        exit(ret)   
    else:
        print "Usage: {exe} <command> <parameters>".format(exe=sys.argv[0])
        print "Commands:"
        print "\t removebridges"
        print "\t startvm\t <network interfaces> <management port to assign to vm>"
        print "\t xterm\t <vm management port>"
        print "\t runcmd\t <vm management port> <command>"
        print "\t shutdown\t <vm management port>"
        exit(1)
    

    exit(0)
