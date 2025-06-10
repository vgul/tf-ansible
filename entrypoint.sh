#!/bin/bash

export AWS_CONFIG_FILE=${AWS_CONFIG_FILE:-/dev/null} # critical for ruby aws sdk

: echo "Pre-start tasks..."
source /etc/profile  # load env

# main run
exec "$@"

