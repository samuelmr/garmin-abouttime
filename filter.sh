#!/bin/bash
TMPFILE1=./filter.tmp
TMPFILE2=./filter2.tmp
touch $TMPFILE1
for filename in ./resources-*/strings.xml; do
  [ -e "$filename" ] || continue
  # echo $filename
  # cat $filename | tr '\n' ' ' | sed -e 's/[ \|]*//g' -e 's/<[^>]*>//g'
  cat $filename | tr '\n' ' ' | sed -e 's/ //g' -e 's/\$.\$//g' -e 's/<[^>]*>//g' >> $TMPFILE1
done
grep -o . $TMPFILE1 | sort -u > $TMPFILE2
cat $TMPFILE2 | tr '\n' ' ' | sed -e 's/ //g' | sed -e 's/|/ /g'
rm $TMPFILE1 $TMPFILE2
