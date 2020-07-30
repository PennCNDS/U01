#!bin/bash

#script to check for behavioral data associated with session


data_root=../../..
sourcedir=${data_root}/source


# loop over subject-sessions
for sesdir in ${sourcedir}/sub-*/ses-*; do
        sub=$(basename $(dirname ${sesdir}))
                ses=$(basename ${sesdir})

# check that behavior folder exists
        if [ ! -d ${sesdir}/behav_data ]; then
                        echo "ERROR: ${sub}: ${ses} is missing behavioral directory"
                fi

done


