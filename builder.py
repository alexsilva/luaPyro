# coding=utf-8
import argparse
import shutil
import os

__author__ = 'alex'


class Builder(object):
    """build release pack"""

    def __init__(self, dirs, outdir, ftypes,
                 curdir=os.path.dirname(__file__),
                 dropout=False):
        self.dirs = dirs
        self.ftypes = ftypes
        self.curdir = os.path.abspath(os.path.normpath(curdir))
        self.outdir = os.path.abspath(os.path.normpath(outdir))
        self.dropout = dropout

    def _clean_if_needed(self):
        if self.dropout and os.path.exists(self.outdir):
            shutil.rmtree(self.outdir)

    def process_filename(self, root, rel_dirname, filename):
        name, ext = os.path.splitext(filename)
        if ext in self.ftypes:
            old_filepath = os.path.join(root, filename)
            new_filepath = os.path.join(self.outdir, rel_dirname, filename)
            if not os.path.exists(new_filepath):
                shutil.copy(old_filepath, new_filepath)

    def process_new_filesdir(self, rel_dirname, dirname):
        new_dir = os.path.join(self.outdir, rel_dirname, dirname)
        if not os.path.exists(new_dir):
            os.makedirs(new_dir)

    def get_old_new_dir(self, dirname):
        old_dir = os.path.join(self.curdir, dirname)
        new_dir = os.path.join(self.outdir, dirname)
        return old_dir, new_dir

    @staticmethod
    def make_new_dirs(old_dir, new_dir):
        if not os.path.exists(new_dir) and os.path.isdir(old_dir):
            os.makedirs(new_dir)

    def build(self):
        # remove o diretório build se configurado.
        self._clean_if_needed()

        for dirname in self.dirs:
            old_dir, new_dir = self.get_old_new_dir(dirname)

            self.make_new_dirs(old_dir, new_dir)

            for root, dirs, files in os.walk(old_dir):
                rel_dirname = os.path.relpath(root, self.curdir)

                for dname in dirs:
                    self.process_new_filesdir(rel_dirname, dname)

                for filename in files:
                    self.process_filename(root, rel_dirname, filename)


def main(*args, **kwargs):
    builder = Builder(*args, **kwargs)
    builder.build()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Builds a new release of the project.')

    parser.add_argument('--buildpath', type=str,
                        dest='buildpath', default=os.path.join(os.getcwd(), 'build'),
                        help='Location for the new release.')

    parser.add_argument('--dropout', action='store_true',
                        dest='dropout', default=False,
                        help='Delete output dir if existing.')

    args = parser.parse_args()

    main(
        ['api-lua3.2', 'luabit', 'sha1'],
        args.buildpath,
        ['.lua'],
        dropout = args.dropout
    )
