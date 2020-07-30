#!/bin/bash

# Anonymize behavioral data

data=${1} # path to the raw data file
outfile=${2} # path to the anonymized data

cp ${data} ${outfile}


# TODO: remove all PHI and dates of administration
