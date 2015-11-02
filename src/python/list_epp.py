#!/usr/bin/env python3

import urllib.request as request
from urllib.parse import urljoin
from xml.etree import ElementTree
import sys
import getpass

__author__ = 'rf9'

SEP = ", "


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


def format_string(in_str):
    return in_str.replace("_", " ").capitalize()


if __name__ == "__main__":
    if len(sys.argv) == 3:
        ROOT_URL = sys.argv[1]
        OUT_FILE_PATH = sys.argv[2]
    else:
        sys.stderr.write("usage: python list_epp.py <root_uri> <output_file>\n")
        sys.exit(1)

    if ROOT_URL[-1] != '/':
        ROOT_URL += "/"

    USER = getpass.getuser()
    USER = input("Username (leave blank for '" + USER + "'): ") or USER
    PASS = getpass.getpass('Password: ')

    setup_urllib()

    with open(OUT_FILE_PATH, 'w') as OUT_FILE:
        OUT_FILE.write(SEP.join(["Protocol", "Step", "Script Name", "Behaviour", "Stage", "Timing", "Script"]) + "\n")

        protocols = get_xml(urljoin(ROOT_URL, 'configuration/protocols/')).findall("protocol")
        print("{:>3}/{}".format(0, len(protocols)))
        for i, protocol in enumerate(protocols):
            protocol_name = protocol.get("name")
            protocol_uri = protocol.get("uri")

            steps = get_xml(protocol_uri).find("steps").findall("step")
            if steps:
                for step in steps:
                    step_name = step.get("name")
                    process_type_uri = step.find("process-type").get("uri")

                    epps = {}
                    epp_triggers = step.find("epp-triggers").findall("epp-trigger")
                    if epp_triggers:
                        for epp_trigger in epp_triggers:
                            epps[epp_trigger.get("name")] = {
                                "type": epp_trigger.get("type") or "",
                                "point": epp_trigger.get("point") or "",
                                "status": epp_trigger.get("status") or "",
                            }

                        for script in get_xml(process_type_uri).findall("parameter"):
                            string = script.find("string")
                            epps[script.get("name")]["script"] = string.text.strip() if string is not None else ""

                        for epp_name, epp in epps.items():
                            OUT_FILE.write(SEP.join([protocol_name, step_name, epp_name, format_string(epp.get('type')),
                                                     format_string(epp.get('status')), format_string(epp.get('point')),
                                                     epp.get('script')]) + "\n")
                    else:
                        OUT_FILE.write(protocol_name + SEP + step_name + "\n")
            else:
                OUT_FILE.write(protocol_name + '\n')
            print("{:>3}/{}".format(i + 1, len(protocols)))
