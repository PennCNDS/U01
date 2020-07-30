#!/bin/env Rscript

# this script will generate the TSV files for the conflict task
# it will split events into along these dimensions:
# (1) fixation: true, false
# (2) emotion:  neutral, fearful
# (3) attention: face, house
# (4) attended_items_match: true, false
# (5) non_attended_items_match: true, false
# (6) response_correct: true, false

# specify duration
dur <- 0.25 # in seconds

#### parse args ####
args <- commandArgs(trailingOnly=TRUE)
data_path <- args[1]
scans_string <- args[2]
skips_string <- args[3]

# read data
data <- read.csv(data_path, stringsAsFactors=FALSE, na.strings='[]')
# parse scans
scans <- strsplit(scans_string, split=',')[[1]]

# parse skips
if (skips_string == 'NA') {
	skips <- NA
} else {
	skips <- as.numeric(strsplit(skips_string, split=',')[[1]])
}

###################
# identify # of runs
nruns <- max(data$RunNumber)

# generate response variable
response <- rep(NA, nrow(data))
for (n in 1:nrow(data)) {
	response[n] <- ifelse(grepl(data$SameDiffResponse.keys[n], data$responseKeyDIFFERENT[n]), 'DIFFERENT',
                       ifelse(grepl(data$SameDiffResponse.keys[n], data$responseKeySAME[n]), 'IDENTICAL', NA))
}
data$response <- response

# loop over runs
k <- 0
for (run in 1:nruns) {
	# if this run should be skipped, continue
	if (run %in% skips) {
		next
	} else {
		k <- k + 1
	}
	ondata <- data[data$RunNumber==run,]
	
	# generate events rows first
	# standard info first
	onset <- ondata$ImageOnset
	duration <- rep(dur, length(onset))
	if ('SameDiffResponse.rt' %in% colnames(ondata)) {
		response_time <- ondata$SameDiffResponse.rt
	} else {
		response_time <- ondata$PressedKeyTimes
	}

	# trial_type information
	fixation <- rep(0, length(onset))
	emotion <- ifelse(ondata$facesAreFearful==1, 'fearful', 'neutral')
	attention <- ifelse(ondata$facesAreAttended==1, 'faces', 'houses')
	attended_items_match <- ifelse(ondata$attendedItemsMatch==1, 1, 0)
	non_attended_items_match <- ifelse(ondata$nonAttendedItemsMatch==1, 1, 0)
	response_correct <- ifelse(ondata$response==ondata$correctResponse, 1, 0)

	# create data.frame
	data.out <- data.frame(onset, duration, response_time,
                               fixation, emotion, attention,
                               attended_items_match, non_attended_items_match, response_correct)

	# do fixations
	stim_end <- 0
	for (trial in 1:nrow(data.out)) {
		fixation <- 1
		onset <- stim_end
		duration <- data.out$onset[trial] - onset
		stim_end <- data.out$onset[trial] + data.out$duration[trial]
		data.out <- rbind(data.out, 
                                  data.frame(onset=onset, duration=duration, response_time=NA,
                                             fixation=fixation, emotion=NA, attention=NA,
                                             attended_items_match=NA, non_attended_items_match=NA, response_correct=NA)
                                 )
	}

	# resort
	data.out <- data.out[order(data.out$onset),]
	
	# write
	write.table(data.out, file=scans[k], quote=FALSE, sep='\t', row.names=FALSE)
}
