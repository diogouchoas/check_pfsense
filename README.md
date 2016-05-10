# check_pfsense
Nagios Compliant check for PFSense Firewall appliances - Checks CPU, Memory, Disk, Load


# Examples

Check Memory Usage
```
./check_pfsense.sh -H 192.168.1.1 -C public -m memory -w 80 -c 90
MEMORY OK - Usage: 10% (Swap: 0%) | memory=10%;80;90 swap=0%;80;90
```
Check CPU Usage
```
./check_pfsense.sh -H 192.168.1.1 -C public -m cpu -w 80 -c 90
CPU OK - Usage: 2% | cpu=2%;80;90 user=0% system=2% idle=98%
```
Check Load Average
```
./check_pfsense.sh -H 192.168.1.1 -C public -m load -w 2 -c 4
LOAD AVERAGE OK - 0.15,0.08,0.07 | load1=0.15;2;4 load5=0.08;2;4 load15=0.07;2;4
```
Check Disk Usage
```
./check_pfsense.sh -H 192.168.1.1 -C public -m disk -w 80 -c 90
DISK USAGE OK - Usage: 79% (Total: 435.63 GiB - Free: 82.77 GiB) | used_pct=79%;80;90 total=467758092288 free=88881172480
```


