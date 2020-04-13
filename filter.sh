#!/bin/bash
TMPFILE1=./filter.tmp
TMPFILE2=./filter2.tmp
for directory in ./resources-*; do
  if [ $directory = "./resources-smallscreen" ] || [ $directory = "./resources-fr920xt" ] || [ $directory = "./resources-venu" ]
  then
    continue
  fi
  cd $directory
  [ -L "bitmaps.xml" ] || ln -s ../resources/bitmaps.xml .
  [ -L "images" ] || ln -s ../resources/images .
  [ -f "settingstrings.xml" ] || cp ../resources/settingstrings.xml .
  [ -L "settings.xml" ] || ln -s ../resources/settings.xml .
  [ -e "resource" ] || mkdir resource
  cd resource
  [ -L "fonts" ] || ln -s ../../resources/resource/fonts .
  [ -e "resources.xml" ] || cp ../../resources/resource/resources.xml .
  [ -e "iconfont.xml" ] || ln -s ../../resources/resource/iconfont.xml .
  echo "0123456789%.km " > $TMPFILE1
  cat ../strings.xml | tr '\n' ' ' | sed -e 's/ //g' -e 's/\$.\$//g' -e 's/<[^>]*>//g' >> $TMPFILE1
  grep -o . $TMPFILE1 | sort -u > $TMPFILE2
  cat $TMPFILE2 | tr '\n' ' ' | sed -e 's/ //g' | sed -e 's/	/ /g' | sed -e 's/|/ /g' > $TMPFILE1
  FILTERSTR=`cat $TMPFILE1`
  echo "${directory}	${FILTERSTR}"
  sed -e "s/filter=\".*\"/filter=\"${FILTERSTR}\"/g" resources.xml > $TMPFILE2
  mv $TMPFILE2 resources.xml
  rm $TMPFILE1
  cd ../..
done
