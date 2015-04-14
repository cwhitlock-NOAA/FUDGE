#UtilityFunctions.R
#'Useful internal functions for FUDGE that do not fit within
#'a specific subfunction
#'Functions may switch out of here as the code adapts
#'Carolyn Whitlock, January 2015

# post_ds = list(mask1=list(type='PR', qc.mask='off', adjust.out='off', loc='outloop', 
#                            qc_args=list(thold='us_trace', freqadj='off')), 
#                mask2=list(type='flag.neg',adjust.out='off',qc.mask='on', loc='inloop',
#                            qc_options=list('na')))

add.over.missvals <- function(val1, val2){
  #Adds the two values.
  #If one value is a missing value, returns
  #the value of the non-missing value
  #If both are missing, returns a missval
  if(sum(is.na(val1), is.na(val2))!=1){
    return(sum(val1, val2))
  }else{
    return(ifelse(is.na(val1), val2, val1))
  }
}

index.a.list <- function(list, index, val){
  #Returns the list if the member of the 
  #list indicated by index is equal to val
  # (helper function for lapply - doesn't speed code, 
  #  but will make it more readable)
  if(list[[index]]==val){
      return(list)
  }
}

compact <- function(x){
  #Removes null values from a function;
  #Needed if your lapply function will return
  #null values a lot of the time
  #Taken from a forum post by Hadley Wickham
  #as the preferred way to deal with nulls in apply()
  Filter(Negate(is.null), x)
}
  
convert.list.to.string <- function(this.vector){
  #Converts a list into a string representation
  #Does not assume that the list is named
  #(easy to convert though; just count off of the names)
  if(length(this.vector)!=0){
    if(length(this.vector) > 1){
      out <- paste(c(this.vector[1:length(this.vector)-1], paste("and", this.vector[length(this.vector)])), collapse=",")
      return(out)
    }else{
      #no 'and' needed
      return(paste(this.vector))
    }
  }else{
    #No string to convert
    return(NA)
  }
}

adapt.pp.input <- function(mask.list=list('na'), pr_opts=list('na')){
  #' Fast and dirty modifications to make the pre- and post-processing 
  #' scheme that the XML currently supports match the R infrastucture
  #' for the more general version yet to be implemented
  pre_ds=list()
  post_ds=list()
  if(mask.list[[1]]!='na'){
    for(i in 1:length(mask.list)){
      post_ds[[i]] <- list(type=mask.list[[i]]$type,
                           adjust.out=mask.list[[i]]$adjust.out,
                           qc.mask=mask.list[[i]]$qc.mask,
                           loc='inloop',
                           qc_args=mask.list[[i]]$qc_options)
      ##DISCUSS RENAMING THESE
    }
  }
  if(pr_opts[[1]]!='na'){
    pre_ds$propts <- list(type='PR', var='pr', apply='all', loc='outloop', 
                          pp.args=list(thold=pr_opts$pr_threshold_in,
                                       freqadj=pr_opts$pr_freqadj_in,
                                       conserve=pr_opts$pr_conserve_in, 
                                       apply_0_mask=pr_opts$apply_0_mask))
    post_ds$propts <- list(type='PR', 
                           adjust.out='on', 
                           qc.mask='off', 
                           loc='outloop', 
                           qc_args=list(thold=pr_opts$pr_threshold_out,
                                           conserve=pr_opts$pr_conserve_out))
  }
  return(list('pre_ds'=pre_ds, 'post_ds'=post_ds))  
}

####This should maybe go in a function of its own?
apply.any.mask <- function(data, mask, dim.apply=NA, na.rm=FALSE, verbose=FALSE){ #switched 'mask' and 'data' in arg
  #Applies any mask to an array
  #array is assumed to be in x,y,t order, with additional dims between
  #y and t
  if(is.null(dim(mask))){
    mask.dim <- length(mask)
  }else{
    mask.dim <- dim(mask)
  }
  if(verbose){(print(paste("dimensions of mask:", paste(mask.dim, collapse=" "))))}
  
  data.dim <- dim(data) #Assume that this will be in x,y,var,t order
  if(is.null(data.dim)){
    data.dim <- length(data)
  }
  
  if(verbose){(print(paste("dimensions of data:", paste(data.dim, collapse=" "))))}
  if(verbose){print('summary of data'); print(summary(as.vector(data)))}
  
  if(!is.na(dim.apply)){
    if(dim.apply=='time' || dim.apply=='temporal'){
      length.time <- data.dim[length(data.dim)]
      if(length.time!=mask.dim){
        stop(paste("Error in apply.any.mask over temporal points: mask had dimensions of",paste(mask.dim, collapse=" "), 
                   "and data had dimensions of", paste(data.dim, collapse=" ")))
      }else{
        if(length(data.dim) > 1){
          #There is more than one dimension present
          #         print( c(length(data.dim), 1:(length(data.dim)-1)))
          data.perm <- aperm(data, c(length(data.dim), 1:(length(data.dim)-1)))#t,x,y order
          result <- rep(mask, length.out=length(data.perm))*data.perm #t,x,y order(yay vector recycling)
          result <- aperm(result, c(2:(length(data.dim)), 1))
          ##Let's see...removing missing values might get complicated
          if(na.rm){
            mask.time <- sum[!is.na(mask)]
            result <- results[!is.na(result)]
            #This bit isn't done, don't use it yet
            ###Assume that if you are removing the NAs from time, all NAs will wind up being taken from that dim - 
            ###you want to remove them from everything else, as much as possible
            dim(result) <- c(data.dim[1:(length(data.dim)-1)], mask.time) #orig x,y,var, new time
          }
        }else{
          #Assume that the only dimension is time
          result <- data*mask
        }
        if(verbose){print('summary of data'); print(summary(as.vector(result)))}
        
      }
    }else if(dim.apply=='spatial'){
      dim.spatial <- mask.dim
      if(sum(dim.spatial==data.dim[1:2])!=2){
        stop(paste("Error in apply.any.mask over spatial points: mask had dimensions of",paste(mask.dim, collapse=" "), 
                   "and data had dimensions of", paste(data.dim, collapse=" ")))
      }else{
        result <- as.vector(data) * as.vector(mask) #x,y,ens/var,t order (if ens exists)
        dim(result) <- data.dim
      }
      #Not implementing a na.rm option for this; too prone to abuse in current version of code
    }
  }else{
    #If no application dim is returned, assume that the dims of the mask and the 
    #data are supposed to be identical, and act accordingly
    if(sum(mask.dim!=data.dim)==0){
      #If they are not non-identical anywhere
      result <- as.vector(mask)*as.vector(data)
      dim(result) <- data.dim
    }else{
      stop(paste("Error in apply.any.mask over all points: mask had dimensions of",paste(mask.dim, collapse=" "), 
                 "and data had dimensions of", paste(data.dim, collapse=" ")))
    }
  }
  return(result)
}

remove.missvals <- function(data){
  #Removes missing values from an array (presumed 1-d)
  return(data[!is.na(data)])
}

