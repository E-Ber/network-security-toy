#!/usr/bin/env bash

#==========================================================================#
#title        :guestList.sh                                                #   
#description  :a script to help monitor the devices connected to a network.#
#prepared for :CIS-2150 Intro to Linux | Professor Tyler Whitney           #
#author       :Eric Berlin                                                 #
#date         :2020-07-30                                                  #
#==========================================================================#

#Check if root access. It is needed to run the Nmap utility.This also makes it so that the log file can not be altered by someone without admin rights.
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Operation failed. Are you root?" >&2 #error reporting to stderr
    exit
fi

#check if log file exists, make one if needed.
if ! [[ -f '/var/log/macaddrs.log'  ]]; then
    echo "Log file not found. Creating log file: '/var/log/macaddrs.log'" >&2 
    touch '/var/log/macaddrs.log' && chmod 600 /var/log/macaddrs.log #nobody without root really needs to see this info. This also helps protect from MAC spoofing very slightly I think.
fi

newDevices=$(mktemp)

#make and populate temporary file of subnets
ifconfig_out=$(ifconfig)
echo "Gathering address ranges..."
_local_interfaces=$(echo $ifconfig_out | grep -P -o '(?<=broadcast\ )([0-9]{1,3}[\.]){3}[0-9]{1,3}')

#main
#run through the _local_interfaces and...
echo "$_local_interfaces" | sed 's/255/0/g' | while read -r _interface ; #basically 'for line in ... do' 	
    do

        #prepare input for nmap
		slash=32
		IFS='.' read -ra  _addr_as_arr<<<"$_interface"
			for i in ${_addr_as_arr[@]};
				do
					if [ $i == 0 ];
						then
							((slash-=8))
					fi
				done
		echo "Scanning $_interface range..."
        #prepare time_stamp variable
		time_stamp=`date +%F_%T`

        #run nmap, alter log as needed.
		nmapOut="`nmap -sn $_interface\/$slash`"
        #echo "$nmapOut"                                                                                                            #debug
		_devices="`echo $nmapOut | grep -P -o '(?<=MAC\ Address\:\ )([0-9A-F]{2}[\:]){5}([0-9A-F]{2})'`"
		for device in $_devices ;
			do
                #echo $device                                                                                                       #debug
				if grep -q $device '/var/log/macaddrs.log' ;
				
                    then
                        #update time_stamp. This line was kind of a nightmare, but I got it to work, and I'm very happy with it.
						perl -p -i.orig -e 's/(?<='$device',\
                            [0-9]{4}-[0-9]{2}-[0-9]{2}_([0-9]{2}:){2}[0-9]{2}, ).*/'$time_stamp'/g' '/var/log/macaddrs.log'
                        #echo "updated previously seen device: $device with datetime: $time_stamp"                                  #debug

                    else
                        #add the new device to log and grab its data from nmapOut var from earlier
                        echo $device, $time_stamp, $time_stamp >> '/var/log/macaddrs.log'
                        echo "$nmapOut" | grep -E '^Nmap scan report|^MAC Address' | grep -i $device -B 1 | sed -e '/Nmap/ { N; s/\n/\ / }; /^--$/d; s/Nmap scan report for//' >>$newDevices
				fi
			done
	done
if [ -s $newDevices ] ; then
        sort -uo $newDevices $newDevices
        echo -e "\e[31;5m ***** NEW NETWORK DEVICES DETECTED *****\e[25m" && cat $newDevices && tput sgr0
        #to recieve a notice of this event in email, personalize and uncomment the next line. Make sure you have mail installed. You can check with your package manager, or `mail -V` to print the version you have installed.
        #$(cat "newDevices") | mail -s 'Unrecognized devices detected on network' user@email.domain
    else
        echo -e "\e[30;102mNO NEW DEVICES DETECTED" && tput sgr0
fi

rm -f $newDevices
