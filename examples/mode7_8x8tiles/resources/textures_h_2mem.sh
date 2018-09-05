#/usr/bin/env sh

if [ $# -eq 0 ] || [ "$1" == "-h" ] ; then
    echo "Usage: `basename $0` [-h] <textures.h>"
    exit 0
fi

cat $1 \
	| sed -n '/^static char header_data\[/,/\}\;/p'  	`# extract lines that contain texture data ` \
	| grep '[0-9]' 						`# strip out the array header and prologue` \
	| sed -e 's/^[ \t]*//' 					`# remove trailing space ` \
	| tr '\n' ' '						`# remove newlines ` \
	| sed -e 's/ //g'					`# remove spaces between numbers ` \
	| awk -F "," '{ for(i=1; i<=NF; i++) { printf("%01x ",$i); if ((i-1)%64==63) printf("\n"); }; printf("\n"); }' 


