#!/bin/bash
db_name=$1
location=$2
recipient=$3
timestamp=$(date +"%Y-%m-%d_%H%M%S")
/sbin/runuser -u postgres -- pg_dump -Fc $db_name | gpg --encrypt --output $location/${db_name}_$timestamp.dump.gpg -r $recipient
