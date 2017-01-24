

# run the snapping for a single set of electrodes
doSnapDykstra <- function(X, V_all, adjacent, preSnapCloser = F, preSnapPial=F,
                          stopval=-Inf, maxeval=100, xtol_rel=0.01) {
  # INPUTS: X - coordinates of electrodes (n x 3 matrix)
  #         V_all - coordinates of all good dura vertices (good.vDura in matlab)
  #         adjacent - adjacency matrix (n x n with 1 for adjacents)
  #         snapCloser - shift the entire grit closer to the surface before starting, for some reason increases optimization time instead of decreasing
  #         stopval - stop optimization at this energy value, not used, so set to -Inf
  #         maxeval - maximum number of iterations for optimizing within SQP, 100 is usually enough
  #         xtol_rel - tolerance of coordinate search, 0.01 is optimal and fast, 0.001 is longer but optimizes the positions better
  #
  # OUPUTS: newX - snapped coordinates with method similar to Dykstra 2012 (not identical)
  #         origX - original coordinates
  #         vertexDistance - distance of snapped elextrodes to closest vertex (in mm)
  #         gridDeofrmation - matrix of deformation distance (in mm) between adjacent electrodes
  #         displacement - travel distance (in mm) from original electrode positions
  #         processTime - amount of time the process took
  
  
  # save starting coordinates in new variable
  X_orig = X
  if (preSnapCloser) X = doSnapCloser(X, V_all)
  if (preSnapPial) X = doSnapPial(X, V_all)
  
  #########################################################
  # define energy and constraint functions inside the main function
  # to allow access of main variables to child functions
  # doesn't work well if we keep functions outside
  #########################################################
      # this is the energy function that should be minimized
      # however it starts from a weird value of zero
      # it's the constraint that actually moves the electrodes
      # to the dura
      getSnapEnergy <- function(X #,
                                #V_all=parent.frame()$V_all, 
                                #adjacent=parent.frame()$adjacent, 
                                #X_orig=parent.frame()$X_orig
                                ) {
        X = matrix(X,ncol=3)
        
        # penalty for being far from surface
        # Dvex = fields::rdist(x2 = V_all, x1 = X)
        # Dvex = apply(Dvex,1,min)
        
        # penalty for moving away from original position
        D = mean( ( rowSums((X-X_orig)^2) ) ) # dorian added sqrt, original had overall mean
        
        # penalty for deforming the grid
        interDistance = as.matrix( dist(X,     diag=T,upper=T) )
        origDistance  = as.matrix( dist(X_orig,diag=T,upper=T) )
        Edeformation = mean( (interDistance[adjacent==T] - origDistance[adjacent==T])^2)

        energy = D + Edeformation*10 # + mean(Dvex)*10
        return(energy)
      }
      
      
      # this is the constraint function, which the
      # optimization will minimize to 0
      # the original dykstra function gives a vector
      # with distances from dura for each electrode
      # I have inlcluded grid deformation, so electrodes
      # that do not respect the neighbors distance
      # do not go to 0 even when being close to a vertex
      # The ideal constraint will both go to 0 and retain
      # the distance between neighbors
      getSnapConstraint <- function(X #, 
                                    #V_all=parent.frame()$V_all,
                                    #adjacent=parent.frame()$adjacent,
                                    #X_orig=parent.frame()$X_orig
                                    ) {
        X = matrix(X,ncol=3)
        D = fields::rdist(x2 = V_all, x1 = X)
        D = apply(D,1,min)
        
        # added this to use deformation as part of constraint
        # it computes deformation between adjacent electrodes
        interDistance = fields::rdist(X)
        origDistance  = fields::rdist(X_orig)
        deformat = abs(interDistance-origDistance)
        deformation = rowSums(deformat*adjacent) / rowSums(adjacent)
        
        constraint = D + deformation
        # vector of length same as electrode number
        return(constraint)
      }
  ######################################################
  # end defining energy and constraint functions
  ######################################################
    
  # set parameters for sequential quadratic programming
  nlopts = list(
    stopval=stopval,
    # number of iterations
    maxeval=maxeval,
    # xtol_rel controls precision, with 000001
    # we get high precision but needs long time
    # with 0.01 we go about 0.5mm close to a vertex
    xtol_rel=xtol_rel
  )
  
  # run SQP
  tic=Sys.time()
  temp = slsqp(x0=X,
               fn=getSnapEnergy,
               heq=getSnapConstraint,
               nl.info=F,
               control=nlopts
  )
  elapsed = Sys.time()-tic
  newX = matrix(temp$par, ncol=3)
  
  # closest vertex distance
  D = fields::rdist(x2 = V_all, x1 = newX)
  vertexdistance = do.call(pmin, as.data.frame(D))
  
  # deformation grid
  griddeformation = (rdist(newX)-rdist(X_orig))*adjacent
  
  # shift from original coordinates
  displacement = diag(rdist(newX, X_orig))
  
  return(list(newX = newX,
              origX = X,
              vertexDistance = vertexdistance,
              gridDeformation = griddeformation,
              displacement = displacement,
              processTime = elapsed
    ))
  
}




# Simple function that shifts the entire electrode grid
# closer to the vertex surface.
# The shift is computed from the average displacement
# required for each electrode to go to the closest vertex
doSnapCloser = function(X, V_all) {
  X = matrix(X,ncol=3)
  D = fields::rdist(x2 = V_all, x1 = X)
  closestvertices = apply(D,1,which.min)
  allshift = X - V_all[closestvertices,]
  shift = colMeans(allshift)
  newX = t( apply(X,1,function(x) x + shift) )
  return(newX)
}

# simple function that snaps each electrode
# to the closest vertex without conserving
# the grid structure. Performed before
# the the correction itself to go faster
doSnapPial = function(X, V_all) {
  X = matrix(X,ncol=3)
  D = fields::rdist(x2 = V_all, x1 = X)
  closestvertices = apply(D,1,which.min)
  newX = V_all[closestvertices, ]
  return(newX)
}
