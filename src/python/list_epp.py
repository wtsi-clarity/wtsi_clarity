#!/usr/bin/env python3

from urllib.parse import urljoin

import sys

from clarity import Clarity

__author__ = 'rf9'

SEP = ", "


def format_string(in_str):
    return in_str.replace("_", " ").capitalize()


if __name__ == "__main__":
    if len(sys.argv) == 3:
        root_url = sys.argv[1]
        OUT_FILE_PATH = sys.argv[2]
    else:
        sys.stderr.write("usage: python list_epp.py <root_uri> <output_file>\n")
        sys.exit(1)

    clarity = Clarity(root_url)

    with open(OUT_FILE_PATH, 'w') as OUT_FILE:

        workflows = clarity.get_xml(urljoin(root_url, 'configuration/workflows/')).findall('workflow')

        for workflow in workflows:
            if workflow.get('status') == 'ACTIVE':
                workflow_xml = clarity.get_xml(workflow.get('uri'))
                protocols = workflow_xml.find('protocols').findall('protocol')

                for protocol in protocols:
                    protocol_name = protocol.get("name")
                    protocol_uri = protocol.get("uri")

                    steps = clarity.get_xml(protocol_uri).find("steps").findall("step")
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

                                for script in clarity.get_xml(process_type_uri).findall("parameter"):
                                    string = script.find("string")
                                    epps[script.get("name")][
                                        "script"] = string.text.strip() if string is not None else ""

                                for epp_name, epp in epps.items():
                                    OUT_FILE.write(SEP.join([workflow.get('name'), protocol_name, step_name, epp_name,
                                                             format_string(epp.get('type')),
                                                             format_string(epp.get('status')),
                                                             format_string(epp.get('point')),
                                                             epp.get('script')]) + "\n")
                            else:
                                OUT_FILE.write(workflow.get('name') + SEP + protocol_name + SEP + step_name + "\n")
                    else:
                        OUT_FILE.write(protocol_name + '\n')
