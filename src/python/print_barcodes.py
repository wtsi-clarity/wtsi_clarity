import getpass
from datetime import datetime

import requests

ROOT_URL = 'http://psd2-s2a.internal.sanger.ac.uk:8000/lims-support/'


def get_printers(root):
    headers = {
        'Content-type': 'application/json',
        'Accept': 'application/json'
    }
    r = requests.get(root + 'label_printers/page=1', headers=headers)
    content = r.json()

    return {printer['name']: printer['uuid'] for printer in content['label_printers']
            if 'clarity_plate' in [template['name'] for template in printer['templates']]}


def make_json(barcodes, user):
    date = datetime.now()
    time_and_date = date.strftime('%a %b %d %H:%M:%S %Y')
    date = date.strftime('%d-%b-%Y')

    labels = []

    for barcode in barcodes:
        label = {
            "template": "clarity_plate",
            "plate": {
                "ean13": barcode['barcode'],
                "label_text": {
                    "date_user": date,
                    "purpose": barcode['purpose'],
                    "num": "",
                    "signature": "",
                    "sanger_barcode": barcode['barcode']
                }
            }
        }

        labels += [label for n in range(barcode['count'])]

    message = {
        "label_printer": {
            "footer_text": {
                "footer_text2": time_and_date,
                "footer_text1": "footer by %s" % user
            },
            "header_text": {
                "header_text2": time_and_date,
                "header_text1": "header by %s" % user
            },
            "labels": labels
        }
    }

    return message


def print_barcode(root, uuid, message):
    headers = {
        'Content-type': 'application/json',
        'Accept': 'application/json'
    }
    r = requests.post(root + uuid, headers=headers, json=message)

    return r.status_code


def main():
    printers = get_printers(ROOT_URL)
    print('Printers:', ', '.join(printers.keys()))

    printer_uuid = printers[input('Select printer: ')]

    os_user = getpass.getuser()
    user = input("Username (leave blank for %r): " % os_user) or os_user

    barcodes = []

    while True:
        barcode = input('Barcode (leave blank to stop): ')

        if not barcode:
            break

        purpose = input('Purpose: ')
        count = int(input('Count: '))

        barcodes.append({
            'barcode': barcode,
            'purpose': purpose,
            'count': count,
        })

    if barcodes:
        message = make_json(barcodes, user)
        response = print_barcode(ROOT_URL, printer_uuid, message)

        if response != 200:
            print("Failed.")


if __name__ == '__main__':
    main()
