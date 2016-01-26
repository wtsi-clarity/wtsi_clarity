#!/usr/bin/env python3

import getpass
from urllib import request
from xml.etree import ElementTree
import sys

__author__ = 'rf9'


def setup_urllib():
    password_mgr = request.HTTPPasswordMgrWithDefaultRealm()
    password_mgr.add_password(None, root_url, USER, PASS)
    handler = request.HTTPBasicAuthHandler(password_mgr)
    opener = request.build_opener(handler)
    opener.open(root_url)
    request.install_opener(opener)


def get_xml(uri):
    xml = request.urlopen(uri)
    return ElementTree.parse(xml).getroot()


if __name__ == "__main__":
    if len(sys.argv) == 2:
        root_url = sys.argv[1]
    else:
        sys.stderr.write("usage: python missing_reagents_check.py <root_uri>\n")
        sys.exit(1)

    if root_url[-1] != '/':
        root_url += "/"

    USER = getpass.getuser()
    USER = input("Username (leave blank for '" + USER + "'): ") or USER
    PASS = getpass.getpass('Password: ')

    setup_urllib()

    process_type = "Library PCR set up".replace(' ', '%20')
    uri = root_url + 'artifacts?process-type=' + process_type + '&start-index=3500'

    while 1:
        xml = get_xml(uri)

        for artifact in xml.findall('artifact'):
            artifact_xml = get_xml(artifact.get('uri'))
            if not artifact_xml.findall('reagent-label'):
                print(artifact_xml.find('parent-process').get('uri'))
            else:
                print('.')

        uri = xml.find('previous-page').get('uri')
