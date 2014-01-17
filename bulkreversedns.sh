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

################
# CHECK PARAMS #
################

if [[ -f $1 ]];then
    IP_FILE=$1
else
    echo "Usage: $0 <ip_list_to_reverse_name> [<DNS_server_to_ask>]"
    exit 1
fi

isValidIP $2
valid_ip=$?
if [[ $valid_ip == 0 ]];then
    DNS_SERVER=$2
else
    dns_resuelto=$(resolveDNSServerName $2)
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

for ip in `cat $IP_FILE`; do
    isValidIP $ip
    valid_ip=$?
    if [[ $valid_ip == 0 ]];then
        
        echo -e "$ip;$(dig -x $ip @$DNS_SERVER +short | tr '\n' ',' | sed s/,$//)"
    else
        echo "Error: $ip is not a valid IP address. Skipping..." 1>&2
    fi
done
