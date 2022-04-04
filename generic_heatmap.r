library(gplots)

# NOTE: replace spending, returns, and needed with your desired two axes and color features.
pdf("yourheatmap.pdf")

colSeq <- sort(unique(df$spending))
rowSeq <- sort(unique(df$returns))

tmpArrayAsMat=rep.int(0,0)
for(colBucket in colSeq)
{
    for(rowBucket in rowSeq)
    {
        cur <-
            mean(df$needed[which(df$spending == colBucket &
                                     df$returns == rowBucket)])
        tmpArrayAsMat<-c(tmpArrayAsMat, cur)
    }
}

#Convert raw ROI array into a matrix, for heatmapping.
theMatrix <-matrix(tmpArrayAsMat,ncol=length(colSeq),
                                         nrow=length(rowSeq))
colnames(theMatrix) = as.character(colSeq)
rownames(theMatrix) = as.character(rowSeq)

#myGradient<-colorRampPalette(c("yellow", "orange", "red", "black", "green",
#                               "blue", "purple"))(n=299)
myGradient<-colorRampPalette(c("red","orange","black", "green","blue"))(n=299)
heatmap.2(theMatrix, Rowv=NA, Colv=NA, dendrogram="none", trace="none",
          density.info="none", hclustfun="none", col=myGradient,
          #breaks=colorBreaks,
          xlab="x axis", ylab="y axis",
          symm=FALSE,symkey=FALSE,scale="none")
dev.off()
