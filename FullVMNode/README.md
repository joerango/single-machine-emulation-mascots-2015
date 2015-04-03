# Ubuntu 14.04.2 Image for Network Emulation Experiments
This image was tested on Ubuntu Server 14.04.1 with Linux 3.13

####Required software:
* qemu (packages: qemu-system-x86, qemu-kvm)
* python2.7
* netifaces modeul (package: python-netifaces)


####If you have problems initializing bridge interfaces in qemu, run the following command:
```
echo 'allow all' > /etc/qemu/bridge.conf
```
