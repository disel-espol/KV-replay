
inputTrace=$1
TIF=$2
outputTrace=$3
typeAlgorithm=${4:-md5}
separator=,

size=$( wc -l $inputTrace | cut -d" " -f1 )
#echo "$size"
perfectSize=$(( size / TIF ))
#resid=$(( size % TIF))
#echo "este es perfectSize : $perfectSize"

> $outputTrace

let counter2=0 #contador global
let oldTime=0
for (( counter=0 ; counter<$perfectSize ; counter ++ ))
do


	for (( i=0 ; i<$TIF ; i++ ))
	do
		let counter2+=1

		let line=$(( (i * perfectSize) + (counter +1) ))
		correctValue=$( sed -n "$line p" < $inputTrace)
		#echo "este es correctValue : $correctValue"
		key=$( echo "$correctValue" | cut -d"," -f2)
		#echo " clave es : $key"
		Command=$( echo "$correctValue" | cut -d"," -f1)
		#echo "clave es : $Command"
		if [ $i -gt 9 ]
		then
			newKey=$i$key
		else
			newKey=0$i$key
		fi

		
		valueForTime=$( sed -n "$counter2 p" < $inputTrace)
		#echo "este es valueForTime : $valueForTime "
		if [ $counter2 -eq 1 ]
		then
			newTime=$( echo "$valueForTime" | cut -d"," -f3)
			correctTime=$newTime
			#echo " este es correctTime : $correctTime"
		else
			newTime=$( echo "$valueForTime" | cut -d"," -f3)
			#echo "este es oldTime : $oldTime"
			#echo "este es newTime : $newTime"
			correctTime=$(echo "scale=9; ((($newTime - $oldTime ) /$TIF) + $oldCorrectTime)" | bc)
			#echo " este es correctTime : $correctTime"
		fi

		sizeRecord=$( echo "$correctValue" | cut -d"," -f4)
		if [ -z "$sizeRecord" ];then
			echo $Command,$newKey,$correctTime >> $outputTrace
		else
			echo $Command,$newKey,$correctTime,$sizeRecord >> $outputTrace
		fi
			



		oldCorrectTime=$correctTime
		#echo "este es oldCorrectTime : $oldCorrectTime"
		oldTime=$newTime
		#echo -e "\n"
		
	done

done 

#echo -e "\n \n ZONA DE RESIDUOS"
#echo "este es counter2 : $counter2"
while [ $counter2 -lt $size ]
do
	let counter2+=1
	#echo "este es counter2 : $counter2"
	resid=$(( counter2 % TIF ))
	valueForTime=$( sed -n "$counter2 p" < $inputTrace)
	#echo "este es valueForTime : $valueForTime"
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
