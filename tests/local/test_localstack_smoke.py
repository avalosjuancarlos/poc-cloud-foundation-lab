from __future__ import annotations

import os
import urllib.error
import urllib.request

import boto3
import pytest
from botocore.exceptions import ClientError

ENDPOINT = os.environ.get("AWS_ENDPOINT_URL", "http://localhost:4566")
REGION = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")
PROJECT = os.environ.get("PROJECT_NAME", "poc-cloud-foundation-lab")
BUCKET = os.environ.get("BUCKET_NAME", f"{PROJECT}-data")
ROLE = os.environ.get("ROLE_NAME", f"{PROJECT}-ec2")


def _localstack_up() -> bool:
    try:
        urllib.request.urlopen(f"{ENDPOINT}/_localstack/health", timeout=2)
        return True
    except (urllib.error.URLError, TimeoutError, OSError):
        return False


pytestmark = pytest.mark.skipif(
    not _localstack_up(),
    reason="LocalStack no está en :4566 (correr pytest en el devcontainer tras 01_up/02_apply)",
)


def _client(service: str):
    return boto3.client(
        service,
        region_name=REGION,
        endpoint_url=ENDPOINT,
        aws_access_key_id=os.environ.get("AWS_ACCESS_KEY_ID", "test"),
        aws_secret_access_key=os.environ.get("AWS_SECRET_ACCESS_KEY", "test"),
    )


def test_vpc_tagged_exists() -> None:
    vpcs = _client("ec2").describe_vpcs(
        Filters=[
            {"Name": "tag:Project", "Values": [PROJECT]},
            {"Name": "tag:Environment", "Values": ["local"]},
        ]
    )["Vpcs"]
    assert vpcs, f"no hay VPC con Project={PROJECT}"


def test_instance_tagged_exists() -> None:
    reservations = _client("ec2").describe_instances(
        Filters=[
            {"Name": "tag:Project", "Values": [PROJECT]},
            {"Name": "tag:Environment", "Values": ["local"]},
            {"Name": "instance-state-name", "Values": ["pending", "running"]},
        ]
    )["Reservations"]
    ids = [i["InstanceId"] for r in reservations for i in r.get("Instances", [])]
    assert ids, "no hay instancia running/pending"


def test_role_and_bucket_exist() -> None:
    iam = _client("iam")
    s3 = _client("s3")
    role = iam.get_role(RoleName=ROLE)["Role"]
    assert "Arn" in role
    try:
        s3.head_bucket(Bucket=BUCKET)
    except ClientError as exc:
        pytest.fail(f"bucket {BUCKET}: {exc}")
