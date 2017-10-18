# Release Notes



## 2.0 (Upcoming)

### Features:

* Dijkstra brain-shift correction for surface electrodes ported
  from MATLAB to Python via R
* Computation of dural surface mesh ported from MATLAB to Python;
  introduces dependency on scikit-image
* Localization information (electrode coordinates and atlas labels)
  stored in JSON format
* Labels from the HCP atlas
* Coordinates on average brain computed using Freesurfer registrations

### Features Not Yet Implemented:

* Brain-shift corrected MNI coordinates for surface electrodes

### Dependencies Introduced:
* scikit-image
* sympy