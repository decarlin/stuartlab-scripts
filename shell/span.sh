#!/bin/bash

network=$1
activities=$2
fdr=$3
pcst=$4

if [ "$4" != "" ]; then
	pcst="--pcst 'yes'"
else
	pcst=""
fi

span.R --network $network --activities $activities --fdr $fdr $pcst |\
sed -e 's/\[.*\]//g' -e 's/ //g' -e 's/--/  /g' -e 's/_/ /g' > /tmp/span.tab 
grep '  ' /tmp/span.tab
