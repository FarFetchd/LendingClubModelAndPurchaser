# given a _pareto.csv or _all.csv type results DF, make a heatmap.
# unlike the previous heatmaps, this is looking at interest and probBad
# as *thresholds* rather than buckets. So, should look pretty smooth.
# (And, if it doesn't look smooth around a nice spot, then that spot
#  only looks that nice due to luck).

# library(gplots)
heatmap_of_thresholds <- function(raw_df, outPdfName)
{
print("heatmap_of_thresholds is NOT IMPLEMENTED since we cant be sure to have gplots everywhere.")

# df = subset(raw_df, fractaken>0.01 & ROIavg > 0.06)
# interestSeq <- sort(unique(df$interest[df$interest < 0.18]))
# badProbSeq <- sort(unique(df$badProb[df$badProb < 0.42]))
# tmpArrayAsMatR=rep.int(0,0)
# for(interestThresh in interestSeq)
# {
#     for(badProbThresh in badProbSeq)
#     {
#         curAvgROI <-
#             mean(df$ROIavg[df$interest == interestThresh &
#                            df$badProb == badProbThresh])
#         tmpArrayAsMatR<-c(tmpArrayAsMatR, curAvgROI)
#     }
# }
# 
# 
# #Convert raw ROI array into a matrix, for heatmapping.
# avgROIbyBucket <-matrix(tmpArrayAsMatR,ncol=length(interestSeq),
#                                          nrow=length(badProbSeq))
# colnames(avgROIbyBucket) = as.character(interestSeq)
# rownames(avgROIbyBucket) = as.character(badProbSeq)
# myGradient<-colorRampPalette(c("white","black"))(n=299)
# pdf(outPdfName)
# heatmap.2(avgROIbyBucket, Rowv=NA, Colv=NA, dendrogram="none", trace="none",
#           density.info="none", hclustfun="none", col=myGradient,
#           #breaks=colorBreaks,
#           xlab="Interest threshold", ylab="RFprobBad cutoff",
#           symm=FALSE,symkey=FALSE,scale="none")
# dev.off()




}
