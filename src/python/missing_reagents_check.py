import getpass
from urllib import request
from xml.etree import ElementTree
import sys

__author__ = 'rf9'


def setup_urllib():
    password_mgr = request.HTTPPasswordMgrWithDefaultRealm()
    password_mgr.add_password(None, ROOT_URL, USER, PASS)
    handler = request.HTTPBasicAuthHandler(password_mgr)
    opener = request.build_opener(handler)
    opener.open(ROOT_URL)
    request.install_opener(opener)


def get_xml(uri):
    xml = request.urlopen(uri)
    return ElementTree.parse(xml).getroot()


if __name__ == "__main__":
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

    process_type = "Library PCR set up".replace(' ', '%20')
    uri = ROOT_URL + 'artifacts?process-type=' + process_type + '&start-index=3500'

    while 1:
        xml = get_xml(uri)

        for artifact in xml.findall('artifact'):
            artifact_xml = get_xml(artifact.get('uri'))
            if not artifact_xml.findall('reagent-label'):
                print(artifact_xml.find('parent-process').get('uri'))
            else:
                print('.')

        uri = xml.find('previous-page').get('uri')