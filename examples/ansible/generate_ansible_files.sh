#!/bin/bash

function usage() {
    echo "Usage: $0 -w <warehouse> -a <ansible directory> -s <service> [ -i ]" >&2
    echo "" >&2
    echo "Generate Ansible inventory, variables, and service configuration files" >&2
    echo "from a Pallet Jack warehouse." >&2
    echo "" >&2
    echo "    -w DIR        warehouse directory" >&2
    echo "    -a DIR        Ansible output directory" >&2
    echo "    -s SERVICE    DHCP and DNS service name" >&2
    echo "    -i            Write IP addresses to Ansible inventory" >&2
}

while getopts ":w:a:s:hi" OPT
do
    case $OPT in
        w)
            WAREHOUSE=$OPTARG
            ;;
        a)
            ANSIBLE=$OPTARG
            ;;
        s)
            SERVICE=$OPTARG
            ;;
        i)
            USE_IPV4=1
            ;;
        h)
            usage
            exit 0
            ;;
        \?)
            echo "Invalid option -$OPTARG" >&2
            usage
            exit 1
           ;;
        :)
            echo "No directory specified for -$OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done

if [ -z "$WAREHOUSE" ]
then
    echo "No warehouse directory specified" >&2
    usage
    exit 1
fi

if [ -z "$ANSIBLE" ]
then
    echo "No Ansible output directory specified" >&2
    usage
    exit 1
fi

if [ -z "$SERVICE" ]
then
    echo "No DHCP and DNS service name specified" >&2
    usage
    exit 1
fi

if [ \! -d "$WAREHOUSE" ]
then
    echo "Warehouse directory $WAREHOUSE does not exist" >&2
    exit 1
fi

if [ \! -d "$ANSIBLE" ]
then
    echo "Ansible output directory $ANSIBLE does not exist" >&2
    exit 1
fi

if [ "$USE_IPV4" == "1" ]
then
    palletjack2ansible -w "$WAREHOUSE" -d "$ANSIBLE" -i
else
    palletjack2ansible -w "$WAREHOUSE" -d "$ANSIBLE"
fi

palletjack2kea -w "$WAREHOUSE" -s "$SERVICE" | \
    sed -E -e '/"valid-lifetime":/ s,: "(.*)",: \1,' > \
        "$ANSIBLE"/roles/kea/files/kea-dhcp4.conf

palletjack2knot -w "$WAREHOUSE" -o "$ANSIBLE"/roles/knot/files/ -s "$SERVICE"

palletjack2knotresolver -w "$WAREHOUSE" > "$ANSIBLE"/roles/knot-resolver/files/kresd.conf

palletjack2pxelinux -w "$WAREHOUSE" -o "$ANSIBLE"/roles/pxelinux/files/tftpboot/
