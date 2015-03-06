#!/bin/csh -f
source /usr/local/Modules/default/init/csh

  set owner="$USER"

  echo " "
  echo "======================================================================================================= "
  echo " "
  echo " Welcome to the FUDGE XML generator for creating a Red River Project downscaling experiment XML file . "
  echo " "
  echo "======================================================================================================= "
  echo " "
  echo " "

# Check if running this as "esd". This affects who owns the root directories that ExperGen will use to write scripts/code/downscaled output.
  echo " You are running as user $owner"
  whoami|grep -i esd
   if ($status != 0) then
     echo " Please run as user esd."
     exit 1
   endif


#============================================================
# ASSUMPTIONS
#============================================================

# The directory where the experiment-specific scripts/ascii-files/code will be written once ExperGen executes.
  set scriptDir = "/home/$owner/PROJECTS/DOWNSCALING"
  if (! -e $scriptDir) mkdir -p $scriptDir
    if ($status != 0) then
      echo "mkdir -p $scriptDir  failed. Exiting. "
      if ($owner == $USER) exit 1
    endif

# The directory where the downscaled netCDF files will be written.
  set dsFileDir = "/archive/$owner/PROJECTS/DOWNSCALING/${exp_prefix}"

# These are files that will/may be used by this script
  set QueryVals = $xmlGenDir/QueryVals.csh
  set SetGCMrips = $xmlGenDir/SetGCMrips.csh
  set prAdjustment = "$xmlGenDir/pr_adjustment.csh"
  set qcAdjustment = "$xmlGenDir/QC_adjustment.csh"
  set qcOptions_file = "$xmlGenDir/QC_Options.txt"

#
# With no time_pruning yet available in fudge, assume that input files have been pruned
#   in PRE-PROCESSING step, so the years in the filenames match the years specified for 
#   historical training period and/or the future period
#
# However, time-pruning COULD be added so placeholders are created for this.
#
# Also, hard-wiring was done for 3 variables, 3 GCM experiment datasets, 4 epochs - 3 future scenarios and one historical. 
# At this time only one downscaling method, CDFt, is supported, though others can be added.
#

  set varList = (tasmax tasmin pr)
  set shortvarList = (tx tn pr)
  set dsMethodList = (CDFt BCQM EDQM)
  set gcmList = ("CCSM4" "MIROC5" "MPI-ESM-LR")
#
# To specify historical as "future predictor", please use XMLgen.pick_rips.csh
# set epochList = ("historical" "rcp26" "rcp45" "rcp85")
#
  set epochList = ("rcp26" "rcp45" "rcp85")

# timeMaskList = Time Masks we may want to use for Red River
# future time mask (aka esdgen time mask) will be the same as historical time mask prefix
# i.e. with the anything past the first "_" separator removed. 
# e.g. if historical time mask = "bymonth_pm2weeks" then future time mask = "bymonth".
#      if historical time mask = "byseason" then future time mask = "byseason".

#------------------

#
  set trainYr1 = 1961
  set trainYr2 = 2005
  set histTargFileYr1 = $trainYr1
  set histTargFileYr2 = $trainYr2
  set histPredFileYr1 = $trainYr1
  set histPredFileYr2 = $trainYr2

  set futureYr1 = 2006
  set futureYr2 = 2099
  set futPredFileYr1 = $futureYr1
  set futPredFileYr2 = $futureYr2

# Livneh version
  set livnehVs = "v1p2"
  if ($livnehVs == "v1p2") set obsID = "L01"
# if ($livnehVs == "v1p3") set obsID = "L02"

# ONLY set up so far for kfold = 0, but logic for kfold 
  set kfold = 0
  if ($kfold <= 9) set kfoldID = "K0$kfold"
  if ($kfold >= 10) set kfoldID = "K$kfold"


# platform ID for PPAN = p1
  set platformID = "p1"

#============================================================
# END ASSUMPTIONS
#============================================================

  echo " "
  echo "======================================================================================================= "
  echo " "
  echo " This script assumes that downscaling will be performed with the following characteristics:"
  echo " "
  echo " -  Scripts/files created by ExperGen will be written under $scriptDir ."
  echo " -  Downscaled output will be written under $dsFileDir ."
  echo " -  The Downscaling method you choose has its own file which prompts the user for options."
  echo "    (This file must be in $xmlGenDir and have the name of : "
  echo "        {DSMETHOD}_Options.csh where {DSMETHOD} = CDFt, BCQM or EDQM.)"
  echo " -  The target variable = the training variable."
  echo " -  All data are on the 0.1x0.1 degree common grid, with the grid region = SCCSC0p1."
  echo " -  Livneh data (version = $livnehVs) is used for the historical target."
  echo " -  The Red River region mask is being used. (project = Red River, short ID = 'RR')"
  echo " -  The historical time period of interest is 1961-2005."
  echo " -  The future time period of interest, if specifying a "future" predictor, is 2006-2099."
  echo " -  Predetermined preferred realizations for CCSM4, MIROC5, MPI-ESM-LR GCMS will be used for "
  echo "      historical and future scenarios for RR." 
  echo " "
  echo "======================================================================================================= "
  
# ===========================
# INPUT VALUES 
# ===========================
#
# TARGET VARIABLE
# ---------------
# prompt for target variable to use

  echo " "
  set varvals = ($varList)
  set dinfo = "Target variable"
  source $QueryVals
  set targVar = "$varvals[$kvar]"
  set varID = $shortvarList[$kvar]

# Downscaling Method 
# ---------------
# prompt for downscaling method to use

  echo " "
  set varvals = ($dsMethodList)
  set dinfo = "Downscaling method"
  source $QueryVals
  set dsMethod = "$varvals[$kvar]"
  set DSMethod_options =  $xmlGenDir/${dsMethod}_Options.csh

# Experiment Series ID
# --------------------
  echo " "
  echo "============================================="
  echo " "
  echo "  User's Experiment Name Input"
  echo " "
  echo "============================================="
  echo " "
  echo -n ">> Enter the Letter of the Experiment Series: "
    set expID=$<
    echo $expID 
#   stty echo
    echo " "
    echo $expID >> ./InputValues.txt
  echo -n ">> Enter a string to be added on to the Experiment Series name: "
    set expOptionID=$<
    echo $expOptionID
#   stty echo
    echo " "
    if ($expOptionID == "") then
     
    echo " " >> ./InputValues.txt
    else
    echo $expOptionID >> ./InputValues.txt
    endif



# TRAINING GCM DATA - HISTORICAL PREDICTOR
# ----------------------------------------

  echo " "
  set varvals = ($gcmList)
  set dinfo = "Historical Predictor dataset"
  source $QueryVals
  set histPredDataset = "$varvals[$kvar]"
# get RIP
  source $SetGCMrips $histPredDataset "historical"
  set histPredRIP = $myRip

# livneh RIP r0i0p0 is Julian calendar data
# livneh RIP r0i0p1 is NOLEAP calendar data
  if ("$histPredDataset" == "CCSM4") then
    set livnehRIP = "r0i0p1"
    set timemaskSuffix = ".NOLEAP"
    set datasetID = 1
  endif
  if ("$histPredDataset" == "MIROC5") then
    set livnehRIP = "r0i0p1"
    set timemaskSuffix = ".NOLEAP"
    set datasetID = 2
  endif
  if ("$histPredDataset" == "MPI-ESM-LR") then
    set livnehRIP = "r0i0p0"
    set timemaskSuffix = ""
    set datasetID = 3
  endif
  
# get version number from lookup table
  set histPredInfo = (`grep $histPredDataset $xmlGenDir/surface_variable_gcm_info |grep hist |grep $histPredRIP`)
  if ("$histPredInfo" == "") then 
    echo "PROBLEM: $histPredRIP does not appear to be available for $histPredDataset historical"
    set histPredavail = (`grep $histPredDataset $xmlGenDir/surface_variable_gcm_info |grep hist`)
    echo "$histPredavail"
    exit 1
  endif
  set histPredVs = $histPredInfo[4]

# TRAINING TIME WINDOW
# --------------------

  echo " "
#.....................................................................
# Uncomment following 2 lines for a more-generic time-window selection 
#    by finding all mask files in the timemask archive directory for
#    the historical period 1961-2005.
# cd /archive/esd/PROJECTS/DOWNSCALING/3ToThe5th/masks/timemasks/
# set varvals = (maskdays*${trainYr1}*${trainYr2}*nc)
#.....................................................................

  set timeMaskList = (bymonth byseason annual)
# bymonth_pm2weeks is not yet available. esdgen code has to be added to allow training on bymonth_pm2weeks, but then
#  bymonth mask applied to so no overlapping days.k
#  if ("$dsMethod" != "CDFt") set timeMaskList = (bymonth bymonth_pm2weeks byseason annual)

  set varvals = ($timeMaskList)
  set dinfo = "Training Time Window"
  source $QueryVals
  set trainTW = $varvals[$kvar]

  set trainTimeWindowFile="/archive/esd/PROJECTS/DOWNSCALING/3ToThe5th/masks/timemasks/maskdays_${trainTW}_${trainYr1}0101-${trainYr2}1231${timemaskSuffix}.nc"
  if (! -e $trainTimeWindowFile) then
    echo "PROBLEM: $trainTimeWindowFile  does not exist."
    echo " "
    exit 1
  else
    echo "............................................................................................."
    echo -n "   Training Time Window = "
    \ls -k "$trainTimeWindowFile"
    echo "............................................................................................."
    echo " "
  endif
  

# FUTURE GCM DATASET = Same as Historical Predictor
# But EPOCH will likely vary
# ----------------------------------------

  set futPredDataset = "$histPredDataset"
  
  echo " "
  set varvals = ($epochList)
  set dinfo = "Future Predictor epoch for $futPredDataset"
  source $QueryVals
  set futPredEpoch = "$varvals[$kvar]"
   if ($futPredEpoch == "historical") then
      set epochID = "0"
      set futureYr1 = $trainYr1
      set futureYr2 = $trainYr2
      set futPredFileYr1 = $histPredFileYr1
      set futPredFileYr2 = $histPredFileYr2
   else if ($futPredEpoch == "rcp26") then
      set epochID = "2"
   else if ($futPredEpoch == "rcp45") then
      set epochID = "4"
   else if ($futPredEpoch == "rcp85") then
      set epochID = "8"
   else
      echo "............................................................................................."
      echo "............................................................................................."
      echo " "
      echo "      PROBLEM: $futPredEpoch has not been added to $0 yet. Please edit file. Exiting."
      echo " "
      echo "............................................................................................."
      echo "............................................................................................."
      echo " "
      exit 1
   endif
  
   source $SetGCMrips $futPredDataset $futPredEpoch
     if($status != 0) exit 1
   set futPredRIP = $myRip

# get version number from lookup table
  set futPredInfo = (`grep "$futPredDataset" $xmlGenDir/surface_variable_gcm_info |grep $futPredEpoch |grep $futPredRIP`)
  if ("$futPredInfo" == "") then 
    echo "............................................................................................."
    echo "............................................................................................."
    echo "     PROBLEM: $futPredRIP does not appear to be available for $futPredDataset $futPredEpoch"
    echo "............................................................................................."
    echo "............................................................................................."
    set futPredavail = (`grep $futPredDataset $xmlGenDir/surface_variable_gcm_info |grep $futPredEpoch`)
    echo "$futPredavail"
    echo " "
    exit 1
  endif
  set futPredVs = $futPredInfo[4]

# "Future" (i.e.Independent sample) TIME WINDOW
# --------------------
echo " "
#.....................................................................
# Uncomment following 2 lines for a more-generic time-window selection 
#    by finding all mask files in the timemask archive directory .
# cd /archive/esd/PROJECTS/DOWNSCALING/3ToThe5th/masks/timemasks/
# set varvals = (maskdays*${futureYr1}*${futureYr2}*nc)
#.....................................................................

#  set varvals = ($timeMaskList)
#  set dinfo = "Future Time Window"
#  source $QueryVals
#  set futureTW = $varvals[$kvar]

# Set future time window based on the training time window value, trainTW
#
  set TWinfo = "$trainTW"
  set splitTWinfo = ($TWinfo:as/_/ /)
  set futureTW = "$splitTWinfo[1]"

  set futureTimeWindowFile="/archive/esd/PROJECTS/DOWNSCALING/3ToThe5th/masks/timemasks/maskdays_${futureTW}_${futureYr1}0101-${futureYr2}1231${timemaskSuffix}.nc"
  if (! -e $futureTimeWindowFile) then
    echo "PROBLEM: $futureTimeWindowFile  does not exist."
    echo " "
    exit 1
  else
    echo -n "   Future Time Window = "
    \ls -k "$futureTimeWindowFile"
    echo -n "   Training Time Window = "
    \ls -k "$trainTimeWindowFile"
    echo " "
  endif
  sleep 2

# ===================================================================================
# ===================================================================================
# ====== CREATE EXPERIMENT NAME BASED ON INPUTS THUS FAR

  set exp_hashtag="${expID}${datasetID}${epochID}${expOptionID}"
  set exp_label="$exp_hashtag$obsID"
  echo " "
  echo "--------------------------------------------------------------------------------------------"
  echo "............................................................................................."
  echo "............................................................................................."
  echo " "
  echo "   Based on your inputs:"
  echo " "
  echo "   ${exp_hashtag}  <= Experiment Hashtag "
  echo "   ${exp_label}  <= Experiment Label "
  echo " "
  set expName = "${exp_prefix}${varID}${platformID}-${dsMethod}-${exp_hashtag}${obsID}${kfoldID}"
  echo "   ${exp_prefix}${varID}${platformID}-${dsMethod}-${exp_hashtag}${obsID}${kfoldID} <= Experiment Name"
  echo " "


  set preExistOpt = "exit"
  source $xmlGenDir/check_experiment_name.csh $expName
    if($status != 0) exit 1

  echo " "
  echo "............................................................................................."
  echo "............................................................................................."
  echo "--------------------------------------------------------------------------------------------"
  echo " "
  
# ===================================================================================
# ===================================================================================
# ===================================================================================
#                                  CREATE XML
# ===================================================================================
# ===================================================================================
# ===================================================================================
echo " "
echo "   Creating XML ... "
echo " "
cat > XMLfile <<EOF
<downscale>
  <ifpreexist>$preExistOpt</ifpreexist>
    <input predictor_list = "$targVar" target = "$targVar" spat_mask = "/archive/esd/PROJECTS/DOWNSCALING/3ToThe5th/masks/geomasks/red_river_0p1/OneD/" maskvar = "red_river_0p1_masks">
        <grid region = "SCCSC0p1">
        <!-- lats, late are used to develop filenames -->
            <lons>181</lons>
            <lone>370</lone>
            <!-- lons, lone used by DSTemplate to specify minifiles-->
            <!-- can theoretically specify one minifile (useful for testing)-->
	    <!-- file_j_range used by DSTemplate to  identify minfile j suffix-->
	    <lats>31</lats>
	    <late>170</late>	
            <file_j_range>"J31-170"</file_j_range>
        </grid>
        <training>
            <historical_predictor
                file_start_time = "$histPredFileYr1"
                file_end_time = "$histPredFileYr2"
                train_start_time = "$trainYr1"
                train_end_time = "$trainYr2"
 		time_window = '$trainTimeWindowFile'
                >
                <dataset>GCM_DATA.CMIP5.${histPredDataset}.historical.atmos.day.${histPredRIP}.${histPredVs}</dataset><!--- we know that we want the tasmax, tasmin vars 
                in the id directory as specified in <input predictor_list = ""> -->
            </historical_predictor>
            <historical_target
                file_start_time = "$histTargFileYr1"
                file_end_time = "$histTargFileYr2"
                train_start_time = "$trainYr1"
                train_end_time = "$trainYr2"
		time_window = '$trainTimeWindowFile'
            >
                <dataset>OBS_DATA.GRIDDED_OBS.livneh.historical.atmos.day.${livnehRIP}.${livnehVs}</dataset>
                <!-- and in this case, we want the target var specified in <input> -->
            </historical_target>
            <future_predictor
                file_start_time = "$futPredFileYr1"
                file_end_time = "$futPredFileYr2"
                train_start_time = "$futureYr1"
                train_end_time = "$futureYr2"
                time_window = '$futureTimeWindowFile'
            >
               <dataset>GCM_DATA.CMIP5.${futPredDataset}.${futPredEpoch}.atmos.day.${futPredRIP}.${futPredVs}</dataset> <!-- still interested in predictor_list vars -->
            </future_predictor>
        </training>
        <esdgen>
            <!--For all methods at the moment, the future_predictor is specified instead of esdgen -->     
        </esdgen>
    </input>    
    <core>
    <!--THIS IS TOTALLY UNCHANGED EXCEPT FOR THE GRID SPECS-->
    <!--Specify the ESD METHOD USED-->
        <method name="$dsMethod"> </method>
	<exp_prefix>$exp_prefix</exp_prefix> 
	<exp_label>$exp_label</exp_label> 
	<exper_series>$exp_label</exper_series> 
	<project>Red River</project>
        <!--Specify the K-FOLD CROSS VALIDATION -->
        <kfold>
              $kfold <!-- "0" is required to run without cross-validation.-->
        </kfold>
        <!--specifies the OUTPUT DIRECTORY -->
        <output>
            <root>$dsFileDir</root>
            <script_root>$scriptDir</script_root>
        </output>
EOF

# ADD PR ADJUSTMENT XML
  if ($targVar == "pr") then
    echo "   Adding precip adjustment options to XML ... "
    source $prAdjustment
      if($status != 0) then
        echo "PROBLEM.  File $prAdjustment does not exist or has an issue to be checked."
        echo " "
        exit 1
      endif
    cat pr_XML >> XMLfile
    \rm pr_XML
  endif

  echo "    </core>" >> XMLfile
  echo "    <custom>" >> XMLfile

# ADD dsMethod options XML
  echo "   Adding $dsMethod options, if any,  to XML ... "
  source $DSMethod_options
    if($status != 0) then
      echo "PROBLEM.  File $DSMethod_options does not exist or has an issue to be checked."
      echo " "
      exit 1
    endif
   sleep 2

# END of CUMSTOM section
  echo "    </custom>" >> XMLfile

# post DS processing - QC adjustments
  echo "    <pp>" >> XMLfile
  source $qcAdjustment
  sleep 2
  cat QC_XML >> XMLfile
  \rm QC_XML
  echo "    </pp>" >> XMLfile


# Finalizing XMLfile 

  echo " "
  echo "==================="
  echo "Finalizing XML ... "
  echo "==================="
  echo " "
cat >> XMLfile<< EOF
    <exp_check exp_name='$expName'>
    </exp_check>
</downscale>
EOF


  if (-e $expName.xml) \mv $expName.xml $expName.xml.backup
  if (-e $expName.input.txt) \mv $expName.input.txt $expName.input.txt.backup
# set xmlDir=$scriptDir/scripts/$exp_prefix/$expName/XML
  set xmlDir=$scriptDir/scripts/$exp_prefix/XML
    if (! -e $xmlDir) mkdir -p $xmlDir
  set xmltxtDir=$scriptDir/scripts/$exp_prefix/XMLtxt
    if (! -e $xmltxtDir) mkdir -p $xmltxtDir
  \mv XMLfile $expName.xml
  \mv $expName.xml $xmlDir/$expName.xml
  \mv ./InputValues.txt $expName.input.txt
  \mv $expName.input.txt $xmltxtDir/$expName.input.txt
  echo " >>>  ......................................................................................."
  echo " >>>  ......................................................................................."
  echo " >>>  ......................................................................................."
  echo " >>>  "
  echo " >>>  Your XMLfile =  $xmlDir/$expName.xml " 
  chmod -w $xmlDir/$expName.xml
  echo " >>>  "
  echo " >>>  Inputs you entered are in $xmltxtDir/$expName.input.txt "
  echo " >>>  "
  $xmlGenDir/XMLchecker.py $xmlDir/$expName.xml
  echo " >>>  "
  echo " >>>  ......................................................................................."
  echo " >>>  ......................................................................................."
  echo " >>>  ......................................................................................."
  echo " "
cd $cDir
echo "Removing work directory $workDir"
sleep 3
\rm -rf $workDir/*
\rm -rf $workDir
