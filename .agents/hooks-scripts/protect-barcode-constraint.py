#!/usr/bin/env python3
import sys
import json

def main():
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        print(json.dumps({"decision": "allow"}))
        return

    tool_call = data.get("toolCall", {})
    args = tool_call.get("args", {})

    content = (
        str(args.get("ReplacementChunks", ""))
        + str(args.get("CodeContent", ""))
    )

    lower = content.lower()
    if "barcodes" in lower and (
        "drop index" in lower
        or "drop constraint" in lower
        or (".unique()" in lower and "false" in lower)
    ):
        print(json.dumps({
            "decision": "deny",
            "reason": (
                "The UNIQUE constraint on barcodes.code is required for "
                "correctness. Do not drop or weaken it."
            )
        }))
        return

    print(json.dumps({"decision": "allow"}))

if __name__ == "__main__":
    main()