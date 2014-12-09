#' driver_a1rv2.r
#' phase 1 of driver script implementation for FUDGE: CDFt train driver 
#' originally created: a1r,08/2014
#' 
#' Modification by CEW 10-20-2014
#' Trying to see if this can run as part of a standalone script generation fxn. 
#' You could probably cut out a lot of the generic DS methods and correstponding QC checks...

############### Library calls, source necessary functions ###################################################
#TODO the following sapplys and sourcing should be a library call
sapply(list.files(pattern="[.]R$", path=paste(FUDGEROOT,'Rsuite/FudgeIO/src/',sep=''), full.names=TRUE), source);
sapply(list.files(pattern="[.]R$", path=paste(FUDGEROOT,'Rsuite/FudgePreDS/src/',sep=''), full.names=TRUE), source);
sapply(list.files(pattern="[.]R$", path=paste(FUDGEROOT,'Rsuite/FudgeQC/src/',sep=''), full.names=TRUE), source);
sapply(list.files(pattern="[.]R$", path=paste(FUDGEROOT,'Rsuite/FudgeTrain/src/',sep=''), full.names=TRUE), source);
#source("~/Code/fudge2014/Rsuite/drivers/LoadLib.R")
sapply(list.files(pattern="[.]R$", path=paste(FUDGEROOT,'Rsuite/Drivers/',sep=''), full.names=TRUE), source);
#source(paste(FUDGEROOT,'Rsuite/drivers/CDFt/TrainDriver.R',sep=''))

#-------Add traceback call for error handling -------
stored.opts <- options()[c('warn', 'error', 'showErrorCalls')]
options(error=traceback, warn = 1, showErrorCalls=TRUE)

#------- Add libraries -------------
LoadLib(ds.method)
#-------End Add libraries ---------

# ----- Begin segment like FUDGE Schematic Section 2: Access Input Data Sets -----

# netcdf handlers: Call FudgeIO

# construct file-names

###First, do simple QC checks, and set variables to be used later.

##Test logic for distringuishing a qc run from a regular run
if (grepl('qcmask', target.var)){
  message('Correcting for QC mask case')
  create.qc.mask <- TRUE
  write.ds.out <- FALSE
  qc.method <- args$qc.method
  args$qc.method <- NULL
  target.var <- sub('qcmask', "", target.var)
}else{
  write.ds.out <- TRUE
}

message("Setting downscaling method information")
SetDSMethodInfo(ds.method)
message("Checking downscaling arguments")
print(args)
QCDSArguments(k=k.fold, ds.method = ds.method, args=args)
#Check for writable output directory 
message("Checking output directory")
QCIO(output.dir)

#### Then, read in spatial and temporal masks. Those will be used
#### not only as a source of dimensions for writing the downscaled
#### output to file, but as an immediate check upon the dimensions
#### of the files being read in.

# spatial mask read check
spat.mask.filename <- paste(spat.mask.var,".","I",i.file,"_",file.j.range,".nc",sep='')
spat.mask.ncobj <- OpenNC(spat.mask.dir_1,spat.mask.filename)
print('OpenNC spatial mask: success..1') 

#ReadNC(spat.mask.ncobj,spat.mask.var,dstart=c(1,22),dcount=c(1,2))
spat.mask <- ReadMaskNC(spat.mask.ncobj, get.bounds.vars=TRUE)
print('ReadMaskNC spatial mask: success..1')

print("get xlon,ylat")
xlon <- sort(spat.mask$dim$lon)
print("xlon: received")
ylat <- sort(spat.mask$dim$lat)
print("ylat: received")

message("Reading in and checking time windowing masks")
if (train.and.use.same){ #set by SetDSMethodInfo() (currently edited for test settings)
  #Future data used in downscaling will be underneath the fut.time tag
  if(fut.time.trim.mask=='na'){
    #If there is no time trimming mask:
    print(paste("time trimming mask", fut.time.trim.mask))
    tmask.list <- CreateTimeWindowList(hist.train.mask = hist.time.window, hist.targ.mask = target.time.window, 
                                       esd.gen.mask = fut.time.window, k=k.fold, method=ds.method)
    names(tmask.list) <- c("train.pred", "train.targ", "fut.pred")
  }else{
    #If there is a time trimming mask
    print(paste("time trimming mask", fut.time.trim.mask))
    tmask.list <- CreateTimeWindowList(hist.train.mask = hist.time.window, hist.targ.mask = target.time.window, 
                                       esd.gen.mask = fut.time.window, k=k.fold, method=ds.method, 
                                       time.prune.mask = fut.time.trim.mask)
    names(tmask.list) <- c("train.pred", "train.targ", "fut.pred", "time.trim.mask")
  }
}else{
  #Data used in downscaling (as opposed to training ) will be underneath the esdgen tag
  tmask.list <- CreateTimeWindowList(hist.train.mask = hist.time.window, hist.targ.mask = target.time.window, 
                                     esd.gen.mask = esdgen.time.window, k=kfold, method=ds.method)
  names(tmask.list) <- c("train.pred", "train.targ", "esd.gen")
}

print(names(tmask.list))

#Check time masks for consistency against each other
QCTimeWindowList(tmask.list, k=k.fold)
#Obtain time series and other information for later checks
downscale.tseries <- tmask.list[[length(tmask.list)]]$dim$tseries
downscale.origin <- attr(tmask.list[[length(tmask.list)]]$dim$tseries, "origin")
downscale.calendar <- attr(tmask.list[[length(tmask.list)]]$dim$time, "calendar")

### Now, access input data sets
### For the variables specified in predictor.vars
for (predictor.var in predictor.vars){
  print(paste("predictor:",predictor.var,sep='')) 
  #TODO with multiple predictors, use this as outer loop before retrieving input files,assign names with predictor.var as suffix. 
  #There is also probably an elegant way to generalize this for an unknown number of input files, but that 
  #should wait for later. See QCINput for more information on what that might look like.
  
  ######################## input minifiles ####################
  
  ###CEW edit 8-28: Will not run without initializing predictor.var
  

  hist.filename <- GetMiniFileName(predictor.var,hist.freq_1,hist.model_1,hist.scenario_1,grid,hist.file.start.year_1,hist.file.end.year_1,i.file,file.j.range)
  print(hist.filename)
  fut.filename <- GetMiniFileName(predictor.var,fut.freq_1,fut.model_1,fut.scenario_1,grid,fut.file.start.year_1,fut.file.end.year_1,i.file,file.j.range)
#  fut.filename <- GetMiniFileName(predictor.var,fut.freq_1,fut.model_1,fut.scenario_1,grid,fut.file.start.year_1,fut.file.end.year_1,i.file,file.j.range)
#  print(fut.filename)
  target.filename <- GetMiniFileName(target.var,target.freq_1,target.model_1,target.scenario_1,grid,target.file.start.year_1,target.file.end.year_1,i.file,file.j.range)
  print(target.filename)
  out.filename <- GetMiniFileName(target.var,fut.freq_1,ds.experiment,fut.scenario_1,ds.region,fut.file.start.year_1,fut.file.end.year_1,i.file,file.j.range)
  print(out.filename)
  ###CEW MOD: create out.file early, so that it can be used for looping by time window.
  out.file <- paste(output.dir,"/", out.filename,sep='')
  out.ds <- OpenNC(output.dir, out.filename)
  
  # load the sample input datasets to numeric vectors
  hist.ncobj <- OpenNC(hist.indir_1,hist.filename)
  print("OpenNC: success..1")
  target.ncobj <- OpenNC(target.indir_1,target.filename)
  print("OpenNC: success..2")
  fut.ncobj <- OpenNC(fut.indir_1,fut.filename)
  print("OpenNC: success..3")
  
  #Read in sample data
  list.hist <- ReadNC(nc.object = hist.ncobj,
                      var.name=predictor.var)#dstart=c(1,1,1),dcount=c(1,140,16436)
  print("ReadNC: success..1")
  list.fut  <- ReadNC(fut.ncobj,var.name=predictor.var) #,dstart=c(1,1,1),dcount=c(1,140,34333) aka length(xlon), lenght(ylat)
  #Also temporarily hard-coded due to longer timeseries and length of mask files
  print("ReadNC: success..2")
  list.target <- ReadNC(target.ncobj,var.name=predictor.var) #,dstart=c(1,1,1),dcount=c(1,140,16436)
  #Temporarily hard-coded due to longer time series on train.target
  print("ReadNC: success..3")

  ####Precipitation changes go here
  if(predictor.var=='pr'){
    #Options currently hard-coded
    pr.mask.opt = 'us_trace'
    lopt.drizzle = TRUE
    lopt.conserve= TRUE
    print("Number of NAs in var:")
    print(sum(is.na(list.hist$clim.in)))
    print("Number of zeroes in var:")
    print(sum(list.hist$clim.in==0))
    if(train.and.use.same==TRUE){
      temp.out <- AdjustWetdays(ref.data=list.target$clim.in, ref.units=list.target$units$value, 
                                adjust.data=list.hist$clim.in, adjust.units=list.hist$units$value, 
                                opt.wetday=pr.mask.opt, lopt.drizzle=lopt.drizzle, lopt.conserve=lopt.conserve, 
                                lopt.graphics=FALSE, verbose=TRUE,
                                adjust.future=list.fut$clim.in, adjust.future.units=list.fut$units$value)
      list.target$clim.in <- temp.out$ref$data
      list.target$pr_mask <-temp.out$ref$pr_mask
      list.hist$clim.in <- temp.out$adjust$data
      list.hist$pr_mask <-temp.out$adjust$pr_mask
      list.fut$clim.in <- temp.out$future$data
      list.fut$pr_mask <-temp.out$future$pr_mask
      #remove from workspace to keep memory overhead low
      remove(temp.out)
    }else{
      temp.out <- AdjustWetdays(ref.data=list.target$clim.in, ref.units=list.target$units, 
                                adjust.data=list.hist$clim.in, adjust.units=list.hist$units, 
                                opt.wetday=opt.wetday, lopt.drizzle=FALSE, lopt.conserve=FALSE, 
                                lopt.graphics=FALSE, verbose=TRUE,
                                adjust.future=NA, adjust.future.units=NA)
      list.target$clim.in <- temp.out$ref$data
      list.target$pr_mask <-temp.out$ref$pr_mask
      list.hist$clim.in <- temp.out$adjust$data
      list.hist$pr_mask <-temp.out$adjust$pr_mask
    }
  }
}

# simulate the user-specified choice of climate variable name to be processed
# TODO: Talk to Aparna about this, because it still needs work.
clim.var.in <- list.fut$clim.in
# ----- Begin segment like FUDGE Schematic Section 3: Pre-processing of Input Data -----

# Spatial Range For Predictors -------------------------
#TODO cew: Explore passing spat.mask.ncobj as second arg, 
#making checks currently done internal to the function that relies on the path to outside. 
#This way, we open the file just once. spat.mask.ncobj potentially to be used in final sections

message("Applying spatial masks")

list.target$clim.in <- ApplySpatialMask(list.target$clim.in, spat.mask$masks[[1]])
print("ApplySpatialMask target: success..1")
list.hist$clim.in <- ApplySpatialMask(list.hist$clim.in, spat.mask$masks[[1]])
print("ApplySpatialMask target: success..2")
list.fut$clim.in <- ApplySpatialMask(list.fut$clim.in, spat.mask$masks[[1]])
print("ApplySpatialMask target: success..3")
#- - - - - Loop through masked.data to downscale points ------------- #

# ----- Begin segment like FUDGE Schematic Section 3: QC of Data After Pre-Processing -----#

#Perform a check upon the time series, dimensions and method of the downscaling 
#input and output to assure compliance
message("Checking input data")

QCInputData(train.predictor = list.hist, train.target = list.target, esd.gen = list.fut, 
            k = k.fold, ds.method=ds.method, calendar=downscale.calendar)

# compute the statistics of the vector to be passed into the downscaling training

# + + + function MyStats + + + moved to MyStats.R
##  CEW edit
#source(paste(FUDGEROOT,'/Rsuite/aux/','MyStats.R',sep=''))
source(paste(FUDGEROOT,'Rsuite/aux/','MyStats.R',sep=''))
# use the my_stats function to compute the statistics of the user-specified variable

####Read in time masks and perform QC operations
#source('Rsuite/FudgePreDS/src/QCTimeMask.R')



# -- QC of input data ends --#

# ----- Begin segment like FUDGE Schematic Section 3: Apply Distribution Transform -----

# If indicated by the user-specified logical variable lopt.wetday,
# classify each day as being a wetday or not, according to the method
# indicated by the user-specified numerical variable opt.wetday
# Note: function WetDayID is in file task1_WetDayID.R

# If the user-specified numerical variable opt.transform > 1, then initiate a
# data transformation processed using the method indicated by the user-specified
# numerical variable opt.transform
# Note: function TransformData is in file task1_transform.R


# ----- Begin segment FUDGE Schematic Section 4: ESD Method Training and Generation -----


################ call train driver ######################################
print("FUDGE training begins...")
start.time <- proc.time()
#source("Rsuite/drivers/TrainDriver.R")
#source("Rsuite/FudgeTrain/src/LoopByTimeWindow.R")
#source("Rsuite/FudgeTrain/src/CallDSMethod.R")
if (args!='na'){
  adjust <- TrainDriver(target.masked.in = list.target$clim.in, 
                    hist.masked.in = list.hist$clim.in, 
                    fut.masked.in = list.fut$clim.in, 
                    mask.list = tmask.list, k=0, 
                    create.ds.out = FALSE, ds.method = ds.method,  downscale.args=args,  
                    create.qc.mask=create.qc.mask, qc.test=qc.method, qc.args=NULL, qc.in=NA, 
                    create.postproc.out = create.postproc.out, postproc.method=postproc,method, postproc.args=postproc.args)
}else{
  adjust <- TrainDriver(target.masked.in = list.target$clim.in, 
                    hist.masked.in = list.hist$clim.in, 
                    fut.masked.in = list.fut$clim.in, 
                    mask.list = tmask.list, k=0, 
                    create.ds.out = FALSE, ds.method = ds.method,  downscale.args=NULL,  
                    create.qc.mask=create.qc.mask, qc.test=qc.method, qc.args=NULL, qc.in=NA,
                    create.postproc.out = create.postproc.out, postproc.method=postproc,method, postproc.args=postproc.args)
}
print(summary(adjust$esd.final))
message("FUDGE training ends")
message(paste("FUDGE training took", proc.time()[1]-start.time[1], "seconds to run"))
##TODO a1r: can be deduced from future train time dimension length or esdgen's ##
#time.steps <- 34333 # No.of time steps in the downscaled output.
time.steps <- dim(adjust$esd.final)[3]
##
############## end call TrainDriver ######################################

# ds.vector <- TrainDriver(i.start,loop.start,loop.end,target.masked.in,hist.masked.in,fut.masked.in,ds.method,k=0,time.steps)
# esd.final <- ds.vector 
#plot(fut.clim.in,esd.output,xlab="fut.esdGen.predictor -- Large-scale data", ylab="ds -- Downscaled data")

# + + + end Training + + +


# ----- Begin segment like FUDGE Schematic Section 5: Apply Distribution Back-Transform -----
#TODO Diana

#--QC Downscaled Values
print("STATS: Downscaled output")
MyStats(ds$esd.final,verbose="yes")

numzeroes <- sum(ds$esd.final[!is.na(ds$esd.final)] < 0)
print(paste("Number of values in output < 0:", numzeroes))
if(numzeroes > 0){
  ds$esd.final[ds$esd.final < 0] <- 0
  print(paste("Number of values in output < 0 after correction:", sum(ds$esd.final[!is.na(ds$esd.final)] < 0)))
}
pr.post.process <- TRUE

if('pr'%in%target.var && pr.post.process){ #TODO: Change to predictand.vars at some point
  print(paste("Adjusting pr values to pr threshold"))
  ds$esd.final <- as.numeric(ds$esd.final) * MaskPRSeries(ds$esd.final, units=list.fut$units$value , index = pr.mask.opt)
}

# ----- Begin segment like FUDGE Schematic Section 6: Write Downscaled results to data files -----
#Replace NAs by missing 
###CEW edit: replaced ds.vector with ds$esd.final
ds$esd.final[is.na(ds$esd.final)] <- 1.0e+20

#out.file <- paste(output.dir,"/","outtest", fut.filename,sep='')
#out.file <- paste(output.dir,"/", fut.filename,sep='')
out.file <- paste(output.dir,"/", out.filename,sep='')

####Start implementing checks for output dirs and /tmpdirs
exists <- file.create(out.file)
if(!exists){
  print("creating output direcotries")
  system(paste("mkdir -p ", output.dir, sep=""))
  system(paste("mkdir -p ", "/", sub(TMPDIR, "", output.dir), sep=""))
#   if(create.qc.mask==TRUE){
#     system(paste("mkdir -p"))
#     system(paste("mkdir -p"))
#   }
}


#Create structure containing bounds and other vars
bounds.list.combined <- c(spat.mask$vars, tmask.list[[length(tmask.list)]]$vars)
isBounds <- length(bounds.list.combined) > 1
#Write to netCDF
# ds.out.filename = WriteNC(out.file,ds$esd.final,target.var,
#                           xlon,ylat[loop.start:loop.end],time.index.start=0,
#                           time.index.end=(time.steps-1),start.year=fut.train.start.year_1,
#                           units=list.fut$units$value,calendar= downscale.calendar,
#                           lname=paste('Downscaled ',list.fut$long_name$value,sep=''),
#                           cfname=list.fut$cfname$value)
#if(write.ds.out){
  ds.out.filename = WriteNC(out.file,ds$esd.final,target.var,
                            xlon,ylat,
                            downscale.tseries=downscale.tseries, 
                            downscale.origin=downscale.origin, calendar = downscale.calendar,
                            #start.year=fut.train.start.year_1,
                            units=list.fut$units$value,
                            lname=paste('Downscaled ',list.fut$long_name$value,sep=''),
                            cfname=list.fut$cfname$value, bounds=isBounds, bnds.list = bounds.list.combined, 
                            is.adjusted=, adjust.method=
  )
  #Write Global attributes to downscaled netcdf
  label.training <- paste(hist.model_1,".",hist.scenario_1,".",hist.train.start.year_1,"-",hist.train.end.year_1,sep='')
  label.validation <- paste(fut.model_1,".",fut.scenario_1,".",fut.train.start.year_1,"-",fut.train.end.year_1,sep='')
  #Code for obtaining the filenames of all files from tmask.list
  # commandstr <- paste("attr(tmask.list[['", names(tmask.list), "']],'filename')", sep="")
  # time.mask.names <- ""
  # for (i in 1:length(names(tmask.list))){
  #   var <- names(tmask.list[i])
  #   time.mask.names <- paste(time.mask.names, paste(var, ":", eval(parse(text=commandstr[i])), ",", sep=""), collapse="")
  #   print(time.mask.names)
  # }
  #Code for obtaining the options for precipitation and post-processing
  #(current PP options are profoundly unlikely to be triggered for anything not pr)
  post.process.string = ""
  if(exists("pr.mask.opt")){
    post.process.string <- paste(post.process.string, "trace pr threshold:", pr.mask.opt, 
                                 ", lopt.drizzle:", lopt.drizzle, ", lopt.conserve:", lopt.conserve, 
                                 ", trace post-processing:", pr.post.process, sep="")
  }
  WriteGlobals(ds.out.filename,k.fold,target.var,predictor.var,label.training,ds.method,
               configURL,label.validation,institution='NOAA/GFDL',
               version=as.character(parse(file=paste(FUDGEROOT, "version", sep=""))),title="CDFt tests in 1^5", 
               ds.arguments=args, time.masks=tmask.list, ds.experiment=ds.experiment, 
               post.process=post.process.string, time.trim.mask=fut.time.trim.mask, 
               tempdir=TMPDIR, include.git.branch=TRUE)
  
  #print(paste('Downscaled output file:',ds.out.filename,sep=''))
  message(paste('Downscaled output file:',ds.out.filename,sep=''))
#}

if(create.qc.mask==TRUE){
  for (var in predictor.vars){
    ds$qc.mask[is.na(ds$qc.mask)] <- as.double(1.0e20)
    ###qc.method needs to get included in here SOMEWHERE.
    qc.var <- paste(var, 'qcmask', sep="_")
    if(Sys.info()['nodename']=="cew"){ #'cew'
      #only activated for testing on CEW workstation
      qc.outdir <- paste(output.dir, "/QCMask/", sep="")
      qc.file <- paste(qc.outdir, sub(pattern=var, replacement=qc.var, out.filename), sep="") #var, "-",
    }else{  
      #presumably running on PP/AN; dir creation taken care of
      qc.splitdir <- strsplit(output.dir, split="/")
      qc.splitdir <- qc.splitdir[[1]]
      qc.index <- length(qc.splitdir)-4
      #assumes var_qcmask directory already created as part of the runscript process
      qc.outdir <- paste(c(qc.splitdir[1:qc.index], qc.var, qc.splitdir[(qc.index + 1):length(qc.splitdir)]),
                         collapse="/")
      qc.file <- paste(qc.outdir, "/", sub(var, qc.var, out.filename), sep="")
    }
    ###Check to make sure that it is possible to create the qc file; create dirs if not
    message("Attempting creation of QC file")
    message(qc.file)
    exists <- file.create(qc.file)
    if(!exists){
      message("creating QC directories")
      message(dirname(qc.file))
      system(paste("mkdir -p ", dirname(qc.file), sep=""))
      message(sub(TMPDIR, "", dirname(qc.file)))
      system(paste("mkdir -p ", "/", sub(TMPDIR, "", dirname(qc.file)), sep=""))
    }
    message(paste('attempting to write to', qc.file))
    qc.out.filename = WriteNC(qc.file,ds$qc.mask,qc.var,
                              xlon,ylat,prec='float', #missval=1.0e20,
                              downscale.tseries=downscale.tseries, 
                              downscale.origin=downscale.origin, calendar = downscale.calendar,
                              #start.year=fut.train.start.year_1,
                              units='boolean',
                              lname=paste('QC Mask'),
                              bounds=isBounds, bnds.list = bounds.list.combined
    )
    WriteGlobals(qc.out.filename,k.fold,target.var,predictor.var,label.training,ds.method,
                 configURL,label.validation,institution='NOAA/GFDL',
                 version=as.character(parse(file=paste(FUDGEROOT, "version", sep=""))),title="CDFt tests in 1^5", 
                 ds.arguments=args, time.masks=tmask.list, ds.experiment=ds.experiment, 
                 post.process=post.process.string, time.trim.mask=(fut.time.trim.mask=='na'), 
                 tempdir=TMPDIR, include.git.branch=TRUE,
                 is.qcmask=TRUE, qc.method=qc.method
                 )
    message(paste('QC Mask output file:',qc.out.filename,sep=''))
    message("Attempting system GCP operation for the QC output file:")
    commandstr <- paste("gcp ", qc.out.filename, " /", sub(TMPDIR, "", qc.out.filename), sep="")
    message(commandstr)
    system(commandstr)
  }
}
print(paste("END TIME:",Sys.time(),sep=''))
