import urllib.request as request
from urllib.parse import urljoin
from urllib.error import HTTPError
import xml.etree.ElementTree as et
import sys

__author__ = 'rf9'

SEP = "\t"


def setup_urllib():
    password_mgr = request.HTTPPasswordMgrWithDefaultRealm()
    password_mgr.add_password(None, ROOT_URL, USER, PASS)
    handler = request.HTTPBasicAuthHandler(password_mgr)
    opener = request.build_opener(handler)
    opener.open(ROOT_URL)
    request.install_opener(opener)


def get_all_protocols():
    uri = urljoin(ROOT_URL, 'configuration/protocols/')
    xml = request.urlopen(uri)
    root = et.parse(xml).getroot()

    return {protocol.get("name"): protocol.get("uri") for protocol in root.findall("protocol")}


def get_processes_from_protocol(uri):
    xml = request.urlopen(uri)
    root = et.parse(xml).getroot()
    process_types = [step.find('process-type') for step in root.find("steps").findall("step")]

    return {process_type.text: process_type.get("uri") for process_type in process_types}


def get_scripts_from_process(process_uri):
    try:
        xml = request.urlopen(process_uri)
    except HTTPError:
        return []

    root = et.parse(xml).getroot()
    params = root.findall("parameter")
    string_objects = [param.find("string") for param in params]
    strings = [string.text.strip() for string in string_objects if string is not None]

    return [string for string in strings if len(string) > 0]


if __name__ == "__main__":
    if len(sys.argv) == 4:
        ROOT_URL = sys.argv[1]
        USER = sys.argv[2]
        PASS = sys.argv[3]
    else:
        sys.stderr.write("usage: python list_epp.py <root_uri> <username> <password>\n")
        sys.exit(1)

    if ROOT_URL[-1] != '/':
        ROOT_URL += "/"


    setup_urllib()

    print("Protocol", "Step", "Script", sep=SEP)

    protocols = get_all_protocols()
    for protocol in protocols:
        processes = get_processes_from_protocol(protocols[protocol])
        if processes:
            for process in processes:
                uri = processes[process]
                scripts = get_scripts_from_process(uri)
                if scripts:
                    for script in scripts:
                        print(protocol, process, script, sep=SEP)
                else:
                    print(protocol, process, "", sep=SEP)
        else:
            print(protocol, "", "", sep=SEP)
