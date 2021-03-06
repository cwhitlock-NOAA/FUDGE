#' driver_a1rv2.r
#' phase 1 of driver script implementation for FUDGE: CDFt train driver 
#' originally created: a1r,08/2014

############### Library calls, source necessary functions ###################################################
#TODO the following sapplys and sourcing should be a library call
sapply(list.files(pattern="[.]R$", path=paste(FUDGEROOT,'Rsuite/FudgeIO/',sep=''), full.names=TRUE), source);
sapply(list.files(pattern="[.]R$", path=paste(FUDGEROOT,'Rsuite/FudgePreDS/',sep=''), full.names=TRUE), source);
sapply(list.files(pattern="[.]R$", path=paste(FUDGEROOT,'Rsuite/FudgeQC/',sep=''), full.names=TRUE), source);
sapply(list.files(pattern="[.]R$", path=paste(FUDGEROOT,'Rsuite/FudgeTrain/',sep=''), full.names=TRUE), source);
source(paste(FUDGEROOT,'Rsuite/Drivers/LoadLib.R',sep=''))
source(paste(FUDGEROOT, 'Rsuite/Drivers/UtilityFunctions.R', sep=""))
#sapply(list.files(pattern="[.]R$", path=paste(FUDGEROOT,'Rsuite/Drivers/',sep=''), full.names=TRUE), source);
#source(paste(FUDGEROOT,'Rsuite/drivers/CDFt/TrainDriver.R',sep=''))

#-------Add traceback call for error handling -------
stored.opts <- options()[c('warn', 'error', 'showErrorCalls')]
error.handler.function <- function(){
  #message(writeLines(traceback()))
  traceback()
  message("Quitting gracefully with exit status 1")
  #If quitting from a non-interactive session, a status of 1 should be sent. Test this.
  #quit(save="no", status=1, runLast=FALSE, save=FALSE) #runLast=FALSE
}
#previously traceback
options(error=error.handler.function, warn = 1, showErrorCalls=TRUE)
###See if there's a good way to return back to the original settings
###after this point. Probably not a component of a --vanilla run. 
###But it unquestionably simplifies debugging.

#------- Add libraries -------------
LoadLib(ds.method)
#-------End Add libraries ---------
###############################################################################################################
#' key data objects -----
#' clim.var.in:   numeric vector containing data of the input climate variable
#                to be processed
#' esd.output:    numeric vector representing data produced by statisical
#                downscaling processes of FUDGE schematic section 4.
#' esd.final:     numeric vector containing the version of the downscaled output
#                to be archived, either the same as esd.output or a 
#                back-transformed version of esd.output

# ----- Begin segment like FUDGE Schematic Section 2: Read User Specs -----
# TODO The following variables will be passed from experGen 
#' user specified options -----
#' predictor.vars: String vector, list of predictor variables  
#' predictand.var: predictand variable
#' -----Information on Historical Training Predictor dataset------
#' hist.file.start.year_1: file start year
#' hist.file.end.year_1: file end year
#' hist.train.start.year_1: train start year
#' hist.train.end.year_1: train end year
#' hist.scenario_1: experiment,ensemble member specification 
#' hist.nyrtot_1: Total number of years 
#' hist.model_1: Name of the model
#' hist.freq_1: Time Frequency 
#' hist.indir_1: Input directory 
#' -----Information on Future Predictor dataset---------
#' fut.file.start.year_1: file start year
#' fut.file.end.year_1: file end year
#' fut.train.start.year_1: train start year
#' fut.train.end.year_1: train end year
#' fut.scenario_1: experiment and ensemble member specification
#' fut.nyrtot_1: Total number of years 
#' fut.model_1: Model name 
#' fut.freq_1: Time frequency 
#' fut.indir_1: Input directory
#' -----Information on Target Dataset used in training------
#' target.file.start.year_1: file start year
#' target.file.end.year_1: file end year
#' target.train.start.year_1: train start year
#' target.train.end.year_1: train end year
#' target.scenario_1: experiment, ensemble member specification 
#' target.nyrtot_1: Total number of years
#' target.model_1: Name of the model 
#' target.freq_1: Time frequency 
#' target.indir_1: Input directory
#' ----------- masks -----------------------
#' spat.mask.dir_1: spatial mask directory
#' spat.mask.var: spatial mask variable (Name of the Region to be downscaled)
#' -----Method descriptors------------------------
#' ds.method: Name of the downscaling method/library
#' ds.experiment: Name of the downscaling experiment
#' k.fold: Value of 'k' in k-fold cross-validation
#' -----Custom method-specific information if any ----
#'  lopt.wetday:   single element logical vector containing user-specified option
#'                 specifying whether function WetDayID should be called (T,F)
#'  opt.wetday:    single element numeric vector containing user-specified option
#'                 indicating which threshold option for wet vs dry day to use
#'  opt.transform: single element numeric vector containing user-specified option
#'                 setting what type of data transform, if any, is to be done
#'  npas : for CDFt number of cuts
#' -----Output root location---------------------
# ----- Begin driver program to develop different sections in FUDGE plus CDFt train -----
#' output.dir: Output root location
#'------- Lon/I,Lat/J range to be downscaled ------
#' i.start: I index start, it is typically 1 since we are reading and writing to minifiles per longitude
#' J.range.suffix: J File range suffix to identify suffix of the input files. Get j.start, j.end from here
#' j.start: J index start - use in file suffix
#' j.end: J index end - use in file suffix
#' loop.start: J loop start , use in writing output
#' loop.end: J loop end, use in writing output

# ----- Begin segment like FUDGE Schematic Section 2: Access Input Data Sets -----

# netcdf handlers: Call FudgeIO

# construct file-names

###First, do simple QC checks, and set variables to be used later.

#message("Attempting to break script deliberately")
#print(fakevar)

message("Setting downscaling method information")
SetDSMethodInfo(ds.method)
message("Checking downscaling arguments")
QCDSArguments(k=k.fold, ds.method = ds.method, args=args)
#Check for writable output directory 
#TODO: remove this; only needed if testing R code separately
message("Checking output directory")
QCIO(output.dir)

if(!exists('pre_ds')){ #put better check in here once you are done with the testing
  message('Conversion of pre- and post- downscaling adjustment input')
  if(exists('pr_opts')){
    pp.out <- adapt.pp.input(mask.list, pr_opts)
  }else{
    pp.out <- adapt.pp.input(mask.list)
  }
  pre_ds <- pp.out$pre_ds
  post_ds <- pp.out$post_ds
}
print(pre_ds)
print(post_ds)

#Initialize instructions for pre- and post-ds adjustment
post.ds <- compact(lapply(post_ds, index.a.list, 'loc', 'outloop'))
post.ds.train <- compact(lapply(post_ds, index.a.list, 'loc', 'inloop'))
qc.maskopts <- qc.mask.check(post.ds.train, post.ds)
pre.ds <- compact(lapply(pre_ds, index.a.list, 'loc', 'outloop'))
pre.ds.train <- compact(lapply(pre_ds, index.a.list, 'loc', 'inloop'))
#Generate metadata references for the pre- and post-processing functions
#Things that contain an ADJUSTMENT
post_ds_adj <- compact(lapply(post_ds, index.a.list, 'adjust.out', 'on'))



message("Checking post-processing/section5 adjustments")

# if(pre_ds!='na'){
# adjust.list <- QCAdjustmentList(post_ds)
# }else{
#   adjust.list <- list("adjust.methods"=NA, "adjust.args"=NA, "adjust.pre.qc"=NA, "adjust.pre.qc.args"=NA, 
#                       "qc.check"=FALSE, "qc.method"=NA,"qc.args"=NA)
# }


#### Then, read in spatial and temporal masks. Those will be used
#### not only for the masks, but as an immediate check upon the dimensions
#### of the files being read in.

# # spatial mask read check
 message("Checking for spatial masks vars")
if(spat.mask.dir_1!="na"){
  #spat.mask.filename <- paste(spat.mask.var,".","I",i.file,"_",file.j.range,".nc",sep='')
  spat.mask.filename <- paste(spat.mask.var,".","I",i.file,"_",file.j.range,".nc",sep='')
  spat.mask.ncobj <- OpenNC(spat.mask.dir_1,spat.mask.filename)
  print('OpenNC spatial mask: success..1') 
  #ReadNC(spat.mask.ncobj,spat.mask.var,dstart=c(1,22),dcount=c(1,2))
  spat.mask <- ReadMaskNC(spat.mask.ncobj, get.bounds.vars=FALSE)#TODO: remove opt for getting the bounds vars from fxn
  print('ReadMaskNC spatial mask: success..1')
}else{
  spat.mask <- NULL
  message("no spatial mask included; skipping to next step")
}

message("Reading in and checking time windowing masks")
#Either all data will use a time-windowing mask, or none will use it. 
if (train.and.use.same){ #set by SetDSMethodInfo() (currently edited for test settings)
  #Future data used in downscaling will be underneath the fut.time tag
  if(fut.time.trim.mask=='na'){
    #If there is no time trimming mask:
    print(paste("time trimming mask", fut.time.trim.mask))
    if(target.time.window!='na'){
      #If there are masks included (this should be the most common use case)
      message('Creating list of time windows')
      tmask.list <- CreateTimeWindowList(hist.train.mask = hist.time.window, hist.targ.mask = target.time.window, 
                                         esd.gen.mask = fut.time.window, k=k.fold, method=ds.method)#TODO: Edit createtimewindowlist, too
      names(tmask.list) <- c("train.pred", "train.targ", "fut.pred")
    }else{
      #Otherwise, if there were no masks included at all
      message("no time windows included; moving on to next step")
      tmask.list <- list("na")
    }
  }else{
    #If there is a time trimming mask, and there are masks of all kinds
    print(paste("time trimming mask", fut.time.trim.mask))
    tmask.list <- CreateTimeWindowList(hist.train.mask = hist.time.window, hist.targ.mask = target.time.window, 
                                       esd.gen.mask = fut.time.window, k=k.fold, method=ds.method, 
                                       time.prune.mask = fut.time.trim.mask)
    names(tmask.list) <- c("train.pred", "train.targ", "fut.pred", "time.trim.mask")
  }
}else{ #Once esd.gen implemented, should be most common use case
  #Data used in downscaling (as opposed to training ) will be underneath the esdgen tag
  if(target.time.window!='na'){
  tmask.list <- CreateTimeWindowList(hist.train.mask = hist.time.window, hist.targ.mask = target.time.window, 
                                     esd.gen.mask = esdgen.time.window, k=kfold, method=ds.method)
  names(tmask.list) <- c("train.pred", "train.targ", "esd.gen")
  }else{
    #Otherwise, if there were no masks included at all
    message("no time windows included; moving on to next step")
    tmask.list <- list("na")
  }
}

# #Check time masks for consistency against each other
# QCTimeWindowList(tmask.list, k=k.fold)
# #Obtain time series and other information for later checks
# downscale.tseries <- tmask.list[[length(tmask.list)]]$dim$tseries
# downscale.origin <- attr(tmask.list[[length(tmask.list)]]$dim$tseries, "origin")
# downscale.calendar <- attr(tmask.list[[length(tmask.list)]]$dim$time, "calendar")

### Now, access input data sets
message("Reading in target data")
target.filename <- GetMiniFileName(target.var,target.freq_1,target.model_1,target.scenario_1,grid,
                                   target.file.start.year_1,target.file.end.year_1,i.file,file.j.range)
print(target.filename)
list.target <- ReadNC(OpenNC(target.indir_1, target.filename), var=target.var, dim="spatial")#,dstart=c(1,1,1),dcount=c(1,140,16436)
message("Applying spatial mask to target data")
list.target$clim.in <- ApplySpatialMask(list.target$clim.in, spat.mask$masks[[1]])

#TODO: When multiple RIP support is enabled, move the output files to the inner RIP loop
out.filename <- GetMiniFileName(target.var,fut.freq_1,ds.experiment,fut.scenario_1,ds.region,
                                fut.file.start.year_1,fut.file.end.year_1,i.file,file.j.range)
print(out.filename)

#When available, loop over all minifiles selected
#for ( c(startlon, startlat) in minifiles)){
  for (predictor.var in 1:length(predictor.vars)){
    #for (i in 1:length(i.files)){ #At some point, discuss how to pass this from the input r code
    #Note that this loop could probably give you the corresponding index of the input directories
    print(paste("predictor:",predictor.var,sep='')) 
    p.var <- predictor.vars[predictor.var]
    #TODO with multiple predictors, use this as outer loop before retrieving input files,assign names with predictor.var as suffix. 
    #There is also probably an elegant way to generalize this for an unknown number of input files, but that 
    #should wait for later. See QCInput for more information on what that might look like.
    
    ######################## input minifiles ####################
  
    #Obtain coarse GCM data
    message("Obtaining Coarse Historical data (predictor)")
    hist.filename <- GetMiniFileName(p.var,hist.freq_1,hist.model_1,hist.scenario_1,grid,
                                     hist.file.start.year_1,hist.file.end.year_1,i.file,file.j.range)
    print(hist.filename)
    hist.ncobj <- OpenNC(hist.indir_1,hist.filename)
    #TODO: When multiple var support is implemented, organize the $hist structure by variable
    #temp.list <- ReadNC(nc.object = hist.ncobj, var.name=predictor.var, dim='spatial')#dstart=c(1,1,1),dcount=c(1,140,16436)
    #ds.struct$hist[[var]] <- ReadNC(nc.object = hist.ncobj, var.name=var)
    list.hist <- ReadNC(nc.object = hist.ncobj, var.name=p.var)
    print("Applying spatial mask to coarse predictor dataset")
    list.hist$clim.in <- ApplySpatialMask(list.hist$clim.in, spat.mask$masks[[1]])
    #Re-initialize RIPs and RIP organization when the input structures can handle it
    #for(rip in 1:length(rips)){
    message(paste("Obtaining future predictor dataset for var (var) and rip (rip)"))
      fut.filename <- GetMiniFileName(p.var,fut.freq_1,fut.model_1,fut.scenario_1,grid,
                                    fut.file.start.year_1,fut.file.end.year_1,i.file,file.j.range)
      fut.ncobj <- OpenNC(fut.indir_1,fut.filename)
      list.fut <- ReadNC(fut.ncobj,var.name=p.var, dim='temporal') #rip=rip, 
      print("Applying spatial mask to future predictor dataset")
      list.fut$clim.in <- ApplySpatialMask(list.fut$clim.in, spat.mask$masks[[1]])
      #if(!is.null(ds.struct$esd[[rip]]$dim)){ #If time dimension has not yet been obtained
        #ds.temp <- ReadNC(fut.ncobj,var.name=var, rip=rip, dim='temporal')
        #ds.struct$esd[[rip]][[var]] <- c(ds.temp$clim.in, ds.temp$cfname, ds.temp$long_name, ds.temp$units)
        #ds.struct$esd[[rip]][["dim"]] <- ds.temp$dim
        #ds.struct$esd[[rip]][["vars"]] <- ds.temp$vars
        #remove(ds.temp)
      #}else{
        ##TODO: the structure here was an alternative. Keep it in mind for later. 
        #ds.struct$esd[[rip]][[var]][[paste(var, rip, sep=".")]] <- ReadNC(fut.ncobj, var.name=var, dim="none")
      #}
    #} RIP for loop
    
  }#Goes with looping over multiple available minifiles
    
    #It is likely that pre- processing could be variable specific (i.e. precipitation)
    #That would seem to require another tag in the XML
    
    

message('Looking for pre-processing functions to apply')
#preproc.outloop <- compact(lapply(pre_ds, index.a.list, 'loc', 'outloop'))
print('preproc application successful')
#Okay, this structure sort of implies a variable ATTRIBUTE rather than a variable element in a list
#Which should be added to ReadNC
if(length(pre.ds) !=0){
  message('Applying S3 Adjustment')
  temp.output <- callS3Adjustment(s3.instructions=pre.ds, 
                                  hist.pred = list.hist$clim.in, 
                                  hist.targ = list.target$clim.in, 
                                  fut.pred = list.fut$clim.in,  
                                  s5.instructions=post.ds)
  #Assign output and remove temporary output 
  post.ds <- temp.output$s5.list
  list.target$clim.in <- temp.output$input$hist.targ
  list.hist$clim.in <- temp.output$input$hist.pred
  list.fut$clim.in <- temp.output$input$fut.pred
  remove(temp.output)
}

#Perform a check upon the time series, dimensions and method of the downscaling 
#input and output to assure compliance
#TODO: Are these checks still neccessary in any sense?
# message("Checking input data")
# QCInputData(train.predictor = list.hist, train.target = list.target, esd.gen = list.fut, 
#             k = k.fold, ds.method=ds.method, calendar=downscale.calendar)

print("FUDGE training begins...")
start.time <- proc.time()

#args should always exist; it's specified in the runcode
if (args[1]=='na'){
  ds.args=NULL
}else{
  ds.args=args
}

  ds <- TrainDriver(target.masked.in = list.target$clim.in, 
                    hist.masked.in = list.hist$clim.in, 
                    fut.masked.in = list.fut$clim.in, ds.var=target.var, 
                    mask.list = tmask.list, ds.method = ds.method, k=0, time.steps=NA, 
                    istart = NA,loop.start = NA,loop.end = NA, downscale.args=ds.args,
                    s3.instructions=pre.ds.train,
                    s5.instructions=post.ds.train, 
                    create.qc.mask=(qc.maskopts$qc.inloop))
print(summary(ds$esd.final[!is.na(ds$esd.final)]))
message("FUDGE training ends")
message(paste("FUDGE training took", proc.time()[1]-start.time[1], "seconds to run"))

############## end call TrainDriver ######################################
# + + + end Training + + +


# ----- Begin segment like FUDGE Schematic Section 5: Apply Distribution Back-Transform -----

#Call the Section 5 Adjustments to be applied to post-downscaled output
message("Calling Section 5 Adjustments")
if(length(post.ds) !=0){
  temp.postproc <- callS5Adjustment(post.ds,
                                    data = ds$esd.final,
                                    hist.pred = list.hist$clim.in, 
                                    hist.targ = list.target$clim.in, 
                                    fut.pred  = list.fut$clim.in)
  ds$esd.final <- temp.postproc$ds.out
  if(qc.maskopts$qc.outloop){
    ds$qc.mask <- temp.postproc$qc.mask
  }
  remove(temp.postproc)
}

message("checking summary data")
print(summary(as.vector(ds$esd.final), digits=6))

# ----- Begin segment like FUDGE Schematic Section 6: Write Downscaled results to data files -----
#Replace NAs by missing 
ds$esd.final[is.na(ds$esd.final)] <- 1.0e+20 #TODO: Mod for changing all missing values. 

#Or: replace within the loop, adding in a missval. That is def. a thing that you could do.
#But it should probably wait until there is a possibility that there might be more than
#one downscaled output, and how you'd decide to loop over those.


#So: for all RIPs in the list of rips to work with, write data as a separate file. 
#This means that each RIP needs to be a separate file, and therefore *one* out.filename
#is probably not sufficient. Therefore, have a chat with the ESD team about where the 
#RIP of the input data would be put for safekeeping. 

#for (rip in 1:length(rips.list)){
out.file <- paste(output.dir,"/", out.filename,sep='')

#Create structure containing bounds and other vars

#bounds.list.combined <- c(spat.mask$vars, tmask.list[[length(tmask.list)]]$vars)
#isBounds <- length(bounds.list.combined) > 1
ds.out.filename = WriteNC(out.file,ds$esd.final,target.var,
                          xlon=list.target$dim$lon,ylat=list.target$dim$lat,
                          downscale.tseries=list.fut$dim$time, 
                          var.data=c(list.target$vars, list.fut$vars),
                          units=list.fut$units$value,
                          lname=paste('Downscaled ',list.fut$long_name$value,sep=''),
                          cfname=list.fut$cfname$value 
                          )

#Write Global attributes to downscaled netcdf
label.training <- paste(hist.model_1,".",hist.scenario_1,".",hist.train.start.year_1,"-",hist.train.end.year_1,sep='')
label.validation <- paste(fut.model_1,".",fut.scenario_1,".",fut.train.start.year_1,"-",fut.train.end.year_1,sep='')

###Code to determine whether or not to include the git branch
if(Sys.getenv("USERNAME")=='cew'){
  git.needed=TRUE
}else{
  #Someone else is running it, modules are available and presumably git branch not needed
  git.needed=FALSE
}

WriteGlobals(ds.out.filename,k.fold,target.var,predictor.vars,label.training,ds.method,
             configURL,label.validation,institution='NOAA/GFDL',
             version=as.character(parse(file=paste(FUDGEROOT, "version", sep=""))),title=paste(target.var, "downscaled with", 
                                                                                               ds.method, ds.experiment), 
             ds.arguments=args, time.masks=tmask.list, ds.experiment=ds.experiment, 
             grid_region=grid, mask_region=ds.region,
             time.trim.mask=fut.time.trim.mask, 
             tempdir=TMPDIR, include.git.branch=git.needed, FUDGEROOT=FUDGEROOT, BRANCH=BRANCH,
#              is.pre.ds.adjust=(length(pre.ds)+length(pre.ds.train) > 0),
#              pre.ds.adjustments=c(pre.ds, pre.ds.train),
#              is.post.ds.adjust=(length(post.ds)+length(post.ds.train) > 0),
#              post.ds.adjustments=c(post.ds.train, post.ds)
             is.pre.ds.adjust=(length(pre_ds) > 0),
             pre.ds.adjustments=pre_ds,
             is.post.ds.adjust=(length(post_ds_adj) > 0),
             post.ds.adjustments=post_ds_adj)
message(paste('Downscaled output file:',ds.out.filename,sep=''))
#}

if(qc.maskopts$qc.inloop || qc.maskopts$qc.outloop){ ##Created waaay back at the beginning, as part of the QC functions
  for (var in predictor.vars){
    ds$qc.mask[is.na(ds$qc.mask)] <- as.double(1.0e20)
    ###qc.method needs to get included in here SOMEWHERE.
    qc.var <- paste(var, 'qcmask', sep="_")
    if(Sys.info()['nodename']=="cew"){ #'cew'
      #only activated for testing on CEW workstation
      qc.outdir <- paste(output.dir, "/QCMask/", sep="")
      qc.file <- paste(qc.outdir, sub(pattern=var, replacement=qc.var, out.filename), sep="") #var, "-",
    }else{  
      qc.file <- paste(mask.output.dir, sub(pattern=var, replacement=qc.var, out.filename), sep="")
    }
    ###Check to make sure that it is possible to create the qc file; create dirs if not
    message("Attempting creation of QC file")
    message(qc.file)
    exists <- file.create(qc.file)
    if(!exists){
      print("ERROR! Dir creation script not beahving as expected!")
    }
    message(paste('attempting to write to', qc.file))
    qc.out.filename = WriteNC(qc.file,ds$qc.mask,qc.var,
                              xlon=list.target$dim$lon,ylat=list.target$dim$lat,
                              downscale.tseries=list.fut$dim$time, 
                              var.data=c(list.target$vars, list.fut$vars),
                              prec='float',missval=1.0e20,
                              units="1",
                              lname=paste('QC Mask')
    )
    #For now, patch the variables in here until se get s5 formalized in the XML
#     message("printing the qc arguments:")
#     message(paste(qc.maskopts$qc.args, sep=" "))
    WriteGlobals(qc.out.filename,k.fold,target.var,predictor.vars,label.training,ds.method,
                 configURL,label.validation,institution='NOAA/GFDL',
                 version=as.character(parse(file=paste(FUDGEROOT, "version", sep=""))),title=paste(target.var, "downscaled with", 
                                                                                                   ds.method, ds.experiment), 
                 ds.arguments=args, time.masks=tmask.list, ds.experiment=ds.experiment, 
                 grid_region=grid, mask_region=ds.region,
                 time.trim.mask=fut.time.trim.mask, 
                 tempdir=TMPDIR, include.git.branch=git.needed, FUDGEROOT=FUDGEROOT, BRANCH=BRANCH,
                 is.qcmask=TRUE,
                 qc.method=qc.maskopts$qc.method, qc.args=qc.maskopts$qc.args,
#                  is.pre.ds.adjust=(length(pre.ds)+length(pre.ds.train) > 0),
#                  pre.ds.adjustments=pre_ds, #Check on this later for an error
#                  is.post.ds.adjust=(length(post.ds)+length(post.ds.train) > 0),
#                  post.ds.adjustments=c(post.ds.train, post.ds)
                 is.pre.ds.adjust=(length(pre_ds) > 0),
                 pre.ds.adjustments=pre_ds,
                 is.post.ds.adjust=(length(post_ds_adj) > 0),
                 post.ds.adjustments=post_ds_adj)
    message(paste('QC Mask output file:',qc.out.filename,sep=''))
  }
#}
}
#Do not change formatting of this: it is used as a flag by two components of the
#regression testing scripts parsing stdout
#message(paste('Final Downscaled output file location:', sub(pattern=TMPDIR, replacement="", ds.out.filename),sep=""))
message(paste('Final Downscaled output file location:', ds.out.filename,sep=""))

# cor.vector <- c("list.fut$clim.in", "list.hist$clim.in", "list.target$clim.in")
# for (j in 1:length(cor.vector)){
#   cor.var <- cor.vector[j]
#   cor.out <- eval(parse(text=cor.var))
#   if(length(cor.out) > length(ds$esd.final)){
#     out.cor <- cor(as.vector(ds$esd.final), as.vector(cor.out)[1:length(ds$esd.final)], use='pairwise.complete.obs')
#   }else{
#   out.cor <- cor(as.vector(ds$esd.final)[1:length(cor.out)], as.vector(cor.out), use='pairwise.complete.obs')
#   }
#   print(paste("ds$esd.final", ",", cor.var, "):", out.cor, sep=""))
# }