import getpass
import os
import urllib.request as request
from xml.etree import ElementTree
import sys

__author__ = 'rf9'

DIRECTORY_NAME = "CaliperGX"
FILE_DIR = os.path.dirname(os.path.realpath(__file__))
CONCENTRATION = "WTSI Library Concentration"
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

    for (directory, subdirectories, filenames) in os.walk(os.path.join(FILE_DIR, DIRECTORY_NAME)):
        for filename in filenames:
            signature = filename.split("_")[1]
            values = {}
            with open(os.path.join(directory, filename)) as f:
                next(f)
                for line in f:
                    cells = line.split(',')

                    well = cells[2].split("_")[0]
                    try:
                        value = float(cells[5]) * 5
                    except ValueError:
                        continue

                    if well not in values:
                        values[well] = value
                    else:
                        values[well] = (values[well] + value) / 2

            xml = get_xml(
                request.urljoin(ROOT_URL, "containers?udf.WTSI%20Container%20Signature=" + signature))
            container = xml.find("container")
            if container:
                container_uri = container.get("uri")

                xml = get_xml(container_uri)
                for placement in xml.findall("placement"):
                    well = placement.find("value").text
                    value = str(values[well.replace(":", "")])
                    placement_uri = placement.get("uri")

                    print(signature, well)

                    sample_uri = get_xml(placement_uri).find("sample").get("uri")

                    xml = get_xml(sample_uri)
                    for field in xml.findall(FIELD):
                        if field.get("name") == CONCENTRATION:
                            field.text = value
                            break
                    else:
                        builder = ElementTree.TreeBuilder()
                        builder.start(FIELD, {
                            "type": "String",
                            "name": CONCENTRATION
                        })
                        element = builder.close()
                        element.text = value
                        # print(ElementTree.tostring(element))
                        xml.append(element)

                    xml_string = ElementTree.tostring(xml)

                    # print(xml_string.decode("ascii"))
                    req = request.Request(url=sample_uri, data=xml_string, method='PUT')
                    req.add_header("Content-Type", "application/xml")
                    with request.urlopen(req) as put_req:
                        pass

                os.rename(os.path.join(directory, filename),
                          os.path.join(directory.replace(DIRECTORY_NAME, "Done"), filename))
