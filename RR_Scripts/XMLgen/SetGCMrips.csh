#
echo " "
echo "   IMPORTANT: rips for CCSM4 & MPI-ESM-LR are decided on. MIROC5 tentatively set to r1i1p1."
set myDataSet = $1
set myEpoch = $2

if ("$myDataSet" == "CCSM4") then                                                                                               
  if ($myEpoch == "historical") set myRip = "r6i1p1"                                                                       
  if ($myEpoch == "rcp26") set myRip = "r6i1p1"                                                                            
  if ($myEpoch == "rcp45") set myRip = "r6i1p1"                                                                            
  if ($myEpoch == "rcp85") set myRip = "r6i1p1"                                                                            
endif                                                                                                                                
if ("$myDataSet" == "MPI-ESM-LR") then                                                                                          
  if ($myEpoch == "historical") set myRip = "r1i1p1"                                                                       
  if ($myEpoch == "rcp26") set myRip = "r1i1p1"                                                                            
  if ($myEpoch == "rcp45") set myRip = "r1i1p1"                                                                            
  if ($myEpoch == "rcp85") set myRip = "r1i1p1"                                                                            
endif                                                                                                                                
if ("$myDataSet" == "MIROC5") then                                                                                              
  if ($myEpoch == "historical") set myRip = "r1i1p1"                                                                       
  if ($myEpoch == "rcp26") set myRip = "r1i1p1"                                                                            
  if ($myEpoch == "rcp45") set myRip = "r1i1p1"                                                                            
  if ($myEpoch == "rcp85") set myRip = "r1i1p1"                                                                            
endif                
echo " "
echo " "
echo "   Using RIP = $myRip"

exit 0
