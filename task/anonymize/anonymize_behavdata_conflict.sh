#!/bin/bash

# Anonymize behavioral data

data_root=../../../..
sourcedir=${data_root}/source
data=${1} # path to the raw data file
outfile=${2} # path to the anonymized data

cp ${data} ${outfile}

for sesdir in ${sourcedir}/sub-NDAR*/ses-*; do
        sub=$(echo ${sesdir} | awk -F '/' '{print $(NF-1)}')

for name in $data ; do 
	awk -F, '{$33="'$sub'"} {split($32,a,"_");$32=a[1]"_"a[2]}1' OFS=, $data > $outfile
	
	done
done
