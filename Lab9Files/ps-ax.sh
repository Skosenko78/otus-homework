#!/usr/bin/env bash

c_ticks=$(getconf CLK_TCK)
echo -e "PID \tTTY \t STAT \t\tTIME \tCOMMAND"

for id in $(ls /proc | grep '[0-9]' | sort -n) 
do
	if [ -d /proc/$id ]; then
		a_stat=($(sed 's/ /\n/g' /proc/$id/stat))
		r_array=($(sed 's/ /\n/' /proc/uptime))
		t_time=$((${a_stat[13]} + ${a_stat[14]}))
		seconds=$(bc <<< "scale=2;(${r_array[0]}-${a_stat[21]})/$c_ticks")
		Res[1]=$id
		Res[2]=$(readlink /proc/$id/fd/0)
		if [ $? -eq 0 ]; then
			if [[ ${Res[2]} == *tty* ]] || [[ ${Res[2]} == *pts/* ]]
			then
				Res[2]=${Res[2]#/dev/}
			else
				Res[2]='?'
			fi
		else
			Res[2]='?'
		fi
		Res[3]=$(cat /proc/$id/status | grep State | awk -F: '{print $2}' | sed  's/^[[:space:]]*//')
		Res[4]=$(bc <<< "scale=2; 100*($t_time/$c_ticks)/$seconds")
		Res[5]=$(tr '\0' ' ' < /proc/$id/cmdline)
		if [ "${Res[5]}" = '' ]; then
			Res[5]="[$(cat /proc/$id/comm)]"
		fi
		( IFS=$'\t'; echo "${Res[*]}" )
	fi
done

exit 0