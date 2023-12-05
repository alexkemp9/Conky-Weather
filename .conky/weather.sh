#!/bin/bash
# utility to replace conky weather using aviationweather.gov (US Govt)
# conky weather stopped working 2016 August
# weather.noaa.gov/pub/data/observations/metar/stations/ withdrawn

# following strips off BASENAME, leaving just script name
SCRIPTNAME=${0##*/}
if [ -z "$1" ]; then
    echo
    echo "USAGE:    $SCRIPTNAME [locationcode]"
    echo "example: '$SCRIPTNAME EGNX' (=='East Midlands')"
    echo
    echo "list of location codes:"
    echo "http://weather.rap.ucar.edu/surface/stations.txt"
    echo
    echo "requires:"
    echo " awk"
    echo " curl"
    echo " hxextract"
    echo " grep"
    echo
    exit 0;
fi

AWK=/etc/alternatives/awk
if [ ! -r $AWK ]; then
    echo
    echo " file '$AWK' cannot be read"
    echo
    exit 0;
fi

CURL=/usr/bin/curl
if [ ! -r $CURL ]; then
    echo
    echo " file '$CURL' cannot be read"
    echo
    exit 0;
fi

HXEXTRACT=/usr/bin/hxextract
if [ ! -r $HXEXTRACT ]; then
    echo
    echo " file '$HXEXTRACT' cannot be read"
    echo
    exit 0;
fi

EGREP=/bin/egrep
if [ ! -r $EGREP ]; then
    echo
    echo " file '$EGREP' cannot be read"
    echo
    exit 0;
fi

URL="https://www.aviationweather.gov/metar/data?ids=$1"
RESULT=`$CURL --connect-timeout 30 -s $URL | $HXEXTRACT div - | $EGREP "^$1"`

ERR=$?
if [ -z "$RESULT" ] || [ $ERR -ne 0 ]; then
    echo
    echo "Error! An empty result using '$URL' (return value = $ERR)"
    echo
    exit 0;
fi

# split result into individual words
# disable shell globbing first for safety
set -f
# note: result never starts with a dash
set $RESULT
# individual words now in $1, $2, etc.
for WORD do
  if [[ $WORD == Q* ]]; then
    # $WORD starts with a 'Q'
    # alternative: ${WORD[0:1]} is first letter of $WORD
    PRESSURE=`echo $WORD | grep -o '[0-9]\+'`
  fi
done
# switch globbing back on
set +f

echo $PRESSURE
