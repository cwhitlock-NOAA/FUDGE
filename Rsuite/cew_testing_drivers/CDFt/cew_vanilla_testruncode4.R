rm(list=ls())

#--------------predictor and target variable names--------#
	predictor.vars <- 'tasmax' 
	target.var <- 'tasmax'
#--------------grid region, mask settings----------#
        grid <- 'SCCSC0p1' 
        ds.region <- 'SCCSC0p1'
        spat.mask.dir_1 <- '/archive/esd/PROJECTS/DOWNSCALING/3ToThe5th/masks/geomasks/red_river_0p1/OneD/' 
        spat.mask.var <- 'red_river_0p1_masks' 
#--------------- I,J settings ----------------#
        file.j.range <- 'J31-170' 
        i.file <- 300   
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
#	hist.indir_1 <- '/archive/esd/PROJECTS/DOWNSCALING///GCM_DATA/CMIP5//MPI-ESM-LR/historical//atmos/day/r1i1p1/v20111006/tasmax/SCCSC0p1/OneD/'
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
fut.time.trim.mask <- 'na'
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
       # ds.method <- 'simple.bias.correct' 
ds.method <- 'CDFt'
	ds.experiment <- 'testing-new.mask.struct-1pow5-txp1-GFDL-CDFtv1-A00X01K00' 
	k.fold <- 0 
mask.list <- list("method1"=list("type" = 'kdAdjust','adjust.out'='on', 'qc.mask'='on')) #Expected off for 'adjust.out is 'na' not 'off'
#create.qc.mask <- TRUE
# qc.method <- 'kdAdjust'
#-------------- output -----------------------#
	#output.dir <- '/work/a1r/PROJECTS/DOWNSCALING/3ToThe5th//downscaled/NOAA-GFDL/MPI-ESM-LR/rcp85_r1i1p1//atmos/day/r1i1p1/v20111014/1pow5-txp1-GFDL-CDFtv1-A00X01K00/tasmax/SCCSC0p1/OneD/v20140108/'
output.dir <- '/home/cew/Code/testing/'
#-------------  custom -----------------------#
        args=list(npas=300, dev=2) 
#args=list('na')
#args=list(ds.method='CDFt', qc.method='simple.bias.correct', qc.comparison=6)
 #Number of "cuts" for which quantiles will be empirically estimated (Default is 100 in CDFt package).

################### others ###################################
#---------------- reference to go in globals ----------------------------------- 
	configURL <-' Ref:http://gfdl.noaa.gov/esd_experiment_configs'
# ------ Set FUDGE environment ---------------
#	FUDGEROOT = Sys.getenv(c("FUDGEROOT"))
	FUDGEROOT <- '/home/cew/Code/fudge2014/'
	print(paste("FUDGEROOT is now activated:",FUDGEROOT,sep=''))
################ call main driver ###################################
print(paste("START TIME:",Sys.time(),sep=''))

#----------Use /vftmp as necessary---------------# 
#TMPDIR = Sys.getenv(c("TMPDIR"))
TMPDIR = ""
# if (TMPDIR == ""){
#   stop("ERROR: TMPDIR is not set. Please set it and try it") 
#   }
#########################################################################
if((grepl('^/archive',spat.mask.dir_1)) | (grepl('^/work',spat.mask.dir_1))){
spat.mask.dir_1 <- paste(TMPDIR,spat.mask.dir_1,sep='')
}
if((grepl('^/archive',hist.indir_1)) | (grepl('^/work',hist.indir_1))){
hist.indir_1 <- paste(TMPDIR,hist.indir_1,sep='')
}
if((grepl('^/archive',fut.indir_1)) | (grepl('^/work',fut.indir_1))){
fut.indir_1 <- paste(TMPDIR,fut.indir_1,sep='')
}
if((grepl('^/archive',hist.indir_1)) | (grepl('^/work',hist.indir_1))){
target.indir_1 <- paste(TMPDIR,target.indir_1,sep='')
}
output.dir <- paste(TMPDIR,output.dir,sep='')
#########################################################################
#-------------------------------------------------#

source(paste(FUDGEROOT,'Rsuite/Drivers/Master_Driver.R',sep=''))
