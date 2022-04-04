theIND=1
while read x; do
  wget -O "loanstats$theIND.zip" "$x"
  sleep 1
  theIND=$(( theIND + 1))
done <toDL.txt
