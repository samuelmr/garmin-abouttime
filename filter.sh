#!/bin/bash
TMPFILE1=filter.tmp
TMPFILE2=filter2.tmp
for directory in ./resources-*; do
  cd $directory
  [ -L "bitmaps.xml" ] || ln -s ../resources/bitmaps.xml .
  [ -L "images" ] || ln -s ../resources/images .
  [ -f "settingstrings.xml" ] || cp ../resources/settingstrings.xml .
  [ -L "settings.xml" ] || ln -s ../resources/settings.xml .
  echo "0123456789%.:km " > $TMPFILE1
  cat strings.xml | tr '\n' ' ' | sed -e 's/ //g' -e 's/\$.\$//g' -e 's/<[^>]*>//g' >> $TMPFILE1
  grep -o . $TMPFILE1 | sort -u > $TMPFILE2
  cat $TMPFILE2 | tr '\n' ' ' | sed -e 's/ //g' | sed -e 's/	/ /g' | sed -e 's/|/ /g' > $TMPFILE1
  FILTERSTR=`cat $TMPFILE1`
  rm $TMPFILE1
  rm $TMPFILE2
  echo "${directory}	${FILTERSTR}"
  for resource in resource small large fr920xt; do
    [ -e $resource ] || mkdir $resource
    cd $resource
    [ -L "fonts" ] || ln -s ../../resources/$resource/fonts .
    [ -e "resources.xml" ] || cp ../../resources/$resource/resources.xml .
    [ -L "iconfont.xml" ] || ln -s ../../resources/$resource/iconfont.xml .
    sed -e "s/filter=\".*\"/filter=\"${FILTERSTR}\"/g" resources.xml > $TMPFILE1
    mv $TMPFILE1 resources.xml
    cd ..
  done
  cd ..
done
