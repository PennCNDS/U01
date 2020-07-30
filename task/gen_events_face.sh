#!/bin/bash

# script that will generate events.tsv file for faceMatching task
# this script will split events by the following dimensions:
# (1) image: object, face, fixation
# (2) emotion: neutral, happy, fearful

log=${1}
output_string=${2}
skips=${3}

# parse output_string
IFS=',' read -r -a outputs <<< ${output_string}

# identify number of runs to process
nstarts=$(grep 'Waiting for the scanner' ${log} | wc -l)
if [ ${nstarts} -eq 0 ]; then
	echo "ERROR: No scans present in log file"
	exit
elif [ ${nstarts} -eq 1 ]; then
	b_started=0
elif [ ${nstarts} -eq 2 ]; then
	b_started=1
else
	echo "ERROR: nstarts is not 0, 1 or 2: ${nstarts}"
	exit
fi

if [ ${skips} == NA ] && [ ${b_started} -eq 1 ]; then
	runs="1 2"
elif [ ${skips} == NA ] && [ ${b_started} -eq 0 ]; then
	echo "WARNING: Both scans present, but log data only present for run A"
	runs="1"
elif [ ${skips} == 2 ]; then
	runs="1"
elif [ ${skips} == 1 ] && [ ${b_started} -eq 1 ]; then
	runs="2"
else
	echo "ERROR: First scan should be skipped, but run B never started in log data"
	exit
fi

# tmp file
tmp=tmp_output_face.tsv

# counter for tsv file names
k=0

####### process runs #########
for run in ${runs}; do 
	if [ -f ${tmp} ]; then
		echo "ERROR: please delete the tmp buffer (tmp_output.tsv)"
		exit
	else
		echo -e "onset\tduration\timage\temotion" > ${tmp}
	fi

	# get timing landmarks
	if [ ${run} -eq 1 ]; then
		runstartline=$(grep 'Waiting for the scanner' -n ${log} | head -1 | awk -F ':' '{print $1}')
		runstart=$(tail -n +${runstartline} ${log} 2> /dev/null | grep 'Keypress: 5' 2> /dev/null | head -1 | awk '{print $1}')
		runend=$(grep "Created unnamed TextStim.*Waiting for the experimenter" ${log} | tail -1 | awk '{print $1}')
		if [ -z ${runend} ]; then
			# if not terminated naturally, draw until the last event
			runend=$(tail -1 ${log} | awk '{print $1}')
		fi

		# get timings and conditions
		timings="$(grep "New trial.*'A'" -A1 ${log} | grep -v "New trial" | awk '{print $1}' | grep -v '\-\-') ${runend}"
		conds=$(grep "New trial.*'A'" ${log} | sed "s/.*'Condition': //" | awk -F "'" '{print $2}')
	elif [ ${run} -eq 2 ]; then
		runstartline=$(grep 'Waiting for the scanner' -n ${log} | tail -1 | awk -F ':' '{print $1}')
		runstart=$(tail -n +${runstartline} ${log} 2> /dev/null | grep 'Keypress: 5' 2> /dev/null | head -1 | awk '{print $1}')
		runend=$(grep "Created thanks_text" -A1 ${log} | tail -1 | awk '{print $1}')
		if [ -z ${runend} ]; then
			# if not terminated naturally, draw until the last occuring scanner pip
			runend=$(tail -1 ${log} | awk '{print $1}')
		fi

		# get timings and conditions
		timings="$(grep "New trial.*'B'" -A1 ${log} | grep -v "New trial" | awk '{print $1}' | grep -v '\-\-') ${runend}"
		conds=$(grep "New trial.*'B'" ${log} | sed "s/.*'Condition': //" | awk -F "'" '{print $2}')
	fi

	# loop through events
	for event in $(seq 1 $(expr $(echo ${timings} | wc -w) - 1)); do
		start=$(echo ${timings} | awk -v var=${event} '{print $var}')
		end=$(echo ${timings} | awk -v var=$(expr ${event} + 1) '{print $var}')
		duration=$(echo ${end} - ${start} | bc)
		cond=$(echo ${conds} | awk -v var=${event} '{print $var}')
		realStart=$(echo ${start} - ${runstart} | bc)

		case ${cond} in
			Happy)
				echo -e "${realStart}\t${duration}\tface\thappy" >> ${tmp}
				;;
			Neutral)
				echo -e "${realStart}\t${duration}\tface\tneutral" >> ${tmp}
				;;
			Fearful)
				echo -e "${realStart}\t${duration}\tface\tfearful" >> ${tmp}
				;;
			Object)
				echo -e "${realStart}\t${duration}\tobject\tNA" >> ${tmp}
				;;
			Fixation)
				echo -e "${realStart}\t${duration}\tfixation\tNA" >> ${tmp}
				;;
			*)
				echo "ERROR: ${cond} is an unclassified event."
				exit
				;;
		esac
	done

	# move tmp file
	mv ${tmp} ${outputs[${k}]}
#	rm ${tmp}
	k=$((k + 1))
done
