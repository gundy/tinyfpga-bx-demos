#/usr/bin/env sh

if [ $# -eq 0 ] || [ "$1" == "-h" ] ; then
    echo "Usage: `basename $0` [-h] <tilemap.csv>"
    exit 0
fi

cat $1 | awk -F "," '{ for(i = 1; i<=NF; i++) { printf("%02x ",$i); }; printf("\n"); }'
