

error.data = function(fluo.channel, ...) {
  return(list("error"=paste(..., sep=''), "fluo.channel"=fluo.channel))
}