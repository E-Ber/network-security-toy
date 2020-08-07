#!/usr/bin/bash
#title          :guestList.sh
#description    :a script to help monitor the devices connected to a network.
#prepared for   :CIS-2150 Intro to Linux | Professor Tyler Whitney
#author         :Eric Berlin
#date           :2020-07-3
###Check if root access. It is needed to run the Nmap utility.This also makes it so that the log file can not be altered by someone without admin rights.
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Operation failed. Are you root?" >&2 #error reporting to stderr
    exit
fi

###check if log file exists, make one if needed.
if ! [[ -f '/var/log/macaddrs.log'  ]]; then
    echo "Log file not found. Creating log file: '/var/log/macaddrs.log'" >&2 
    touch '/var/log/macaddrs.log'
fi

###make and populate temporary file of subnets
interfacestemp=$(mktemp)
ifconfig | grep -P -o '(?<=broadcast\ )([0-9]{1,3}[\.]){3}[0-9]{1,3}'>"$interfacestemp"
sed -i 's/255/0/g' "$interfacestemp"

###main

#run through the interfacetemp temp file and...
cat "$interfacestemp" | while read -r _interface ; #basically 'for line in file', or in this case, 'for ipaddr in file'... 	
    do

        ###prepare input for nmap
		slash=32
		echo "Scanning address range starting at: $_interface..."
		IFS='.' read -ra  _addr_as_arr<<<"$_interface"
			for i in ${_addr_as_arr[@]};
				do
					if [ $i == 0 ];
						then
							((slash-=8))
					fi
				done
		
        #prepare timestamp variable:
		timeStamp=`date +%F_%T`
		neverBeforeSeen=$(mktemp)

        #run nmap, alter log as needed.
		nmapOut="`nmap -sn -P $_interface\/$slash`"
        echo "$nmapOut"
		_devices="`echo $nmapOut | grep -P -o '(?<=MAC\ Address\:\ )([0-9A-F]{2}[\:]){5}([0-9A-F]{2})'`"
		for device in $_devices;
			do
				if grep -q $device '/var/log/macaddrs.log' ;
					then
                        #update timeStamp. This line was kind of a nightmare, but I got it to work, and I'm very happy with it.
						perl -p -i.orig -e 's/(?<='$device', [0-9]{4}-[0-9]{2}-[0-9]{2}_([0-9]{2}:){2}[0-9]{2}, ).*/'$timeStamp'/g' '/var/log/macaddrs.log'
					else
                        #add the new device to log and grab its data from nmapOut var from earlier
                        echo $device, $timeStamp, $timeStamp >> '/var/log/macaddrs.log'
                        #TODO. These data need to be parsed and saved outside of this loop, to create the alert message that will be shown later.
					    $_device_data_raw+="`echo $nmapOut | grep -B 3 $device`"
                fi
			done
	done

# cleanup
rm "$interfacestemp"
