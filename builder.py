import argparse
import shutil
import os

__author__ = 'alex'


class Builder(object):
    """build release pack"""

    def __init__(self, dirs, outdir, ftypes, location=os.getcwd()):
        self.dirs = dirs
        self.ftypes = ftypes
        self.location = os.path.abspath(os.path.normpath(location))
        self.outdir = os.path.abspath(os.path.normpath(outdir))

    def build(self):
        for dirname in self.dirs:
            old_location = os.path.join(self.location, dirname)
            new_location = os.path.join(self.outdir, dirname)

            if not os.path.exists(new_location) and os.path.isdir(old_location):
                os.makedirs(new_location)

            for root, dirs, files in os.walk(old_location):
                rel_dirname = root.replace(self.location, '').lstrip(os.sep)

                for dname in dirs:
                    _new_location = os.path.join(self.outdir, rel_dirname, dname)
                    if not os.path.exists(_new_location):
                        os.makedirs(_new_location)

                for filename in files:
                    name, ext = os.path.splitext(filename)
                    if ext in self.ftypes:
                        old_filepath = os.path.join(root, filename)
                        new_filepath = os.path.join(self.outdir, rel_dirname, filename)

                        if not os.path.exists(new_filepath):
                            shutil.copy(old_filepath, new_filepath)


def main(dirs, buildpath, ftypes):
    builder = Builder(dirs, buildpath, ftypes)
    builder.build()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Builds a new release of the project.')

    parser.add_argument('--buildpath', type=str,
                        dest='buildpath', default=os.path.join(os.getcwd(), 'build'),
                        help='Location for the new release.')

    args = parser.parse_args()

    main(
        ['api-lua3.2', 'luabit', 'sha1'],
        args.buildpath,
        ['.lua']
    )
