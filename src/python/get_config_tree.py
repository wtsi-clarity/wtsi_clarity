#!/usr/bin/env python3
"""
This script is used to download an xml representation of the active workflows in clarity.

usage: python list_epp.py <root_uri> <output_file>

Root url is the url that ends in `/api/v2`

Use with config_diff.py to get the differences between two xml configs.
"""

from urllib.parse import urljoin
from xml.etree import ElementTree
import sys
from clarity import Clarity

__author__ = 'rf9'

IGNORE_LIST = ['show-in-tables']


def expand(element_to_expand):
    if element_to_expand.get('uri'):
        for child_element in clarity.get_xml(element_to_expand.get('uri')):
            element_to_expand.append(child_element)
        # Remove the uri from the element (because it will always be different)
        del element_to_expand.attrib['uri']


def sort_tree(tree):
    for child_element in tree:
        sort_tree(child_element)

    children_elements = sorted(list(tree), key=lambda x: ElementTree.tostring(x))
    for child_element in children_elements:
        tree.remove(child_element)

        if tree.tag not in IGNORE_LIST:
            tree.append(child_element)


if __name__ == "__main__":
    if len(sys.argv) == 3:
        root_url = sys.argv[1]
        out_file_path = sys.argv[2]
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
    sort_tree(workflows)

    with open(out_file_path, 'w') as out_file:
        out_file.write(ElementTree.tostring(workflows).decode('ascii'))
