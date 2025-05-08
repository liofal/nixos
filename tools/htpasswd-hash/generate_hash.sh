#!/usr/bin/env bash
set -euo pipefail

read -rsp "Enter password to hash: " PASSWORD_TO_HASH
echo
htpasswd -bnBC 10 "" "${PASSWORD_TO_HASH}" | tr -d ':\n'
echo # Add a final newline for cleaner terminal output
