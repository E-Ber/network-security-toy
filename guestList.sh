#description	:a script to help monitor the devices connected to a network.
#author     	:EBerlin
#date		    :2020-07-31

#The nmap utility needs root priveledges to see mac addresses. First we will check to make sure the user is root.

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "You must be root."
    exit
fi

if ! [[ -f .addrs.log  ]]; then
	echo "Log file not found in current directory. Creating log file: .addrs.log"
	touch .addrs.log
else
	echo "Log file found."
fi

newEntries=0
#Run ifconfig. Pipe the output to grep. Keep the broadcast IP addresses only.
for OUTPUT in $(ifconfig | grep -P -o '(?<=broadcast\ )([0-9]{1,3}[\.]){3}[0-9]{1,3}')

#Scan each IP range...
	do
		#Instantiate the "slash" variable. We will use it later. 
		slash=32
		#announce the range being scanned
		echo "Scanning ${OUTPUT//255/0}..."
		#Replace any "255" with "0"
		IPRANGE="${OUTPUT//255/0}" 
		#Read each of those IP addresses into its own array, delimited by the . character.
		IFS='.' read -ra  ARR<<<"$IPRANGE"
			#For each entry in the array...
			for i in ${ARR[@]}
				do
						#If the entry is 0, it means that it was masked. Decrease the slash variable to increase the range of addresses that nmap will search.
						echo "look at ${ARR[@]}" 
						if [ $i == 0 ]; then
							((slash-=8))
						fi
				done
		
		###working to this line###

		#Using the variables from above as arguments, run nmap. The options here dictate that the scan should deal with pings but not ports. 
		list=($(nmap -sn -P $IPRANGE\/$slash | grep -P -o '(?<=MAC\ Address\:\ )([0-9A-F]{2}[\:]){5}([0-9A-F]{2})' ))

		echo $list
		for range in $list
			do
				timeNow=`date +%F_%T`
				echo "time is $timeNow"
				for addr in  ${list[@]} 
					do
						if ! grep -q ${addr[@]} .addrs.log; then
							echo ${addr[@]}, $timeNow, $timeNow >> .addrs.log 
							echo "New entry added to log file."
							newEntries+=1
						else
							perl -pe 's/(?<='${addr[@]}'\,\ .{21}).{19}/'$timeNow'/g' .addrs.log
							echo "Entry updated in log file."
						fi
					done
			done
	done
if [[ $newEntries>=0 ]]; then
	notify-send -u normal "$newEntries new entries added to .addrs.log at `date +%T`"\
		"You should probably look into that."
fi
