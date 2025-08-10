import boto3
import os

def lambda_handler(event, context):
    instance_id = os.environ.get("INSTANCE_ID")
    region = os.environ.get("REGION")

    ec2 = boto3.client("ec2", region_name=region)
    ec2.start_instances(InstanceIds=[instance_id])

    print(f"Started instance: {instance_id} in region: {region}")

