#!/bin/bash

# script that will generate events.tsv file for gambling task
# this script will split events by the following dimensions:
# (1) condition: gain, loss, neutral

log=${1}
output_string=${2}
skips=${3}

# parse output_string
IFS=',' read -r -a outputs <<< ${output_string}

# identify number of runs to process
# first, check if A started
if [ $(grep 'Waiting for the scanner' ${log} | wc -l) -ne 1 ]; then
	echo "ERROR: No scans present in log file"
	exit
fi

# second, check if B started
if [ $(grep 'Imported all_blocks_list_B.csv' ${log} | wc -l) -eq 1 ]; then
	b_started=1
else
	b_started=0
fi

# next decide runs based on skips and starts
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
tmp=tmp_output_gambling.tsv

# counter for tsv file names
k=0
####### process runs #########
for run in ${runs}; do 
	if [ -f ${tmp} ]; then
		echo "ERROR: please delete the tmp buffer (tmp_output.tsv)"
		exit
	else
		echo -e "onset\tduration\tcondition" > ${tmp}
	fi

	# get timing landmarks
	if [ ${run} -eq 1 ]; then
		runstartline=$(grep 'Waiting for the scanner' -n ${log} 2> /dev/null | head -1 | awk -F ':' '{print $1}')
		runstart=$(tail -n +${runstartline} ${log} 2> /dev/null | grep 'Keypress: 5' 2> /dev/null | head -1 | awk '{print $1}')
		runendline=$(grep "Created unnamed TextStim.*Waiting for the experimenter" -n ${log} | tail -1 | awk -F ':' '{print $1}')
		runend=$(grep "Created unnamed TextStim.*Waiting for the experimenter" ${log} | tail -1 | awk '{print $1}')
		if [ -z ${runend} ]; then
			# if not terminated naturally, draw until the last event
			runend=$(tail -1 ${log} | awk '{print $1}')
		fi

		# get timings
		timinglines=$(head -${runendline} ${log} | grep "trial_sing_text: text = '?'" -n | awk -F ':' '{print $1}')
	elif [ ${run} -eq 2 ]; then
		importline=$(grep 'Imported all_blocks_list_B.csv' -n ${log} | awk -F ':' '{print $1}')
		runstartline=$(head -${importline} ${log} | grep 'Keypress: q' -n | tail -1 | awk -F ':' '{print $1}')
		runstart=$(tail -n +${runstartline} ${log} | grep 'Keypress: 5' 2> /dev/null | head -1 | awk '{print $1}')
		
		# get timings and conditions
		timinglines_rel=$(tail -n +${runstartline} ${log} | grep -n "trial_sing_text: text = '?'" | awk -F ':' '{print $1}')
		timinglines=
		for timing in ${timinglines_rel}; do 
			timinglines="${timinglines} $((timing + runstartline - 1))"
		done
	fi

	# loop through events
	for event in $(seq 1 $(echo ${timinglines} | wc -w)); do
		start=$(tail -n +$(echo ${timinglines} | awk -v var=${event} '{print $var}') ${log} | grep "trial_card_text: autoDraw = True" 2> /dev/null | head -1 | awk '{print $1}')
		cond=$(tail -n +$(echo ${timinglines} | awk -v var=${event} '{print $var}') ${log} | grep "trial_feedback_image: image = " 2> /dev/null | head -1 | sed "s/.*image = //" | awk -F "'" '{print $2}' | sed "s/.png//")
		realstart=$(echo ${start} - ${runstart} | bc)

		case ${cond} in
			positive)
				echo -e "${realstart}\t1\tgain" >> ${tmp}
				;;
			negative)
				echo -e "${realstart}\t1\tloss" >> ${tmp}
				;;
			neutral)
				echo -e "${realstart}\t1\tneutral" >> ${tmp}
				;;
			"")
				echo "Warning: event terminated weirdly"
				continue
				;;
			*)
				echo "ERROR: ${cond} is an unclassified event."
				exit
				;;
		esac
	done

	# move tmp file
	mv ${tmp} ${outputs[${k}]}
	k=$((k + 1))
done
