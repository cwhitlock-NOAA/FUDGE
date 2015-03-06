#!/usr/bin/python
#
import xml.etree.ElementTree as ET
import sys, subprocess
from subprocess import PIPE
#
#
# This python script constructs the path of input files as defined in FUDGE2014 XML.
# If the file is properly set and exists, you will see an '\ls -l' listing.
# If the file does n ot exist, you will not see the listing.
#
# NOTE: If having problems running this script, try doing:  module unload cdat
# 


if len(sys.argv) < 1 :
  print ("!!!!!!!!!!!!!!!!!!!!!!!!!!")
  print ("Need to input XMLfile path")
  print ("!!!!!!!!!!!!!!!!!!!!!!!!!!")
  exit()

xmlFile = sys.argv[1]
if xmlFile != "":
  print xmlFile
else:
  exit()


root = ET.parse(xmlFile)
input = root.findall("./input")
grid = root.findall("./input/grid")

# getting values
target         = input[0].get("target")
predictor_list = input[0].get("predictor_list")
smaskDir       = input[0].get("spat_mask")[0:-5]
smask          = input[0].get("maskvar")
region         = grid[0].get("region")
lons = root.findtext("./input/grid/lons")
lone = root.findtext("./input/grid/lone")
lats = root.findtext("./input/grid/lats")
late = root.findtext("./input/grid/late")
file_j_range = root.findtext("./input/grid/file_j_range")
training = root.findall("./input/training")
histPred = root.findall("./input/training/historical_predictor")
histTarg = root.findall("./input/training/historical_target")
futPred  = root.findall("./input/training/future_predictor")
core = root.findall("./core")
methodInfo = root.findall("./core/method")
method = methodInfo[0].get("name")
kfold = int(root.findtext("./core/kfold"))
if kfold <= 9:
  kfold = "0" + str(kfold)

outputRootDir = root.findtext("./core/output/root")
scriptRootDir = root.findtext("./core/output/script_root")
exper_series = root.findtext("./core/exp_label")

if target == "tasmax":
  varname = "tx"
elif target == "tasmin":
  varname = "tn"
elif target == "pr":
  varname = "pr"
else:
  varname = target

if smask == "red_river_0p1_masks":
  region_abbrev = "RR"
  experiment = region_abbrev+varname+"p1-"+method+"-"+exper_series+"K"+kfold
else:
  print ("Region abbreviation not yet defined. Stopping.")
  exit()

#===================================
# get Historical Predicton attributes
#===================================
#
hpTimeWindow = histPred[0].get("time_window")
hpFileYrBeg = histPred[0].get("file_start_time")
hpFileYrEnd = histPred[0].get("file_end_time")
hpTrainYrBeg = histPred[0].get("train_start_time")
hpTrainYrEnd = histPred[0].get("train_end_time")
""" Alternate way to get at attributes and values
hpKeys = histPred[0].keys()
#print hpKeys
hpItems = histPred[0].items()
print hpItems
hpTimeWindow = hpItems[0][1]
hpFileYrEnd = hpItems[1][1]
hpTrainYrBeg = hpItems[2][1]
hpFileYrBeg = hpItems[3][1]
hpTrainYrEnd = hpItems[4][1]
#k=0
#for tags in hpKeys:
#  print k, tags, hpItems[k][0], hpItems[k][1]
#  k=k+1

"""
# create historical predictor path
hpRootDir = "/archive/esd/PROJECTS/DOWNSCALING"
hpSubDirs = histPred[0].findtext("dataset").split(".")
#hpSubDirs.insert(4,"day")
hpVars = predictor_list.split(".")

np=len(hpSubDirs)-1

# create historical predictor path
k=0
hpArcDir = hpRootDir
for dir in hpSubDirs:
   hpArcDir = hpArcDir + "/" + dir
   k=k+1

k=0
for pvar in hpVars:
  hpPath = hpArcDir + "/" + pvar + "/" + region
# print ("HistPredictor Path = " + hpPath)
  hpFileName = hpPath+'/*'+hpFileYrBeg+'*'+hpFileYrEnd+'*.nc'
  p1 = subprocess.Popen('\ls -l '+hpPath+'/*'+hpFileYrBeg+'*'+hpFileYrEnd+'*.nc',shell=True,stdout=PIPE,stdin=PIPE, stderr=PIPE)
  hpInfo = p1.communicate()
  hpFile = hpInfo[0][0:-1]
# print ("HistPredictor File "+str(k)+": "+hpFile)
  if k == 0:
    hpFiles = [hpFile]
    hpFileNames = [hpFileName]
  else:
    hpFiles.append(hpFile)
    hpFileNames.append(hpFileName)
  k=k+1 

#print hpFiles
#===================================
# get Historical Target attributes
#===================================
#
htTimeWindow = histTarg[0].get("time_window")
htFileYrBeg = histTarg[0].get("file_start_time")
htFileYrEnd = histTarg[0].get("file_end_time")
htTrainYrBeg = histTarg[0].get("train_start_time")
htTrainYrEnd = histTarg[0].get("train_end_time")

# create historical target path
htArcDir = "/archive/esd/PROJECTS/DOWNSCALING"
htSubDirs = histTarg[0].findtext("dataset").split(".")
#htSubDirs.insert(4,"day")

np=len(htSubDirs)-1

# create historical targ path
k=0
for dir in htSubDirs:
   htArcDir = htArcDir + "/" + dir
   k=k+1

htArcDir = htArcDir + "/" + target + "/" + region
htFileName = htArcDir+'/*'+htFileYrBeg+'*'+htFileYrEnd+'*.nc'
#print ("HistTarget Path = " + htArcDir)
p2 = subprocess.Popen('\ls -l '+htArcDir+'/*'+htFileYrBeg+'*'+htFileYrEnd+'*.nc',shell=True,stdout=PIPE,stdin=PIPE, stderr=PIPE)
htInfo = p2.communicate()
htFile = htInfo[0][0:-1]
#print ("htFile = "+htFile)

#===================================
# get Future predictor attributes
#===================================
#
fpTimeWindow = futPred[0].get("time_window")
fpFileYrBeg = futPred[0].get("file_start_time")
fpFileYrEnd = futPred[0].get("file_end_time")
fpTrainYrBeg = futPred[0].get("train_start_time")
fpTrainYrEnd = futPred[0].get("train_end_time")

# create future predictor path
fpArcDir = "/archive/esd/PROJECTS/DOWNSCALING"
fpSubDirs = futPred[0].findtext("dataset").split(".")
#fpSubDirs.insert(4,"day")

np=len(fpSubDirs)-1

# create future predictor path
k=0
for dir in fpSubDirs:
   fpArcDir = fpArcDir + "/" + dir
   k=k+1

fpArcDir = fpArcDir + "/" + target + "/" + region
fpFileName = fpArcDir+'/*'+fpFileYrBeg+'*'+fpFileYrEnd+'*.nc'
#print ("FuturePredictor Path = " + fpArcDir)
p3 = subprocess.Popen('\ls -l '+fpArcDir+'/*'+fpFileYrBeg+'*'+fpFileYrEnd+'*.nc',shell=True,stdout=PIPE,stdin=PIPE, stderr=PIPE)
fpInfo = p3.communicate()
fpFile = fpInfo[0][0:-1]
fpSubDirs.insert(4,"day")

# create downscaled output path
k=0
dsArcDir = outputRootDir+"/downscaled/NOAA-GFDL"
for dir in fpSubDirs[2:len(fpSubDirs)]:
   dsArcDir = dsArcDir + "/" + dir
   k=k+1

#dsArcDir = dsArcDir + "/" + experiment + "/" + target + "/" + region_abbrev + "/" +"v*"
dsArcDir = dsArcDir + "/" + experiment + "/" + target + "/" + region_abbrev + "/" 
#print ("Downscaled Output Path = " + dsArcDir)
#p4 = subprocess.Popen('\ls -l '+dsArcDir+'/*'+fpFileYrBeg+'*'+fpFileYrEnd+'*.nc',shell=True,stdout=PIPE,stdin=PIPE, stderr=PIPE)
#dsInfo = p4.communicate()
#dsFile = dsInfo[0][0:-1]

p5 = subprocess.Popen('\ls -l '+smaskDir+smask+'.nc',shell=True,stdout=PIPE,stdin=PIPE, stderr=PIPE)
spFileName = smaskDir+smask+'.nc'
spInfo = p5.communicate()
spFile = spInfo[0][0:-1]

htwFileName = htTimeWindow
p6 = subprocess.Popen('\ls -l '+htTimeWindow,shell=True,stdout=PIPE,stdin=PIPE, stderr=PIPE)
htwInfo = p6.communicate()
htwFile = htwInfo[0][0:-1]

p7 = subprocess.Popen('\ls -l '+fpTimeWindow,shell=True,stdout=PIPE,stdin=PIPE, stderr=PIPE)
ftwFileName = fpTimeWindow
ftwInfo = p7.communicate()
ftwFile = ftwInfo[0][0:-1]

#===================================
#===================================


#custom = root.findall("./custom")


#logFileName = xmlFile[0:-4]+".log"
logFileName = experiment+".log"
logfile = open(logFileName, 'w') 
logfile.write('................................................................' + "\n")
logfile.write('Experiment: ' + experiment + "\n")
logfile.write('................................................................' + "\n")
logfile.write('XML: ' + xmlFile + "\n")
logfile.write('................................................................' + "\n")
logfile.write("historical_target_file:  \n")
logfile.write(htFileName + ": \n")
logfile.write('   ' + htFile + "\n")
logfile.write("\n")
logfile.write('................................................................' + "\n")
logfile.write("historical_predictor dir = " + hpPath + "\n")
k=0
for hpFile in hpFiles:
  logfile.write('historical_predictor_file_'+str(k)+': ' + '\n')
  logfile.write(hpFileNames[k] + ': \n')
  logfile.write('   ' + hpFiles[k] + '\n')
  k=k+1
logfile.write("\n")
logfile.write('................................................................' + "\n")

logfile.write("future_predictor dir = " + fpArcDir + "\n")
logfile.write('future_pedictor_file: \n')
logfile.write(fpFileName + ": \n")
logfile.write('   ' + fpFile + "\n")
if not fpFile:
  print(">>>>>>> MISSING <<<<<<<<")
logfile.write("\n")
logfile.write('................................................................' + "\n")
logfile.write("downscaled_output_dir \n")
logfile.write(dsArcDir + "\n")
logfile.write("\n")
logfile.write('................................................................' + "\n")
logfile.write("spatial_mask_file: \n")
logfile.write(spFileName + ": \n")
logfile.write('   ' + spFile + "\n")
logfile.write("\n")
logfile.write('................................................................' + "\n")
logfile.write('historical_time_window_file: ' + htwFileName + ": \n")
logfile.write('   ' + htwFile + "\n")
logfile.write('................................................................' + "\n")
logfile.write('future_time_window_file: ' + ftwFileName + ": \n")
logfile.write('   ' + ftwFile+ "\n")
logfile.write('................................................................' + "\n")
logfile.write('hist_Target_training_yrbeg: ' + htTrainYrBeg + "\n")
logfile.write('hist_Target_training_yrend: ' + htTrainYrEnd + "\n")
logfile.write('hist_Predictor_training_yrbeg: ' + hpTrainYrBeg + "\n")
logfile.write('hist_Predictor_training_yrend: ' + hpTrainYrEnd + "\n")
logfile.write('fut_Predictor_training_yrbeg: ' + fpTrainYrBeg + "\n")
logfile.write('fut_Predictor_training_yrend: ' + fpTrainYrEnd + "\n")
logfile.close()
print file(logFileName).read()
quit()
