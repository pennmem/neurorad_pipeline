
# load arguments
args=commandArgs(TRUE)
for(i in 1:length(args)){
  eval(parse(text=args[i]))
}


source('/home1/dorian.pustina/dykstra/loadFunctions.R')
source('/home1/dorian.pustina/dykstra/doSnapDykstra_experimental.R')


# sub = 'R1238N'
# outfolder = '/data10/RAM/subjects/R1238N/imaging/R1238N'
# fsfolder = '/data/eeg/freesurfer/subjects/R1238N'


radius = 40 # radius around electrodes to keep vertices
xtol_rel=0.001 # tolerance for optimization 0.01 - 0.000001
preSnapCloser = F # whether to move entire lead closer to surface before optimization, no deformation produced
preSnapPial = F # whether to snap each electrode to closest vertex

############
# load necessary libraries
libraries = c('nloptr', 'fields',
              'freesurfer', 'igraph')
installed = rownames(installed.packages())
present = libraries %in% installed
if (all(present)) {
  invisible(lapply(libraries, require, character.only=T))
} else {
  stop(paste('Missing libraries. Please install:', paste(libraries[!present], collapse=' ') ))
}
############


############
# load LOC coordinates
loc = getLOC(sub, outfolder)
xyz_orig = loc$xyz
pairs = loc$pairs

groups = getGroups(pairs)$groups
adjacency = getGroups(pairs)$adjacency
############

############
# load vertices
v_duraAll = getFreesurferVertices(sub, fsfolder)
# remove vertices too far
tempsurf = xyz_orig[ xyz_orig$types=='S', c('x','y','z')]
D = fields::rdist(x1 = tempsurf, x2 = v_duraAll)
goodvert = apply(D, 2, function(x) any(x<radius))
v_duraAll = v_duraAll[goodvert,]
rm(D,tempsurf,goodvert)

# load pial vertices
v_pialAll = getFreesurferPial(sub, fsfolder, outfolder)
############


###########
# run dykstra
# first loop to check pairs match with xyz electrodes
for (g in 1:length(groups)) {
  theseel = groups[[g]]
  xyzlines = match(theseel, xyz_orig$labels)
  if (any(is.na(xyzlines))) {
    stop(paste(
      'No coordinates for some electrodes in lead:', paste(theseel, collapse='-')
    ))
  }
  # check no depth/surface mixtures
  thisxyz = xyz_orig[xyzlines,]
  if (all(thisxyz$types == 'D') | all(thisxyz$types == 'S')) {
    next
  } else {
    stop(paste(
      'Mixed surface/depth electrodes in same lead:', paste(theseel, collapse='-')
    ))
  }
}
# second loop to run dykstra
# add more columns to table
dummy = rep(NA,nrow(xyz_orig))
xyz_orig = data.frame(xyz_orig,
                      corrx=dummy,
                      corry=dummy,
                      corrz=dummy,
                      displaced=dummy,
                      closestvertexdist=dummy,
                      closestvertexx=dummy,
                      closestvertexy=dummy,
                      closestvertexz=dummy,
                      linkedto=dummy,
                      linkdisplaced=dummy,
                      group=dummy)
# run correction loop

print(paste('Starting', Sys.time()))
for (g in 1:length(groups)) {
  theseel = groups[[g]]
  xyzlines = match(theseel, xyz_orig$labels)
  thisxyz = xyz_orig[xyzlines,]
  rowadj = match(theseel, rownames(adjacency))
  coladj = match(theseel, colnames(adjacency))
  thisadjacency = adjacency[rowadj,coladj]
  
  # print info
  cat(paste('Working on group', g, paste0('(',length(theseel),')') ,'...'))
  
  # if depth continue
  if (all(thisxyz$types == 'D')) {
    cat('skipping depth\n')
    next
  }
  
  
  # run dykstra on this lead
  correct = doSnapDykstra(X=as.matrix(thisxyz[ , c('x','y','z')]),
                          V_all=v_duraAll,
                          adjacent=thisadjacency,
                          xtol_rel=xtol_rel,
                          preSnapCloser = preSnapCloser,
                          preSnapPial = preSnapPial)
  
  # put results in table
  xyz_orig[xyzlines, 
           c('corrx','corry','corrz')] = correct$newX
  #
  xyz_orig[xyzlines, 
             c('displaced')] = correct$displacement
  #
  xyz_orig[xyzlines, 
           c('group')] = g
  #
  linkedto = apply(thisadjacency, 1, function(x) colnames(thisadjacency)[x==1])
  linkedto = sapply(linkedto, paste0, collapse='-')
  xyz_orig[xyzlines, 
           c('linkedto')] = linkedto
  #
  linkeddisp=rep(NA,nrow(thisadjacency))
  for (li in 1:length(linkeddisp))
    linkeddisp[li] = paste0(round(correct$gridDeformation[li,][thisadjacency[li,]==1],3), collapse='-')
  xyz_orig[xyzlines, 
           c('linkdisplaced')] = linkeddisp
  #
  xyz_orig[xyzlines, 
           c('closestvertexdist')] = correct$vertexDistance
  #
  closestvertex = doSnapPial(correct$newX, v_duraAll)
  xyz_orig[xyzlines, 
           c('closestvertexx','closestvertexy','closestvertexz')] = closestvertex
  
  cat(paste(format(correct$processTime),'\n'))
}
print(paste('ENDING', Sys.time()))


# copy depth info from original
xyz_orig[ xyz_orig$types=='D' , c('closestvertexx','closestvertexy','closestvertexz',
                                  'closestvertexdist','group','displaced')] = c(0,0,0,0,0,0)
xyz_orig[ xyz_orig$types=='D' , c('corrx','corry','corrz')] = 
  xyz_orig[ xyz_orig$types=='D' , c('x','y','z')]
xyz_orig[ xyz_orig$types=='D' , c('linkedto','linkdisplaced')] = c('N/A','N/A')

write.csv(xyz_orig, 
          file = file.path(outfol