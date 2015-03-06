#!/bin/csh -f

 set echo
 source /usr/local/Modules/default/init/csh
 source ~esd/local/.cshrc_esd
 set fudge_version = "fudge/cinnamon"

 set XMLfile = $1
 set varname = $2
 set readyQCfiles = $3

 module load $fudge_version
 module list
 printenv PATH
 which python
 
 if ($readyQCfiles == 1) then
   postProc -i $XMLfile -v $varname,${varname}_qcmask
 endif
 if ($readyQCfiles != 1) then
   postProc -i $XMLfile -v $varname
 endif

 exit 0
