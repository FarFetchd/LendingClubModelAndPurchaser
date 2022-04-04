
paretoFront = function(avgNonNA)
{
  parfront <- subset(avgNonNA, ROIavg > MIN_INTERESTING_ROI & fractaken > MIN_INTERESTING_FRACTAKEN)
  THE_BAR_WIGGLE = 0.0004
  while (T)
  {
    i=1
    start_rows = nrow(parfront)
    while (i <= nrow(parfront))
    {
      cur_bar_frac = parfront$fractaken[i] - THE_BAR_WIGGLE
      cur_bar_avg = parfront$ROIavg[i] - THE_BAR_WIGGLE
      parfront = subset(parfront, fractaken >= cur_bar_frac | ROIavg >= cur_bar_avg)
      i = i+1
    }
    if (start_rows == nrow(parfront))
      break
  }
  print(paste("Pruned down to",nrow(parfront),"points"))
  parfront<-parfront[order(parfront$ROIavg),]
  return(parfront)
}
