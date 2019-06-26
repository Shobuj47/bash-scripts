#!/bin/bash

echo "########################################################################"
echo "#                 Processlist $(date "+%d-%m-%Y %H:%M")                         #"
echo "########################################################################"
echo $(free -m)


printf "%-10s%-15s%-15s%s\n" "PID" "OWNER" "MEMORY" "COMMAND"

function sysmon_main(){
	RAWIN=$(ps -o pid,user,%mem,command ax | grep -v PID | awk '/[0-9]*/{print $1 ":" $2 ":" $4}')
	
	for i in $RAWIN
	do
		PID=$(echo $i | cut -d: -f1)
		OWNER=$(echo $i | cut -d: -f2)
		COMMAND=$(echo $i | cut -d: -f3)
		MEMORY=$(pmap $PID | tail -n 1 | awk '/[0-9]K/{print $2}')
		printf "%-10s%-15s%-15s%s\n" "$PID" "$OWNER" "$MEMORY" "$COMMAND"
		done
}

sysmon_main | sort -bnr -k3
