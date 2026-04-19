#!/usr/bin/env python3
"""
parse_service_configs.py — reads concatenated etcd service config JSON from stdin,
extracts Name/Port/Address/Version from each config blob, and writes one of:
  --mode table   → markdown table rows (default)
  --mode json    → {"count":N,"services":[...]}
"""
import sys
import json

mode = "table"
if "--mode" in sys.argv:
    idx = sys.argv.index("--mode")
    if idx + 1 < len(sys.argv):
        mode = sys.argv[idx + 1]

data = sys.stdin.read()
decoder = json.JSONDecoder()
pos = 0
services = []

while pos < len(data):
    rest = data[pos:]
    data_slice = rest.lstrip()
    if not data_slice:
        break
    stripped = len(rest) - len(data_slice)  # chars removed by lstrip
    try:
        obj, end = decoder.raw_decode(data_slice)
        pos += stripped + end
        if not isinstance(obj, dict):
            continue
        name    = obj.get("Name") or obj.get("name") or ""
        port    = obj.get("Port") or obj.get("port") or 0
        address = obj.get("Address") or obj.get("address") or ""
        version = obj.get("Version") or obj.get("version") or ""
        # Only include top-level service configs that have a Name field.
        # Instance/proxy records typically lack "Name" or have no port.
        if name and "." in name:
            services.append({
                "name":    name,
                "port":    port,
                "address": address,
                "version": version,
            })
    except json.JSONDecodeError:
        nxt = data_slice.find("{", 1)
        if nxt < 0:
            break
        pos += stripped + nxt

services.sort(key=lambda s: s["name"])

if mode == "json":
    print(json.dumps({"count": len(services), "services": services}))
else:
    for s in services:
        print("| {} | {} | {} | {} |".format(
            s["name"], s["port"], s["address"], s["version"]))
