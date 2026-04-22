import json
import boto3
import os

glue = boto3.client("glue", region_name="us-east-2")
JOB_NAME = os.environ["GLUE_JOB_NAME"]


def handler(event, context):
    for record in event["Records"]:
        body = json.loads(record["body"])
        # Cada record es un evento S3
        for s3_event in body.get("Records", []):
            key = s3_event["s3"]["object"]["key"]
            print(f"Triggering Glue job for key: {key}")
            glue.start_job_run(
                JobName=JOB_NAME,
                Arguments={"--source_key": key},
            )
