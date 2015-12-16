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
    if len(sys.argv) == 3:
        root_url_test = sys.argv[1]
        root_url_prod = sys.argv[2]
    else:
        sys.stderr.write("usage: python list_epp.py <root_uri_test> <root_uri_prod>\n")
        sys.exit(1)

    date = str(datetime.datetime.now()).replace(' ', '_')

    if not os.path.exists(DIRECTORY):
        os.makedirs(DIRECTORY)

    test_file = '%s/%s_test.xml' % (DIRECTORY, date)
    prod_file = '%s/%s_prod.xml' % (DIRECTORY, date)
    test_file_diff = '%s/%s_test_diff.xml' % (DIRECTORY, date)
    prod_file_diff = '%s/%s_prod_diff.xml' % (DIRECTORY, date)

    print('Input test credentials:')
    test_user = getpass.getuser()
    test_user = input("Username (leave blank for '" + test_user + "'): ") or test_user
    test_password = getpass.getpass('Password: ')
    temp_clarity = Clarity(root_url_test, test_user, test_password)

    print('Input production credentials:')
    prod_user = getpass.getuser()
    prod_user = input("Username (leave blank for '" + prod_user + "'): ") or prod_user
    prod_password = getpass.getpass('Password: ')
    temp_clarity = Clarity(root_url_prod, prod_user, prod_password)

    test_clarity = Clarity(root_url_test, test_user, test_password)
    get_config_tree.main(test_clarity, test_file)

    prod_clarity = Clarity(root_url_prod, prod_user, prod_password)
    get_config_tree.main(prod_clarity, prod_file)

    config_diff.main(test_file, prod_file, test_file_diff, prod_file_diff)
