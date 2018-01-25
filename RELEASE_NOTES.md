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

## Output Formats

The output of the new neurorad pipeline is a JSON file, `localization.json`.
with the following structure:
```
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
- dkavg
- hcp
- whole_brain
- mtl
- manual

Note that not every contact has a location from every atlas.

With the release of the new pipeline, the montage-specific files
`contacts.json` and `pairs.json` will be built using the information
in `localization.json`. `contacts.json` has the following format:

```
{SUBJECT:
    {"contacts":{
        NAME1:{
            "atlases":{
                ATLAS_1:{
                    "region": REGION,
                    "x": XCOORD,
                    "y": YCOORD,
                    "z": ZCOORD,
                    }
                ...
                }
            "channel":CHANNEL_NUMBER,
            "code": NAME1,
            "type": LEAD_TYPE
            }
         ...
         }
     },
"version": VERSION_NUMBER
 }
 ```

and `pairs.json` has the following format:
```
{SUBJECT:
    {"pairs":{
        NAME1:{
            "atlases":{
                ATLAS_1:{
                    "region": REGION,
                    "x": XCOORD,
                    "y": YCOORD,
                    "z": ZCOORD,
                    }
                ...
                }
            "channel_1":CHANNEL_NUMBER_1,
            "channel_2":CHANNEL_NUMBER_2,
            "code": NAME1,
            "type": LEAD_TYPE
            }
         ...
         }
     },
 "version": VERSION_NUMBER
 }
 ```

In these two files, the atlas names are as follows:

|    Name       | Description | Coordinates | Region label|
|   :-----:     | :---------- | :---------: | :--------:  |
| ind           | Uncorrected coordinates in individual Freesurfer space | Yes | Yes |
| ind.corrected | Brainshift-corrected coordinates in individual Freesurfer space| Yes | No|
| avg           | Uncorrected coordinates in average Freesurfer space | Yes | No|
| avg.corrected | Brainshift-corrected coordinates in average Freesurfer space| Yes | No
| vox           | CT voxels | Yes | No
| mni           | Uncorrected coordinates in MNI space | Yes | Yes |
| hcp  | surface atlas labels based on HCP template; <br>labels derived from corrected individual freesurfer coordinates| No | Yes|

Atlases without a region have "null" as the value of "region"; atlases without
coordinates have NaN as the values of "x", "y", and "z".

## Comparing Atlas/Coordinate Information between v1.x and v2.0
Over the years a number of things have changed intermittantly in the neurorad pipeline including:

    1. File formats (.mat versus .json)
    2. The coordinates and atlas locations that are generated and stored
    3. The algorithm used for brainshift correction
    
In v1.x, the MATLAB talstructures existed alongside the pairs/contacts.json files. The json files were generated using a now-deprecated system whose source code is hosted on [Gitlab](https://rhinogit.sas.upenn.edu/jlubken/stim). You will need to contact Hippomanager in order to gain access to this repository. Although these files contained similar information, there is not a direct 1:1 correspondence between them. In v2.0, the pairs/contacts.json files continue to exist, although they are now derived from the localization.json file. The new pairs/contacts.json files are a subset of the information contained in localization.json but modified to miror their v1.x equivalent. The intention was to make the transion to v2.0 as seemless as possible for users relying on these files. The tables below outline the mapping between the matlab talstructures, v1.x pairs/contacts.json, v2.0 pairs/contacts.json, and the v2.0 localization.json file.

### Coordinates
|   localization.json   | pairs/contacts.json (v2) | pairs/contacts.json (v1) |    MATLAB (v1)   | Description                                                                                                 |
|:---------------------:|:------------------------:|:------------------------:|:----------------:|-------------------------------------------------------------------------------------------------------------|
|     ct_voxel (raw)    |            vox           |            vox           |                  | Uncorrected CT voxel coordinates                                                                            |
|     fs (corrected)    |       ind.corrected      |                          | indvSurf_Dykstra | Brainshift-corrected coordinates in individual Freesurfer space using Dijkstra energy-minimization method    |
|                       |                          |                          | indvSurf_dural   | Brainshift-corrected coordinates in individual Freesurfer space using dural snapping method                 |
|                       |                          |         ind.dural        | indvSurf_snap    | Brainshift-corrected coordinates in individual Freesurfer space using snapping method                       |
|                       |                          |                          | indvSurf_esnap   | Brainshift-corrected coordinates in individual Freesurfer space using deprecated energy-minimization method |
|        fs (raw)       |            ind           |            ind           | indvSurf         | Uncorrected coordinates in individual Freesurfer space                                                      |
| fsaverage (corrected) |       avg.corrected      |                          | avgSurf_Dykstra  | Brainshift-corrected coordinates in average Freesurfer space using Dijkstra energy-minimization method       |
|                       |                          |         avg.snap         | avgSurf_dural    | Brainshift-corrected coordinates in average Freesurfer space                                                |
|                       |                          |         avg.dural        | avgSurf_snap     | Brainshift-corrected coordinates in average Freesurfer space                                                |
|                       |                          |                          | avgSurf_esnap    | Brainshift-corrected coordinates in average Freesurfer space using deprecated enery-minimization method     |
|    fsaverage (raw)    |            avg           |            avg           | avgSurf          | Uncorrected coordinates in average Freesurfer space                                                         |
|   t1_mri (corrected)  |                          |                          |                  | Brainshift-corrected T1-weighted MRI coordinates                                                            |
|      t1_mri (raw)     |                          |                          |                  | Uncorrected T1-weighted MRI coordinates                                                                     |
|    tal (corrected)    |                          |                          |                  | Brainshift-corrected coordinates in talairach space                                                         |
|       tal (raw)       |                          |            tal           | tal              | Uncorrected coordinates in talairach space                                                                  |
| mni (corrected)       |                          |                          |                  | Brainshift-corrected coordinates in MNI space                                                               |
| mni (raw)             |                          |                          |                  | Uncorrected coordinates in MNI space                                                                        |
### Atlases
| localization.json | pairs/contacts.json (v2) | pairs/contacts.json (v1) | MATLAB (v1) |                                                       Description                                                       |
|:-----------------:|:------------------------:|:------------------------:|:-----------:|:-----------------------------------------------------------------------------------------------------------------------:|
|                   |            ind           |            ind           |             | Surface labels using the Desikan-Killilany atlas dervied from uncorrected individual Freesurfer coordinates             |
|         dk        |            dk            |            dk            |             | Surface labels using the Desikan-Killiany atlas derived from the corrected individual freesurfer coordinates            |
|       dkavg       |                          |                          |             | Surface labels using the Desikan-Killiany atlas derived from the corrected average  Freesurfer coordinates              |
|                   |            mni           |            mni           |             |                                                                                                                         |
|        hcp        |                          |                          |             | Surface labels based on the Human Connectome Project atlas derived from the corrected individual Freesurfer coordinates |
|    whole_brain    |            wb            |            wb            |             |                                                                                                                         |
|        mtl        |                          |                          |             |                                                                                                                         |
|       manual      |                          |                          |             | Manually assigned labels                                                                                                |
|                   |           stein          |                          |             | Labels assigned during localization by neuroradiologist Joel Stein                                                      |
|                   |            das           |                          |             | Labels assigned during localization by neuroradiologist Sandy Das                                                       |
|                   |                          |                          |  Loc1-Loc6  | Labels based on the talairach hierarchy (hemisphere, lobe, gyrus, tissue-type, cell type)                               |
|                   |                          |                          |    LocTag   | Labels assigned during localization by a neuroradiologist                                                               |
## Avaliable Files

* V2.0 replaces the various tal structs (`talLoc_database_*.mat`) with a
single file, `localization.json`

* The various `RAW_coords*` and `VOX_coords*` files will no longer be produced.

* `VOX_coords_mother`, the output of voxTool, may be replaced by `voxel_coordinates.json`

* The files `contacts.json` and `pairs.json` will persist in the new pipeline

## 1-16-2018 (v2.0.2):

### Features:
- Updates to VoxTool; see https://github.com/pennmem/voxTool/blob/master/CHANGELOG.txt
- Added function to map T1 MRI coordinates to MNI coordinates;
  function is used to derive brainshift-corrected MNI coordinates
- Brainshift correction now prints log file to screen
- Incorporated bipolar reference scheme into pairs.json



## 11-22-2017 (v2.0.1)
### Features:
- Updates to VoxTool; see https://github.com/pennmem/voxTool/blob/master/CHANGELOG.txt
### Bug fixes:
- Removed assumptions about upper/lower case in contact names
- jacksheet can now be read even if it uses \r\n line endings
- version numbers in contacts/pairs.json now read from neurorad.version
- jacksheet names now have to agree in case with names in localization file

- Fields in pairs.json now agree with previous fields
- Localization pipeline no longer indexes output, to avoid breaking the
  index file
- Version numbers to start from 2.0


## 10-30-2017 (v2.0)

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


* Brain-shift corrected MNI coordinates for surface electrodes are missing
* "Stim-only" bipolar pairs and non-adjacent bipolar pairs are not supported
* Adding manual corrections from a spreadsheet requires re-running the entire pipeline
