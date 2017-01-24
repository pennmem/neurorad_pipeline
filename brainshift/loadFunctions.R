

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
  if ( any(! file.exists(c(lnamevf,rnamevf,lna