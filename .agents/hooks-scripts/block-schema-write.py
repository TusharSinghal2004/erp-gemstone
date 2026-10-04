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

    target = (
        args.get("TargetFile", "")
        or args.get("AbsolutePath", "")
        or ""
    )
    content = (
        str(args.get("ReplacementChunks", ""))
        + str(args.get("CodeContent", ""))
        + str(args.get("CommandLine", ""))
    )

    if "schema.ts" in target or "schema.ts" in content:
        print(json.dumps({
            "decision": "deny",
            "reason": (
                "src/db/schema.ts is protected. The schema is hand-written and "
                "frozen. Stop and ask the human for explicit approval before "
                "modifying it."
            )
        }))
        return

    print(json.dumps({"decision": "allow"}))

if __name__ == "__main__":
    main()