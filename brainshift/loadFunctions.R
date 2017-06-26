

############
# function to read inputs
getLOC <- function(sub, LOCbasefolder) {
  fcoord = file.path(LOCbasefolder, paste0(sub, '_shift_coords.csv'))
  fnames = file.path(LOCbasefolder, paste0(sub, '_shift_elnames.csv'))
  ftypes = file.path(LOCbasefolder, paste0(sub, '_shift_eltypes.csv'))
  fpairs = file.path(LOCbasefolder, paste0(sub, '_shift_bpairs.csv'))
  if ( any(!file.exists(c(fcoord,fnames,ftypes,fpairs))) ) {
    stop(paste('Cannot find input files in ', LOCbasefolder))
  }
  
  coord = read.csv(fcoord, header=F, col.names=c('x','y','z'))
  names = read.csv(fnames, header=F, col.names=c('labels'))
  types = read.csv(ftypes, header=F, col.names=c('types'))[,1]
  pairs = read.csv(fpairs, header=F)
  
  
  # check rows have equal number
  if (length( unique(c(nrow(coord), nrow(names), length(types)))) != 1) {
    stop('Inconsistent dimensions of names, coordinates, or types')
  }
  
  
  xyz = cbind(names, coord, types)
  return(list(xyz=xyz,
              pairs=pairs))
  # xyz - dataframe with labels,x,y,z
  # pairs - dataframe with el1,el2
}
############


############
# function to read Freesurfer dural surface
getFreesurferVertices <- function(sub, FSbasefolder) {
  fnameL = file.path(FSbasefolder, 'surf', 'lh.pial-outer-smoothed')
  fnameR = file.path(FSbasefolder, 'surf', 'rh.pial-outer-smoothed')
  if ( any(! file.exists(c(fnameL,fnameR)) )) {
    stop(paste('Cannot find Freesurfer surfaces in:', 
               file.path(FSbasefolder, 'surf' )))
  }  
  sink("nul:")
  v_duraL = freesurfer_read_surf(fnameL)$vertices
  v_duraR = freesurfer_read_surf(fnameR)$vertices
  sink();
  
  return(rbind(v_duraL, v_duraR))
}
#############


############
# function to read Freesurfer pial surface
getFreesurferPial <- function(sub, FSbasefolder, LOCbasefolder) {
  fnameL = file.path(FSbasefolder, 'surf', 'lh.pial')
  fnameR = file.path(FSbasefolder, 'surf', 'rh.pial')
  if ( any(! file.exists(c(fnameL,fnameR)) )) {
    stop(paste('Cannot find Freesurfer pial surfaces in:', 
               file.path(FSbasefolder, 'surf' )))
  }  
  sink("nul:")
  
  v_pialL = freesurfer_read_surf(fnameL)$vertices
  v_pialR = freesurfer_read_surf(fnameR)$vertices
  sink();

  # now load list of names per vertex from python
  lnamevf = file.path(LOCbasefolder, paste0(sub, '_shift_lhvertex.csv'))
  rnamevf = file.path(LOCbasefolder, paste0(sub, '_shift_rhvertex.csv'))
  lnamenf = file.path(LOCbasefolder, paste0(sub, '_shift_lhname.csv'))
  rnamenf = file.path(LOCbasefolder, paste0(sub, '_shift_rhname.csv'))
  if ( any(! file.exists(c(lnamevf,rnamevf,lnamenf, rnamenf)) )) {
    stop(paste('Cannot find Freesurfer pial surfaces in:',
               file.path(FSbasefolder, 'surf' )))
  }
  lnamev = read.csv(lnamevf, header=F, col.names=c('labels'))
  lnamen = read.csv(lnamenf, header=F, col.names=c('names'))
  rnamev = read.csv(rnamevf, header=F, col.names=c('labels'))
  rnamen = read.csv(rnamenf, header=F, col.names=c('names'))
  if (nrow(lnamev) != nrow(v_pialL) | nrow(rnamev) != nrow(v_pialR) ) {
    stop('Mismatched number of vertices in pial surface and python derived labels')
  }
  all_lnames = rep(NA, nrow(lnamev))
  all_rnames = rep(NA, nrow(rnamev))
  all_lnames[lnamev$labels>=0] =
    paste0('L_', lnamen$names[lnamev$labels[lnamev$labels>=0]+1 ] )
  all_rnames[rnamev$labels>=0] =
    paste0('R_', rnamen$names[rnamev$labels[rnamev$labels>=0]+1 ] )

  finaldf = data.frame( rbind(v_pialL, v_pialR),
                    c(all_lnames, all_rnames))
  colnames(finaldf) = c('x','y','z','name')

  return(finaldf)
}
#############

# function to get names given a set of
# coordinates (X) and the data.frame of
# all pial vertices with names (x,y,z,names)
findPialNames = function(X, V_pial) {
  X = matrix(as.matrix(X),ncol=3)
  V = as.matrix(V_pial[,c('x','y','z')])
  D = fields::rdist(x2 = V, x1 = X)
  closestvertices = apply(D,1,which.min)
  names = V_pial$name[closestvertices]
  distances = round(apply(D,1,min),2)
  distances=paste0(distances,'mm')

  return( paste(names,distances,sep='_') )
}

#############
# find groups based on attached pairs
getGroups <- function(allpairs) {

  allpairs = apply(allpairs,2,as.character) # convert to character
  g = graph_from_edgelist(allpairs, directed=F) # make it a graph
  clust = clusters(g) # find clusters of connected electrodes
  betwn = betweenness(g) # find endpoint elextrodes (betweenness=0)
  groups = list()
  # put into groups
  for (i in 1:clust$no) {
    groups[[i]] = names(clust$membership)[clust$membership==i]
  }
  # this commented loop finds the exact order in strip electrodes
  # but might fail with grid. so we get groups simply from
  # clust$membership
  #for (i in 1:clust$no) {
  #  endpoints = V(g)$name[ clust$membership==i & betwn==0 ]
  #  groups[[i]] = get.shortest.paths(g, endpoints[1], endpoints[2])$vpath[[1]]
  #}

  adjacency=get.adjacency(g,sparse=F)
  return(list(groups=groups, adjacency=adjacency))
}
#############