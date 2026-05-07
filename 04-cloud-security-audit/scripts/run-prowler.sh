#!/bin/bash

set -e

OUTPUT_DIR="./reports"

mkdir -p $OUTPUT_DIR

prowler aws \
    --profile security-audit \
    --service iam s3 cloudwatch cloudtrail ec2 vpc \
    --output-formats json-ocsf html \
    --output-directory $OUTPUT_DIR \
    --severity critical high medium low \



echo "Prowler scan completed. Results saved in $OUTPUT_DIR"
