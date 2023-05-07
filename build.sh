#!/bin/bash

TEST=""
TESTMESSAGE="for release"
PUBLISH=0

while getopts ":tp" opt; do
  case $opt in
    t)
      TEST="--unit-test"
      TESTMESSAGE="with unit tests for testing"
      ;;
    p)
      PUBLISH=1
      TESTMESSAGE="for immediate publishing"
      ;;
  esac
done
shift $((OPTIND - 1))

TRANSLATION="$1"
if [ -z "$1" ]; then # empty; compile all translations
  TRANSLATION="*"
fi

: ${CIQ_TARGET:="fenix5plus"}
PROJECT=`basename $PWD`
TARGETPOSTFIX=""
if [ $CIQ_TARGET = "fr920xt" ]; then
  TARGETPOSTFIX="_sim"
fi

echo "Updating font filters"
./filter.sh

for jungle in ./monkey-$TRANSLATION.jungle; do
  LANGUAGE=`echo $jungle | sed -e "s/^.*monkey-\(.*\).jungle.*$/\1/g"`
  echo "Building $LANGUAGE $TESTMESSAGE"
  if [ $TEST ]; then
    filename="releases/AboutTime-$LANGUAGE-$CIQ_TARGET.prg"
    CMD="monkeyc -f $jungle -d ${CIQ_TARGET}${TARGETPOSTFIX} -y $CIQ_KEYFILE -o $filename $TEST"
  else
    filename="releases/AboutTime-$LANGUAGE.iq"
    CMD="monkeyc -f $jungle -e -y $CIQ_KEYFILE -o $filename"
  fi
  echo $CMD
	$CMD && echo "Built $filename"
  if [ $PUBLISH -eq 1 ]; then
    echo "Publishing $filename"
    node ./publish.js $LANGUAGE
  fi
done
