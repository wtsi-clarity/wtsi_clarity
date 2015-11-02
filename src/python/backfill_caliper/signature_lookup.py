#!/usr/bin/env python3

import getpass
import os
import urllib.request as request
from xml.etree import ElementTree
import sys

__author__ = 'rf9'

SIGNATURE = "WTSI Container Signature"
FIELD = "{http://genologics.com/ri/userdefined}field"


def setup_urllib():
    password_mgr = request.HTTPPasswordMgrWithDefaultRealm()
    password_mgr.add_password(None, ROOT_URL, USER, PASS)
    handler = request.HTTPBasicAuthHandler(password_mgr)
    opener = request.build_opener(handler)
    opener.open(ROOT_URL)
    request.install_opener(opener)


def get_xml(uri):
    with request.urlopen(uri) as data:
        return ElementTree.parse(data).getroot()


if __name__ == '__main__':
    if len(sys.argv) == 2:
        ROOT_URL = sys.argv[1]
    else:
        sys.stderr.write("usage: python list_epp.py <root_uri>\n")
        sys.exit(1)

    if ROOT_URL[-1] != '/':
        ROOT_URL += "/"

    USER = getpass.getuser()
    USER = input("Username (leave blank for '" + USER + "'): ") or USER
    PASS = getpass.getpass('Password: ')

    setup_urllib()

    for index in ['4000']:
        for container in get_xml(request.urljoin(ROOT_URL, "containers?start-index=" + index)).findall("container"):
            container = get_xml(container.get("uri"))

            for field in container.findall(FIELD):
                if field.get("name") == SIGNATURE:
                    print(field.text)
