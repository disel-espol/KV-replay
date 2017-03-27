declare -A table=()

inputTrace=$1
let TIF=$2
outputTrace=$3
typeAlgorithm=${4:-md5}
separator=,

> $outputTrace

conversion (){
	foo=$1
	output=""
	for (( i=0; i<${#foo}; i++ )); do
		letter="${foo:$i:1}"
		LC_CTYPE=C 
  		a=$(printf '%d' "'$letter")
  		output="$output$a"
	done

	echo "$output"	
}

numberOfSubtraces2=$(( TIF -1))
let counter=0
Size=""


bool=false
while IFS=$separator read -ra ARRAY || [[ -n "$ARRAY" ]]; do

	ID="${ARRAY[1]}"
	Timestamp="${ARRAY[2]}"
	Command="${ARRAY[0]}"
	if [ ${#ARRAY[@]} -gt 3 ]
	then
		Size="${ARRAY[3]}"
		#echo -e "\n \n #Size"
		#echo "$Size"
		bool=true
	fi


	if [ "$typeAlgorithm" = "ascii" ] ; then
		let hashed=$(conversion $ID)
		let temp=$(( $hashed % $TIF ))
		if [ $temp -lt 0 ];then
			temp=$(( temp *-1))
		fi
	elif [ "$typeAlgorithm" = "sha" ]; then
		hashed=$(echo -n $ID | sha1sum | cut -d" " -f1) 
		let temp=$(( 16#$hashed % $TIF ))
		if [ $temp -lt 0 ];then
			temp=$(( temp *-1))
		fi
	elif [ "$typeAlgorithm" = "onlynumbers" ]; then
		hashed=$ID
		let temp=$(( 10#$hashed % $TIF ))
		if [ $temp -lt 0 ];then
			temp=$(( temp *-1))
		fi

	elif [ "$typeAlgorithm" = "tr" ]; then
		hashed=$(echo "$ID"| tr "[:upper:]" "[:lower:]" |  tr "u-z" "0-5" | tr "k-t" "0-9" | tr "a-j" "0-9" | tr "@\-_%" "6-9") 
		let temp=$(( 10#$hashed % $TIF ))
		if [ $temp -lt 0 ];then
			temp=$(( temp *-1))
		fi
	else
		hashed=$(echo -n $ID | md5sum | cut -d" " -f1) 
		let temp=$(( 16#$hashed % $TIF ))
		if [ $temp -lt 0 ];then
			temp=$(( temp *-1))
		fi

	fi
	for (( i=0; i<=$numberOfSubtraces2; i++ ))
	do
		#echo "entra aqui 0"
		if [[ $temp -eq $i ]] 
		then
			#echo "entra aqui 1"

			if [ -z "${table[$i] + 1}" ]
			then
				arrayOfRecords=()
				table[$i]=${arrayOfRecords[@]}
	
			fi
			if [ $counter -eq 0 ]
			then
				firstTimeStamp=$Timestamp
				let value=0
			else
				#echo "$Timestamp"
				#echo "$preTimeStamp"
				#echo "$TIF"
				value=$(echo "scale=9;($Timestamp - $preTimeStamp )/$TIF" | bc)
				#echo "value es $value"
			fi
			arrayGanador=(${table[$i]})
			if [ $bool = true ]
			then
				arrayGanador+=("$Command,$ID,$value,$Size")
			else
				arrayGanador+=("$Command,$ID,$value")
			fi
			
			table[$i]=${arrayGanador[@]}
			let counter+=1
			preTimeStamp=$Timestamp

		fi

		#echo "${table[$i]}"

	done

done < "$inputTrace" 

maxLength=0
for (( i=0; i<=$numberOfSubtraces2; i++ )); do
	arrayTemp1=(${table[$i]})
	#echo -e "\n este es el subtrace $i : ${arrayTemp1[@]}"
	if [[ ${#arrayTemp1[@]} -gt $maxLength ]]; then
		maxLength=${#arrayTemp1[@]}

	fi
done

prevTime=$firstTimeStamp
for (( i=0; i<=$maxLength; i++ ))
do
	for (( j=0; j<=$numberOfSubtraces2; j++ ))
	do

		arrayTemp2=(${table[$j]})
		if [ ! -z "${arrayTemp2[$i]}" ]
		then
			value2=${arrayTemp2[$i]}
			Command=$( echo $value2 | cut -d"," -f1 )
			key=$( echo $value2 | cut -d"," -f2 )
			timme=$( echo $value2 | cut -d"," -f3 )
			

			#echo "timme es $timme"
			newtimme=$(echo "scale=9; $prevTime + $timme" | bc)
			#echo "newtimme es $newtimme"
			if [ $bool = true ]
			then
				size=$( echo $value2 | cut -d"," -f4 )
				echo $Command,$key,$newtimme,$size >> $outputTrace

			else
				echo $Command,$key,$newtimme >> $outputTrace
			fi			
			prevTime=$newtimme


		
		else
			continue

		fi

	done

done



