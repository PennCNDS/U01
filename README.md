# U01
Dimensional connectomics of anxious misery



This repository contains scripts related to the generation of task files associated with U01 imaging data. 

task

  -assign_souce.sh: contains code that unpacks task data and assigns them to specific NDARS of associated subjects
  
  -gen_events_conflict.sh: script that will generate the .tsv files for the conflict task
  
  -gen_events_face.sh: script that will generate events.tsv file for faceMatching task
  
  -gen_events_gambling.sh: script that will generate events.tsv file for gambling task
  
  -wrapper_gen_events: loops over each subject's source behavioral data and generate a BIDS compliant events.tsv file
  
anonymize: contains scripts related to the anonymization of previously generated task files

generic_events: contains templates for generation of subjects-specific task files
