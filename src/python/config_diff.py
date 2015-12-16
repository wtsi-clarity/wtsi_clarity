#!/usr/bin/env python3
"""
This script is used to get the difference between two xml files.

usage: python list_epp.py <file1> <file2> <output_file1> <output_file2>

file1 will have everything that is the same removed and be written out as output_file1. The same will be done for file2.
Whist retaining the xml structure, only the differences between the two input files will be in the output files.

This script ignores the order of the xml, so if you care about the order of elements this will not work.
"""

from xml.etree import ElementTree
import sys

__author__ = 'rf9'


def remove_same(node1, node2):
    sorted1 = sorted(node1, key=lambda x: ElementTree.tostring(x))
    sorted2 = sorted(node2, key=lambda x: ElementTree.tostring(x))

    for e1 in sorted1:
        for e2 in sorted2:
            if e1.tag == e2.tag and e1.items() == e2.items() and e1.text == e2.text and e2 in node2:
                if remove_same(e1, e2):
                    node1.remove(e1)
                    node2.remove(e2)
                    break

    if not list(node1) and not list(node2):
        if node1.tag == node2.tag and node1.items() == node2.items() and node1.text == node2.text:
            return True

    return False


if __name__ == "__main__":
    if len(sys.argv) == 5:
        in_file_1 = sys.argv[1]
        in_file_2 = sys.argv[2]
        out_file_1 = sys.argv[3]
        out_file_2 = sys.argv[4]
    else:
        sys.stderr.write("usage: python list_epp.py <file1> <file2> <output_file1> <output_file2>\n")
        sys.exit(1)

    tree1 = ElementTree.parse(in_file_1).getroot()
    tree2 = ElementTree.parse(in_file_2).getroot()

    for parent in tree1.iter():
        for child in parent:
            if child.tag == 'show-in-tables':
                parent.remove(child)

    for parent in tree2.iter():
        for child in parent:
            if child.tag == 'show-in-tables':
                parent.remove(child)

    remove_same(tree1, tree2)

    with open(out_file_1, mode='w') as out_file:
        out_file.write(ElementTree.tostring(tree1).decode('ascii'))

    with open(out_file_2, mode='w') as out_file:
        out_file.write(ElementTree.tostring(tree2).decode('ascii'))
