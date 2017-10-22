# Release Notes -- Neurorad Pipeline v2.0

Neurorad Pipeline v2.0 replaces Neurorad Pipeline v1.x,
which was written in MATLAB and Freesurfer scripts. V2.0 is written in
Python and R using exclusively open-source resources, and integrates with
the CML event creationtool (www.github.com/pennmem/event_creation)

## Installation

#### If the event creation tool has not yet been installed:

1. Install the event creation tool

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

#### If the event creation tool has already been installed:
1. Go to the directory where the event creation tool is installed:

   ```
   cd ~/event_creation
   ```
   or whatever the root directory of the event creationtool is.

2. Update the event creationtool:
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

## Output Format

The output of the new neurorad pipeline is a JSON file, `localization.json`,
with the following structure:
```json
{'leads':
        LEAD1:{
            'contacts':[
                {'name':CONTACT_NAME,
                 'info': {
                    'closest_vertex_coordinate':[...],
                    'closest_vertex_distance':[...]
                    'displacement': disp,
                    'group_corrected':group_corrected,
                    'link-displaced':"...",
                    'linked_electrodes':"CONTACT1-CONTACT2(...)"
                    },
                 'coordinate_spaces':{
                    COORDINATE_SPACE_1:[x,y,z],
                    ...,}
                 'atlases':{
                    ATLAS_1:atlas_1_loc_tag,
                    ...}
                 }
                 ...
             ],
            'pairs':[
                {'names':[ANODE_NAME,CATHODE_NAME],
                 'info': {
                    'closest_ortho_vertex_coordinate':[...]
                    },
                 'coordinate_spaces':{
                    COORDINATE_SPACE_1:{
                        'raw':[x,y,z],
                        ('corrected':[x,y,z]),
                    ...,}
                 'atlases':{
                    ATLAS_1:atlas_1_loc_tag,
                    ...}
                 }
                 ...
             ],
             'n_groups':N_GROUPS,
             'type':LEAD_TYPE
             }
        ...
        }
 }
 ```
The coordinate spaces included in `localization.json` are:

- ct_voxel
- t1_mri
- fs
- fsaverage
- mni
- tal

The atlases included in `localization.json` are
- dk
- hcp
- whole_brain
- mtl
- manual

Note that not every contact has a location from every atlas.

## Avaliable Files

* V2.0 replaces the various tal structs (`talLoc_database_*.mat`) with a
single file, `localization.json`

* The various `RAW_coords*` and `VOX_coords*` files will no longer be produced.

* `VOX_coords_mother`, the output of voxTool, may be replaced by `voxel_coordinates.json`

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
| ind  | Desikan-Killaney atlas labels; <br> labels derived from raw individual freesurfer coordinates|

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
