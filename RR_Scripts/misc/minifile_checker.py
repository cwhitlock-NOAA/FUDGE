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
  print ("Exiting.")
  print ("!!!!!!!!!!!!!!!!!!!!!!!!!!")
  exit(1)

xmlFile = sys.argv[1]
if xmlFile == "":
  print ("!!!!!!!!!!!!!!!!!!!!!!!!!!")
  print ("Need to input XMLfile path")
  print ("Exiting.")
  print ("!!!!!!!!!!!!!!!!!!!!!!!!!!")
  exit(1)


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
nOneDFiles = int(lone)-int(lons)+1
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
exp_prefix = root.findtext("./core/exp_prefix")
expInfo = root.findall("./exp_check")
exp_name = expInfo[0].get("exp_name")
qcInfo = root.findall("./pp/qc")
qc_type = qcInfo[0].get("type")
qc_mask = qcInfo[0].get("qc_mask")
qc_adjust_out = qcInfo[0].get("adjust_out")

if target == "tasmax":
  varname = "tx"
elif target == "tasmin":
  varname = "tn"
elif target == "pr":
  varname = "pr"
  pr_threshold_in = root.findtext("./core/pr_opts/pr_threshold_in")
  pr_freqadj_in = root.findtext("./core/pr_opts/pr_freqadj_in")
  pr_conserve_in = root.findtext("./core/pr_opts/pr_conserve_in")
  pr_threshold_out = root.findtext("./core/pr_opts/pr_threshold_out")
  pr_conserve_out = root.findtext("./core/pr_opts/pr_conserve_out")
else:
  varname = target

if smask == "red_river_0p1_masks":
  region_abbrev = "RR"
  experiment = region_abbrev+varname+"p1-"+method+"-"+exper_series+"K"+kfold
else:
  region_abbrev = exp_prefix
  experiment = region_abbrev+varname+"p1-"+method+"-"+exper_series+"K"+kfold
  print ("smask = "+smask)

if exp_name != experiment:
  print ("PROBLEM. exp_name="+exp_name+" and should be same as "+experiment+"\n")
  exit(1)

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
#print hpItems
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
  tmpFile,hpError = p1.communicate()
  hpFile = tmpFile.strip()
  if(hpError!=""):
    print(hpError)
#   print("Exiting.")
#   sys.exit()
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
fpEPOCH = fpSubDirs[3]
fpRIP = fpSubDirs[6]
#print('fpEPOCH: '+fpEPOCH+"\n")
#print('fpRIP: '+fpRIP+"\n")
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

dsArcDir = dsArcDir + "/" + experiment + "/" + target + "/" + region_abbrev 
dsOneDArcDir = dsArcDir+'/OneD/v*/'
dsOneDFileName = target+'_day_'+experiment+'_'+fpEPOCH+'_'+fpRIP+'_'+exp_prefix+'_'+fpTrainYrBeg+'0101-'+fpTrainYrEnd+'1231.I'
p4 = subprocess.Popen('\ls '+dsArcDir+'|grep ^v',shell=True,stdout=PIPE,stdin=PIPE, stderr=PIPE)
dsInfo = p4.communicate()
dsVersion = dsInfo[0][0:-1]
p40 = subprocess.Popen('\ls -l '+dsArcDir+'/'+dsVersion,shell=True,stdout=PIPE,stdin=PIPE, stderr=PIPE)
ds2DFiles,ds2DError = p40.communicate()
p41 = subprocess.Popen('\ls -l '+dsOneDArcDir+'| grep '+dsOneDFileName+' | grep nc | wc -l',shell=True,stdout=PIPE,stdin=PIPE, stderr=PIPE)
ds1DFiles,ds1DError = p41.communicate()
numds1DFiles = ds1DFiles.strip()
numds1DError = ds1DError.strip()
strnOneDFiles = str(nOneDFiles)

if qc_mask=='on':
  qcOneDArcDir = dsArcDir+'/OneD/v*/'+target+'_qcmask/'
  qcOneDFileName = target+'_qcmask_day_'+experiment+'_'+fpEPOCH+'_'+fpRIP+'_'+exp_prefix+'_'+fpTrainYrBeg+'0101-'+fpTrainYrEnd+'1231.I'
  p42 = subprocess.Popen('\ls -l '+qcOneDArcDir+'| grep '+qcOneDFileName+'| grep nc | wc -l',shell=True,stdout=PIPE,stdin=PIPE, stderr=PIPE)
  qc1DFiles,qc1DError = p42.communicate()
  numqc1DFiles = qc1DFiles.strip()
  numqc1DError = qc1DError.strip()
else:
  numqc1DFiles = "-99"


if smask!="none":
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


print(strnOneDFiles+" "+numds1DFiles+" "+numqc1DFiles+" "+target+"\n")
print(strnOneDFiles+" minifiles expected \n")
print(numds1DFiles+" downscaled minifiles found \n")
print(numqc1DFiles+" qcmask minifiles found \n")
if numds1DFiles==0:
  print(experiment+" apparently has not yet been run or encountered problems. \n")
if numqc1DFiles==0:
  print(experiment+" apparently has not yet been run or encountered problems.\n")
if numqc1DFiles=="-99":
  print(experiment+" did not save qcmask files.\n")
