#!/bin/bash

# Summary: This script tries to obtain the name of an IP using dig
# Author: Felipe Molina (@felmoltor)

function isValidIP()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

#################

function resolveDNSServerName()
{
    echo $(dig +short $1 @8.8.8.8)
}

##########
# CONFIG #
##########

IP_FILE=""
DNS_SERVER="8.8.8.8"
SCANRANGE_C=0 
OUTPUT="$(date +%Y%m%d_%H%M%S).bulkreverse.csv"

################
# CHECK PARAMS #
################

if [[ -f $1 ]];then
    IP_FILE=$1
else
    echo "Usage: $0 <ip_list_to_reverse_name> <[SCAN_C|NOSCAN_C]> [<DNS_server_to_ask>]"
    exit 1
fi

if [[ "$2" -eq "SCAN_C" ]];then
    SCANRANGE_C=1
fi

isValidIP $3
valid_ip=$?
if [[ $valid_ip == 0 ]];then
    DNS_SERVER=$3
else
    dns_resuelto=$(resolveDNSServerName $3)
    isValidIP $dns_resuelto
    valid_ip=$?
    if [[ $valid_ip == 0 ]];then
        DNS_SERVER=$dns_resuelto
    else
        echo "Wrong IP address for DNS server. Using $DNS_SERVER by default" 1>&2
    fi
fi

########
# MAIN #
########

# Create output CSV file
echo "FROM;IP;NAME" > $OUTPUT


for ip in `cat $IP_FILE`; do
    isValidIP $ip
    valid_ip=$?
    if [[ $valid_ip == 0 ]];then
        echo "" 
        echo -e "FILE;$ip;$(dig -x $ip @$DNS_SERVER +short | tr '\n' ',' | sed s/,$//)" >> $OUTPUT 
        echo -e "=> $ip ->  $(dig -x $ip @$DNS_SERVER +short | tr '\n' ',' | sed s/,$//)" # Now scanning range C of this same address
        rangec=$(echo "$(echo $ip | cut -f1-3 -d.)")
        echo ""
        for octet in `seq 1 254`
        do
            # echo " Asking for $rangec.$octet..."
            ptr=$(host $rangec.$octet $DNS_SERVER | grep -i 'domain name pointer' | awk '{print $5}') 
            if [[ "$ptr" != "" ]];then
                echo "SCAN_C;$rangec.$octet;$ptr" >> $OUTPUT
                echo "  * $ptr -> $rangec.$octet"
            fi
        done
    else
        echo "Error: $ip is not a valid IP address. Skipping..." 1>&2
    fi
done
