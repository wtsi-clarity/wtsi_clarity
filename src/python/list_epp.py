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
        out_file_path = sys.argv[2]
    else:
        sys.stderr.write("usage: python list_epp.py <root_uri> <output_file>\n")
        sys.exit(1)

    clarity = Clarity(root_url)

    with open(out_file_path, 'w') as out_file:

        workflows = clarity.get_object(clarity.root + 'configuration/workflows/').workflow

        for workflow in workflows:
            if workflow.status == ['ACTIVE']:
                protocols = workflow.protocols.protocol

                for protocol in protocols:
                    protocol_name = protocol.name[0]

                    steps = protocol.steps.step
                    if steps:
                        for step in steps:
                            step_name = step.name[0]

                            epps = {}
                            epp_triggers = step.epp_triggers.epp_trigger
                            if epp_triggers:
                                for epp_trigger in epp_triggers:
                                    epps[epp_trigger.name[0]] = {
                                        "type": (epp_trigger.type or [""])[0],
                                        "point": (epp_trigger.point or [""])[0],
                                        "status": (epp_trigger.status or [""])[0],
                                    }

                                for script in step.process_type.parameter:
                                    string = script.string
                                    epps[script.name[0]]["script"] = string.text[0].strip() if string is not None else ""

                                for epp_name, epp in epps.items():
                                    out_file.write(SEP.join([workflow.name[0], protocol_name, step_name, epp_name,
                                                             format_string(epp.get('type')),
                                                             format_string(epp.get('status')),
                                                             format_string(epp.get('point')),
                                                             epp.get('script')]) + "\n")
                            else:
                                out_file.write(workflow.name[0] + SEP + protocol_name + SEP + step_name + "\n")
                    else:
                        out_file.write(protocol_name + '\n')
