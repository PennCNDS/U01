#!/bin/bash

# Loop over every subject's source behavioral data and generate
# a BIDS compliant events.tsv file

data_root=../../..
sourcedir=${data_root}/source
rawdir=${data_root}/raw
qc_log=${data_root}/scripts/import/imaging/qc/qc_log.tsv

tasks="conflict face gambling"

for sesdir in ${sourcedir}/sub-*/ses-*; do 
	sub=$(echo ${sesdir} | awk -F '/' '{print $(NF-1)}')
	ses=$(echo ${sesdir} | awk -F '/' '{print $(NF)}')
	echo
	echo "------ ${sub}: ${ses} -------"

	if [ -d ${sesdir}/behav_data ]; then
		# check that quarantine directory was generated
		if [ ! -d ${sesdir}/behav_data/quarantine ]; then
			echo "ERROR: ${sub}: ${ses} is missing a quarantine directory."
			continue
		fi
	fi

	# check that subject exists in image import qc log
	if [ -z $(grep -P "${sub}\\t${ses}" ${qc_log} | awk '{print $1}') ]; then
		echo "ERROR: ${sub}: ${ses} is not present in image import QC log. Rerun."
		exit
	fi

	bidsdir=${rawdir}/${sub}/${ses}/func
	# loop over tasks
	for task in ${tasks}; do 
		# check that scans exist
		if [ ! -f $(echo ${bidsdir}/${sub}_${ses}_task-${task}*.nii.gz | awk '{print $1}') ]; then
			continue
		fi

		# check that tsv files aren't already processed
		first_tsv=$(echo ${bidsdir}/${sub}_${ses}_task-${task}*events.tsv | awk '{print $1}')
		if [ -f ${first_tsv} ] && \
		   [ $(wc -l ${first_tsv} | awk '{print $1}') -ne 0 ]; then
			echo "${sub}: ${ses}, ${task} has already completed conversion"
			continue
		fi

		# check that behav files exist
		case ${task} in
			conflict)
				task_name="conflict*.csv"
				;;
			face)
				task_name="FaceMatching*.log"
				;;
			gambling)
				task_name="Gambling*.log"
				;;
		esac
		behav_files=${sesdir}/behav_data/*${task_name}
		# if this is conflict, filter out the _1.csv file
		if [ ${task} == "conflict" ]; then
			behav_files=$(echo ${behav_files} | tr ' ' '\n' | grep -v _1.csv | tr '\n' ' ')
		fi

		# check length of behav_files
		if [ $(echo ${behav_files} | wc -w) -gt 1 ]; then
			echo "ERROR: ${sub}: ${ses}, has more than one ${task} files"
			exit
		elif [ ! -f ${behav_files} ]; then
			echo "WARNING: ${sub}: ${ses}, is missing ${task} files."
		fi

		# parse blocks to skip
		skip_col=$(head -1 ${qc_log} | tr '\t' '\n' | grep -n ${task} | awk -F ':' '{print $1}')
		skips=$(grep -P "${sub}\\t${ses}" ${qc_log} | awk -v var=${skip_col} -F '\t' '{print $var}')
		if [ -z ${skips} ]; then
			skips=NA
		fi

		# run gen script
		echo "Generating events.tsv for ${sub}: ${ses}, ${task}"
		./gen_events.py ${task} ${bidsdir} ${behav_files} ${skips}
	done
done
echo
