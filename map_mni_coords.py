from nibabel import nifti1
import numpy as np


def map_coords(coordinates,nifti_file):
    """
    Apply the RAS+ transform in a nifti file to a set of coordinates in voxel space
    :param coordinates: Array-like with shape (3,N) or (4,N)
    :param nifti_file:
    :return:
    """
    transform = nifti1.load(nifti_file).get_affine()

    coordinates = np.matrix(coordinates)
    if coordinates.shape[0]==3:
        coordinates = np.stack([coordinates,np.ones(coordinates.shape[1])],axis=0)

    assert coordinates.shape[0] ==4

    ras_coords = coordinates * transform.astype(np.mat)
    return ras_coords[:3,:]

