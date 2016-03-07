#!/usr/bin/env python3

import sys

from clarity import Clarity

if __name__ == "__main__":
    if len(sys.argv) == 3:
        root_url = sys.argv[1]
        out_file_path = sys.argv[2]
    else:
        sys.stderr.write("usage: python backfill_billing.py <root_uri> <output_file>\n")
        sys.exit(1)

    clarity = Clarity(root_url)

    with open(out_file_path, mode='w') as out:
        print('#!/bin/bash', file=out)
        print(file=out)

        for step, purpose in [('Fluidigm 96.96 IFC Analysis (SM)', 'charging_fluidigm'),
                              ('E-Gel Creation (SM)', 'charging_secondary_qc'),
                              ('Post Capture Library Pooling', 'charging_library_construction'),
                              ('Sequencing Data Manual QC (NPG)', 'charging_sequencing')]:
            step = step.replace(' ', '%20')
            processes = clarity.get_object(clarity.root + 'processes?type=' + step).find('process').get('uri')

            for process in processes:
                string = 'epp --action queue_message --routing_key event --purpose %s --process_url %s --step_url %s'
                print(string % (purpose, process, process.replace('processes', 'steps')), file=out)

            print(file=out)
