#! /bin/bash

# Idea taken from cloudlogbashcat.sh 
# A simple script to keep Cloudlog in synch with rigctld or flrig.
# Copyright (C) 2018  Tony Corbett, G0WFV
#
# optimized version for Cloudlog and SparkSDR. It doies not need rigctld started upfront
# advantage: rigctld terminates if SparkSDR is not available. This script could be startet @reboot
# it waits until SparkSDR is available and pushes the data to Cloudlog
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

DEBUG=0

rigFreq=0
rigOldFreq=1

rigMode="MATCH"
rigOldMode="NO MATCH"

delay=1
n=0

# load in config ...
source /home/pi/Cloudlog/cloudlogspark.conf


while true; do
			rigFreq=$(rigctl -r $host:$port -m2 f)
			rigMW=$(rigctl -r $host:$port -m2 m)
			
			rigMode=$(grep [A-Z] <<<$rigMW)
			if [ "$rigMode" = "" ]; then 
			    rigMode="?"
			fi
			rigWidth=$(grep [0-9] <<<$rigMW)
			
			# sparksdr delivers not all modes, try to guess them
			if [ "$rigMode" = "?" ]; then 
			    case $rigFreq in
				136000)
				    rigMode="USB"
				    ;;
				474200)
				    rigMode="USB"
				    ;;
				1836000)
				    rigMode="FT8"
				    ;;
				3573000)
				    rigMode="FT8"
				    ;;
				3576000)
				    rigMode="FT4"
				    ;;
				3568600)
				    rigMode="WSPR"
				    ;;
				5357000)
				    rigMode="FT8"
				    ;;
				5366000)
				    rigMode="WSPR"
				    ;;
				7074000)
				    rigMode="FT8"
				    ;;
				7038600)
				    rigMode="WSPR"
				    ;;
				7047500)
				    rigMode="FT4"
				    ;;
				10136000)
				    rigMode="FT8"
				    ;;
				10138700)
				    rigMode="WSPR"
				    ;;
				10140000)
				    rigMode="FT4"
				    ;;
				14074000)
				    rigMode="FT8"
				    ;;
				14080000)
				    rigMode="FT4"
				    ;;
				14095600)
				    rigMode="WSPR"
				    ;;
				18100000)
				    rigMode="FT8"
				    ;;
				18104000)
				    rigMode="FT4"
				    ;;
				18104600)
				    rigMode="WSPR"
				    ;;
				21074000)
				    rigMode="FT8"
				    ;;
				21094600)
				    rigMode="WSPR"
				    ;;
				21140000)
				    rigMode="FT4"
				    ;;
				24915000)
				    rigMode="FT8"
				    ;;
				24919000)
				    rigMode="FT4"
				    ;;
				24924600)
				    rigMode="WSPR"
				    ;;
				28070000)
				    rigMode="FT4"
				    ;;
				28074000)
				    rigMode="FT8"
				    ;;
				28124600)
				    rigMode="WSPR"
				    ;;
			    esac
			fi    
			
			if [ "$rigMode" = "?" ]; then 
			case $rigWidth in
			    USB)
				rigMode="SSB"
				;;
			    LSB)
				rigMode="SSB"
				;;
			    280)
				rigMode="WSPR"
				;;
			    4900)
				rigMode="JT9"
				;;
			    2850)
				rigMode="SSTV"
				;;
			    3000)
				rigMode="PSK"
				;;
			    16000)
				rigMode="FM"
				;;
			    44000)
				rigMode="HL2-DATA"
				;;
			    PKTUSB)
				rigMode="HL2-DATA"
				;;
			    PKTLSB)
				rigMode="HL2-DATA"
				;;
    			esac
			fi

  if [ "$n" -gt 600 ]; then
# make sure that at least every 10 min something is pushed to cloudlog, to prevent an error message (rig not responding)
    rigOldFreq=0
    n=0
    [[ $DEBUG -eq 1 ]] && printf  "%s   %s $(date +"%Y/%m/%d %H:%M")\n" $rigFreq $rigMode
 else 
    n=$((n+1))
  fi    

		
  if [ "$rigFreq" -ne "$rigOldFreq"  ] || [ "$rigMode" != "$rigOldMode"  ]; then
    # rig freq or mode changed, update Cloudlog
    [[ $DEBUG -eq 1 ]] && printf  "To Cloudlog: %s   %s $(date +"%Y/%m/%d %H:%M")\n" $rigFreq $rigMode
    rigOldFreq=$rigFreq
    rigOldMode=$rigMode

    curl --silent --insecure \
         --header "Content-Type: application/json" \
         ${cloudlogHttpAuth:+"--header"} \
         ${cloudlogHttpAuth:+"Authorization: $cloudlogHttpAuth"} \
         --request POST \
         --data "{ 
           \"key\":\"$cloudlogApiKey\",
           \"radio\":\"$cloudlogRadioId\",
           \"frequency\":\"$rigFreq\",
           \"mode\":\"$rigMode\",
           \"timestamp\":\"$(date -u +"%Y/%m/%d %H:%M")\"
         }" $cloudlogApiUrl >/dev/null 2>&1

    n=0
  fi

	sleep $delay
done

# Testcall, use in CLI, if script does not show any update in cloudlog
# curl --insecure --header "Content-Type: application/json" --request POST --data "{ \"key\":\"cl6key2520519d8\",\"radio\":\"HL2 R1\",\"frequency\":\"24911000\",\"mode\":\"FM\",\"timestamp\":\"2023/02/02 12:42\"}" https://192.168.1.1/index.php/api/radio
