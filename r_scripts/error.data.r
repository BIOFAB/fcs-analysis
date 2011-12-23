

error.data = function(well.name, fluo.channel, ...) {
  return(list("error"=paste(..., sep=''), "fluo_channel"=fluo.channel, "well_name"=well.name))
}