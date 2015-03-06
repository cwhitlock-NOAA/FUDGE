#!/bin/csh -f
source /usr/local/Modules/default/init/csh

#The XML is for the Red River Project
  set exp_prefix = "RR"

# Directory where this xml script & associated files sits
# set xmlGenDir = "${CODEBASE}${BRANCH}/fudge2014/RR_Scripts/XMLgen"
  set xmlGenDir = "/home/esd/local/opt/fudge/cinnamon/fudge2014/RR_Scripts/XMLgen"

  set cDir=`pwd`
  set datetime=`date +%m.%d.%Y-%k.%M.%S`
# workDir is removed at the end of this script
  set workDir=/nbhome/esd/work.XMLgen.$datetime
  if (-e  $workDir) then
    echo "Seriously?? Someone else is running this at exactly the same moment?? What are the odds!"
    echo "Try again."
    exit 1
  endif

  mkdir -p $workDir
  cd $workDir

  echo "    "
  echo "    "
  echo "    For Red River Experimentsi: "
  echo "      - livneh is used for the 'historical target'"
  echo "      - a pre-defined realization (RIP), evaluated to be the best, is used for the GCM the user selects to be used for the 'historical predictor'. "
  echo " "
  echo "    Pick an option for selecting the 'future predictor':"
  set opt
  while ($opt != 1 && $opt != 2) 
     echo " Option  Description"
     echo " ------  -----------"
     echo "   1     Run:  $xmlGenDir/XMLgen.csh "
     echo "         NOTE: The 'future predictor' can not be a GCM 'historical' epoch, and the RIP will be the same as that for the 'historical predictor', which is pre-defined based on GCM experiment selection."
     echo "     "
     echo "   2     Run: $xmlGenDir/XMLgen.pick_rips.csh"
     echo "         NOTE: User selects both the epoch and RIP for 'future predictor'. The 'historical predictor' is a pre-defined RIP based on GCM experiment selection."
     echo " "
     echo "    Enter the option number, or just hit Enter if you wish to exit."
     echo " "
     set opt=$<
     echo "$opt" > ./InputValues.txt
  
     if ($opt == "") then
        echo "Exiting"
        exit 0
     endif
     if ($opt != 1 && $opt != 2) echo "You selected $opt , which is not valid."
  end

  if ($opt == 1) source $xmlGenDir/XMLgen.csh
  if ($opt == 2) source $xmlGenDir/XMLgen.pick_rips.csh
