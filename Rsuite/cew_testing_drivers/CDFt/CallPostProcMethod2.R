#'CallPostProcMethod
#'Calls a Post-processing method on a series of downscaled
#'data, transforming it in one way or another. The 
#'Methods generally take two parameters: 
#'@param data: The downscaling data to be processed. 
#'@param args: The arguments to the pot-processing function.
#'
#'@author Carolyn Whitlock, October 2014
#'

CallPostProcMethod <- function(pp.method, data, mask, mask.data, args){
  switch(pp.method, 
         'compare.correct' = postProc_byCompare(data, mask, mask.data, args),
         'Nothing' = postProc_Nothing(data, args), 
         ReturnPostProcMethodError(pp.method))
}

ReturnPostProcMethodError <- function(pp.method){
  stop(paste("Post Process Mehtod Error: method", pp.method, 
             "is not supported for post-processing at this time."))
}
callNothing <- function(data, args){
  #Does absolutely nothing to the downscaling values of the current 
  #function. 
  return(data)
}

postProc_byCompare <- function(data, mask, mask.data, args){
  #TODO: At some point, include the var post-processing option
  #and some sort of units check to go with it.
  if(!is.null(args$compare.factor)){
    correct.factor <- args$compare.factor
    args$compare.factor <- NULL
  }else{
    if(!is.null(args$var)){
      if(args$var=='pr'){
        correct.factor <- 1e-06
      }else{
        correct.factor = 6
      } 
    }else{
      correct.factor <- 6
    }
    if(length(args)!=0) sample.args=args else sample.args=NULL
    out.vals <- ifelse( (mask==1), yes=data, no=mask.data )
    print(summary(out.vals))
    return(out.vals)
  }
}

postProc.Driver <- function(in.file=NA, var, k.fold, postproc.method, out.dir,
                            tmask.infile, postproc.outfile, 
                            in.dir=NA, tmask.dir=NA, postproc.outdir=NA, lons=NA, lone=NA, ...){
  #R driver script for the post-processing functions to set them up as a 
  library(ncdf4)
  #FUDGEROOT = Sys.getenv(c('BASEDIR')) #Should be sourced from the setenv_fudge file
  #Temporarily hard-coded; should probably be passed in from c-shell script/args
  FUDGEROOT = "/home/cew/Code/fudge2014/"
  print(FUDGEROOT)
  message('R script entered')
  options(error=traceback, warn = 1, showErrorCalls=TRUE)
  sapply(list.files(pattern="[.]R$", path=paste(FUDGEROOT,'Rsuite/FudgeIO/src/',sep=''), full.names=TRUE), source);
  sapply(list.files(pattern="[.]R$", path=paste(FUDGEROOT,'Rsuite/FudgePreDS/src/',sep=''), full.names=TRUE), source);
  sapply(list.files(pattern="[.]R$", path=paste(FUDGEROOT,'Rsuite/FudgeTrain/src/',sep=''), full.names=TRUE), source);
  sapply(list.files(pattern="[.]R$", path=paste(FUDGEROOT,'Rsuite/FudgeQC/src/',sep=''), full.names=TRUE), source);
  ###Start on drive script itself
#   if(is.na(in.file)){
#     #Assume that a directory means minifiles
#     message(paste("Running in iterate mode; searching for lons and lone"))
#     for (index in lons:lone){
#       message(paste("On lon", index, "of", lone))
#       in.file <- list.files(pattern=index, path=in.dir, full.names=TRUE)
#       if(length(in.file) > 1){
#         stop(paste("Pattern match error: There is more than one file in the directory", 
#                    in.dir, "that matches the pattern", index, ". Please recehck directory."))
#       }
#       in.suffix <- basename(in.file)
#       tmask.infile <- list.files(pattern=index, path=tmask.dir, full.names=TRUE)
#       #build postproc.outfile from the netcdf of the input
#       postproc.outfile <- paste("PostProcess/", postproc.method, "-",in.suffix, sep="")
#       print(postproc.outfile)
#       print(paste('ncks -a -h -v', var, postproc.outfile))
#       system(paste('ncks -a -h -v', var, postproc.outfile))
#       new.arg.list <- as.list(match.call())
#       new.arg.list$in.file = in.file
#       new.arg.list$tmask.infile = tmask.infile
#       new.arg.list$postproc.outfile = postproc.outfile
#       if(postproc.method=='compare.correct'){
#         new.arg.list$qc.mask.path <- list.files(pattern=index, path=new.arg.list$qc.mask.path)
#         new.arg.list$qc.data.path <- list.files(pattern=index, path=new.arg.list$qc.data.path)
#       }
#       PostProcessAll(unlist(new.arg.list))
#     }
#   }else{
#     #print(postproc.outfile)
#     postproc.outpath <- paste(out.dir, postproc.outfile, sep="/")
#     print(postproc.outpath)
# #     print(paste(paste('ncks -a -h -v', var, in.file, postproc.outpath)))
# #     system(paste('ncks -a -h -v', var, in.file, postproc.outpath))
#     PostProcessAll(as.list(match.call()))
#   }
# }
# 
# PostProcessAll <- function(in.file, var, k.fold, postproc.method, out.dir,
#                            tmask.infile, postproc.outfile, ...){
  message("Entering PostProcessAll")
  print(in.file)
  message(in.file)
  in.data.nc <- nc_open(in.file)
  data <- ncvar_get(in.data.nc, var, collapse_degen=FALSE)
  args=list()
  if(postproc.method=='compare.correct'){
    train.and.use.same <<-TRUE
    twindow.list <- CreateTimeWindowList(hist.train.mask=tmask.infile, hist.targ.mask=tmask.infile, esd.gen.mask=tmask.infile, 
                                         k=k.fold, method="generic")
    qc.mask.nc <- nc_open(qc.mask.path)
    varnames <- names(qc.mask.nc$var)
    print(varnames)
    print(paste('var_name:', varnames[[which(regexpr('*qc_mask', varnames) > 0 ) ]]))
    qc.mask <- ncvar_get(qc.mask.nc, varnames[[which(regexpr('*qc_mask', varnames) > 0 ) ]], collapse_degen=FALSE)
    qc.data.nc <- nc_open(qc.data.path)
    qc.data <- ncvar_get(qc.data.nc, var, collapse_degen=FALSE)
    postproc.args$var <- var
    output <- TrainDriver(target.masked.in=qc.mask, hist.masked.in=qc.data, fut.masked.in=data, mask.list=twindow.list, ds.method=NULL, k=k.fold,
                          create.postproc.out=TRUE, postproc.method=postproc.method, postproc.args=postproc.args)
  }
  dirpop <- getwd()
  setwd(out.dir)
  postproc.nc <- nc_open(postproc.outfile, write=TRUE)
  postproc.var <- ncvar_def(paste(var, "_postproc"), 
                            units='boolean', 
                            list(postproc.nc$dim$lon, postproc.nc$dim$lat, postproc.nc$dim$time), 
                            prec='float') #Got error when tried to specify 'short'
  postproc.nc <- ncvar_add(postproc.nc, postproc.var, verbose=TRUE)
  print('post-processing values added')
  ncvar_put(postproc.nc, postproc.var, output$postproc.out, verbose=TRUE)
  nc_close(postproc.nc)
  setwd(dirpop)
}

# # ####Instructions for a sample run with the 300th lon file
# in.file <- "/work/cew/downscaled/NOAA-GFDL/MPI-ESM-LR/rcp85/day/atmos/day/r1i1p1/v20111014/RRtxp1-CDFt-A38L01K00/tasmax/RR/OneD/v20140108/tasmax_day_RRtxp1-CDFt-A38L01K00_rcp85_r1i1p1_RR_20060101-20991231.I300_J31-170.nc"
# var='tasmax'
# k.fold=0
# postproc.method='compare.correct'
# out.dir <- "/home/cew/Code/testing/"
# tmask.infile='/archive/esd/PROJECTS/DOWNSCALING/3ToThe5th/masks/timemasks/maskdays_bymonth_20060101-20991231.nc'
# qc.mask.path <- "/home/cew/Code/testing/QCMasks/tasmax_day_testing-qc-mask4-1pow5-txp1-GFDL-CDFtv1-A00X01K00_rcp85_r1i1p1_SCCSC0p1_20060101-20991231.I300_J31-170-kdAdjust-QCMask.nc"
# qc.data.path <- "/home/cew/Code/testing/tasmax_day_testing-simple.bias-1pow5-txp1-GFDL-CDFtv1-A00X01K00_rcp85_r1i1p1_SCCSC0p1_20060101-20991231.I300_J31-170.nc"
# postproc.args=list('na')
# postproc.outfile <- "/work/cew/post-processed-out.nc"
# pp.out <- postProc.Driver(in.file, var, k.fold, postproc.method, out.dir, tmask.infile, qc.mask.path=qc.mask.path, 
#                           qc.data.path=qc.data.path, postproc.outfile=postproc.outfile)
# ####Instructions for a sample run with concatenated data, qcmask and qcdata files.
in.file <- "/work/cew/downscaled/NOAA-GFDL/MPI-ESM-LR/rcp85/day/atmos/day/r1i1p1/v20111014/RRtxp1-CDFt-A38k-mL01K00/tasmax/RR/v20140108/tasmax_day_RRtxp1-CDFt-A38k-mL01K00_rcp85_r1i1p1_RR_20060101-20991231.nc"
var='tasmax'
k.fold=0
postproc.method='compare.correct'
out.dir <- "/work/cew/"
tmask.infile='/archive/esd/PROJECTS/DOWNSCALING/3ToThe5th/masks/timemasks/maskdays_bymonth_20060101-20991231.nc'
qc.mask.path <- "/work/cew//downscaled/NOAA-GFDL/MPI-ESM-LR/rcp85/day/atmos/day/r1i1p1/v20111014/RRtxp1-CDFt-A38k-mL01K00/qc_mask/RR/v20140108/qc_mask_day_RRtxp1-CDFt-A38k-mL01K00_rcp85_r1i1p1_RR_20060101-20991231.nc"
qc.data.path <- "/work/cew//downscaled/NOAA-GFDL/MPI-ESM-LR/rcp85/day/atmos/day/r1i1p1/v20111014/RRtxp1-simple.bias.correct-A38r-mL01K00/tasmax/RR/v20140108/tasmax_day_RRtxp1-simple.bias.correct-A38r-mL01K00_rcp85_r1i1p1_RR_20060101-20991231.nc"
postproc.args=list('na')
postproc.outfile <- "post-processed-test-output.nc"
pp.out <- postProc.Driver(in.file, var, k.fold, postproc.method, out.dir, tmask.infile, qc.mask.path=qc.mask.path, 
                          qc.data.path=qc.data.path, postproc.outfile=postproc.outfile)