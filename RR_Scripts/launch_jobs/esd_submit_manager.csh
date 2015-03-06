#!/bin/csh -f
source /usr/local/Modules/default/init/csh

#module purge
module load fre

set parentdir = "$HOME/PROJECTS/DOWNSCALING/SUBPROJECTS"
set shortvarList = (tx tn pr)

 echo "============================================================"
 echo "This c-shell script $0"
 echo "allows user Oar.Gfdl.Esd to submit FUDGE masterscripts,"
 echo "based upon user input.  This scripts runs interactively"
 echo "on the GFDL Analysis cluster, and submits batchjobs to"
 echo "run on the GFDL PostProccessing cluster"

 set account = `whoami`
 /usr/bin/whoami | /bin/grep -i esd
 if ( $status !=  0 ) then
   echo " ###################"
   echo " ###    ERROR    ### "
   echo " ### whoami does not return Oar.Gfdl.Esd or esd "
   echo " ### instead it returns $account"
   echo " ### exiting $0 "
   echo " ###################"
   exit
 else
   echo " "
   echo " --- OK: whoami" 
   echo " "
 endif

 echo $HOSTNAME | /bin/grep an 
 if ( $status !=  0 ) then
   echo " ###################"
   echo " ###    ERROR    ### "
   echo " ### It appears you are not logged into an analysis node"
   echo " ### HOSTNAME = $HOSTNAME"
   echo " ### exiting $0 "
   echo " ###################"
   exit
 else
   echo " --- OK: HOSTNAME" 
   echo " "
 endif

 echo "(Assumes experiments are under $parentdir )"
 echo "There are 6 questions..."
 echo " "
 echo "============================================================"
 echo "Q1: What is the SUBPROJECT of the experiment to be run?"
 echo "    (valid arguments are the names of directories under"
 echo "    $home/PROJECTS/DOWNSCALING/SUBPROJECTS)"
 /bin/ls -1F  $home/PROJECTS/DOWNSCALING/SUBPROJECTS  | /bin/grep "/"
 echo "============================================================"
 echo ">>> Enter SUBPROJECT identifier (without trailing slash)"

 set opt=$<
 set exp_prefix = $opt
 if ( -d $parentdir/$exp_prefix ) then 
   echo " "
   echo " --- OK: SUBPROJECT" 
 else
   echo " ###################"
   echo " ###    ERROR    ### "
   echo " ### $parentdir/$exp_prefix DOES NOT EXIST"
   echo " ###    ERROR    ### "
   echo " ### exiting $0 "
   echo " ###################"
   exit
 endif

 echo " "
 echo "============================================================"
 echo "Q2: What climate variable is to be downscaled?"
 echo "    (valid arguments are $shortvarList )"
 echo "============================================================"
 echo ">>> Enter 2 character climate variable identifier"
 
 set opt=$<
 echo $opt
 set dsvar = $opt
 
 echo $dsvar

 @ foundvar = 0
 foreach  var ( $shortvarList )
   if ( $dsvar == $var ) then 
     @ foundvar = $foundvar + 1
   endif
 end

 if ( $foundvar == 1 ) then 
   echo " "
   echo " --- OK: downscaled climate var" 
 else
   echo " ###################"
   echo " ###    ERROR    ### "
   echo " ### your input for a variable ($dsvar)"
   echo " ### is is not in the list $shortvarList"
   echo " ###    ERROR    ### "
   echo " ### exiting $0 "
   echo " ###################"
   exit 1
 endif
 
 echo "==========================="
 echo " Potential Experiment Names"
 echo "==========================="
 cd $parentdir/$exp_prefix
 /bin/ls -ltF | /bin/grep $exp_prefix | /bin/grep $dsvar | /bin/grep K | /bin/grep -
    if ($status != 0) then
      echo " ###################"
      echo " ###    ERROR    ###"
      echo " ###    "
      echo " ### No experiments exist for $dsvar "
      echo " ### in $parentdir/$exp_prefix "
      echo " ###    "
      echo " ### exiting $0  "
      echo " ###################"
      exit 1
    endif
 echo " "
 echo "============================================================"
 echo "    The above is a listing of potential experiment names"
 echo "    found under $cwd "
 echo "    (the list is sorted by date with newest at top)"
 echo "Q3: What is the full NAME of the experiment to be run?"
 echo "============================================================"
 echo ">>> Enter one of the above experiment names"

 set opt=$<
 echo $opt
 set expname = $opt
 cd $expname

 
 if ( -d $parentdir/$exp_prefix/$expname/master ) then 
   echo " "
   echo " --- OK: master" 
 else
   echo " ###################"
   echo " ###    ERROR    ### "
   echo " ### EXPECTED DIRECTORY OF MASTERSCRIPTS"
   echo " ### $parentdir/$exp_prefix/master "
   echo " ### DOES NOT EXIST"
   echo " ###    ERROR    ### "
   echo " ### exiting $0 "
   echo " ###################"
   exit 1
 endif

# CHECK if master scripts have already been run and OneD files exist in archive
 
 if (-e $parentdir/$exp_prefix/$expname/log/) then
    set nlogfiles=`/bin/ls -lt $parentdir/$exp_prefix/$expname/log/|grep out|wc -l`
    if ($nlogfiles != 0) then 
       set expfile="$parentdir/$exp_prefix/$expname/experiment_info.txt"
       set archFile=`cut -d : -f 2 $expfile|grep downscaled`
       set nOneD = `/bin/ls -lt $archFile/|grep nc|wc -l`
       echo "   "
       echo " ############################"
       echo "   "
       echo " ======== PROBLEM? ==========="
       echo "   "
       echo "    Found $nlogfiles log files in $parentdir/$exp_prefix/$expname/log/"
       echo "    Found $nOneD OneD files in $archFile "
       echo "   "
       echo "    If you wish to re-run $expname, "
       echo "    please set XML <ifpreexist>erase</ifpreexist> "
       echo "    and re-run expergen to ensure proper file clean-up."
       echo "   "
       echo "    Exiting $0 "
       echo "   "
       echo " ############################"
       exit 1
    endif
 endif

 cd $parentdir/$exp_prefix/$expname/master
 echo $cwd
 /bin/ls -lt master_script*
 set num_master = `/bin/ls -lt master_script* | /bin/grep master | wc -l`
 echo " A total of $num_master master_scripts exist "
 set masterList = `/bin/ls -1t master_script* | /bin/grep master`
#echo " +++ $masterList +++ "
 echo " "
 echo "============================================================"
 echo "    The above is a list of the $num_master master_scripts"
 echo "    (sorted by modificaiton time, newst on top)."
 echo "    This script will submit each masterscript, in order, to "
 echo "    PP/AN if you choose to continue."
 echo "Q4: Do you wish to continue and submit these $num_master jobs?"
 echo "============================================================"
 echo ">>> Enter  Y  or  y  to continue this script."

 set opt=$<
 echo $opt
 set ycontinue = $opt
 
 if ( $ycontinue  == Y | $ycontinue  == y |) then 
   echo " "
   echo " --- OK: continue" 
 else
   echo " ################### "
   echo " exiting $0 "
   echo " ###################"
   exit 0
 endif

 echo " "
 echo "============================================================"
 echo "    The MOAB batch job scheduler can optionally send email"
 echo "    to a designated user when the batchjob exits the system." 
 echo "Q5: Do you wish MOAB to send email notifications?"
 echo "============================================================"
 echo ">>> Either enter a full NEMS address (First.Last@noaa.gov) -or- "
 echo "     Enter  N  or n  to skip the email option."

 set opt=$<
 echo $opt
 set nmail = $opt
 echo " "
 if ( $nmail  == N | $nmail  == n |) then 
   set NEMSemail = " "
   echo " --- No email will be sent by MOAB " 
 else
   set NEMSemail = $opt
   echo " --- MOAB will send emails to $NEMSemail"
 endif

 set msub_string = "-m ae -M $NEMSemail"

 echo "NEMSemail=$NEMSemail "

 echo " "
 echo "============================================================"
 echo "Q6: How much of a time delay (in minutes) should there be "
 echo "    between successive job submissions?  " 
 echo "============================================================"
 echo ">>> Enter 0 to have the jobs submitted only seconds apart. "
 echo "    Enter a positive integer to set the time interval in minutes."

 set opt=$<
 echo $opt
 @ m_sleep = $opt
 @ s_sleep = 60 * $m_sleep
 @ pausesec = 20
 @ s_sleep = $s_sleep - $pausesec

 echo "============================================================"
 echo "=== Begin submitting $num_master batchjobs for experiment"
 echo "=== $expname "
 echo "=== `date` "
 echo "============================================================"
 echo " " 
 @ kount = 0
 foreach batchjob ( $masterList )
  @ kount = $kount + 1
  echo " %%% submitting job $kount of $num_master"
  msub $msub_string $batchjob
  if ($m_sleep > 0) then
    sleep $pausesec
    echo "------------------------------------------------------------------------"
    echo "--------------------  `date`  --------------------"
    echo "------------------------------------------------------------------------"
    set numjobs = `sq --user=$account | /bin/grep $account | /usr/bin/wc -l`
    echo "=== $numjobs = number of jobids owned by $account "
    echo "------------------------------------------------------------------------"
    echo " - - - LIST OF RUNNING JOBS, results of: sq --user =$account -r "
    /home/gfdl/bin2/sq --user =$account -r
    echo " - - - - - - - - - - - - - - - - -  - - -  - - - - - - - - - -"
    echo " - - - LIST OF IDLE JOBS, results of: sq --user =$account -i "
    /home/gfdl/bin2/sq --user =$account -i
    echo " - - - - - - - - - - - - - - - - -  - - -  - - - - - - - - - -"
    echo " - - - LIST OF BLOCKED JOBS, results of: sq --user =$account -b "
    /home/gfdl/bin2/sq --user =$account -b
    echo "------------------------------------------------------------------------"
  else
    echo " " 
  endif

  if ($m_sleep > 0 && $kount != $num_master ) then
    echo "--- Next job to be submitted in less than $m_sleep minutes "
    echo "--------------------  `date`  --------------------"
    echo " " 
    sleep $s_sleep
  endif
 end

 echo "============================================================"
 echo "===   $0 master script submissions are complete "
 echo "============================================================"
 echo " "
 echo " "
 echo " "
 echo "============================================================"
 echo "Q: Do you wish to monitor the batchjobs' progress as "
 echo "    they archive minifiles?"
 echo "============================================================"
 echo ">>> Enter  N  or  N  to exit this script."

 set opt=$<
 echo $opt
 set nend = $opt
 
 if ( $nend  == N | $nend  == n |) then 
   echo " ################### "
   echo " ### exiting $0 "
   echo " ###################"
   exit 0
 endif

 echo " Job stats and minifile creation will be monitored in a loop every 10 minutes."
 set XMLdir = "$parentdir/$exp_prefix/XML"
 set XMLfile = "$XMLdir/$expname.xml"
 if (! -e $XMLfile) then
   echo " "
   echo "-------------------------------
   echo "WARNING WARNING WARNING WARNING"
   echo "-------------------------------
   echo " "
   echo " The XML file is expected to be in $XMLfile, but does not exist."
   echo " postProc takes the XML file path as input argument, and this script"
   echo " assumes the location is $XMLfile."
   echo " Please run postProc offline."
   echo " Exiting."
   echo " "
   echo "-------------------------------
   echo " "
   exit 1
 else
   echo " The XML file = $XMLfile."
   echo " "
   echo "============================================================"
   echo " Q: Once jobs are completed, do you want to launch postProc to "
   echo " create the 2D file and qcmask if that option was specified in the XML?"
   echo "============================================================"
   echo ">>> Enter  Y  or  y  to do the postProc step."

   set opt=$<
   echo $opt
   set ycontinue = $opt
 
   set run_postProc = 0
   if ( $ycontinue  == Y | $ycontinue  == y |) then 
     echo " "
     echo " --- OK: do postProc when done." 
     set run_postProc = 1
   endif
 endif

 echo "/home/Oar.Gfdl.Esd/MJN_sandbox/launch_jobs/esd_postProc.csh $XMLfile $run_postProc"
 /home/Oar.Gfdl.Esd/MJN_sandbox/launch_jobs/esd_postProc.csh $XMLfile $run_postProc

# /home/esd/bin/esd_postProc.csh $XMLfile $run_postProc


exit 0
