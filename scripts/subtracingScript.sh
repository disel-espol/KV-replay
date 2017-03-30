
declare -A table=()
declare -A tableObjects=()
tableArrayObjects=()

inputTrace=$1
numberOfSubtraces=$2
typeAlgorithm=${3:-md5}
separator=,

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

numberOfSubtraces2=$(( numberOfSubtraces -1))

for (( j=1; j<=$numberOfSubtraces; j++ ))
do

	> "$inputTrace-subtrace-$j-of-$numberOfSubtraces-method-$typeAlgorithm"
done

while IFS=$separator read -ra ARRAY || [[ -n "$ARRAY" ]]; do

	ID="${ARRAY[1]}"


	if [ "$typeAlgorithm" = "ascii" ] ; then
		let hashed=$(conversion $ID)
		let temp=$(( $hashed % $numberOfSubtraces ))
		if [ $temp -lt 0 ];then
			temp=$(( temp *-1))
		fi
	elif [ "$typeAlgorithm" = "sha" ]; then
		hashed=$(echo -n $ID | sha1sum | cut -d" " -f1) 
		let temp=$(( 16#$hashed % $numberOfSubtraces ))
		if [ $temp -lt 0 ];then
			temp=$(( temp *-1))
		fi
	elif [ "$typeAlgorithm" = "onlynumbers" ]; then
		hashed=$ID
		let temp=$(( 10#$hashed % $numberOfSubtraces ))
		if [ $temp -lt 0 ];then
			temp=$(( temp *-1))
		fi

	elif [ "$typeAlgorithm" = "tr" ]; then
		hashed=$(echo "$ID"| tr "[:upper:]" "[:lower:]" |  tr "u-z" "0-5" | tr "k-t" "0-9" | tr "a-j" "0-9" | tr "@\-_%" "6-9") 
		let temp=$(( 10#$hashed % $numberOfSubtraces ))
		if [ $temp -lt 0 ];then
			temp=$(( temp *-1))
		fi
	else
		hashed=$(echo -n $ID | md5sum | cut -d" " -f1) 
		let temp=$(( 16#$hashed % $numberOfSubtraces ))
		if [ $temp -lt 0 ];then
			temp=$(( temp *-1))
		fi

	fi
	for (( i=0; i<=$numberOfSubtraces2; i++ ))
	do
		if [[ $temp -eq $i ]]; then
			COMMAND="${ARRAY[0]}"
			TIMESTAMP="${ARRAY[2]}"
			if [ ${#ARRAY[@]} -gt 3 ]
			then
				SIZE="${ARRAY[3]}"
				let number=$(( i + 1))
				echo $COMMAND$separator$ID$separator$TIMESTAMP$separator$SIZE >> "$inputTrace-subtrace-$number-of-$numberOfSubtraces-method-$typeAlgorithm"
				if [ -n "${table[$i] + 1}" ]; then	
					let table[$i]+=1
					if [ -z "${tableObjects[$ID] + 1}" ]
					then
						tableObjects[$ID]=$i
					fi

				else
					let table[$i]=1
					if [ -z "${tableObjects[$ID] + 1}" ]
					then
						tableObjects[$ID]=$i
					fi
				fi
			else
				let number=$(( i + 1))
				echo $COMMAND$separator$ID$separator$TIMESTAMP >> "$inputTrace-subtrace-$number-of-$numberOfSubtraces-method-$typeAlgorithm"
				if [ -n "${table[$i] + 1}" ]; then	
					let table[$i]+=1
					if [ -z "${tableObjects[$ID] + 1}" ]
					then
						tableObjects[$ID]=$i
					fi
				else
					let table[$i]=1
					if [ -z "${tableObjects[$ID] + 1}" ]
					then
						tableObjects[$ID]=$i
					fi
				fi

			fi
		fi

	done


done < "$inputTrace"


for value in ${tableObjects[@]}
do
	if [ -n "${tableArrayObjects[$value]} +1" ]
	then
		let tableArrayObjects[$value]+=1
	else
		let tableArrayObjects[$value]=1

	fi
done


for (( k=1; k<=$numberOfSubtraces; k++ ))
do
	value=$(( k -1))
	echo " the subtrace : $inputTrace-subtrace-$k-of-$numberOfSubtraces-method-$typeAlgorithm has ${table[$value]} records and ${tableArrayObjects[$value]} unique objects"
done
