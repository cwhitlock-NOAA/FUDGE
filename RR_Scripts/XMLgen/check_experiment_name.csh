#!/bin/csh -f

echo " "
echo "   CHECKING IF EXPERIMENT and/or related-files ALREADY EXISTS"
echo " "
unset exists
set preExistOpt = "exit"
set expDir = /home/esd/PROJECTS/DOWNSCALING/SUBPROJECTS/RR

#check if experiment directory exists in expDir
if (-e $expDir/$1) then
  set exists
  echo "   >> $expDir/$1 exists. Do you want to overwrite?"
  echo -n "   >> Enter y for 'yes'; Enter n or hit the 'Enter' key for 'no' :"
  set opt=$<
  echo "$opt" >> ./InputValues.txt
  if($opt == "y") then
    set preExistOpt = "erase" 
    echo " "
    echo "   NOTE: All data for $1 experiment will be erased when experGen runs this XML."
    echo " "
  else 
    echo " "
    echo "   OK. You do not want to overwrite $1."
    echo "   Please re-run XMLgen with new experiment name."
    echo "   Exiting."
    echo " "
  endif
  exit 0
else
  echo "   $expDir/$1 does not exists."
endif

#
#if experiment directory DOES NOT exist then check for earlier versions of XML & related text files 
# that will be backed-up


set datetime=`date +%m.%d.%Y-%k.%M.%S`

set notfound
if (-e $expDir/XML/$1.xml) then
  echo "   Found $expDir/XML/$1.xml"
  \mv $expDir/XML/$1.xml $expDir/XML/$1.xml.$datetime.backup
  echo "   Moved $expDir/XML/$1.xml to $expDir/XML/$1.xml.$datetime"
  unset notfound
  sleep 2
endif  
if (-e $expDir/XMLtxt/$1.log) then
  \mv $expDir/XMLtxt/$1.log $expDir/XMLtxt/$1.log.$datetime
  echo "   Found $expDir/XMLtxt/$1.log"
  echo "   Moved $expDir/XMLtxt/$1.log to $expDir/XMLtxt/$1.log.$datetime"
  unset notfound
  sleep 2
endif
if (-e $expDir/XMLtxt/$1.input.txt) then
  echo "   Found $expDir/XMLtxt/$1.input.txt"
  \mv $expDir/XMLtxt/$1.input.txt $expDir/XMLtxt/$1.input.txt.$datetime
  echo "   Moved $expDir/XMLtxt/$1.input.txt to $expDir/XMLtxt/$1.input.txt.$datetime"
  unset notfound
  sleep 2
endif

if ($?notfound) echo "   No other XML text files found."
echo "   Proceeding."
echo " "
echo "========================================================== "
echo " "
sleep 5

exit 0
