#!/usr/bin/env python3
import sys

from clarity import Clarity

FIELD = "{http://genologics.com/ri/userdefined}field"

if __name__ == '__main__':
    if len(sys.argv) == 4:
        root_url = sys.argv[1]
        in_file = sys.argv[2]
        out_file = sys.argv[3]
    else:
        sys.stderr.write("usage: python samples_to_uuid_and_container.py <root_uri> <input_file> <output_file>\n")
        sys.exit(1)

    clarity = Clarity(root_url)

    with open(in_file) as f:
        uuids = [l.strip() for l in f][:10]

    batch_size = 100

    sample_ids = []

    for i in range(0, len(uuids), batch_size):
        search_xml = clarity.get_xml(
            clarity.root + 'samples?' + '&'.join(['name=' + uuid.strip() for uuid in uuids[i:i + batch_size]]))
        sample_ids += [sample.get('limsid') for sample in search_xml.findall('sample')]

    samples = clarity.get_xml([clarity.root + 'samples/' + sample_id for sample_id in sample_ids])
    samples = clarity.get_xml([clarity.root + 'samples/' + sample_id for sample_id in sample_ids])

    search_xml = [clarity.get_xml(
        'http://web-clarityprod-01.internal.sanger.ac.uk:8080/api/v2/artifacts'
        '?process-type=Post%20Lib%20PCR%20QC%20GetData'
        '&samplelimsid=' + sample_id) for sample_id in sample_ids]

    artifact_uris = {artifact.get('uri') for result in list(search_xml) for artifact in result.findall('artifact')}

    artifacts = clarity.get_xml(artifact_uris)

    parent_process_uris = list({artifact.find('parent-process').get('uri') for artifact in artifacts})

    parent_artifact_uris = []
    for parent_process_uri in parent_process_uris:
        process = clarity.get_xml(parent_process_uri)
        parent_artifact_uris.append(process.find('input-output-map').find('input').get('uri'))

    parent_artifacts = clarity.get_xml(parent_artifact_uris)
    container_uris = {artifact.find("location").find('container').get('uri') for artifact in parent_artifacts}
    containers = clarity.get_xml(container_uris)

    with open(out_file, 'w') as fout:
        for uuid in uuids:
            sample = [sample for sample in samples if sample.find('name').text == uuid][0]
            supplier = [field.text for field in sample.findall(FIELD)
                        if field.get('name') == 'WTSI Supplier Sample Name (SM)'][0]

            artifact = [artifact for artifact in artifacts
                        if artifact.find('sample').get('limsid') == sample.get('limsid')][0]
            process = clarity.get_xml(artifact.find('parent-process').get('uri'))
            parent_artifact = clarity.get_xml(process.find('input-output-map').find('input').get('uri'))
            container = clarity.get_xml(parent_artifact.find('location').find('container').get('uri'))
            barcode = container.find('name').text

            print(uuid, supplier, barcode, sep=',', file=fout)
