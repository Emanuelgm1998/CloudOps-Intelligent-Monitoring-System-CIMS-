#!/usr/bin/env bash
CMD=$1
shift || true

if [ -z "$CMD" ]; then
  echo "CloudOps CLI"
  echo "Usage:"
  echo "  ./cli/cloudopsctl.sh status"
  echo "  ./cli/cloudopsctl.sh cleanup"
  echo "  ./cli/cloudopsctl.sh restart <service>"
  exit 0
fi

node src/cli.js "$CMD" "$@"
