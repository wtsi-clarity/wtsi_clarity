#!/usr/bin/env python3

import os
from xml.etree import ElementTree

import sys

from clarity import Clarity

__author__ = 'rf9'

DIRECTORY_NAME = "backfill_test"
FILE_DIR = os.path.dirname(os.path.realpath(__file__))
CONCENTRATION = "WTSI Library Concentration"
MOLARITY = "WTSI Library Molarity"
FIELD = "{http://genologics.com/ri/userdefined}field"


def get_rows(file):
    headers = next(file).split(',')
    for line in file:
        yield {header: cell for (header, cell) in zip(headers, line.split(','))}


def change_xml(xml, field_name, value):
    for field in sample_xml.findall(FIELD):
        if field.get("name") == field_name:
            field.text = value
            break
    else:
        builder = ElementTree.TreeBuilder()
        builder.start(FIELD, {
            "type": "String",
            "name": field_name
        })
        element = builder.close()
        element.text = value

        xml.append(element)


if __name__ == '__main__':
    if len(sys.argv) == 2:
        root_url = sys.argv[1]
    else:
        sys.stderr.write("usage: python list_epp.py <root_uri>\n")
        sys.exit(1)

    clarity = Clarity(root_url)

    for (directory, subdirectories, filenames) in os.walk(os.path.join(FILE_DIR, DIRECTORY_NAME)):
        for filename in filenames:
            signature = filename.split("_")[1]
            signature = signature.replace('+', '%2B').replace('l', '%2F')

            molarities = {}
            concentrations = {}
            for row in get_rows(open(os.path.join(directory, filename))):
                well = row['Sample Name'].split("_")[0]

                try:
                    molarity = float(row['Region[200-700] Molarity (nmol/l)']) * 5

                    if well not in molarities:
                        molarities[well] = molarity
                    else:
                        molarities[well] = (molarities[well] + molarity) / 2
                except (KeyError, ValueError):
                    pass

                try:
                    concentration = float(row['Total Conc. (ng/ul)']) * 5

                    if well not in concentrations:
                        concentrations[well] = concentration
                    else:
                        concentrations[well] = (concentrations[well] + concentration) / 2
                except (KeyError, ValueError):
                    pass

            search_xml = clarity.get_xml(clarity.root + "containers?udf.WTSI%20Container%20Signature=" + signature)
            container_uri = search_xml.find("container").get('uri')

            container_xml = clarity.get_xml(container_uri)
            placement_uris = {placement.get('uri') for placement in container_xml.findall('placement')}
            artifact_xmls = clarity.batch_get_xml('artifacts', placement_uris)
            sample_uris = {artifact.find('sample').get('uri') for artifact in artifact_xmls}
            sample_xmls = clarity.batch_get_xml('samples', sample_uris)

            post_xmls = []

            for placement_uri in placement_uris:
                artifact_xml = \
                    [artifact for artifact in artifact_xmls if artifact.get('uri').startswith(placement_uri)][0]
                sample_uri = artifact_xml.find('sample').get('uri')
                sample_xml = [sample for sample in sample_xmls if sample.get('uri') == sample_uri][0]

                well = artifact_xml.find('location').find('value').text.replace(':', '')

                if well in molarities:
                    molarity = str(molarities[well])
                    change_xml(sample_xml, MOLARITY, molarity)

                if well in concentrations:
                    concentration = str(concentrations[well])
                    change_xml(sample_xml, CONCENTRATION, concentration)

                post_xmls.append(sample_xml)

            clarity.batch_post_xml('samples', post_xmls)
