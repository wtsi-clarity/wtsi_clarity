#!/usr/bin/env python3
import sys

from clarity import Clarity

if __name__ == '__main__':
    if len(sys.argv) == 4:
        root_url = sys.argv[1]
        in_file = sys.argv[2]
        out_file = sys.argv[3]
    else:
        sys.stderr.write("usage: python list_epp.py <root_uri> <input_file> <output_file>\n")
        sys.exit(1)

    clarity = Clarity.new(root_url)

    with open(in_file) as f:
        uuids = [l.strip() for l in f]

    batch_size = 100

    sample_ids = []

    for i in range(0, len(uuids), batch_size):
        search_xml = clarity.get_xml(
            clarity.root + 'samples?' + '&'.join(['name=' + uuid.strip() for uuid in uuids[i:i + batch_size]]))
        sample_ids += [sample.get('limsid') for sample in search_xml.findall('sample')]

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

    with open(out_file, 'w') as fout:
        for container_uri in container_uris:
            print(container_uri, file=fout)
