# neruorad_pipeline

To install dependencies:

Install miniconda for python2.7 (https://www.continuum.io/downloads)

    conda install scipy
    conda install mayavi
    pip install nibabel
    
## Localization object
   
This pipeline depends on the Localization class (`localization.Localization`). This object holds all of the 
localization information, and can be queried or added to at each stage in the pipeline:
 * Bottom of the file contains examples for usage
 * Run example code with `python localization.py`.
 * Use in your own file with:
    ```python
    from localization import Localization
    loc = Localization('/path/to/voxel_coordinates.json')
    loc.get_contacts()
    ```

## Integration into submission utility

The submission utility is currently located in the [event_creation](https://github.com/pennmem/event_creation) repo.

There are four hooks into the neuroradiology pipeline from the submission utility:

##### Transfer config:
Each pipeline in the submission utility has its own list of input files/links/directories. The file 
`submission/transfer_inputs/localization_inputs.yml` defines the inputs to the neurorad pipeline:
```yaml
  - name: native_loc
    << : *FILE
    origin_directory: *IMAGING_SUBJ_DIR
    origin_file: 'electrodenames_coordinates_native.csv'
    destination: 'coordinates_native.csv'
    
  - name: mni_loc
    << : *FILE
    origin_directory: *IMAGING_SUBJ_DIR
    origin_file: 'electrodenames_coordinates_mni.csv'
    destination: 'coordinates_mni.csv'
    
  - name: coords_t1
    << : *FILE
    origin_directory: *IMAGING_SUBJ_DIR
    origin_file: 'electrodenames_coordinates_native_and_T1.csv'
    destination: 'coordinates_native_and_t1.csv'

  - name: fs_orig_t1
    << : *FILE
    origin_directory: *FS_MRI
    origin_file: 'orig.mgz'
    destination: 'orig_mri.mgz'

  - name: vox_mom
    <<: *FILE
    groups: [ 'old' ]
    origin_directory: *TAL_DIR
    origin_file: 'VOX_coords_mother.txt'
    destination: 'VOX_coords_mother.txt'

  - name: jacksheet
    <<: *FILE
    groups: [ 'old' ]
    origin_directory: *DOCS_DIR
    origin_file: 'jacksheet.txt'
    destination: 'jacksheet.txt'

  - name: voxel_coordinates
    <<: *FILE
    groups: [ 'new' ]
    origin_directory: *TAL_DIR
    origin_file: 'voxel_coordinates.json'
    destination: 'voxel_coordinates.json'
```

The origin directories for each file are references to directories defined at the top of the yaml file.
If any other files become necessary for the completion of the pipeline, they should be added here. 

Note that `VOX_coords_mother` and `jacksheet` are present as inputs when the group is `old`, and 
`voxel_coordinates` is an input when the group is `new`. The pipeline can convert the old-formatted
"mother" file into the newer json format, but can also just use the new format if it exists. 

##### Transferer:

`submission.transferer` contains the following function to generate a localization transferer:
```python
def generate_localization_transferer(subject, protocol, localization, code, is_new):
    cfg_file = TRANSFER_INPUTS['localization']
    destination = os.path.join(paths.db_root,
                               'protocols', protocol,
                               'subjects', subject,
                               'localizations', localization,
                               'neuroradiology')
    if is_new:
        groups = ('new',)
    else:
        groups = ('old',)
    return Transferer(cfg_file, groups, destination,
                      protocol=protocol,
                      subject=subject,
                      localization=localization,
                      code=code,
                      data_root=paths.data_root, db_root=paths.db_root)
```

Note again the presence of `old` or `new`, which tells the pipeline whether to look for the old
`.txt` based or new `.json` based format of the CT voxel coordinates. 

The transferer will ensure that all of the required files are present for the specified group.

##### Submission pipeline

Each pipeline defines a list of tasks to be executed. For localization, this pipeline is implemented
in the function `submission.pipelines.build_import_localization_pipeline()`:
```python
def build_import_localization_pipeline(subject, protocol, localization, code, is_new):
    transferer = generate_localization_transferer(subject, protocol, localization, code, is_new)
    tasks = [
        LoadVoxelCoordinatesTask(subject, localization, is_new),
        CalculateTransformsTask(subject, localization),
        CorrectCoordinatesTask(subject, localization),
        AddContactLabelsTask(subject, localization),
        AddMNICoordinatesTask(subject, localization),
        WriteFinalLocalizationTask()
    ]
    return TransferPipeline(transferer, *tasks)
```

The pipeline ensures that each of the six tasks:
* creation of `Localization` object
* calculation of transforms
* correction of coordinates (dykstra, not yet fully implemented)
* addition of atlas labels
* addition of MNI coordinates
* writing of final file

is executed in order, and that if any one of them fails the appropriate error message is listed,
and submission is rolled back. 

##### Task definitions
Finally, each task to be executed is defined in `submission.neurorad_tasks`

Here, each of the files in the neurorad pipeline is referenced (with the exception of coordinate
correction, which has not yet been included):
```python
class LoadVoxelCoordinatesTask(PipelineTask):


    def __init__(self, subject, localization, is_new, critical=True):
        super(LoadVoxelCoordinatesTask, self).__init__(critical)
        self.name = 'Loading {} voxels for {}, loc: {}'.format('new' if is_new else 'old', subject, localization)
        self.is_new = is_new

    def _run(self, files, db_folder):
        logger.set_label(self.name)
        if self.is_new:
            vox_file = files['voxel_coordinates']
        else:
            vox_file = os.path.join(self.pipeline.source_dir, 'converted_voxel_coordinates.json')
            vox_mother_converter.convert(files, vox_file)

        localization = Localization(vox_file)

        self.pipeline.store_object('localization', localization)

class CalculateTransformsTask(PipelineTask):

    def __init__(self, subject, localization, critical=True):
        super(CalculateTransformsTask, self).__init__(critical)
        self.name = 'Calculate transformations {} loc: {}'.format(subject, localization)

    def _run(self, files, db_folder):
        logger.set_label(self.name)
        localization = self.pipeline.retrieve_object('localization')
        calculate_transformation.insert_transformed_coordinates(localization, files)

class CorrectCoordinatesTask(PipelineTask):

    def __init__(self, subject, localization, critical=False):
        super(CorrectCoordinatesTask, self).__init__(critical)
        self.name = 'Correcting coordinates {} loc {}'.format(subject, localization)

    def _run(self, files, db_folder):
        logger.set_label(self.name)
        localization = self.pipeline.retrieve_object('localization')
        # TODO : Dysktra method here

class AddContactLabelsTask(PipelineTask):

    def __init__(self, subject, localization, critical=True):
        super(AddContactLabelsTask, self).__init__(critical)
        self.name = 'Add labels {} loc {}'.format(subject, localization)

    def _run(self, files, db_folder):
        logger.set_label(self.name)
        localization = self.pipeline.retrieve_object('localization')

        logger.info("Adding Autoloc")
        add_locations.add_autoloc(files, localization)

class AddMNICoordinatesTask(PipelineTask):

    def __init__(self, subject, localization, critical=True):
        super(AddMNICoordinatesTask, self).__init__(critical)
        self.name = 'Add MNI {} loc {}'.format(subject, localization)

    def _run(self, files, db_folder):
        logger.set_label(self.name)
        localization = self.pipeline.retrieve_object('localization')

        logger.info("Adding MNI")
        add_locations.add_mni(files, localization)

class WriteFinalLocalizationTask(PipelineTask):

    def _run(self, files, db_folder):
        localization = self.pipeline.retrieve_object('localization')

        logger.info("Writing localization.json file")
        self.create_file(os.path.join(db_folder, 'localization.json',), localization.to_jsons(), 'localization', False)
```