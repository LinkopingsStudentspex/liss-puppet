#!/bin/bash
# Updates the puppet code and runs the update script, which runs puppet apply.

cd /etc/puppet/code

git pull || exit 1
./update.sh || exit 1
