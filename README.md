# couch-utils

How to get, post, put, delete data from your couchDB.
This is just a wrapper aroung the couch endpoints to make your job easier.

1. bulk_delete_from_couch.py
      1. Delete bulk data from couch based on some selection criteria
      2. Before deletion it will ask for confirmation.
      3. Usage - python3 bulk_delete_from_couch.py -db <database_name> -id <matching id to delete>
    
      You can put a matching id like critria also e.g. delete all id which starts with "2019-09" and it will delete all matching 2019-09*.
        
  
2. query_couch.py
      1. Get result set from a particular view based on particular search key.
      2. Usage - python3 query_couch.py -db <database_name> -view <view_name> -key <key_to_seach>
      
      
3. perform_couch_operations.pl
       1. Insert, Update, Delete, Select from CouchDB
