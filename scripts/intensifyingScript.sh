
inputTrace=$1
TIF=$2
outputTrace=$3
typeAlgorithm=${4:-md5}
separator=,

size=$( wc -l $inputTrace | cut -d" " -f1 )
perfectSize=$(( size / TIF ))
> $outputTrace

let counter2=0 
let oldTime=0
for (( counter=0 ; counter<$perfectSize ; counter ++ ))
do


	for (( i=0 ; i<$TIF ; i++ ))
	do
		let counter2+=1

		let line=$(( (i * perfectSize) + (counter +1) ))
		correctValue=$( sed -n "$line p" < $inputTrace)
		key=$( echo "$correctValue" | cut -d"," -f2)
		Command=$( echo "$correctValue" | cut -d"," -f1)
		if [ $i -gt 9 ]
		then
			newKey=$i$key
		else
			newKey=0$i$key
		fi

		
		valueForTime=$( sed -n "$counter2 p" < $inputTrace)
		if [ $counter2 -eq 1 ]
		then
			newTime=$( echo "$valueForTime" | cut -d"," -f3)
			correctTime=$newTime
		else
			newTime=$( echo "$valueForTime" | cut -d"," -f3)
			correctTime=$(echo "scale=9; ((($newTime - $oldTime ) /$TIF) + $oldCorrectTime)" | bc)
		fi

		sizeRecord=$( echo "$correctValue" | cut -d"," -f4)
		if [ -z "$sizeRecord" ];then
			echo $Command,$newKey,$correctTime >> $outputTrace
		else
			echo $Command,$newKey,$correctTime,$sizeRecord >> $outputTrace
		fi
			



		oldCorrectTime=$correctTime
		oldTime=$newTime
		
	done

done 


while [ $counter2 -lt $size ]
do
	let counter2+=1
	resid=$(( counter2 % TIF ))
	valueForTime=$( sed -n "$counter2 p" < $inputTrace)
	key=$( echo "$valueForTime" | cut -d"," -f2)
	if [ $resid -gt 9 ]
	then
		newKey=$resid$key
	else
		newKey=0$resid$key
	fi
	Command=$( echo "$valueForTime" | cut -d"," -f1)
	newTime=$( echo "$valueForTime" | cut -d"," -f3)
	correctTime=$(echo "scale=9; ((($newTime - $oldTime ) /$TIF) + $oldCorrectTime)" | bc)
	sizeRecord=$( echo "$valueForTime" | cut -d"," -f4)
	if [ -z "$sizeRecord" ];then
		echo $Command,$newKey,$correctTime >> $outputTrace
	else
		echo $Command,$newKey,$correctTime,$sizeRecord >> $outputTrace
	fi
	oldCorrectTime=$correctTime
	oldTime=$newTime
done
