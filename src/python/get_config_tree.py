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

IGNORE_LIST = ['stage']


def main(clarity, out_file_path):
    def expand(element_to_expand):
        uri = element_to_expand.get('uri')

        if 'uri' in element_to_expand.attrib:
            del element_to_expand.attrib['uri']
        if 'protocol-uri' in element_to_expand.attrib:
            del element_to_expand.attrib['protocol-uri']
        if 'next-step-uri' in element_to_expand.attrib:
            del element_to_expand.attrib['next-step-uri']

        if element_to_expand.tag in IGNORE_LIST:
            return

        if uri and element_to_expand is not None:
            for child_element in clarity.get_xml(uri):
                element_to_expand.append(child_element)

        for child_element in element_to_expand:
            expand(child_element)

    def sort_tree(tree):
        for child_element in tree:
            sort_tree(child_element)

        children_elements = sorted(tree, key=lambda x: ElementTree.tostring(x))
        for child_element in children_elements:
            tree.remove(child_element)
            tree.append(child_element)

    workflows = clarity.get_xml(urljoin(clarity.root, 'configuration/workflows/'))

    for workflow in workflows.findall('workflow'):
        if workflow.get('status') != 'ACTIVE':
            workflows.remove(workflow)

    expand(workflows)

    # Alphabetise the xml (retaining structure) to avoid false changes in the diff.
    sort_tree(workflows)

    with open(out_file_path, 'w') as out_file:
        out_file.write(ElementTree.tostring(workflows).decode('ascii'))


if __name__ == "__main__":
    if len(sys.argv) == 3:
        root = sys.argv[1]
        out = sys.argv[2]
    else:
        sys.stderr.write("usage: python get_config_tree.py <root_uri> <output_file>\n")
        sys.exit(1)

    main(Clarity(root), out)
