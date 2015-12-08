import getpass
import re
import urllib.request as request
from collections import defaultdict
from urllib.error import HTTPError
from xml.etree import ElementTree

import sys

BATCHABLE = ('artifacts', 'containers', 'files', 'samples')

__author__ = 'rf9'


class ClarityException(Exception):
    pass


class Clarity:
    def __init__(self, root):
        if root[-1] != '/':
            root += "/"
        self.root = root

        user = getpass.getuser()
        user = input("Username (leave blank for '" + user + "'): ") or user
        password = getpass.getpass('Password: ')

        try:
            self.setup_urllib(user, password)
        except HTTPError as err:
            if err.msg == "Unauthorized":
                sys.stderr.write("Invalid username or password\n")
            else:
                sys.stderr.write("Invalid root uri\n")
            sys.exit(1)

        self.cache = {}

    def setup_urllib(self, user, password):
        password_mgr = request.HTTPPasswordMgrWithDefaultRealm()
        password_mgr.add_password(None, self.root, user, password)
        handler = request.HTTPBasicAuthHandler(password_mgr)
        opener = request.build_opener(handler)
        opener.open(self.root)
        request.install_opener(opener)

    def get_xml(self, uri_list, use_cache=True):

        # Allow to be called with a single uri and return a single element (Not in list)
        if isinstance(uri_list, str):
            return self.get_xml([uri_list], use_cache)[0]

        uri_list = list(set(uri_list))

        elements = []

        # Get all the elements you can from the cache
        if use_cache:
            for uri in list(uri_list):
                if uri in self.cache:
                    elements.append(self.cache[uri])
                    uri_list.remove(uri)

        # Split the uris into their object types
        partitioned_uris = defaultdict(list)
        for uri in uri_list:
            # Match a string of not '/' after the root url.
            m = re.match(self.root + '([^/]*)', uri)
            object_type = m.group(1) if m else None
            partitioned_uris[object_type].append(uri)

        for object_type in partitioned_uris:
            if object_type in BATCHABLE:
                elements += self._batch_get_xml(partitioned_uris[object_type], object_type)
            else:
                for uri in partitioned_uris[object_type]:
                    print('Downloading: ' + uri)
                    with request.urlopen(uri) as response:
                        self.cache[uri] = ElementTree.parse(response).getroot()
                    elements.append(self.cache[uri])

        return elements

    def _batch_get_xml(self, uri_list, object_type):
        print('Downloading %d %s' % (len(uri_list), object_type))

        builder = ElementTree.TreeBuilder()
        builder.start('ri:links', {
            'xmlns:ri': "http://genologics.com/ri",
        })
        xml_element = builder.close()

        for uri in uri_list:
            child = ElementTree.TreeBuilder().start('link', {
                'uri': uri,
                'rel': object_type,
            })
            xml_element.append(child)

        req = request.Request(url=(self.root + object_type + '/batch/retrieve'), data=ElementTree.tostring(xml_element),
                              method='POST')
        req.add_header("Content-Type", "application/xml")

        with request.urlopen(req) as response:
            elements = ElementTree.parse(response).getroot().getchildren()

        for element in elements:
            self.cache[element.get('uri')] = element

        return elements

    def batch_post_xml(self, object_type, xml_list):
        if object_type not in BATCHABLE:
            raise ClarityException("Cannot batch %r" % object_type)

        builder = ElementTree.TreeBuilder()
        builder.start('ns0:details', {
        })
        element = builder.close()

        for xml in xml_list:
            element.append(xml)

        req = request.Request(url=(self.root + object_type + '/batch/update'), data=ElementTree.tostring(element),
                              method='POST')
        req.add_header("Content-Type", "application/xml")

        with request.urlopen(req) as response:
            return ElementTree.parse(response).getroot().getchildren()
