#!/bin/bash

TEST=""
TESTMESSAGE=" for release"
if [ "$1" = "-t" ]
then
  TEST="--unit-test"
  TESTMESSAGE=" with unit tests for testing"
fi

: ${CIQ_TARGET:="fenix5plus"}
PROJECT=`basename $PWD`
TARGETPOSTFIX=""
if [ $CIQ_TARGET = "fr920xt" ]
then
  TARGETPOSTFIX="_sim"
fi

echo "Updating font filters"
./filter.sh

for jungle in ./monkey-*.jungle; do
  LANGUAGE=`echo $jungle | sed -e "s/^.*monkey-\(.*\).jungle.*$/\1/g"`
  echo "Building $LANGUAGE$TESTMESSAGE"
  if [ $TEST ]
  then
    filename="releases/AboutTime-$LANGUAGE-$CIQ_TARGET.prg"
    CMD="monkeyc -f $jungle -f monkey.jungle -d ${CIQ_TARGET}${TARGETPOSTFIX} -y ~/garmin/developer_key.der -o $filename $TEST"
    echo $CMD
    monkeyc -f $jungle -f monkey.jungle -d ${CIQ_TARGET}${TARGETPOSTFIX} -y ~/garmin/developer_key.der -o $filename $TEST
  else
    filename="releases/AboutTime-$LANGUAGE.iq"
    CMD="monkeyc -f $jungle -e -y ~/garmin/developer_key.der -o $filename"
    echo $CMD
    monkeyc -f $jungle -e -y ~/garmin/developer_key.der -o $filename
  fi
  echo "Built $filename"
done
