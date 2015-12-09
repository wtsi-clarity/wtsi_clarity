#!/usr/bin/env python3

import os

import sys

from clarity import Clarity

FILE_DIR = os.path.dirname(os.path.realpath(__file__))
FIELD = "{http://genologics.com/ri/userdefined}field"
SUPPLIER_NAME = "WTSI Supplier Sample Name (SM)"

if __name__ == "__main__":
    clarity = Clarity(sys.argv[1])

    signatures = ['%2BDKO4', '%2BOYEX', '203SE', '4T0TW', '5I7CR', '78S5O', '7LJTU', '8DDJZ', '8JT81', 'AQIG3', 'DCYSM',
                  'EEO19', 'F82NF', 'FDMCN', 'FLDIM', 'FMHGG', 'HXERB', 'J1RK4', 'OBQ%2B7', 'OIEWK', 'Q19LN', 'QC6FZ',
                  'RJDUP', 'WHBWK', '6FG8L', 'APBRC', 'DHWS9', 'EDTMV', 'HLEDS', 'RYGCM', 'SK4YN', 'XSMIN', 'YN7%2F%2F',
                  'ZTGUA']

    # for (directory, subdirectories, filenames) in os.walk(os.path.join(FILE_DIR, 'backfill2')):
    #     for filename in filenames:
    #         signatures.append(filename.split('_')[1])

    url = clarity.root + 'containers?' + '&'.join(
        ['udf.WTSI%20Container%20Signature=' + signature for signature in signatures])

    # uuids = []
    #
    # for signature in signatures:
    #     containers = clarity.get_xml(clarity.root + 'containers?udf.WTSI%20Container%20Signature=' + signature)
    #     container = containers.findall('container')[0]
    #
    #     container_xml = clarity.get_xml(container.get('uri'))
    #     artifact_uris = {placement.get('uri') for placement in container_xml.findall('placement')}
    #     artifacts = clarity.batch_get_xml('artifacts', artifact_uris)
    #     sample_uris = {artifact.find('sample').get('uri') for artifact in artifacts}
    #     samples = clarity.batch_get_xml('samples', sample_uris)
    #     uuid = {sample.find('name').text for sample in samples}
    #     uuids += uuid
    #
    # with open('sample_names.txt', 'w') as f:
    #     f.writelines('\n'.join(uuids))

    batch_size = 100

    with open('sample_names.txt', 'r') as fin:
        with open('sample_names_and_suplier.txt', 'w') as fout:
            uuids = [uuid.strip() for uuid in fin]
            for i in range(0, len(uuids), batch_size):
                search_xml = clarity.get_xml(
                    clarity.root + 'samples?' + '&'.join(['name=' + uuid.strip() for uuid in uuids[i:i + batch_size]]))
                sample_uris = [sample.get('uri') for sample in search_xml.findall('sample')]
                samples = clarity.batch_get_xml('samples', sample_uris)

                for sample in samples:
                    supplier = [field.text for field in sample.findall(FIELD) if field.get('name') == SUPPLIER_NAME][0]

                    print(sample.find('name').text + ',' + supplier, file=fout)
