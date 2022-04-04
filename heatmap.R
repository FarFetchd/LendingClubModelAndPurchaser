library(gplots)

# bucket bad probs ONLY for heat mapping.
thedf$bucketedBadProb <- round(thedf$badProbs*250)/250
thedf$bucketedBadProb <- round(thedf$bucketedBadProb*125)/125
#thedf$bucketedBadProb <- round(thedf$bucketedBadProb*62.5)/62.5

interestSeq <- sort(unique(thedf$bucketedInt[thedf$bucketedInt>=0.08 & thedf$bucketedInt<=0.195]))
badProbSeq <- sort(unique(thedf$bucketedBadProb[thedf$bucketedBadProb<=MAX_BADPROB_TO_CONSIDER]))

#Compute avg ROI and avg writeoff for all 2-D buckets.
tmpArrayAsMatR=rep.int(0,0)
tmpArrayAsMatW=rep.int(0,0)
for(interestBucket in interestSeq)
{
    for(badProbBucket in badProbSeq)
    {
        curAvgROI <-
            mean(thedf$realROI[which(thedf$bucketedInt == interestBucket &
                                     thedf$bucketedBadProb == badProbBucket)])
        curAvgROI <- ifelse(curAvgROI < -0.1, -0.1, curAvgROI)
        curAvgROI <- ifelse(curAvgROI > 0.15, 0.15, curAvgROI)

        curAvgWriteoff <-
            mean(thedf$realWriteoff[which(thedf$bucketedInt == interestBucket &
                                          thedf$bucketedBadProb == badProbBucket)])
        tmpArrayAsMatR<-c(tmpArrayAsMatR, curAvgROI)
        # When looking at writeoffs, cap it between (any significant amount, 0) so that we can
        # easily see broad regions with non-negligible chargeoff rates.
        curwritTemp = ifelse(curAvgWriteoff < 0, curAvgWriteoff, 0)
        tmpArrayAsMatW<-c(tmpArrayAsMatW, ifelse(curwritTemp < -0.05, -0.05, curwritTemp))
    }
}

#Convert raw ROI array into a matrix, for heatmapping.
avgROIbyBucket <-matrix(tmpArrayAsMatR,ncol=length(interestSeq),
                                         nrow=length(badProbSeq))
colnames(avgROIbyBucket) = as.character(interestSeq)
rownames(avgROIbyBucket) = as.character(badProbSeq)

#myGradient<-colorRampPalette(c("yellow", "orange", "red", "black", "green",
#                               "blue", "purple"))(n=299)
myGradient<-colorRampPalette(c("red","orange","black", "green","blue"))(n=299)
pdf(paste0(rfOutputFilename,"_record.pdf"))
heatmap.2(avgROIbyBucket, Rowv=NA, Colv=NA, dendrogram="none", trace="none",
          density.info="none", hclustfun="none", col=myGradient,
          #breaks=colorBreaks,
          xlab="Interest rate", ylab="RFprobBad",
          symm=FALSE,symkey=FALSE,scale="none")
dev.off()




avgWriteoffByBucket <-matrix(tmpArrayAsMatW,ncol=length(interestSeq),
                                         nrow=length(badProbSeq))
colnames(avgWriteoffByBucket) = as.character(interestSeq)
rownames(avgWriteoffByBucket) = as.character(badProbSeq)

writeoffGradient<-colorRampPalette(c("red", "black", "green"))(n=299)
pdf(paste0(rfOutputFilename,"_writeoffs.pdf"))
heatmap.2(avgWriteoffByBucket, Rowv=NA, Colv=NA, dendrogram="none",
          trace="none", density.info="none", hclustfun="none",
          col=writeoffGradient,
          #breaks=colorBreaks,
          xlab="Interest rate", ylab="RFprobBad",
          symm=FALSE,symkey=FALSE,scale="none")
dev.off()

print(paste0("Heatmapping done! See ",rfOutputFilename,
             "_record.pdf for bucketed crossval performance. "))
