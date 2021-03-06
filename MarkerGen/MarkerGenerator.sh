#!/bin/bash

# Generate metadata for AddChapterMarkers.sh using @xanamp tweets. version 0.1
# CHANGE PATHS BEFORE USING THIS SCRIPT.
# supply tweets.csv withe following format:
# 2018-02-18-03:13:53\FurCast - News
# 2018-02-18-03:07:46\GoldFish, Julia Church - Heart Shaped Box (Original Mix)

# BUG: Last chapter will use incorrect end time. Start time is usually correct.

# M4A chapter reference. Add to ffmpeg metadata file.
# [CHAPTER]
# TIMEBASE=1/1 - precision control. best to be left at seconds although you can be even more precise by adding 0's
# START=10
# END=25 - do not omit
# title= - track title to be shown in the player

function buildmetadata {
	read -e -p "Starting point: " -i "100" spoint # Intro length. newer: 100 older: 65. change occured at episode 125
	echo -e '\n[CHAPTER]\nTIMEBASE=1/1\nSTART='0'\nEND='$spoint'\ntitle='"Intro" >> "$dstpath/${name}_metadata"
	read -p "Starting line: " line # first track line number in tweets.csv
	prev=$spoint
	read -p "lines to repeat: " type # how many tracks are in the episode
	until [[ $type == 0 ]]; do
		title="$(sed "${line}q;d" $tweets)"
		echo "$title"
		echo -e "[CHAPTER]\nTIMEBASE=1/1" >> $dstpath/${name}_metadata
		cdate=$(sed "$((line))q;d" $tweets | cut -c1-19)
		ndate=$(sed "$((line-1))q;d" $tweets | cut -c1-19)
		diff=$(python3 TimeDiff.py $cdate $ndate)
		end=$(($prev+diff))
		echo 'START='$prev >> $dstpath/${name}_metadata
		echo 'END='$end >> $dstpath/${name}_metadata
		echo 'title='$(echo $title | cut -c21-) >> $dstpath/${name}_metadata
		type=$(($type-1))
		prev=$end
		unset end
		line=$(($line-1))
	done
	unset done
}

tweets="/mnt/c/Users/Ray/Documents/GitHub/XBN/XanaNP-tweets/tweets_formatted.csv"
srcpath=/mnt/d/Users/Ray/MoreMusic/FNT
dstpath=/mnt/d/Users/Ray/MoreMusic/FNT/metadata
delete=0

for file in $srcpath/*.mp3; do
	name=`basename $file | cut -d'.' -f1`;
	echo $name;
	ffmpeg -i "$file" -f ffmetadata "$dstpath/${name}_metadata" # extract basic metadata
	
	# process csv here
	if [[ $? != 0 ]]; then read -e -p "Skip this file? [y/n] " -i "y" skipit ; fi
	if [[ $skipit != y ]]; then echo "$name" ; buildmetadata; else skipit=n ;  fi
	read -e -p "Processing done. Modify? " -i "n" modify # sometimes tweets don't line up correctly
	if [[ "$modify" != "n" ]]; then
		modify=n
		cmd.exe /c "C:\Program Files (x86)\Notepad++\notepad++.exe" 'D:\Users\Ray\MoreMusic\FNT\metadata\'"$name"'_metadata'
		read -p "Waiting for ENTER."
	fi
done

echo "Program completed sucessfully."
exit 0
