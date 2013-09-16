#!/bin/bash
# path to .bashrc, .zshrc, etc.
export RC='~/.bashrc'

logfile=server.log
highbeep="-l 50 -f 900"
midbeep="-l 50 -f 600"
lowbeep="-l 50 -f 500"
echologin="Played login beep"
echologout="Played disconnect beep"

while true
do
	while inotifywait -e modify $logfile
	do
		string=`tail -n-1 $logfile`;
		if [[ "$string" == *" logged in with entity id "* ]]
		then
			echo "$echologin" >> $logfile
			echo "$echologin"
			screen -dmS loginbeep beep $midbeep -n $highbeep
		elif [[ "$string" == *" lost connection: "* ]]
		then
			echo "$echologout" >> $logfile
			echo "$echologout"
			screen -dmS logoutbeep beep $midbeep -n $lowbeep
		fi
	done
done
