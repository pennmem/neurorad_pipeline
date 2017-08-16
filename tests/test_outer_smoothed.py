from make_outer_surface import make_smoothed_surface
import os.path as osp
from config import paths
import argparse
from nibabel import freesurfer as nf

def test(subject,db_root):
    temp = subject.split('_')
    localization = '0' if len(temp)==1 else temp[1]
    subject = temp[0]

    for hem in ['lh', 'rh']:
        surface_file = osp.join(paths.rhino_root,db_root,'protocols','r1','subjects',subject,'localizations',localization,'neuroradiology',
                                  'current_source','surf','%s.pial'%hem)
        outer_smoothed = make_smoothed_surface(surface_file)
        reference_smoothed_file = osp.join(paths.rhino_root,'data','eeg','freesurfer','subjects',subject,'surf','%s.pial-outer-smoothed'%hem)
        print 'reference_smoothed_file:\n%s'%reference_smoothed_file
        new_coords,new_faces = nf.read_geometry(outer_smoothed)
        old_coords,old_faces = nf.read_geometry(reference_smoothed_file)
        assert new_coords.shape == old_coords.shape
        assert new_faces.shape == old_faces.shape
        assert (new_coords==old_coords).all()
        assert (new_faces==old_faces).all()
        print "Success!"



if __name__ =='__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('subjects',nargs='+')
    args = parser.parse_args()
    for subject in args.subjects:
        print 'Testing %s'%subject
        test(subject,'home1/leond')