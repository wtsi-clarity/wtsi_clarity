#!/usr/bin/env python3

import datetime
import getpass
import os

import sys

import get_config_tree
import config_diff

from clarity import Clarity

__author__ = 'rf9'

DIRECTORY = 'snapshots'

if __name__ == "__main__":
    if len(sys.argv) == 2:
        root_url = sys.argv[1]
    else:
        sys.stderr.write("usage: python list_epp.py <root_uri_prod>\n")
        sys.exit(1)

    date = str(datetime.datetime.now()).replace(' ', '_')

    if not os.path.exists(DIRECTORY):
        os.makedirs(DIRECTORY)

    # Save current snapshot to directory
    prod_file = '%s/%s_prod.xml' % (DIRECTORY, date)
    cmp_file1 = '%s/%s_prod_cmp_1.xml' % (DIRECTORY, date)
    cmp_file2 = '%s/%s_prod_cmp_2.xml' % (DIRECTORY, date)

    clarity = Clarity(root_url)

    get_config_tree.main(clarity, prod_file)

    filenames = list(os.walk(DIRECTORY))[0][2]

    prod_filenames = [DIRECTORY + '/' + filename for filename in filenames if filename.endswith('_prod.xml')]

    if len(prod_filenames) >= 2:
        exit(not config_diff.main(prod_filenames[-2], prod_filenames[-1], cmp_file1, cmp_file2))
