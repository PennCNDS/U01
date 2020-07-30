#!/bin/env Rscript

for (run in 1:4) {
	faces_fearful <- read.table(paste0('run', run, '_face_fearful.txt'))
	faces_neutral <- read.table(paste0('run', run, '_face_neutral.txt'))
	houses_fearful <- read.table(paste0('run', run, '_house_fearful.txt'))
	houses_neutral <- read.table(paste0('run', run, '_house_neutral.txt'))

	faces_fearful$emotion <- 'fearful'; faces_fearful$attention <- 'faces'
	faces_neutral$emotion <- 'neutral'; faces_neutral$attention <- 'faces'
	houses_fearful$emotion <- 'fearful'; houses_fearful$attention <- 'houses'
	houses_neutral$emotion <- 'neutral'; houses_neutral$attention <- 'houses'

	data <- rbind(faces_fearful, faces_neutral, houses_fearful, houses_neutral)
	data$V3 <- NULL

	colnames(data)[1:2] <- c('onset', 'duration')
	
	# change duration
	data$duration <- 0.25
	# set generic
	data$generic <- 1
	# set fixation
	data$fixation <- 0 

	data <- data[order(data$onset),]

	# add back trimmed volumes
	data$onset <- data$onset + 8

	# do fixations
	stim_end <- 0
	for (n in 1:nrow(data)) {
		fixation <- 1
		onset <- stim_end
		duration <- data$onset[n] - onset
		stim_end <- data$onset[n] + data$duration[n]

		data <- rbind(data, data.frame(onset=onset, duration=duration, fixation=fixation, emotion=NA, attention=NA, generic=1))
	}

	# resort
	data <- data[order(data$onset),]

	# reorder columns
	data <- data[,c('onset', 'duration', 'fixation', 'emotion', 'attention', 'generic')]

	write.table(data, paste0('conflict_', run, '_events.tsv'), row.names=FALSE, quote=FALSE, sep='\t')
}
