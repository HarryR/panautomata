#!/usr/bin/env python3
import json
import sys

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: %s <solc-output.json>" % (sys.argv[0],))
        sys.exit(1)
    with open(sys.argv[1], 'r') as handle:
        data = json.load(handle)
        print(json.dumps(data['abi']))
    sys.exit(0)
