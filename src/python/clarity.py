import getpass
import os
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
    def __init__(self, root, user=None, password=None):
        if root[-1] != '/':
            root += "/"
        self.root = root

        os_user = getpass.getuser()
        user = user or os.environ.get('USERNAME') or input("Username (leave blank for %r): " % os_user) or os_user
        password = password or os.environ.get('PASSWORD') or getpass.getpass('Password: ')

        self.opener = self.make_opener(user, password)
        try:
            # Test the credentials
            with self.opener.open(self.root):
                pass
        except HTTPError as err:
            if err.msg == "Unauthorized":
                sys.stderr.write("Invalid username or password\n")
            else:
                sys.stderr.write("Invalid root uri\n")
            sys.exit(1)

        self.cache = {}

    def make_opener(self, user, password):
        password_mgr = request.HTTPPasswordMgrWithDefaultRealm()
        password_mgr.add_password(None, self.root, user, password)
        handler = request.HTTPBasicAuthHandler(password_mgr)
        return request.build_opener(handler)

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
                    with self.opener.open(uri) as response:
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

        with self.opener.open(req) as response:
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

        with self.opener.open(req) as response:
            return ElementTree.parse(response).getroot().getchildren()

    def get_object(self, uri):
        return ClarityElement(self, [self.get_xml(uri)])


class ClarityElement:
    def __init__(self, clarity, xml_list):
        self.clarity = clarity
        self.xml_list = xml_list

    def get(self, item):
        # Try the xml method
        try:
            return [getattr(xml, item) for xml in self.xml_list]
        except AttributeError:
            pass

        # Look for the attribute
        attributes = [x for x in [xml.attrib.get(item) for xml in self.xml_list] if x is not None]
        if attributes:
            return attributes

        # Look for a child
        elements = [child for xml in self.xml_list for child in xml.findall(item)]
        if elements:
            return ClarityElement(self.clarity, elements)

        # If it has a url, fetch the urls and try with the fetched objects.
        uris = [x for x in [xml.get('uri') for xml in self.xml_list] if x is not None]
        if uris:
            try:
                return ClarityElement(self.clarity, self.clarity.get_xml(uris)).get(item)
            except RuntimeError as err:
                pass

        return []

    def get_first(self, item):
        values = self.get(item)
        return values[0] if values else None

    def __iter__(self):
        self.n = 0
        return self

    def __next__(self):
        if self.n < len(self):
            element = ClarityElement(self.clarity, [self.xml_list[self.n]])
            self.n += 1
            return element
        else:
            raise StopIteration

    def __len__(self):
        return len(self.xml_list)

    def __bool__(self):
        return bool(self.xml_list)


if __name__ == '__main__':
    clarity_class = Clarity('http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2')

    container = clarity_class.get_object(clarity_class.root + 'containers/27-12105')

    # print(container.attrib)
    # print(container.limsid)
    # print(container.name.text)
    #
    # artifacts = container.placement
    #
    # print(artifacts.limsid)
    # print(artifacts.value.text)
    # print(artifacts.name)
    # print(artifacts.name.text)
    # print(artifacts.sample.limsid)

    print(container.foo)
