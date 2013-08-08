#!/bin/bash

# Gwyn
#
# Pulls down yesterdays files from mlb.com
# This only gets the files needed to populate Mike Fast's schema
# structure
# namely the game,boxscore and players.xml and the innings directory.
# there's a lot more information for each game that this script doesn;t pull down
#

DATADIR=/opt/data/pitchfx
CODEDIR=/opt/code/pitchfx

inning=inning

# yesterdays date info
YEAR=`date --date="yesterday" +%Y`
MONTH=`date --date="yesterday" +%m`
DAY=`date --date="yesterday" +%d`

#check for dates passed ar ARGS
if [[ -n $1 ]] && [[ -n $2 ]] && [[ -n $3 ]];
then
	echo "Running for dates passed as arguments - not for yesterday"
	YEAR=$1
	MONTH=$2
	DAY=$3
fi
echo "$YEAR - $MONTH - $DAY"

# format the mlb.com variables
MLBYEAR=year_$YEAR
MLBMONTH=month_$MONTH
MLBDAY=day_$DAY

# mlb.com url build
MLBSTATIC=components/game/mlb
MLBADDRESS=http://gd2.mlb.com
MLBURL=$MLBADDRESS/$MLBSTATIC/$MLBYEAR/$MLBMONTH/$MLBDAY/

cd $DATADIR

# remove previous runs index file
rm /tmp/index.html

# get the index file for yesterday and save to tmp
wget -P /tmp --quiet $MLBURL

# pull the game dirs from the index file and loop through them
for i in `cat /tmp/index.html|grep gid|cut -d"\"" -f2`
do
echo $i
wget  -m -nH -np --cut-dirs=3 -e robots=off  --quiet $MLBURL$i/boxscore.xml
wget  -m -nH -np --cut-dirs=3 -e robots=off  --quiet $MLBURL$i/game.xml
wget  -m -nH -np --cut-dirs=3 -e robots=off  --quiet $MLBURL$i/players.xml
wget -r -nH -np --cut-dirs=3 -e robots=off --quiet $MLBURL$i$inning/
# wait a couple of seconds between games
sleep 2
done
