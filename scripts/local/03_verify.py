#!/usr/bin/env python3
"""Verifica VPC/EC2/IAM/S3 en LocalStack por tag. No prueba HTTP/phpinfo (ADR 004)."""

from __future__ import annotations

import os
import sys

import boto3
from botocore.exceptions import ClientError

ENDPOINT = os.environ.get("AWS_ENDPOINT_URL", "http://localhost:4566")
REGION = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")
PROJECT = os.environ.get("PROJECT_NAME", "poc-cloud-foundation-lab")
BUCKET = os.environ.get("BUCKET_NAME", f"{PROJECT}-data")
ROLE = os.environ.get("ROLE_NAME", f"{PROJECT}-ec2")


def client(service: str):
    return boto3.client(
        service,
        region_name=REGION,
        endpoint_url=ENDPOINT,
        aws_access_key_id=os.environ.get("AWS_ACCESS_KEY_ID", "test"),
        aws_secret_access_key=os.environ.get("AWS_SECRET_ACCESS_KEY", "test"),
    )


def fail(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    print(f"==> 03_verify: endpoint={ENDPOINT} region={REGION} project={PROJECT}")
    print("Criterio: recursos visibles en la API. phpinfo no se consulta.")

    ec2 = client("ec2")
    iam = client("iam")
    s3 = client("s3")

    vpcs = ec2.describe_vpcs(
        Filters=[
            {"Name": "tag:Project", "Values": [PROJECT]},
            {"Name": "tag:Environment", "Values": ["local"]},
        ]
    )["Vpcs"]
    if not vpcs:
        fail(f"no hay VPC con tag Project={PROJECT} Environment=local")
    vpc_id = vpcs[0]["VpcId"]
    print(f"OK  VPC {vpc_id}")

    instances = ec2.describe_instances(
        Filters=[
            {"Name": "tag:Project", "Values": [PROJECT]},
            {"Name": "tag:Environment", "Values": ["local"]},
            {"Name": "instance-state-name", "Values": ["pending", "running"]},
        ]
    )["Reservations"]
    instance_ids = [
        inst["InstanceId"]
        for res in instances
        for inst in res.get("Instances", [])
    ]
    if not instance_ids:
        fail("no hay instancia running/pending con esos tags")
    print(f"OK  EC2 {instance_ids[0]} (user-data no se valida en Community)")

    try:
        role = iam.get_role(RoleName=ROLE)["Role"]
    except ClientError as exc:
        fail(f"rol {ROLE}: {exc}")
    print(f"OK  IAM role {role['Arn']}")

    try:
        s3.head_bucket(Bucket=BUCKET)
    except ClientError as exc:
        fail(f"bucket {BUCKET}: {exc}")
    print(f"OK  S3 bucket {BUCKET}")

    print("Stack local verificado. Segunda corrida de este script debe dar el mismo resultado.")


if __name__ == "__main__":
    main()
