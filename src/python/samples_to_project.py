#!/usr/bin/env python3
import sys

from clarity import Clarity

if __name__ == '__main__':
    if len(sys.argv) == 4:
        root_url = sys.argv[1]
        in_file = sys.argv[2]
        out_file = sys.argv[3]
    else:
        sys.stderr.write("usage: python samples_to_project.py <root_uri> <input_file> <output_file>\n")
        sys.exit(1)

    clarity = Clarity(root_url)

    with open(in_file) as f:
        uuids = [l.strip() for l in f]

    batch_size = 100

    sample_uris = []

    for i in range(0, len(uuids), batch_size):
        search_xml = clarity.get_xml(
            clarity.root + 'samples?' + '&'.join(['name=' + uuid.strip() for uuid in uuids[i:i + batch_size]]))
        sample_uris += [sample.get('uri') for sample in search_xml.findall('sample')]

    samples = clarity.get_xml(sample_uris)

    project_uris = {sample.find('project').get('uri') for sample in samples}
    projects = clarity.get_xml(project_uris)

    with open(out_file, 'w') as fout:
        for sample in samples:
            uuid = sample.find('name').text
            project = clarity.get_xml(sample.find('project').get('uri'))
            project_name = project.find('name').text

            print(uuid, project_name, sep=',', file=fout)