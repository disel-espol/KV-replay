#!/bin/bash

inputTrace=$1
copies=$2
outputTrace=$3
separator=,

> $outputTrace

while IFS=$separator read -ra ARRAY || [[ -n "$ARRAY" ]]; do

	ArrayLenght=${#ARRAY[@]}
	ID="${ARRAY[1]}"
	COMMAND="${ARRAY[0]}"
	TIMESTAMP="${ARRAY[2]}"
	SIZE=""
	if [ $ArrayLenght -gt 3 ]
	then
		SIZE="${ARRAY[3]}"
		for (( c=1; c<=$copies; c++ ))
		do
			newKey=0$c$ID
			echo $COMMAND$separator$newKey$separator$TIMESTAMP$separator$SIZE >> $outputTrace
		done
	else
		for (( c=1; c<=$copies; c++ ))
		do
			newKey=0$c$ID
			echo $COMMAND$separator$newKey$separator$TIMESTAMP >> $outputTrace
		done

	fi

	

done < "$inputTrace"


