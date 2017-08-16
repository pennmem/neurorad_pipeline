import subprocess
from config import paths
import logging
import os.path as osp
import os

log = logging.getLogger('submission')


def mri_fill(pial_file,filled_file):
    subprocess.call([osp.join(paths.freesurfer_bin,'mris_fill'),'-c','-r','1',pial_file,filled_file])


def make_outer_surface_matlab(filled_file,output_surface_file):
    assert osp.isfile(filled_file)
    freesurfer_matlab = osp.join(osp.dirname(paths.freesurfer_bin),'matlab')
    curr_dir = os.getcwd()
    print('matlab directory: %s'%freesurfer_matlab)
    os.chdir(freesurfer_matlab)
    matlab_call = 'try make_outer_surface(\'{0}\',15,\'{1}\');catch; end; quit;'.format(filled_file,output_surface_file)
    bash_call = ['matlab', '-nodisplay', '-nojvm', '-nodesktop', '-r', "{}".format(matlab_call)]
    print('system call: \n %s'%bash_call)
    subprocess.call(bash_call)
    os.chdir(curr_dir)


def extract_main_component(outer_surface_file,main_component_file):
    subprocess.call([osp.join(paths.freesurfer_bin,'mris_extract_main_component'), outer_surface_file,main_component_file])


def smooth_surface(main_component_file,smoothed_file):
    subprocess.call([osp.join(paths.freesurfer_bin,'mris_smooth'),'-nw','-n','30', main_component_file,smoothed_file])


def make_smoothed_surface(pial_surface_file):
    filled_file = pial_surface_file+'.filled.mgz'
    outer_surface_file  = pial_surface_file+'-outer'
    main_component_file = outer_surface_file+'-main'
    smoothed_file = outer_surface_file+'-smoothed'
    mri_fill(pial_surface_file,filled_file)
    make_outer_surface_matlab(filled_file,outer_surface_file)
    extract_main_component(outer_surface_file,main_component_file)
    smooth_surface(main_component_file,smoothed_file)

    return smoothed_file


