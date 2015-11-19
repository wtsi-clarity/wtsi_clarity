#!/usr/bin/env python3

from urllib.parse import urljoin
from xml.etree import ElementTree
import sys
from clarity import Clarity

__author__ = 'rf9'

SEP = ", "


def expand(element):
    for child in clarity.get_xml(element.get('uri')):
        element.append(child)
    del element.attrib['uri']


def sort_xml(parent, element_name, comp_lambda):
    elements = parent.findall(element_name)
    elements.sort(key=comp_lambda)
    for element in elements:
        parent.remove(element)
        parent.append(element)


if __name__ == "__main__":
    if len(sys.argv) == 3:
        root_url = sys.argv[1]
        OUT_FILE_PATH = sys.argv[2]
    else:
        sys.stderr.write("usage: python list_epp.py <root_uri> <output_file>\n")
        sys.exit(1)

    clarity = Clarity(root_url)
    clarity.caching = True

    workflows = clarity.get_xml(urljoin(root_url, 'configuration/workflows/'))

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

                # sort_xml(process_type, 'process-type-attribute', lambda x: x.get('name'))

                for type_definition in process_type.findall('type-definition'):
                    expand(type_definition)

                # sort_xml(process_type, 'field-definition', lambda x: x.get('name'))

                for field_definition in process_type.findall('field-definition'):
                    expand(field_definition)

                for process_output in process_type.findall('process-output'):
                    # sort_xml(process_output, 'field-definition', lambda x: x.get('name'))

                    for field_definition in process_output.findall('field-definition'):
                        expand(field_definition)

                for transition in step.find('transitions').findall('transition'):
                    del transition.attrib['next-step-uri']

                # sort_xml(step.find('queue-fields'), 'queue-field', lambda x: x.get('name'))

                permitted_control_types = step.find('permitted-control-types')
                if permitted_control_types is not None:
                    for control_type in permitted_control_types.findall('control-type'):
                        expand(control_type)

        for stage in workflow.find('stages').findall('stage'):
            del stage.attrib['uri']

    for element in workflows.iter():
        children = list(element)
        children.sort(key=lambda x: ElementTree.tostring(x))
        for child in children:
            element.remove(child)

            if child.tag != 'show-in-tables':
                element.append(child)

    with open(OUT_FILE_PATH, 'w') as OUT_FILE:
        OUT_FILE.write(ElementTree.tostring(workflows).decode('ascii'))
