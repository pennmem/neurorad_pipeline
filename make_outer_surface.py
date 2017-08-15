import subprocess
from config import paths
import logging
import os.path as osp
import os

log = logging.getLogger('submission')


def mri_fill(pial_file,filled_file):
    subprocess.call([osp.join(paths.freesurfer_bin,'mris_fill'),'-c','-r','1',pial_file,filled_file])


def make_outer_surface_matlab(filled_file,output_surface_file):
    freesurfer_matlab = osp.join(osp.dirname(paths.freesurfer_bin),'matlab')
    curr_dir = os.getcwd()
    os.chdir(freesurfer_matlab)
    matlab_call = 'try make_outer_surface({0},10,{1});catch; end; quit;'.format(filled_file,output_surface_file)
    bash_call = 'matlab -nodisplay -nojvm -nodesktop -r "{0}"'.format(matlab_call)
    subprocess.call(bash_call)
    os.chdir(curr_dir)


def extract_main_component(outer_surface_file,main_component_file):
    subprocess.call()