#!/bin/bash

while getopts "H:C:m:w:c:h" OPT; do
	case $OPT in
		"H") host=$OPTARG;;
		"C") community=$OPTARG;;
		"m") mode=$OPTARG;;
		"w") warning=$OPTARG;;
		"c") critical=$OPTARG;;
		"h") 
			echo "Syntax:  $0 -H <host address> -C <snmp community> -m <mode> -w <pct used warning> -c <pct used critical>"
			exit 3
		;;
	esac
done

function bytesToHuman(){
    b=${1:-0}; d=''; s=0; S=(Bytes {K,M,G,T,E,P,Y,Z}iB)
    while ((b > 1024)); do
        d="$(printf ".%02d" $((b % 1024 * 100 / 1024)))"
        b=$((b / 1024))
        let s++
    done
    echo "$b$d ${S[$s]}"
}

check_cpu (){
	idle_oid=".1.3.6.1.4.1.2021.11.11.0"
	user_oid=".1.3.6.1.4.1.2021.11.9.0"
	system_oid=".1.3.6.1.4.1.2021.11.10.0"

	output=$(snmpget -t 50 -v 2c -c $community $host $idle_oid $user_oid $system_oid)

	cpu_idle=$(echo "$output" |awk 'FNR==1 {print $4}')
	cpu_used=$((100-cpu_idle))
	cpu_user=$(echo "$output" |awk 'FNR==2 {print $4}')
	cpu_system=$(echo "$output" |awk 'FNR==3 {print $4}')

	if [[ $cpu_used -ge $critical ]]; then
		status=2
		message="Critical -"
	else if [[ $cpu_used -ge $warning ]]; then
   		status=1
   		message="Warning -"
	else
   		status=0
   		message="OK -"
	fi
	fi

	echo "CPU $message Usage: $cpu_used% | cpu=$cpu_used%;$warning;$critical user=$cpu_user% system=$cpu_system% idle=$cpu_idle%"
	exit $status
}


check_memory (){
	swap_total_oid=".1.3.6.1.4.1.2021.4.3.0"
	swap_free_oid=".1.3.6.1.4.1.2021.4.4.0"
	memory_total_oid=".1.3.6.1.4.1.2021.4.5.0"
	memory_free_oid=".1.3.6.1.4.1.2021.4.11.0"

	output=$(snmpget -t 50 -v 2c -c $community $host $swap_total_oid $swap_free_oid $memory_total_oid $memory_free_oid)

	swap_total=$(echo "$output" |awk 'FNR==1 {print $4}')
	swap_free=$(echo "$output" |awk 'FNR==2 {print $4}')
	memory_total=$(echo "$output" |awk 'FNR==3 {print $4}')
	memory_free=$(echo "$output" |awk 'FNR==4 {print $4}')
	swap_free_pct=$(echo "scale=0; $swap_free*100/$swap_total" | bc)
	memory_free_pct=$(echo "scale=0; $memory_free*100/$memory_total" | bc)

	swap_used=$((100-$swap_free_pct))
	memory_used=$((100-$memory_free_pct))

	memory_warning=$(echo $warning |cut -d ',' -f 1)
	swap_warning=$(echo $warning |cut -d ',' -f 2)

	memory_critical=$(echo $critical |cut -d ',' -f 1)
	swap_critical=$(echo $critical |cut -d ',' -f 2)

	if [[ $memory_used -ge $memory_critical ]] || [[ $swap_used -ge $swap_critical ]]; then
		status=2
		message="Critical -"
	else if [[ $memory_used -ge $memory_warning ]] || [[ $swap_used -ge $swap_warning ]]; then
   		status=1
   		message="Warning -"
	else
   		status=0
   		message="OK -"
	fi
	fi

	echo "MEMORY $message Usage: $memory_used% (Swap: $swap_used%) | memory=$memory_used%;$memory_warning;$memory_critical swap=$swap_used%;$swap_warning;$swap_critical"
	exit $status
}

check_load (){
	load1_oid=".1.3.6.1.4.1.2021.10.1.3.1"
	load5_oid=".1.3.6.1.4.1.2021.10.1.3.2"
	load15_oid=".1.3.6.1.4.1.2021.10.1.3.3"

	output=$(snmpget -t 50 -v 2c -c $community $host $load1_oid $load5_oid $load15_oid)

	load1_long=$(echo "$output" |awk 'FNR==1 {print $4}'|sed -e 's/^"//'  -e 's/"$//')
	load5_long=$(echo "$output" |awk 'FNR==2 {print $4}'|sed -e 's/^"//'  -e 's/"$//')
	load15_long=$(echo "$output" |awk 'FNR==3 {print $4}'|sed -e 's/^"//'  -e 's/"$//')

	load1=$(echo $load1_long|cut -d '.' -f 1)
	load5=$(echo $load5_long|cut -d '.' -f 1)
	load15=$(echo $load15_long|cut -d '.' -f 1)

	if [[ $load1 -ge $critical ]] || [[ $load5 -ge $critical ]] || [[ $load15 -ge $critical ]]; then
		status=2
		message="Critical -"
	else if [[ $load1 -ge $warning ]] || [[ $load5 -ge $warning ]] || [[ $load15 -ge $warning ]]; then
   		status=1
   		message="Warning -"
	else
   		status=0
   		message="OK -"
	fi
	fi

	echo "LOAD AVERAGE $message $load1_long,$load5_long,$load15_long | load1=$load1_long;$warning;$critical load5=$load5_long;$warning;$critical load15=$load15_long;$warning;$critical"
	exit $status
}

check_disk (){
	used_pct_oid=".1.3.6.1.4.1.2021.9.1.9.1"
	disk_total_oid=".1.3.6.1.4.1.2021.9.1.6.1"
	disk_free_oid=".1.3.6.1.4.1.2021.9.1.7.1"

	output=$(snmpget -t 50 -v 2c -c $community $host $used_pct_oid $disk_total_oid $disk_free_oid)

	used_pct=$(echo "$output" |awk 'FNR==1 {print $4}')
	total_kbytes=$(echo "$output" |awk 'FNR==2 {print $4}')
	free_kbytes=$(echo "$output" |awk 'FNR==3 {print $4}')
	total_bytes=$((1024*$total_kbytes))
	free_bytes=$((1024*$free_kbytes))
	total=$(bytesToHuman $total_bytes)
	free=$(bytesToHuman $free_bytes)

	if [[ $used_pct -ge $critical ]]; then
		status=2
		message="Critical -"
	else if [[ $used_pct -ge $warning ]]; then
   		status=1
   		message="Warning -"
	else
   		status=0
   		message="OK -"
	fi
	fi

	echo "DISK USAGE $message Usage: $used_pct% (Total: $total - Free: $free) | used_pct=$used_pct%;$warning;$critical total=$total_bytes free=$free_bytes"
	exit $status
}

check_users (){
	users_oid=".1.3.6.1.2.1.25.1.5.0"

	output=$(snmpget -t 50 -v 2c -c $community $host $users_oid)

	users=$(echo "$output" |awk 'FNR==1 {print $4}')

	if [[ $users -ge $critical ]]; then
		status=2
		message="Critical -"
	else if [[ $users -ge $warning ]]; then
   		status=1
   		message="Warning -"
	else
   		status=0
   		message="OK -"
	fi
	fi

	echo "USERS $message Active sessions: $users | users=$users;$warning;$critical"
	exit $status
}

check_procs (){
	procs_oid=".1.3.6.1.2.1.25.1.6.0"

	output=$(snmpget -t 50 -v 2c -c $community $host $procs_oid)

	procs=$(echo "$output" |awk 'FNR==1 {print $4}')

	if [[ $procs -ge $critical ]]; then
		status=2
		message="Critical -"
	else if [[ $procs -ge $warning ]]; then
   		status=1
   		message="Warning -"
	else
   		status=0
   		message="OK -"
	fi
	fi

	echo "PROCS $message Processes: $procs | procs=$procs;$warning;$critical"
	exit $status
}

check_states (){
	states_oid=".1.3.6.1.4.1.12325.1.200.1.3.1.0"

	output=$(snmpget -t 50 -v 2c -c $community $host $states_oid)

	states=$(echo "$output" |awk 'FNR==1 {print $4}')

	if [[ $states -ge $critical ]]; then
		status=2
		message="Critical -"
	else if [[ $states -ge $warning ]]; then
   		status=1
   		message="Warning -"
	else
   		status=0
   		message="OK -"
	fi
	fi

	echo "STATES $message States: $states | states=$states;$warning;$critical"
	exit $status
}

case $mode in
	"cpu") check_cpu;;
	"memory") check_memory;;
	"load") check_load;;
	"disk") check_disk;;
	"users") check_users;;
	"procs") check_procs;;
	"states") check_states;;
	"*")
		echo "Available modes: cpu memory disk load"
		exit 3
	;;
esac

