#!/usr/bin/env python3

import datetime
import getpass
import os

import sys

import get_config_tree
import config_diff

from clarity import Clarity

__author__ = 'rf9'

if __name__ == "__main__":
    if len(sys.argv) == 3:
        root_url = sys.argv[1]
        directory = sys.argv[2]
        if directory.endswith('/'):
            directory = directory[:-1]
    else:
        sys.stderr.write("usage: python check_same.py <root_uri_prod> <directory>\n")
        sys.exit(1)

    date = str(datetime.datetime.now()).replace(' ', '_')

    if not os.path.exists(directory):
        os.makedirs(directory)

    # Save current snapshot to directory
    prod_file = '%s/%s_prod.xml' % (directory, date)
    cmp_file1 = '%s/%s_prod_cmp_1.xml' % (directory, date)
    cmp_file2 = '%s/%s_prod_cmp_2.xml' % (directory, date)

    clarity = Clarity(root_url)

    get_config_tree.main(clarity, prod_file)

    filenames = list(os.walk(directory))[0][2]

    prod_filenames = [directory + '/' + filename for filename in filenames if filename.endswith('_prod.xml')]

    if len(prod_filenames) >= 2:
        if not config_diff.main(prod_filenames[-2], prod_filenames[-1], cmp_file1, cmp_file2):
            sys.stderr.write('%s workflow configuration changed' % date)
