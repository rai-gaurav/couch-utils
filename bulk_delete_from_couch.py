 
#!/usr/bin/python3

import argparse
import json
import requests
import sys

parser = argparse.ArgumentParser()
parser.add_argument("-db", required=True, type=str, help="Database name")
parser.add_argument("-id", required=True, type=str, help="Id to delete")
args = parser.parse_args()

database = args.db
ids_to_delete = args.id

couch_base_url = "http://localhost:5050/{}".format(database)

response = requests.get(couch_base_url + "/_all_docs")

if (response.status_code == 200):
    rows = json.loads(response.text)['rows']
    print("Total document found in given Database: " + str(len(rows)))

    todelete = []
    for doc in rows:
        if ids_to_delete in doc["id"]:
            todelete.append(
                {"_deleted": True, "_id": doc["id"], "_rev": doc["value"]["rev"]})

    print("Total Document to be deleted matching criteria: " + str(len(todelete)))

    if (len(todelete) != 0):
        user_input = input(
            "Press 'y' to continue deletion, press 'n' to exit... ")

        if user_input == "y" or user_input == "Y":
            r = requests.post(
                couch_base_url + "/_bulk_docs", json={"docs": todelete})
            print("Deleted!! Status Code: " + str(r.status_code))
        else:
            print("Wise Decision! With Great Power Comes Great Responsibility.")
            print("Better do nothing than screw anything.")
    else:
        print("Noting to Delete. Exiting!!!")
else:
    print("Issue while connection to couch: " + response.text)
