#!/bin/bash

WORKFLOW_ID=$(gh api repos/zhaow-de/rotating-tor-http-proxy/actions/workflows --paginate | jq '.workflows[] | select(.["name"] == "auto-upgrade") | .id')
RUN_IDS=$(gh api repos/zhaow-de/rotating-tor-http-proxy/actions/workflows/$WORKFLOW_ID/runs --paginate | jq '.workflow_runs[].id')

for run_id in ${RUN_IDS}
do
  echo "Deleting Run ID $run_id"
  gh api repos/zhaow-de/rotating-tor-http-proxy/actions/runs/$run_id -X DELETE >/dev/null
done
