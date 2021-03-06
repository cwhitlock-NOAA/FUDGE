########Input R parameters generated by experGen suite of tools for use in driver script -------
rm(list=ls())

#--------------predictor and target variable names--------#
	predictor.vars <- 'tasmax' 
	target.var <- 'tasmax'
#--------------grid region, mask settings----------#
        grid <- 'SCCSC0p1' 
        spat.mask.dir_1 <- '/archive/esd/PROJECTS/DOWNSCALING/3ToThe5th/masks/geomasks/red_river_0p1/OneD/' 
        spat.mask.var <- 'red_river_0p1_masks' 
#--------------- I,J settings ----------------#
        file.j.range <- 'J31-170' 
        i.file <- 200   
        j.start <- 31 
        j.end <- 170 
        loop.start <-  j.start - (j.start-1)
        loop.end <-  j.end - (j.start-1)
#------------ historical predictor(s)----------# 
	hist.file.start.year_1 <- 1961 
	hist.file.end.year_1 <- 2005
        hist.train.start.year_1 <- 1961
	hist.train.end.year_1 <- 2005 
	hist.scenario_1 <- 'historical_r1i1p1'
	hist.nyrtot_1 <- (hist.train.end.year_1 - hist.train.start.year_1) + 1
	hist.model_1 <- 'MPI-ESM-LR' 
	hist.freq_1 <- 'day' 
	hist.indir_1 <- '/archive/esd/PROJECTS/DOWNSCALING///GCM_DATA/CMIP5//MPI-ESM-LR/historical//atmos/day/r1i1p1/v20111006/tasmax/SCCSC0p1/OneD/' 
	hist.time.window <- '/archive/esd/PROJECTS/DOWNSCALING/3ToThe5th/masks/timemasks/maskdays_bymonth_19610101-20051231.nc' 
#------------ future predictor(s) -------------# 
	fut.file.start.year_1 <- 2006 
	fut.file.end.year_1 <- 2099 
        fut.train.start.year_1 <- 2006 
        fut.train.end.year_1 <- 2099 
	fut.scenario_1 <- 'rcp85_r1i1p1'
	fut.nyrtot_1 <- (fut.train.end.year_1 - fut.train.start.year_1) + 1
	fut.model_1 <- 'MPI-ESM-LR' 
	fut.freq_1 <- 'day' 
	fut.indir_1 <- '/archive/esd/PROJECTS/DOWNSCALING///GCM_DATA/CMIP5//MPI-ESM-LR/rcp85//atmos/day/r1i1p1/v20111014/tasmax/SCCSC0p1/OneD/'
	fut.time.window <- '/archive/esd/PROJECTS/DOWNSCALING/3ToThe5th/masks/timemasks/maskdays_bymonth_20060101-20991231.nc'
#------------- target -------------------------# 
	target.file.start.year_1 <- 1961 
	target.file.end.year_1 <- 2005 
        target.train.start.year_1 <- 1961 
        target.train.end.year_1 <- 2005 
	target.scenario_1 <- 'historical_r0i0p0'
	target.nyrtot_1 <- (target.train.end.year_1 - target.train.start.year_1) + 1 
	target.model_1 <- 'livneh'
	target.freq_1 <- 'day' 
        target.indir_1 <- '/archive/esd/PROJECTS/DOWNSCALING///OBS_DATA/GRIDDED_OBS//livneh/historical//atmos/day/r0i0p0/v1p2/tasmax/SCCSC0p1/OneD/'
	target.time.window <- '/archive/esd/PROJECTS/DOWNSCALING/3ToThe5th/masks/timemasks/maskdays_bymonth_19610101-20051231.nc'
#------------- method name k-fold specs-----------------------#
        ds.method <- 'CDFt' 
	ds.experiment <- '1pow5-txp1-GFDL-CDFtv1-A00X01K00' 
	k.fold <- 0 
#-------------- output -----------------------#
###CEW EDIT:
#	output.dir <- '/work/a1r/PROJECTS/DOWNSCALING/3ToThe5th//downscaled/NOAA-GFDL/MPI-ESM-LR/rcp85_r1i1p1//atmos/day/r1i1p1/v20111014/CDFt/tasmax/SCCSC0p1/OneD/v20140108/'
output.dir <- '/work/cew/sampleout'
#-------------  custom -----------------------#
###CEW EDIT:
#        npas=300
args = "npas=300"
 #Number of "cuts" for which quantiles will be empirically estimated (Default is 100 in CDFt package).

################### others ###################################
#---------------- reference to go in globals ----------------------------------- 
	configURL <-' Ref:http://gfdl.noaa.gov/esd_experiment_configs'
# ------ Set FUDGE environment ---------------
###CEW EDIT:
#	FUDGEROOT = Sys.getenv(c("FUDGEROOT"))
#	FUDGEROOT <- '/home/a1r/gitlab/cew/fudge2014/'
FUDGEROOT <- '/home/cew/Code/fudge2014/'
	print(paste("FUDGEROOT is now activated:",FUDGEROOT,sep=''))
################ call main driver ###################################
print(paste("START TIME:",Sys.time(),sep=''))

#----------Use /vftmp as necessary---------------# 
# TMPDIR = Sys.getenv(c("TMPDIR"))
# ###CEW EDIT:
# TMPDIR <- "/tmp"
# if (TMPDIR == ""){
#   stop("ERROR: TMPDIR is not set. Please set it and try it") 
#   }
#########################################################################
# if((grepl('^/archive',spat.mask.dir_1)) | (grepl('^/work',spat.mask.dir_1))){
# spat.mask.dir_1 <- paste(TMPDIR,spat.mask.dir_1,sep='')
# }
# if((grepl('^/archive',hist.indir_1)) | (grepl('^/work',hist.indir_1))){
# hist.indir_1 <- paste(TMPDIR,hist.indir_1,sep='')
# }
# if((grepl('^/archive',fut.indir_1)) | (grepl('^/work',fut.indir_1))){
# fut.indir_1 <- paste(TMPDIR,fut.indir_1,sep='')
# }
# if((grepl('^/archive',hist.indir_1)) | (grepl('^/work',hist.indir_1))){
# target.indir_1 <- paste(TMPDIR,target.indir_1,sep='')
# }
# output.dir <- paste(TMPDIR,output.dir,sep='')
#########################################################################
#-------------------------------------------------#

###CEW EDIT:
#source(paste(FUDGEROOT,'Rsuite/Drivers/',ds.method,'/Driver_',ds.method,'.R',sep=''))
#source(paste(FUDGEROOT,'Rsuite/drivers/',ds.method,'/driverv2.2','.R',sep=''))
driver <- paste(FUDGEROOT, 'Rsuite/drivers/CDFt/driverv2.2.R', sep="")
print(driver)
source(driver)
