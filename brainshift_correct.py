from __future__ import print_function

import os
import os.path as osp
from subprocess import call
from submission.log import logger
from numpy import savetxt
import pandas as pd
import nibabel as nb
import numpy as np

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
    og_dir = os.getcwd()
    corrfile = os.path.join(outfolder, sub + '_shift_corrected.csv')
    [lhvertex, _, lhname] = nb.freesurfer.io.read_annot(os.path.join(fsfolder, 'label', 'lh.aparc.annot'))
    [rhvertex, _, rhname] = nb.freesurfer.io.read_annot(os.path.join(fsfolder, 'label', 'rh.aparc.annot'))

    if os.path.isfile(corrfile) and not overwrite:
        print("Corrected csv file already exists for " + sub + ". Use 'overwrite=True' to overwrite results.")
    else:
        ### get data and save them to files that R can read
        elnames = loc.get_contacts()
        coords = loc.get_contact_coordinates('fs', elnames)
        eltypes = loc.get_contact_types(elnames)
        bpairs = loc.get_pairs()
        savetxt(os.path.join(outfolder, sub + '_shift_coords.csv'), coords, delimiter=',')
        savetxt(os.path.join(outfolder, sub + '_shift_eltypes.csv'), eltypes, fmt='%s')
        savetxt(os.path.join(outfolder, sub + '_shift_bpairs.csv'), bpairs, fmt='%s', delimiter=',')
        savetxt(os.path.join(outfolder, sub + '_shift_elnames.csv'), elnames, fmt='%s')
        savetxt(os.path.join(outfolder, sub + '_shift_lhvertex.csv'), lhvertex, fmt='%s')
        savetxt(os.path.join(outfolder, sub + '_shift_lhname.csv'), lhname, fmt='%s')
        savetxt(os.path.join(outfolder, sub + '_shift_rhvertex.csv'), rhvertex, fmt='%s')
        savetxt(os.path.join(outfolder, sub + '_shift_rhname.csv'), rhname, fmt='%s')
        ###

        os.chdir(osp.join(here,'brainshift'))

        ### prepare R command and run

        cmd_args = "'--args sub=\"{sub}\" outfolder=\"{outfolder}\" fsfolder=\"{fsfolder}\"'".format(
            sub=sub,outfolder=outfolder,fsfolder=fsfolder
        )
        logfile = os.path.join(outfolder, sub + '_shiftCorrection.Rlog')
        cmd = ["R", "CMD", "BATCH", "--no-save", "--no-restore", cmd_args,Rcorrection, logfile]
        logger.debug('Executing shell command %s'%str(cmd))
        call(' '.join(cmd),shell=True)
        ###

        os.chdir(og_dir)
    ### load the corrected output
    corrected_data = pd.DataFrame.from_csv(corrfile)
    newnames=corrected_data.index.values


    # put data in loc
    loc.set_contact_coordinates('fs', newnames, corrected_data[['corrx','corry','corrz']].values, coordinate_type='corrected')
    loc.set_contact_infos('displacement', newnames, corrected_data.displaced.values)
    loc.set_contact_infos('closest_vertex_distance', newnames,corrected_data.closestvertexdist.values)
    loc.set_contact_infos('linked_electrodes', newnames, corrected_data.linkedto.values)
    loc.set_contact_infos('link_displaced', newnames, corrected_data.linkdisplaced.values)
    loc.set_contact_infos('group_corrected', newnames, corrected_data['group'].values)
    loc.set_contact_infos('closest_vertex_coordinate', newnames,
                          corrected_data[['closestvertexx','closestvertexy','closestvertexz']].values.tolist())
    # loc.set_contact_labels('dk', newnames, corrected_data.DKT.values)
    # loc.set_contact_coordinates('tal', newnames, corrected_data[['fsavg_x','fsavg_y','fsavg_z']].values.tolist(), coordinate_type='corrected')

    lhcoords = nb.freesurfer.read_geometry(osp.join(fsfolder,'surf','lh.pial'))[0]
    rhcoords = nb.freesurfer.read_geometry(osp.join(fsfolder,'surf','rh.pial'))[0]
    lhname = ['L_'+x for x in lhname]
    rhname = ['R_'+x for x in rhname]
    rhvertex[0] = 0
    lhvertex[0] = 0
    rhvertex+= len(lhname)
    fs_vertices = np.concatenate([lhvertex,rhvertex])
    fs_names = np.concatenate([lhname,rhname])

    coords = np.concatenate([lhcoords,rhcoords])

    loc.set_contact_labels('dk',newnames,get_dk_labels(
        loc.get_contact_coordinates('fs',newnames,coordinate_type='corrected'),coords,
        fs_vertices,fs_names))

    loc.set_pair_labels('dk', loc.get_pairs(), get_dk_labels(
        loc.get_pair_coordinates('fs',coordinate_type='corrected'), coords, fs_vertices,
        fs_names))

    return loc


def get_dk_labels(electrode_coords,vertex_coords,vertex_inds,labels):
    electrode_labels = []
    for coord in electrode_coords:
        closest_vertex_index = np.argmin(np.linalg.norm(vertex_coords-np.squeeze(coord),axis=1))
        label = labels[vertex_inds[closest_vertex_index]]
        electrode_labels.append(label)
    return electrode_labels
