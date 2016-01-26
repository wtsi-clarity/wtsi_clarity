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

        workflows = clarity.get_object(clarity.root + 'configuration/workflows/').get('workflow')

        for workflow in workflows:
            if workflow.get_first('status') == 'ACTIVE':
                for protocol in workflow.get('protocols').get('protocol'):
                    steps = protocol.get('steps').get('step')
                    if steps:
                        for step in steps:
                            epps = {}
                            epp_triggers = step.get('epp-triggers').get('epp-trigger')
                            if epp_triggers:
                                for epp_trigger in epp_triggers:
                                    epps[epp_trigger.get_first('name')] = {
                                        "type": epp_trigger.get_first('type') or "",
                                        "point": epp_trigger.get_first('point') or "",
                                        "status": epp_trigger.get_first('status') or "",
                                    }

                                for script in step.get('process-type').get('parameter'):
                                    string = script.get('string')
                                    epps[script.get_first('name')]["script"] = (string.get_first('text') or "").strip()

                                for epp_name, epp in epps.items():
                                    print(workflow.get_first('name'), protocol.get_first('name'),
                                          step.get_first('name'), epp_name, format_string(epp['type']),
                                          format_string(epp['status']), format_string(epp['point']), epp['script'],
                                          sep=SEP, file=out_file)
                            else:
                                print(workflow.get_first('name'), protocol.get_first('name'), step.get_first('name'),
                                      sep=SEP, file=out_file)
                    else:
                        print(workflow.get_first('name'), protocol.get_first('name'), sep=SEP, file=out_file)
