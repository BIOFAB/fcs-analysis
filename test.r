
root.path = getwd()
script.path = file.path(root.path, 'r_scripts')
main.script = file.path(script.path, 'fcs3_analysis.r')
replicate.path = file.path(root.path, 'example_replicate')
out.path = file.path(root.path, 'output')
dump.file = file.path(out.path, 'out.dump')

fluo.channel = 'GRN' # or 'RED'
init.gate = 'ellipse' # or 'rectangle

setwd(script.path)
source(main.script)

fcs.file.paths = c()
files = list.files(replicate.path)

for(i in 1:length(files)) {
  if(length(grep(".+\\.fcs$", files[i], perl=TRUE)) > 0) {
    fcs.file.paths = c(fcs.file.paths, file.path(replicate.path, files[i]))
  }
}

data.set = batch(out.path, fcs.file.paths, fluo.channel=fluo.channel, init.gate=init.gate, verbose=TRUE, min.cells=100)

cat("Analysis completed.\n")
cat("Cleaned fcs files and plots in: ", out.path, "\n")
cat("Output data not dumped (not implemented).\n")

