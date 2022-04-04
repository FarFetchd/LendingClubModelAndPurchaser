
#Throw out (bad) loans recent enough that good loans wouldn't have finished.
#(But then restore them once we're done here, so other runs can train on them).
thedf <- df
thedf <- subset(thedf, (TERM==36 & issue_d < as.Date(THREE_YEARS_AGO)) |
                (TERM==60 & issue_d < as.Date(FIVE_YEARS_AGO)))
print(paste0("Evaluating on ",nrow(thedf)," loans"))

#Bucket to nearest half-%
thedf$bucketedInt <- round(thedf$INTEREST_RATE*200)/200

#print("now heatmapping...")
#source("heatmap.R")
#print("heatmapping done")

interestSeq <- sort(unique(thedf$bucketedInt[thedf$bucketedInt>=0.09 & thedf$bucketedInt<=0.14]))
thedf$bucketedBadProb <- round(thedf$badProbs*400)/400
badProbSeq <- sort(unique(thedf$bucketedBadProb[thedf$bucketedBadProb>=0.03 & thedf$bucketedBadProb<=MAX_BADPROB_TO_CONSIDER]))
ceilSeq <- sort(unique(thedf$bucketedInt[thedf$bucketedInt>=0.14 & thedf$bucketedInt<=0.19]))
print(paste0("intseq, badprobseq, ceilseq lengths are ",length(interestSeq)," ",length(badProbSeq)," ", length(ceilSeq)))

#give this function a which()-style set of indices.
#it will return a list() of: lo95 roi hi95 numfrac
selectionStats <- function(curIdx)
{
    NNN <- ifelse(length(thedf$realROI[curIdx]) > 1, length(thedf$realROI[curIdx]), 2)
    sampleMuHatI <- (1/(NNN-1)) * (sum(thedf$realROI[curIdx]) - thedf$realROI[curIdx])
    sampleMuHat <- (1/NNN) * sum(thedf$realROI[curIdx])
    svarsvarianceqrd <- (1/(NNN-1))*sum(thedf$realROI[curIdx]*thedf$realROI[curIdx])
                        - (NNN/(NNN-1))*sampleMuHat*sampleMuHat
    svariance <- sqrt(svarsvarianceqrd)
    conf95low  <- signif(sampleMuHat - (1.645 * svariance) / sqrt(NNN), digits=3)
    conf95high <- signif(sampleMuHat + (1.645 * svariance) / sqrt(NNN), digits=3)
    #conf99low <- sampleMuHat - (2.326 * svariance) / sqrt(NNN)
    #conf99high <- sampleMuHat + (2.326 * svariance) / sqrt(NNN)
    meanROI <- signif(sum(thedf$realROI[curIdx])/length(thedf$realROI[curIdx]), digits=3)

    return(list(conf95low,
                meanROI,
                conf95high,
                signif(length(curIdx) / length(thedf$realROI), digits=3),
                length(curIdx)))
}








# LOOOOOOOOOOOOOOOOOL actually slower than the old way. Oh well, it was a fun little challenge.
# library(rlist)
# print("STARTING NEW! TIME IS:")
# print(date())
# #NEW
# #
# #
# # Here's what this mess does:
# # Make a list: for each ceiling in ceilSeq (and similar for the other 2), there is a list entry with the indices whose
# # interest is under that ceiling.
# # Then, do set intersection.
# print("making ceil, thresh, prob index lists!")
# reversed_interestSeq = rev(interestSeq)
# ceil_idx_list = as.list(c())
# for (ceil in ceilSeq)
# {
  # single_entry = as.list(which(thedf$INTEREST_RATE <= ceil))
  # ceil_idx_list = list.append(ceil_idx_list, single_entry)
# }

# thresh_idx_list = as.list(c())
# for (thresh in reversed_interestSeq)
# {
  # single_entry = as.list(which(thedf$INTEREST_RATE >= thresh))
  # thresh_idx_list = list.append(thresh_idx_list, single_entry)
# }

# prob_idx_list = as.list(c())
# for (prob in badProbSeq)
# {
  # single_entry = as.list(which(thedf$badProbs <= prob))
  # prob_idx_list = list.append(prob_idx_list, single_entry)
# }

# print("doing set intersections!")
# newArrayAsDF=c()
# for(cur_ceil_ind in 1:length(ceilSeq))
# {
  # for(cur_thresh_ind in 1:length(reversed_interestSeq))
  # {
    # tempIdx = intersect(unlist(ceil_idx_list[[cur_ceil_ind]]), unlist(thresh_idx_list[[cur_thresh_ind]]))
    # for(cur_cutoff_ind in 1:length(badProbSeq))
    # {
      # selStats <- selectionStats(intersect(tempIdx, unlist(prob_idx_list[[cur_cutoff_ind]])))
      # newArrayAsDF<-c(newArrayAsDF, selStats[[1]], selStats[[2]], selStats[[4]], selStats[[5]],
                      # badProbSeq[cur_cutoff_ind], reversed_interestSeq[cur_thresh_ind], ceilSeq[cur_ceil_ind])
    # }
  # }
# }
# print("FINISHED NEW, WILL START OLD! TIME IS:")
# print(date())






#OLD
print("Assigning ordering to the cut-thresh-ceiling cube...")
#Assign a linear ordering to the cut-thresh-ceiling cube
curLinInd <- 1
cutoffsIterated <- list()
threshIterated <- list()
ceilingIterated <- list()
for(curceil in ceilSeq)
{
  for(c1 in badProbSeq)
  {
    for(t1 in rev(interestSeq))
    {
      cutoffsIterated[[curLinInd]] <- c1
      threshIterated[[curLinInd]] <- t1
      ceilingIterated[[curLinInd]] <- curceil
      curLinInd <- curLinInd + 1
    }
  }
}

print(paste0("length(cutoffsIterated) ",length(cutoffsIterated)))
print("Building array to become data frame...")
#the 95CI and numfrac stuff for plain rectangles, like in the old version
newArrayAsDF=rep.int(0,0)
for(i in seq(1,length(cutoffsIterated)))
{
    cutoff <- cutoffsIterated[[i]]
    thresh <- threshIterated[[i]]
    intceil <- ceilingIterated[[i]]
    curIdx <- which(thedf$badProbs <= cutoff &
                    thedf$INTEREST_RATE >= thresh &
                    thedf$INTEREST_RATE <= intceil)
    selStats <- selectionStats(curIdx)
    newArrayAsDF<-c(newArrayAsDF, selStats[[1]], selStats[[2]],
                    selStats[[4]], selStats[[5]], cutoff, thresh, intceil)
}














print("Making data frame...")
avgROIDF <-data.frame(t(matrix(newArrayAsDF,nrow=7)))
colnames(avgROIDF) <- c("ROI95lo","ROIavg","fractaken","numtaken",
                        "badProb","interest","intceil")
avgNonNA <- avgROIDF[!is.na(avgROIDF$ROIavg),]
write.csv(format(avgNonNA, digits=5),
          file = paste0(rfOutputFilename,"_all.csv"))

source("heatmap_results.r")
heatmap_of_thresholds(avgNonNA, paste0(rfOutputFilename,"_useful_overview_heatmap.pdf"))

source("pareto.r")
parfront = paretoFront(avgNonNA)

write.csv(format(parfront, digits=5),
          file = paste0(rfOutputFilename,"_pareto.csv"))
