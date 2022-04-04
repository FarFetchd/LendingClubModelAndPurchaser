#Get the header from one of the data files. This way, if they add fields, don't
#have to manually update the header. (Obviously, if they rename collections_12_mths_ex_med,
#would need to change this. Less obviously: if the change *other* names, that the R stuff
#uses, would have to go change that R stuff).
grep collections_12_mths_ex_med LoanStats_securev1_2017Q1.csv >TEMPHEADER
STRTEST=`diff TEMPHEADER HEADER`
if [ -z "$STRTEST" ] ; then
  rm TEMPHEADER
else
  echo "*******************************************************"
  echo "*******************************************************"
  echo "*******************************************************"
  echo "*******************************************************"
  echo "          HEADER CHANGED!!!! USING NEW HEADER!!!"
  echo "     You should check to be sure they didn't change"
  echo "     any field names. If they did, you need to update"
  echo "         R's parsing, to use those new field names."
  echo "*******************************************************"
  echo "*******************************************************"
  echo "*******************************************************"
  echo "*******************************************************"
  mv TEMPHEADER HEADER
fi

rm -f tempCombined
for file in `ls LoanStats*.csv` ; do
  echo "now cleaning the dates in $file"
  # NOTE: the 1d;2d deletes the first two lines: "Notes offered by prospectus",
  #       and the .csv header.
  sed '1d;2d; s/"Jan-\([0-9][0-9][0-9][0-9]\)"/"\1-01-15"/g;s/"Feb-\([0-9][0-9][0-9][0-9]\)"/"\1-02-15"/g;s/"Mar-\([0-9][0-9][0-9][0-9]\)"/"\1-03-15"/g;s/"Apr-\([0-9][0-9][0-9][0-9]\)"/"\1-04-15"/g;s/"May-\([0-9][0-9][0-9][0-9]\)"/"\1-05-15"/g;s/"Jun-\([0-9][0-9][0-9][0-9]\)"/"\1-06-15"/g;s/"Jul-\([0-9][0-9][0-9][0-9]\)"/"\1-07-15"/g;s/"Aug-\([0-9][0-9][0-9][0-9]\)"/"\1-08-15"/g;s/"Sep-\([0-9][0-9][0-9][0-9]\)"/"\1-09-15"/g;s/"Oct-\([0-9][0-9][0-9][0-9]\)"/"\1-10-15"/g;s/"Nov-\([0-9][0-9][0-9][0-9]\)"/"\1-11-15"/g;s/"Dec-\([0-9][0-9][0-9][0-9]\)"/"\1-12-15"/g;' "$file" >>tempCombined
done

cat HEADER tempCombined > combined.csv
rm tempCombined

echo "import_LC_historical.R after this!"

