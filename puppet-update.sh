#!/bin/bash
# Updates the puppet code and runs the update script, which runs puppet apply.

cd /etc/puppet/code || exit 1

git pull > /dev/null || exit 1

# Until postgresql_password deprecation fixes have landed, redirect stderr as well to avoid clutter in logs and email
./update.sh &> /dev/null || exit 1
