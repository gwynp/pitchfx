#!/bin/bash

YEAR=$1
MONTH=$2
FIRSTDAY=1

echo year=$YEAR
echo month=$MONTH

if [ $MONTH -lt 4 ] || [ $MONTH -gt 10 ]
then
	echo please pick a month in which they play baseball
	exit 1
fi


FULLDATE="$YEAR-$MONTH-01"
echo $FULLDATE

LASTDAY=`date -d "$(date -d "$FULLDATE" +%Y-%m-01) +1 month -1 day" +%d`
echo $LASTDAY

for (( DAY = $FIRSTDAY; DAY <= $LASTDAY; DAY++ ))
do
	if [[ $DAY -lt "10" ]]
	then
		DATESTR="$YEAR $MONTH `printf %02d $DAY`"
	else	
		DATESTR="$YEAR $MONTH $DAY"
	fi

	 ./mlbScraperDaily.sh $DATESTR

done
