#!/bin/bash

if [[ -z $FOO_OUTPUT_DIR ]]; then
    echo "ERROR: \$FOO_OUTPUT_DIR is not defined" >&2
    exit 1
fi

mkdir -p $FOO_OUTPUT_DIR

echo "Hello from $TASK_NAME at $CYCLE_TIME in $CYLC_SUITE_NAME"

sleep $TASK_EXE_SECONDS

touch $FOO_OUTPUT_DIR/data.$CYCLE_TIME

echo "Goodbye"
