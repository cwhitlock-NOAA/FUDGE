#!/bin/csh -f

 source /usr/local/Modules/default/init/csh
 echo " "
 echo "==========================================================================="
 echo " "
 echo " Running $0"

#set echo

 set fudge_version = "fudge/cinnamon"

#  to use postProc, need to load fudge modules
#  FOR NOW, HARDWIRED to use fudge/cinnamon
#
#  also expects full pathname to the XML in a /home/esd/PROJECTS/DOWNSCALING/SUBPROJECTS/  subdirectory


# check that argument 1 is supplied and valid

 if ($1 == "" ) then
   
   echo " "
   echo "==========================================================================="
   echo " "
   echo " Missing XML_file_path."
   echo " Expecting a full pathname to an XML in a /home/esd/PROJECTS/DOWNSCALING/SUBPROJECTS/  subdirectory."
   echo " "
   echo " usage: $0 <full_XML_file_path> <runPostProc>"
   echo "           where <runPostProc> is either  0 or 1, "
   echo "           where 0 = do NOT run the postProc routine once all minifiles are accounted for."
   echo "           where 1 = DO run the postProc routine once all minifiles are accounted for."
   echo " "
   echo " exiting $0"
   echo " "
   echo "==========================================================================="
   echo " "
   exit 1
 endif

 if (! -e $1) then
   echo " "
   echo "==========================================================================="
   echo " "
   if ($1 != "") echo " XML file named    $1    does not exist. Exiting."
   echo " Expecting a full pathname to an XML in a /home/esd/PROJECTS/DOWNSCALING/SUBPROJECTS/  subdirectory."
   echo " "
   echo " usage: $0 <full_XML_file_path> <runPostProc>"
   echo "           where <runPostProc> is either  0 or 1, "
   echo "           where 0 = do NOT run the postProc routine once all minifiles are accounted for."
   echo "           where 1 = DO run the postProc routine once all minifiles are accounted for."
   echo " "
   echo " exiting $0"
   echo " "
   echo "==========================================================================="
   echo " "
   exit 1
 endif

 set XMLfile = $1

# check that the XML points to an experiment that has been run
 set expname = $XMLfile:t:r
 set expDir = $XMLfile:h:h/$expname
   if (! -e $expDir) then
      echo " "
      echo "==========================================================================="
      echo " "
      echo " $expname appears to not have been expergen-ed. "
      echo " Directory $expDir does not exists."
      echo " Expecting a full pathname to an XML in a /home/esd/PROJECTS/DOWNSCALING/SUBPROJECTS/  subdirectory."
      echo " "
      echo " Exiting $0"
      echo " "
      echo "==========================================================================="
      echo " "
      exit 1
   else
      echo " "
      echo " "
      echo "==========================================================================="
      echo " "
      echo " $expname appears to have been expergen-ed. "
      echo " "
   endif

# check that argument 2 is supplied and valid

 if ($2 != 0 && $2 != 1) then
   echo " "
   echo "==========================================================================="
   echo " "
   echo " usage: $0 <full_XML_file_path> <runPostProc>"
   echo "           where <runPostProc> is either  0 or 1, "
   echo "           where 0 = do NOT run the postProc routine once all minifiles are accounted for."
   echo "           where 1 = DO run the postProc routine once all minifiles are accounted for."
   echo " "
   echo " 2nd argument should be 0 or 1; where  0 = do NOT run postProc, 1 = run postProc"
   echo " "
   echo " You specified: $2 "
   echo " "
   echo " Exiting $0 "
   echo " "
   echo "==========================================================================="
   echo " "
   exit 1
 endif

 set runPostProc = $2

 set readyDSfiles = 0
 set readyQCfiles = 0
 set nsleep = "0s"
 while ($readyDSfiles == 0 || $readyQCfiles == 0)
   set dtime=`date`
   echo " $dtime"
   echo " "
   echo " Pausing for $nsleep. (If you do not wish to proceed, exit with ctrl-c)"
   echo " "
   sleep $nsleep

   set minifileInfo = `/home/esd/bin/minifile_checker.py $XMLfile`
   set tot_minifiles = $minifileInfo[1]
   set tot_DS_minifiles = $minifileInfo[2]
   set tot_QC_minifiles = $minifileInfo[3]
   set varname = $minifileInfo[4]

# check downscaled minifiles
   if ($tot_DS_minifiles == $tot_minifiles) then
     set readyDSfiles = 1
   endif
   echo " "
   echo " "
   echo " Found $tot_DS_minifiles/$tot_minifiles downscaled minifiles."

# check for qc_mask minifiles if present.
#  (if qc_masks are not to be saved, minifile_checker.py returned -99 for tot_QC_minifiles)
   if ($tot_QC_minifiles >= 0) then
     if ($tot_QC_minifiles == $tot_minifiles) then
       set readyQCfiles = 1
     endif
     echo " Found $tot_QC_minifiles/$tot_minifiles qc_mask minifiles."
   else
     echo " No qc_mask files expected. (Flagged: tot_QC_minifiles = $tot_QC_minifiles)."
     set readyQCfiles = -1
   endif
   sleep 5
   echo " "

   if ($readyDSfiles == 0 || $readyQCfiles == 0) then

     echo " Checking Jobs status."
#   To eliminate annoying Warning messages from an un-updated 'sq':
#    /home/kd/myscript/resources/esd_jobs.csh
     /home/kd/myscript/resources/esd_jobs.csh >& /tmp/sqOUT
     grep -v Warning /tmp/sqOUT
     \rm /tmp/sqOUT
   else
    echo " "
    echo " All minifiles are present for $XMLfile."
    echo " "
     
   endif

   set nsleep = "10m"

 end

 if ($runPostProc == 0) echo " You have specified that postProc NOT be run."
 echo " "
 if ($runPostProc == 1) then
   echo "FOR NOW, HARDWIRED to use $fudge_version"
#  to use postProc, need to load fudge modules
   source ~esd/local/.cshrc_esd
   module load $fudge_version
   if ($readyQCfiles == 1) then
     postProc -i $XMLfile -v $varname,${varname}_qcmask
   else
     postProc -i $XMLfile -v $varname
   endif
 endif
 echo " Exiting $0"
 echo " "
 exit 0
