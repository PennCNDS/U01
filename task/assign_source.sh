#!/bin/bash

# Unpack zip and assign task files to NDARs

data_root=../../..
sourcedir=${data_root}/source
taskdir=${data_root}/task_files_dump
zipfile=${taskdir}/U01_Data-20200428T191132Z-001.zip # re-assign this every time you want to update
ndarfile=${data_root}/../analysis/data/metadata/clean/ndar_alpha_status.csv

# unzip zip file
if [ -d ${taskdir}/U01_Data ]; then
	echo "ERROR: zip file was already unzipped"
#	exit
else
	unzip ${zipfile} -d ${taskdir}
fi

for subdir in ${taskdir}/U01_Data/*/*; do 
	alpha=$(basename ${subdir})
	ndarlines=$(grep ,${alpha}, ${ndarfile})
	if [ $(grep ,${alpha}, ${ndarfile} | wc -l) -eq 0 ]; then
		echo "ERROR: ${alpha} was not found in ${ndarfile}"
		exit
	elif [ $(grep ,${alpha}, ${ndarfile} | wc -l) -gt 1 ]; then
		ndar1=$(grep ,${alpha}, ${ndarfile} | awk -F ',' '{print $1}' | head -1)
		ndar2=$(grep ,${alpha}, ${ndarfile} | awk -F ',' '{print $1}' | tail -1)
		echo "WARNING: ${subdir} has two NDARs: ${ndar1}, ${ndar2} : Assign manually."
		continue
	fi

	# else alpha as a unique ndar, move all files
	ndar=$(grep ,${alpha}, ${ndarfile} | awk -F ',' '{print $1}')

	# parse dates based on dicom header
	sesdirs=$(echo ${sourcedir}/sub-${ndar}/ses-*)
	if [ ! -d $(echo ${sesdirs}/dicom | awk '{print $1}') ]; then
		echo "ERROR: ${ndar} has not had their images imported"
		continue
	fi

	# loop through source directories and assign by date
	for sesdir in ${sesdirs}; do 
		# parse date of scan based on DICOM header
		dcm=$(echo ${sesdir}/dicom/*.dcm | awk '{print $1}')
		if [ ! -f ${dcm} ]; then
			echo "ERROR: ${dcm} does not exist. Exiting."
			exit
		fi
		scandate=$(dicom_hdr ${dcm} | grep "ID Acquisition Date" | awk -F '//' '{print $NF}')
		taskdate=$(date --date="${scandate}" +'%Y_%b_%d')
		
		# look for the date in the behav files
		onfiles=${subdir}/*${taskdate}*
		dest=${sesdir}/behav_data
		if [ ! -f $(echo ${onfiles} | awk '{print $1}') ]; then
			continue # this subject does not have this date in their behav directory
		elif [ -d ${dest} ]; then
			continue # this subject already has a behav_data directory
		else
			echo "Copying files for ${sesdir}"
			# copy onfiles to destination # NOTE: I am assuming that files with the same name are identical
			mkdir ${dest}
			rsync ${onfiles} ${dest}
		fi
	done
done
