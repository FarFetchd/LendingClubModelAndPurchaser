setwd(sub("\"\n", "", sub(".*LOANSPATH=\"", "", readChar("/etc/profile", file.info("/etc/profile")$size))))

a = read.csv("monitor/data/available_cash.csv", h=T)
a$date = as.Date(a$date)
s = read.csv("monitor/data/spent.csv", h=T)
s$date = as.Date(s$date)

for (i in seq(1, nrow(a)-1)) {
  diff = a$available[i+1] - a$available[i]
  if (diff > 1000) {
    est = round(diff / 1000) * 1000
    s_ind = which(s$date == a$date[i+1])
    if (length(s_ind) == 0) {
      next
    }
    if (min(s$spent[s_ind]) >= 0) {
      for (j in seq(nrow(s), 1)) {
        if (s$date[j] == a$date[i+1]) {
          s$spent[j] = s$spent[j] - est
          #print(paste(s$date[j], est))
          break
        }
      }
    }
  }
}

write.csv(s, "monitor/data/spent.csv", row.names=F)
