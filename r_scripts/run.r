
# well.channels is a list where the keys are well names and the value fluorescence channel names
# well.channels is ignored if fluo.channel is set to a valid fluorescence channel
# if well.channels does not contain a key for the well name, fluo.channel is used instead

run = function(out.path.fcs,
               out.path.plot,
               fcs.path, # path of single fcs file
               fluo.channel=NULL, # RED, GRN or ? (TODO)
               well.channels=list(), # list mapping well names to fluo channels
               clean=TRUE, 
               cluster=TRUE,
               init.gate="ellipse",
               output.filename="out.fcs",
               output.filename.cluster2="out.cluster2.fcs",
               clust.levels=c(0.95,0.95), 
               scale.gating="Lin", 
               scale.analysis="Log",
               verbose=FALSE) {

  if(verbose) {
    cat("----------------------------------------------------------\n")
    cat("Now analyzing FCS file: ", fcs.path, "\n")
    cat("----------------------------------------------------------\n")
  }

  # === Initialization ===

  data = vector("list")
  mixed = vector("list")
  flowframe2 = NULL

  # === Read fcs file ===

  flowset = read.flowSet(path=dirname(fcs.path), pattern=basename(fcs.path))

  if(length(flowset) != 1) {
    return(error.data("Failed to read FCS file"))
  }

  # minimum number of events
  if(nrow(flowset[[1]]@exprs) < 50) {
    return(error.data("Too few events"))
  }

  well.name = flowset[[1]]@description$`$WELLID`

  if(verbose) {
    cat("  Events: ", nrow(flowset[[1]]@exprs), "\n")
    cat("  Well name: ", well.name, "\n")
  }
  
  # check if a valid fluorescence exiss
  if(length(well.channels) > 0)  {
    if(well.name %in% names(well.channels)) {
      fluo.channel = well.channels[well.name]
      if(verbose) {
        cat("Fluorescence channel found for well.\n")
      }
    }
  } 


  if(class(get.fluo(fluo.channel, scale.gating)) == 'NULL') {
    return(error.data("Invalid fluorescence channel"))
  }

  if(clean == FALSE) {

    if(verbose) {
      cat("No cleaning...\n")
    }

  } else {

    # === Clean ===

    if(verbose) {
      cat("Cleaning... \n")
    }

    flowset = clean.flowSet(flowset, fluo.channel=fluo.channel, scale=scale.gating)

    # === Select filter ===

    filter = NULL
    if(init.gate == "ellipse") {
      if(verbose) {
        cat("Recapitulate ellipsoidal gating... \n")
      }
      filter = ellipseGateFilter(flowset)

    } else if(init.gate == "rectangle") {

      if(verbose) {
        cat("Recapitulate rectangular gating... \n")
      }
      filter = rectangularGateFilter(flowset)
    }

    # === Filter the data ===

    flowset = Subset(flowset, filter)

  }

  # === Clustering ===

  flowframe = flowset[[1]]

  fluo_name = get.fluo(fluo.channel, scale.gating)

  if(cluster) {
    if(verbose) {
      cat("Clustered Gating... \n")
    }

    restrict = FALSE

    clusters = clustGating(flowframe, fluo.channel=fluo.channel, scale.gating=scale.gating, scale.analysis=scale.analysis, out.path.plot=out.path.plot, levels=clust.levels)

    if(class(clusters) == 'NULL') {
      return(error.data("Cluster-gating failed"))
    }    

    # propagate error
    if(class(clusters) == 'list') {
      if(!is.null(clusters[['error']])) {
        return(clusters)
      }
    }

    flowframe = clusters[[1]]
    flowframe2 = clusters[[2]]
  }

  data = extractData(flowframe, flowframe2, fluo.channel, scale.gating)
  data['infile_fcs'] = fcs.path
  data['outfile_plot'] = out.path.plot
  data['well_id'] = flowset[[1]]@description$`$WELLID`

  if(clean | cluster) {

    # === Save FCS files ===

    write.FCS(flowframe, file.path(out.path.fcs, output.filename))
    data['outfile_fcs'] = file.path(out.path.fcs, output.filename)
    data['well_name'] = flowset[[1]]@description$`$WELLID`

    if(class(flowframe2) == "flowFrame") {
      write.FCS(flowframe2, file.path(out.path.fcs, output.filename.cluster2))
      data['outfile_fcs_c2'] = file.path(out.path.fcs, output.filename.cluster2)
    }

  }

  # === Create summary ===


  if(length(mixed) == 0) {
    mixed = NULL
  }

  # TODO return mixed as well

  return(data)
}