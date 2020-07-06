#!/bin/bash
db_name=$1
location=$2
recipient=$3
timestamp=$(date +"%Y-%m-%d_%H%M%S")
mysqldump $db_name | gpg --encrypt --output $location/${db_name}_$timestamp.sql.gpg -r $recipient
