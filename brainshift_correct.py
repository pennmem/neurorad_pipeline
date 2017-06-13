from __future__ import print_function

import os
import os.path as osp
from subprocess import call

from numpy import loadtxt, savetxt
import numpy as np
import nibabel as nb


def brainshift_correct(loc, sub, outfolder, fsfolder, overwrite=False):
    """ Corrects for brain shift using sequential quadratic
    programming optimization in R (package nloptr).
    :param loc: localization structure
    :param sub: subject name
    :param outfolder: where will logs and csv file be saved
    :param fsfolder: fresurfer folder for this subject
    :param overwrite: force processing and overwrite existing files
    """
    here = osp.realpath(osp.dirname(__file__))
    Rcorrection = osp.join(here, "brainshift", "duralDykstra.R")
    # sub = 'R1238N'
    # outfolder = '/data10/RAM/subjects/R1238N/imaging/R1238N'
    # fsfolder = '/data/eeg/freesurfer/subjects/R1238N'

    corrfile = os.path.join(outfolder, sub + '_shift_corrected.csv')

    if os.path.isfile(corrfile) and not overwrite:
        print("Corrected csv file already exists for " + sub + ". Use 'overwrite=True' to overwrite results.")
        return -1

    ### get data and save them to files that R can read
    elnames = loc.get_contacts()
    coords = loc.get_contact_coordinates('fs', elnames)
    eltypes = loc.get_contact_types(elnames)
    bpairs = loc.get_pairs()
    [lhvertex, _, lhname] = nb.freesurfer.io.read_annot( os.path.join(fsfolder, 'label', 'lh.aparc.annot') )
    [rhvertex, _, rhname] = nb.freesurfer.io.read_annot( os.path.join(fsfolder, 'label', 'rh.aparc.annot') )
    savetxt(os.path.join(outfolder, sub + '_shift_coords.csv'), coords, delimiter=',')
    savetxt(os.path.join(outfolder, sub + '_shift_eltypes.csv'), eltypes, fmt='%s')
    savetxt(os.path.join(outfolder, sub + '_shift_bpairs.csv'), bpairs, fmt='%s', delimiter=',')
    savetxt(os.path.join(outfolder, sub + '_shift_elnames.csv'), elnames, fmt='%s')
    savetxt(os.path.join(outfolder, sub + '_shift_lhvertex.csv'), lhvertex, fmt='%s')
    savetxt(os.path.join(outfolder, sub + '_shift_lhname.csv'), lhname, fmt='%s')
    savetxt(os.path.join(outfolder, sub + '_shift_rhvertex.csv'), rhvertex, fmt='%s')
    savetxt(os.path.join(outfolder, sub + '_shift_rhname.csv'), rhname, fmt='%s')
    ###
    
    ### prepare R command and run
    logfile = os.path.join(outfolder, sub + '_shiftCorrection.Rlog')
    cmd = ["R", "CMD", "BATCH", "--no-save", "--no-restore", "--args",
           "sub='{:s}'".format(sub), "outfolder='{:s}'".format(outfolder),
           "fsfolder='{:s}'".format(fsfolder), Rcorrection, logfile]
    call(cmd)
    ###

    ### load the corrected output
    newcoords = loadtxt(corrfile, skiprows=1, usecols=[5,6,7], delimiter=',')
    newnames = loadtxt(corrfile, skiprows=1, usecols=[0], delimiter=',', dtype=np.str)
    newtypes = loadtxt(corrfile, skiprows=1, usecols=[4], delimiter=',', dtype=np.str)
    displaced = loadtxt(corrfile, skiprows=1, usecols=[8], delimiter=',')
    closestVrtxDist = loadtxt(corrfile, skiprows=1, usecols=[9], delimiter=',')
    linkedNames = loadtxt(corrfile, skiprows=1, usecols=[13], delimiter=',', dtype=np.str)
    linkedDisp = loadtxt(corrfile, skiprows=1, usecols=[14], delimiter=',', dtype=np.str)
    corrGroup = loadtxt(corrfile, skiprows=1, usecols=[15], delimiter=',', dtype=np.str)
    closestVrtxCoord = loadtxt(corrfile, skiprows=1, usecols=[10,11,12], delimiter=',', dtype=np.str)
    DKT = loadtxt(corrfile, skiprows=1, usecols=[16], delimiter=',', dtype=np.str)
    fsaverage = loadtxt(corrfile, skiprows=1, usecols=[17,18,19], delimiter=',')
    # put data in loc
    loc.set_contact_coordinates('fs', newnames, newcoords, coordinate_type='corrected')
    loc.set_contact_infos('displacement', newnames, displaced)
    loc.set_contact_infos('closest_vertex_distance', newnames, closestVrtxDist)
    loc.set_contact_infos('linked_electrodes', newnames, linkedNames)
    loc.set_contact_infos('link_displaced', newnames, linkedDisp)
    loc.set_contact_infos('group_corrected', newnames, corrGroup)
    loc.set_contact_infos('closest_vertex_coordinate', newnames, closestVrtxCoord.tolist())
    loc.set_contact_labels('dk', newnames, DKT)
    loc.set_contact_coordinates('fsaverage', newnames, fsaverage, coordinate_type='corrected')
    ###
    os.remove(os.path.join(outfolder, sub + '_shift_coords.csv'))
    os.remove(os.path.join(outfolder, sub + '_shift_eltypes.csv'),)
    os.remove(os.path.join(outfolder, sub + '_shift_bpairs.csv'))
    os.remove(os.path.join(outfolder, sub + '_shift_elnames.csv'))
    
    os.remove(os.path.join(outfolder, sub + '_shift_lhvertex.csv'))
    os.remove(os.path.join(outfolder, sub + '_shift_lhname.csv'))
    os.remove(os.path.join(outfolder, sub + '_shift_rhvertex.csv'))
    os.remove(os.path.join(outfolder, sub + '_shift_rhname.csv'))
    
    return loc
