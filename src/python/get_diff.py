#!/usr/bin/env python3

from urllib.parse import urljoin
from xml.etree import ElementTree
import sys
from clarity import Clarity

__author__ = 'rf9'


def expand(element_to_expand):
    for child_element in clarity.get_xml(element_to_expand.get('uri')):
        element_to_expand.append(child_element)
    # Remove the uri from the element (because it will always be different)
    del element_to_expand.attrib['uri']


if __name__ == "__main__":
    if len(sys.argv) == 3:
        root_url = sys.argv[1]
        OUT_FILE_PATH = sys.argv[2]
    else:
        sys.stderr.write("usage: python list_epp.py <root_uri> <output_file>\n")
        sys.exit(1)

    clarity = Clarity(root_url)

    workflows = clarity.get_xml(urljoin(clarity.root, 'configuration/workflows/'))

    for workflow in workflows.findall('workflow'):

        if workflow.get('status') != 'ACTIVE':
            workflows.remove(workflow)
            continue

        expand(workflow)

        for protocol in workflow.find('protocols').findall('protocol'):
            expand(protocol)

            for step in protocol.find('steps').findall('step'):
                for reagent_kit in step.find('required-reagent-kits').findall('reagent-kit'):
                    expand(reagent_kit)

                del step.attrib['protocol-uri']
                del step.attrib['uri']

                process_type = step.find('process-type')
                expand(process_type)

                for type_definition in process_type.findall('type-definition'):
                    expand(type_definition)

                for field_definition in process_type.findall('field-definition'):
                    expand(field_definition)

                for process_output in process_type.findall('process-output'):
                    for field_definition in process_output.findall('field-definition'):
                        expand(field_definition)

                for transition in step.find('transitions').findall('transition'):
                    del transition.attrib['next-step-uri']

                permitted_control_types = step.find('permitted-control-types')
                if permitted_control_types is not None:
                    for control_type in permitted_control_types.findall('control-type'):
                        expand(control_type)

        for stage in workflow.find('stages').findall('stage'):
            del stage.attrib['uri']

    # Alphabetise the xml (retaining structure) to avoid false changes in the diff.
    for element in workflows.iter():
        children = list(element)
        children.sort(key=lambda x: ElementTree.tostring(x))
        for child in children:
            element.remove(child)

            # The show in tables setting appears to be useless, so we're ignoring differences in it for now.
            if child.tag != 'show-in-tables':
                element.append(child)

    with open(OUT_FILE_PATH, 'w') as OUT_FILE:
        OUT_FILE.write(ElementTree.tostring(workflows).decode('ascii'))
