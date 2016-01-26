#!/usr/bin/env python3
import getpass
import urllib.request as request
from xml.etree import ElementTree

import sys

__author__ = 'rf9'

SIGNATURE = "WTSI Container Signature"
FIELD = "{http://genologics.com/ri/userdefined}field"


def setup_urllib():
    password_mgr = request.HTTPPasswordMgrWithDefaultRealm()
    password_mgr.add_password(None, root_url, user, password)
    handler = request.HTTPBasicAuthHandler(password_mgr)
    opener = request.build_opener(handler)
    opener.open(root_url)
    request.install_opener(opener)


def get_xml(uri):
    with request.urlopen(uri) as data:
        return ElementTree.parse(data).getroot()


if __name__ == '__main__':
    if len(sys.argv) == 2:
        root_url = sys.argv[1]
    else:
        sys.stderr.write("usage: python signature_lookup.py <root_uri>\n")
        sys.exit(1)

    if root_url[-1] != '/':
        root_url += "/"

    user = getpass.getuser()
    user = input("Username (leave blank for '" + user + "'): ") or user
    password = getpass.getpass('Password: ')

    setup_urllib()

    for index in ['4000']:
        for container in get_xml(request.urljoin(root_url, "containers?start-index=" + index)).findall("container"):
            container = get_xml(container.get("uri"))

            for field in container.findall(FIELD):
                if field.get("name") == SIGNATURE:
                    print(field.text)
