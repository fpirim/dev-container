#!/bin/bash
set -eu
set -o allexport 
source /etc/environment 
set +o allexport

sudo /usr/sbin/sshd -D &
exec "$@"