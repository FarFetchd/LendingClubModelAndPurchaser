source("modelBuildingVars.R")

#inputs:
#no more than 6! unless you want to get into yucky colors.
# filenames = c("cleanerpareto_pr300_e1_mcw15.csv")
# filenames = c("cleanerpareto_pr300_e1_mcw10.csv",filenames)
# filenames = c("cleanerpareto_pr300_e07_mcw10.csv",filenames)
# filenames = c("cleanerpareto_pr200_e1_mcw12.csv",filenames)
# filenames = c("cleanerpareto_pr200_e1_mcw8.csv",filenames)
# filenames = c("cleanerpareto_pr200_e1_mcw10.csv",filenames)
#set output filename here:
# output_filename = "compare_cleanerpareto_300rounds.pdf"

compareScatterplots = function(filenames, output_filename)
{
  pdf(output_filename)

  i = 1
  all_colors = c("black", "red", "orange", "green", "blue", "purple")
  named_colors = ""
  for (name in filenames)
  {
    named_colors = paste(named_colors, filenames[i], ":", all_colors[i], ",")
    i = i+1
  }

  i = 1
  for (name in filenames)
  {
    df = read.csv(filenames[i], h=T)
    if (i == 1)
    {
      plot(df$ROIavg, df$fractaken,
           xlim=c(MIN_INTERESTING_ROI, 0.095), ylim=c(MIN_INTERESTING_FRACTAKEN, 0.07),
           col="black", main=named_colors, sub="remember, you can select-all title and copy it!")
    }
    else
    {
      points(df$ROIavg, df$fractaken, col=all_colors[i])
    }
    i = i+1
  }
  dev.off()
}
