#!/usr/bin/python3                                                                                                                                                                           

import argparse
import json
import requests
import sys 
import urllib.parse

parser = argparse.ArgumentParser()
parser.add_argument("-db", required=True, type=str, help="Database name")
parser.add_argument("-view", required=True, type=str, help="view Name")
parser.add_argument("-key", required=True, type=str, help="Key to search")
args = parser.parse_args()

database = args.db
view = args.view
key = args.key

couch_base_url = "http://localhost:6000/{}".format(database)

url_encode = urllib.parse.quote(key)
print(url_encode)
response = requests.get(couch_base_url + "/_design/api/_view/" + view + "?key=\"" + url_encode + "\"")

if (response.status_code == 200):
    rows = json.loads(response.text)['rows']
    print("Total matching rows found in given Database: " + str(len(rows)))
    print(rows)
else:
    print("Issue while connection to couch: " + response.text)
