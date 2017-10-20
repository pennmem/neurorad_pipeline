# Release Notes -- Neurorad Pipeline v2.0

Neurorad Pipeline v2.0 replaces Neurorad Pipeline v1.x,
which was written in MATLAB and Freesurfer scripts. V2.0 is written in
Python and R using exclusively open-source resources, and integrates with
the CML submission tool (www.github.com/pennmem/event_creation)

## Installation

#### If the submission tool has not yet been installed:

1. Install the submission tool

   ```
   git clone http://github.com/pennmem/event_creation.git
   cd event_creation
   ```

2. Set up the neurorad submodule:
   ```
   git submodule init
   git submodule update
   ```

3. Install the appropriate conda environment:
   ```
   conda env create -f conda_environment.yml
   ```

#### If the submission tool has already been installed:
1. Go to the directory where the submission tool is installed:

   ```
   cd ~/event_creation
   ```
   or whatever the root directory of the submission tool is.

2. Update the submission tool:
    ```
    git pull origin master
    ```
3. Update the neurorad submodule:
    ```
    git submodule update
    ```
4. Update the conda environment:
    ```
    conda env update -f conda_environment.yml
    ```


## Avaliable Files

* V2.0 replaces the various tal structs (`talLoc_database_*.mat`) with a
single file, `localization.json`

* `VOX_coords_mother`, the output of voxTool, may be replaced by `voxel_coordinates.json`

* The remainder of the contents of `/data/eeg/SUBJECT/tal/` will likely vanish

* The files `contacts.json` and `pairs.json` will persist in the new pipeline,
  with the following fields:

#### Electrode Coordinates:

|    Name       | Description |
|   :-----:     | ----------- |
| ind           | Uncorrected coordinates in individual Freesurfer space |
| ind.corrected | Brainshift-corrected coordinates in individual Freesurfer space|
| avg           | Uncorrected coordinates in average Freesurfer space |
| avg.corrected | Brainshift-corrected coordinates in average Freesurfer space|
| vox           | CT voxels |
| mni           | Uncorrected coordinates in MNI space |

#### Atlas labels:
| Name | Description |
| :---:| -------------|
| mni  | Whole-brain atlas based on MNI parcellation|
| hcp  | surface atlas labels based on HCP template; <br>labels derived from corrected individual freesurfer coordinates|
| ind  | Desian-Kilney atlas labels; <br> labels derived from raw individual freesurfer coordinates|

### Features:

* Dijkstra brain-shift correction for surface electrodes ported
  from MATLAB to Python via R
* Computation of dural surface mesh ported from MATLAB to Python;
  introduces dependency on scikit-image
* Localization information (electrode coordinates and atlas labels)
  stored in JSON format
* Labels from the HCP atlas
* Coordinates on average brain computed using Freesurfer registrations

### Known Issues:

* Certain coordinates and labels are missing:
    * Brain-shift corrected MNI coordinates for surface electrodes
    * DK atlas locations based on fsaverage coordinates

* "Stim-only" bipolar pairs are not supported
