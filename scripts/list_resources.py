#!/usr/bin/env python3
import json
import subprocess
import sys

if len(sys.argv) != 2:
    print("Usage: python list_resources.py <resource-group-name>")
    sys.exit(1)

rg_name = sys.argv[1]
result = subprocess.run(
    ["az", "resource", "list", "--resource-group", rg_name, "--output", "json"],
    check=True,
    capture_output=True,
    text=True,
)
resources = json.loads(result.stdout)
for item in resources:
    print(f"{item['type']} | {item['name']} | {item['location']}")
