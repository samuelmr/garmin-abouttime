#!/bin/bash

TRANSLATION=""
TEST=""
TESTMESSAGE="for release"
if [ "$1" = "-t" ]; then
  TEST="--unit-test"
  TESTMESSAGE="with unit tests for testing"
elif [ -z "$1" ]; then # empty; compile all translations
  TRANSLATION="*"
else
  TRANSLATION=$1
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
done
