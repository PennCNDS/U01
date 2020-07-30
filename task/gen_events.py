#!/bin/env python

import json
import glob
import sys
import os
import re
import shutil

# parse args
task = sys.argv[1]
funcdir = sys.argv[2]
behavfile = sys.argv[3]
skips = sys.argv[4]

# sort the available scans
scans = glob.glob(funcdir + '/*' + task + '*_bold.json')
scan_times = []
for scan in scans:
	# open json file, get acquisition time
        with open(scan, 'r') as f:
                data = json.load(f)

        scan_times.append(data['AcquisitionTime'])

scan_dict = dict(zip(scan_times, scans))
scans_ordered = []
for scan in sorted(scan_dict):
	scans_ordered.append(scan_dict[scan])

# turn into a string
tsv_list = ','.join([re.sub('_bold.json', '_events.tsv', x) for x in scans_ordered])

# check if behavfiles are real files
if (not os.path.exists(behavfile)):
	# parse skips and tsv_list
	skips_list = skips.split(',')
	tsv_list_parsed = tsv_list.split(',')	

	if (task == 'gambling'):
		print('ERROR: Generic timings do not exist for gambling task.')
	elif (task == 'conflict'):
		runs = [x for x in ['1', '2', '3', '4'] if x not in skips_list]
		# copy over generic timings
		[shutil.copyfile('generic_events/conflict_' + x + '_events.tsv', y) for x, y in zip(runs, tsv_list_parsed)]
	elif (task == 'face'):
		runs = [x for x in ['1', '2'] if x not in skips_list]
		# copy over generic timings
		[shutil.copyfile('generic_events/face_' + x + '_events.tsv', y) for x, y in zip(runs, tsv_list_parsed)]
else:
	# submit to run script
	if task == 'conflict':
		os.system('./gen_events_conflict.R ' + behavfile + ' ' + tsv_list + ' ' + skips)
	elif task == 'face':
		os.system('./gen_events_face.sh ' + behavfile + ' ' + tsv_list + ' ' + skips)
	elif task == 'gambling':
		os.system('./gen_events_gambling.sh ' + behavfile + ' ' + tsv_list + ' ' + skips)
