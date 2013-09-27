#!/bin/bash

# Summary: This script tries to obtain the name of an IP using dig
# Author: Felipe Molina (@felmoltor)

IP_FILE=""
DNS_SERVER="8.8.8.8"

if [[ -f $1 ]];then
    IP_FILE=$1
else
    echo "Usage: $0 <ip_list_to_reverse_name> [<DNS_server_to_ask>]"
    exit 1
fi

if [[ $2 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]];then
    DNS_SERVER=$2
else
    echo "Wrong IP address specification. Using $DNS_SERVER by default"
fi

for ip in `cat $IP_FILE`; do
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]];then
        echo -e "$ip;$(dig -x $ip @$DNS_SERVER +short)"
    else
        echo "Error: $ip is not a valid IP address. Skipping..."
    fi
done
