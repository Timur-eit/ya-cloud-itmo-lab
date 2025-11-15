from datetime import datetime
import json


def handler(event, context):
    now = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    context_id = getattr(context, "execution_id", None)

    print("=== SERVERLESS FUNCTION START ====")
    print("event =", json.dumps(event))
    print("context_id =", context_id)

    filename = f"/tmp/event_{now}.txt"

    content = {
        "datetime": now,
        "event": event,
        "context_info": {
            "function_id": getattr(context, "function_id", None),
            "execution_id": context_id,
        },
    }

    with open(filename, "w") as f:
        f.write(json.dumps(content, indent=2))

    print("File written:", filename)

    try:
        with open(filename, "r") as f:
            file_contents = f.read()
    except Exception as e:
        print("Error reading file:", e)
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Failed to read temporary file"}),
        }

    print("=== FILE CONTENT START ===")
    print("file_contents =", json.dumps(file_contents))
    print("=== FILE CONTENT END ===")

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {"status": "OK", "filename": filename, "fileContents": file_contents}
        ),
    }

    # return {"status": "OK", "message": f"Event saved to {filename}"}
    # return {
    #     "statusCode": 200,
    #     "headers": {"Content-Type": "application/json"},
    #     "body": json.dumps({"status": "OK", "message": f"Event saved to {filename}"}),
    # }


# для локального запуска
if __name__ == "__main__":
    # фиктивный event/context для отладки
    test_event = {
        "bucket": "test-bucket",
        "object_id": "input/file.txt",
        "event_type": "create-object",
    }
    test_context = {"function_id": "local-debug"}
    result = handler(test_event, test_context)
    print(result)
