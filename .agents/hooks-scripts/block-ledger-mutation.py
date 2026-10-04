#!/usr/bin/env python3
import sys
import json
import re

APPEND_ONLY_TABLES = ["stock_ledger", "barcode_events"]

def main():
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        print(json.dumps({"decision": "allow"}))
        return

    tool_call = data.get("toolCall", {})
    args = tool_call.get("args", {})

    content = (
        str(args.get("CommandLine", ""))
        + str(args.get("ReplacementChunks", ""))
        + str(args.get("CodeContent", ""))
    )

    for table in APPEND_ONLY_TABLES:
        pattern = rf"\b(UPDATE|DELETE\s+FROM)\s+{re.escape(table)}\b"
        if re.search(pattern, content, re.IGNORECASE):
            print(json.dumps({
                "decision": "deny",
                "reason": (
                    f"{table} is append-only. Use an INSERT reversing entry "
                    f"instead of UPDATE or DELETE."
                )
            }))
            return

    print(json.dumps({"decision": "allow"}))

if __name__ == "__main__":
    main()