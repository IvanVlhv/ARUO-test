#!/usr/bin/env bash
set -euo pipefail

RG_NAME="${1:?Usage: ./list_resources.sh <resource-group-name>}"
az resource list --resource-group "$RG_NAME" --output table
